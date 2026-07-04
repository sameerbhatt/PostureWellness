//
//  PostureCalculator.swift
//  PostureWellness
//
//

import Foundation
import Vision

// MARK: - Joint Points

struct JointPoints {
    let nose: CGPoint?
    let neck: CGPoint?
    let leftShoulder: CGPoint?
    let rightShoulder: CGPoint?
    let leftEar: CGPoint?
    let rightEar: CGPoint?
    let leftHip: CGPoint?
    let rightHip: CGPoint?
    
    // Average confidence across all joints
    let averageConfidence: Float
    
    init(from observation: VNHumanBodyPoseObservation) {
        // Helper to safely extract joint point
        func getPoint(_ jointName: VNHumanBodyPoseObservation.JointName) -> (CGPoint?, Float) {
            guard let point = try? observation.recognizedPoint(jointName),
                  point.confidence > 0.1 else {  // Lower threshold for partial visibility
                return (nil, 0.0)
            }
            return (point.location, point.confidence)
        }
        
        // Extract all joints
        let (nosePoint, noseConf) = getPoint(.nose)
        let (neckPoint, neckConf) = getPoint(.neck)
        let (leftShoulderPoint, leftShoulderConf) = getPoint(.leftShoulder)
        let (rightShoulderPoint, rightShoulderConf) = getPoint(.rightShoulder)
        let (leftEarPoint, leftEarConf) = getPoint(.leftEar)
        let (rightEarPoint, rightEarConf) = getPoint(.rightEar)
        let (leftHipPoint, leftHipConf) = getPoint(.leftHip)
        let (rightHipPoint, rightHipConf) = getPoint(.rightHip)
        
        self.nose = nosePoint
        self.neck = neckPoint
        self.leftShoulder = leftShoulderPoint
        self.rightShoulder = rightShoulderPoint
        self.leftEar = leftEarPoint
        self.rightEar = rightEarPoint
        self.leftHip = leftHipPoint
        self.rightHip = rightHipPoint
        
        // Calculate average confidence
        let confidences = [noseConf, neckConf, leftShoulderConf, rightShoulderConf,
                          leftEarConf, rightEarConf, leftHipConf, rightHipConf]
        let validConfidences = confidences.filter { $0 > 0 }
        self.averageConfidence = validConfidences.isEmpty ? 0.0 : validConfidences.reduce(0, +) / Float(validConfidences.count)
    }
    
    // Check if we have minimum required joints for analysis
    var hasMinimumJoints: Bool {
        // Very lenient - we can work with almost anything
        // At minimum, we need EITHER:
        // - Neck OR nose
        // - At least one ear OR shoulder
        
        let hasHead = nose != nil || neck != nil || leftEar != nil || rightEar != nil
        let hasReference = leftShoulder != nil || rightShoulder != nil || neck != nil
        
        return hasHead && hasReference
    }
}

// MARK: - Posture Calculator

struct PostureCalculator {
    
    // MARK: - Neck Angle Calculation
    
    /// Calculate forward head posture angle and side tilt
    /// Returns tuple: (forwardAngle, sideTilt) in degrees
    static func calculateNeckAngle(joints: JointPoints) -> (forward: Double, side: Double)? {
        // Try to find the best available points for calculation
        
        // For forward tilt, we need: head point, neck/shoulder reference, and vertical reference
        let head = joints.leftEar ?? joints.rightEar ?? joints.nose
        let neck = joints.neck
        let shoulder: CGPoint?
        
        if let left = joints.leftShoulder, let right = joints.rightShoulder {
            shoulder = CGPoint(x: (left.x + right.x) / 2, y: (left.y + right.y) / 2)
        } else {
            shoulder = joints.leftShoulder ?? joints.rightShoulder
        }
        
        // Calculate forward angle if we have enough points
        var forwardAngle: Double = 0
        
        if let head = head, let neck = neck, let shoulder = shoulder {
            // Best case: have all points
            let headToNeck = CGPoint(x: head.x - neck.x, y: head.y - neck.y)
            let vertical = CGPoint(x: 0, y: 1)
            forwardAngle = angleBetweenVectors(headToNeck, vertical)
        } else if let head = head, let shoulder = shoulder {
            // No neck, but have head and shoulder - estimate
            let headToShoulder = CGPoint(x: head.x - shoulder.x, y: head.y - shoulder.y)
            let vertical = CGPoint(x: 0, y: 1)
            forwardAngle = angleBetweenVectors(headToShoulder, vertical)
        } else if let head = head, let neck = neck {
            // Have head and neck but no shoulder - limited info
            let headToNeck = CGPoint(x: head.x - neck.x, y: head.y - neck.y)
            let vertical = CGPoint(x: 0, y: 1)
            forwardAngle = angleBetweenVectors(headToNeck, vertical)
        } else {
            // Not enough points for forward angle
            return nil
        }
        
        // Calculate side tilt if possible
        var sideTilt: Double = 0
        
        if let leftEar = joints.leftEar, let rightEar = joints.rightEar {
            // Both ears visible - best accuracy
            let earHeightDiff = abs(leftEar.y - rightEar.y)
            let earDistance = distance(leftEar, rightEar)
            
            if earDistance > 0.01 { // Avoid division by zero
                let tiltRadians = asin(min(earHeightDiff / earDistance, 1.0))
                sideTilt = tiltRadians * 180.0 / .pi
            }
        }
        // With only one ear visible, a horizontal ear/neck offset can't be
        // distinguished from head yaw (turning) vs. actual side tilt (roll),
        // and the previous heuristic saturated to a "significant" tilt from
        // a few percent of frame width - well within normal detection jitter.
        // Skip the estimate rather than guess; side tilt needs both ears.
        
        return (forward: forwardAngle, side: sideTilt)
    }
    
    // MARK: - Shoulder Alignment
    
    /// Calculate shoulder symmetry (height difference)
    /// Returns difference in cm (estimated)
    static func calculateShoulderSymmetry(joints: JointPoints) -> Double? {
        guard let left = joints.leftShoulder,
              let right = joints.rightShoulder else {
            return nil
        }
        
        // Y difference in normalized coordinates (0-1)
        let yDiff = abs(left.y - right.y)

        // Scale using the shoulder-to-shoulder width visible in this frame as the
        // calibration reference (avg adult shoulder width ~40cm), instead of
        // assuming the normalized coordinate span equals full body height (170cm).
        // A desk webcam shot is chest-up only, so the old assumption inflated the
        // estimated cm difference several-fold and triggered false asymmetry issues.
        let shoulderWidth = distance(left, right)
        guard shoulderWidth > 0.01 else { return nil } // Avoid division by zero

        let averageShoulderWidthCm = 40.0
        let estimatedDiffCm = (yDiff / shoulderWidth) * averageShoulderWidthCm

        return estimatedDiffCm
    }
    
    /// Calculate shoulder rounding (forward roll)
    /// Returns angle in degrees
    static func calculateShoulderRounding(joints: JointPoints) -> Double? {
        guard let neck = joints.neck else { return nil }
        
        // Try to get shoulder position
        let shoulder: CGPoint?
        if let left = joints.leftShoulder, let right = joints.rightShoulder {
            shoulder = CGPoint(x: (left.x + right.x) / 2, y: (left.y + right.y) / 2)
        } else {
            shoulder = joints.leftShoulder ?? joints.rightShoulder
        }
        
        guard let shoulder = shoulder else { return nil }
        
        // If we have hips, use them for better accuracy, but if not available, use a simplified calculation
        if let leftHip = joints.leftHip, let rightHip = joints.rightHip {
            let hip = CGPoint(x: (leftHip.x + rightHip.x) / 2, y: (leftHip.y + rightHip.y) / 2)
            
            let neckToShoulder = CGPoint(x: shoulder.x - neck.x, y: shoulder.y - neck.y)
            let hipToNeck = CGPoint(x: neck.x - hip.x, y: neck.y - hip.y)
            let angle = abs(angleBetweenVectors(neckToShoulder, hipToNeck))
            return angle
        } else {
            // No hips - forward roll fundamentally needs a hip-to-neck spine
            // reference to distinguish rounding from head yaw or camera angle.
            // The previous horizontal-deviation heuristic divided by a fixed 0.1
            // (10% of frame width), so ordinary detection jitter alone routinely
            // saturated it to "significant" rounding on a person sitting up straight.
            // Skip the estimate rather than guess wrong.
            print("   ⚠️ Shoulder rounding: Skipped (hips not visible, no reliable estimate)")
            return nil
        }
    }
    
    // MARK: - Torso Angle (Slouch)
    
    /// Calculate torso slouch angle
    /// Returns angle in degrees from vertical, or nil if hips not visible
    static func calculateTorsoAngle(joints: JointPoints) -> Double? {
        guard let neck = joints.neck else { return nil }
        
        // Hips might not be visible - this is optional
        let hip: CGPoint?
        if let left = joints.leftHip, let right = joints.rightHip {
            hip = CGPoint(x: (left.x + right.x) / 2, y: (left.y + right.y) / 2)
        } else {
            hip = joints.leftHip ?? joints.rightHip
        }
        
        // If no hips visible, we can't calculate torso angle
        guard let hip = hip else {
            print("   ⚠️ Torso angle: Skipped (hips not visible)")
            return nil
        }
        
        // Vector from hip to neck
        let torsoVector = CGPoint(x: neck.x - hip.x, y: neck.y - hip.y)
        
        // Vertical reference (straight up)
        let vertical = CGPoint(x: 0, y: 1)
        
        // Angle from vertical
        let angle = angleBetweenVectors(torsoVector, vertical)
        
        return angle
    }
    
    // MARK: - Screen Distance (Placeholder)
    
    /// Estimate distance from screen
    /// This is a placeholder - requires camera calibration for accuracy
    /// Returns estimated distance in cm
    static func estimateScreenDistance(joints: JointPoints, imageWidth: CGFloat) -> Double? {
        // This is a simplified estimation
        // In reality, we'd need:
        // 1. Camera field of view
        // 2. Known reference size (e.g., face width ~15cm)
        // 3. Pixel-to-cm conversion
        
        guard let nose = joints.nose,
              let leftEar = joints.leftEar,
              let rightEar = joints.rightEar else {
            return nil
        }
        
        // Calculate face width in normalized coordinates
        let faceWidth = abs(leftEar.x - rightEar.x)
        
        // Average human face width: ~15cm
        // This is a ROUGH estimation - needs calibration
        // Assuming: larger face in frame = closer to camera
        
        // Inverse relationship: smaller face width = farther distance
        // This formula is a placeholder and will need real-world calibration
        let estimatedDistance = (0.15 / max(faceWidth, 0.01)) * 100.0
        
        // Clamp to reasonable range
        return min(max(estimatedDistance, 30), 150)
    }
    
    // MARK: - Helper Functions
    
    /// Calculate angle between two vectors in degrees
    private static func angleBetweenVectors(_ v1: CGPoint, _ v2: CGPoint) -> Double {
        let dotProduct = v1.x * v2.x + v1.y * v2.y
        let magnitude1 = sqrt(v1.x * v1.x + v1.y * v1.y)
        let magnitude2 = sqrt(v2.x * v2.x + v2.y * v2.y)
        
        guard magnitude1 > 0, magnitude2 > 0 else { return 0 }
        
        let cosAngle = dotProduct / (magnitude1 * magnitude2)
        let angleRadians = acos(max(-1, min(1, cosAngle)))  // Clamp to valid range
        let angleDegrees = angleRadians * 180.0 / .pi
        
        return angleDegrees
    }
    
    /// Calculate Euclidean distance between two points
    private static func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return sqrt(dx * dx + dy * dy)
    }
}
