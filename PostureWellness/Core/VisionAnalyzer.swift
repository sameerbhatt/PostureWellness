//
//  VisionAnalyzer.swift
//  PostureWellness
//
//

import Foundation
import Vision
import CoreImage

// MARK: - Vision Analyzer

class VisionAnalyzer {
    
    private let config: PostureConfig
    private let evaluator: PostureEvaluator
    
    // Track sitting duration
    private var sittingStartTime: Date?
    private var lastPersonDetectedTime: Date?
    private var lastSignificantPosition: CGPoint?
    
    init(config: PostureConfig = ConfigurationManager.shared.config) {
        self.config = config
        self.evaluator = PostureEvaluator(config: config)
    }
    
    // MARK: - Main Analysis Function
    
    /// Analyze a captured image for posture
    /// - Parameter image: The captured camera frame (CIImage or CGImage)
    /// - Returns: PostureReading with analysis results
    func analyzePosture(image: CIImage, imageWidth: CGFloat = 1920) -> PostureReading {
        
        // ✅ Convert to CGImage first, then back to CIImage
        // This ensures proper format for Vision framework
        let context = CIContext()
        guard let cgImage = context.createCGImage(image, from: image.extent) else {
            print("❌ Failed to convert to CGImage")
            return PostureReading.unknown(confidence: 0.0)
        }
        
        // Create fresh CIImage from CGImage
        let processedImage = CIImage(cgImage: cgImage)
        
        print("🎯 Processed image for Vision:")
        print("   Original extent: \(image.extent)")
        print("   Processed extent: \(processedImage.extent)")
        print("   CGImage size: \(cgImage.width)x\(cgImage.height)")
        
        // Try different orientations
        let orientationsToTry: [CGImagePropertyOrientation] = [
            .up,            // rawValue: 1
            .upMirrored,    // rawValue: 2
            .leftMirrored,  // rawValue: 5
            .rightMirrored  // rawValue: 7
        ]
        
        var bestResult: PostureReading?
        var bestConfidence: Double = 0.0
        
        for orientation in orientationsToTry {
            print("🔄 Trying orientation: \(orientation.rawValue)")
            
            let semaphore = DispatchSemaphore(value: 0)
            var result: PostureReading?
            
            // Create Vision request
            let request = VNDetectHumanBodyPoseRequest { request, error in
                if let error = error {
                    print("❌ Vision error: \(error.localizedDescription)")
                    result = PostureReading.unknown(confidence: 0.0)
                    semaphore.signal()
                    return
                }
                
                // Get the first detected person
                guard let observations = request.results as? [VNHumanBodyPoseObservation] else {
                    print("   ❌ No results")
                    result = PostureReading.unknown(confidence: 0.0)
                    semaphore.signal()
                    return
                }
                
                print("   🔍 Detected \(observations.count) person(s)")
                
                guard let observation = observations.first else {
                    print("   ⚠️ No person in results")
                    result = PostureReading.unknown(confidence: 0.0)
                    semaphore.signal()
                    return
                }
                
                // Extract joint points
                let joints = JointPoints(from: observation)
                
                print("   📊 Joint confidence: \(String(format: "%.2f", joints.averageConfidence))")
                print("   📊 Has minimum joints: \(joints.hasMinimumJoints)")
                
                // Check if we have minimum required joints - More lenient check
                guard joints.hasMinimumJoints else {
                    print("⚠️ Insufficient joints detected")
                    print("   Available: nose=\(joints.nose != nil), neck=\(joints.neck != nil), ears=\(joints.leftEar != nil || joints.rightEar != nil), shoulders=\(joints.leftShoulder != nil || joints.rightShoulder != nil)")
                    result = PostureReading.unknown(confidence: Double(joints.averageConfidence))
                    semaphore.signal()
                    return
                }
                
                print("   ✅ Valid detection! Confidence: \(String(format: "%.2f", joints.averageConfidence))")
                
                // Debug: Print detected joints
                let jointNames: [VNHumanBodyPoseObservation.JointName] = [
                    .nose, .neck, .leftShoulder, .rightShoulder,
                    .leftEar, .rightEar, .leftHip, .rightHip
                ]
                
                for jointName in jointNames {
                    if let point = try? observation.recognizedPoint(jointName) {
                        let conf = point.confidence
                        if conf > 0.3 {
                            let emoji = conf > 0.7 ? "✅" : "⚠️"
                            print("      \(emoji) \(jointName.rawValue): \(String(format: "%.2f", conf))")
                        }
                    }
                }
                
                // Update sitting duration tracking
                self.updateSittingDuration(joints: joints)
                
                // Calculate all metrics
                let neckAngles = PostureCalculator.calculateNeckAngle(joints: joints)
                let neckAngle = neckAngles?.forward
                let neckSideTilt = neckAngles?.side ?? 0
                let shoulderSymmetry = PostureCalculator.calculateShoulderSymmetry(joints: joints)
                let shoulderRounding = PostureCalculator.calculateShoulderRounding(joints: joints)
                let torsoAngle = PostureCalculator.calculateTorsoAngle(joints: joints)
                
                // Screen distance estimation
                let screenDistance: Double?
                if self.config.distance.auto_detect_enabled {
                    screenDistance = PostureCalculator.estimateScreenDistance(joints: joints, imageWidth: imageWidth)
                } else {
                    screenDistance = self.config.distance.manual_distance
                }
                
                // Get sitting duration in minutes
                let sittingMinutes = self.getCurrentSittingDuration()
                
                // Debug output
                print("   📊 Measurements:")
                if let neck = neckAngle {
                    print("      Neck: \(String(format: "%.1f°", neck))")
                }
                if let symmetry = shoulderSymmetry {
                    print("      Shoulder symmetry: \(String(format: "%.1f cm", symmetry))")
                }
                if let rounding = shoulderRounding {
                    print("      Shoulder rounding: \(String(format: "%.1f°", rounding))")
                }
                if let torso = torsoAngle {
                    print("      Torso: \(String(format: "%.1f°", torso))")
                } else {
                    print("      Torso: N/A (hips not visible)")
                }
                
                // Evaluate posture
                result = self.evaluator.evaluate(
                    neckAngle: neckAngle,
                    neckSideTilt: neckSideTilt,
                    shoulderSymmetry: shoulderSymmetry,
                    shoulderRounding: shoulderRounding,
                    torsoAngle: torsoAngle,
                    screenDistance: screenDistance,
                    sittingDuration: sittingMinutes,
                    jointPositions: JointPositions(from: joints),
                    confidence: Double(joints.averageConfidence)
                )
                
                semaphore.signal()
            }
            
            // Perform the request with current orientation
            let handler = VNImageRequestHandler(ciImage: processedImage, orientation: orientation, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                print("   ❌ Request failed: \(error.localizedDescription)")
                continue
            }
            
            // Wait for completion
            _ = semaphore.wait(timeout: .now() + 2.0)
            
            if let r = result {
                print("Result is valid \(r.isValid) (confidence: \(String(format: "%.2f", r.confidence)))")
            } else {
                print("Result is nil after Vision request")
            }
            
            // Check if this result is better
            if let result = result {
                print("   Result: valid=\(result.isValid), confidence=\(String(format: "%.2f", result.confidence)), score=\(result.overallScore)")
                
                if result.isValid && result.confidence > bestConfidence {
                    bestResult = result
                    bestConfidence = result.confidence
                    print("   🎯 Best result so far!")
                }
            }
            
            // If we got a good result, use it
            if let best = bestResult, best.confidence > 0.20 {
                print("✅ Using orientation \(orientation.rawValue) (confidence: \(String(format: "%.2f", best.confidence)))")
                return best
            }
        }
        
        // Return best result found, or unknown if none worked
        if let best = bestResult, best.confidence > 0.15 {
            print("✅ Best detection found: confidence \(String(format: "%.2f", best.confidence))")
            return best
        } else {
            print("❌ No detection with sufficient confidence (minimum 0.15 required)")
            print("   Best confidence achieved: \(String(format: "%.2f", bestConfidence))")
            return PostureReading.unknown(confidence: bestConfidence)
        }
    }
    
    // MARK: - Sitting Duration Tracking
    
    private func updateSittingDuration(joints: JointPoints) {
        let now = Date()
        
        // Initialize if first detection
        if sittingStartTime == nil {
            sittingStartTime = now
            lastPersonDetectedTime = now
            lastSignificantPosition = joints.neck ?? joints.nose
            return
        }
        
        lastPersonDetectedTime = now
        
        // Check for significant movement (if enabled)
        if config.sitting.reset_on_movement {
            if let currentPos = joints.neck ?? joints.nose,
               let lastPos = lastSignificantPosition {
                
                // Calculate movement distance
                let dx = currentPos.x - lastPos.x
                let dy = currentPos.y - lastPos.y
                let distance = sqrt(dx * dx + dy * dy)
                
                // If movement exceeds threshold, reset sitting timer
                if distance > CGFloat(config.sitting.movement_threshold) {
                    print("🚶 Significant movement detected, resetting sitting timer")
                    sittingStartTime = now
                    lastSignificantPosition = currentPos
                }
            }
        }
    }
    
    private func handleNoPersonDetected() -> PostureReading {
        // If person not detected for >5 seconds, reset sitting timer
        if let lastSeen = lastPersonDetectedTime,
           Date().timeIntervalSince(lastSeen) > 5.0 {
            print("👋 Person left frame, resetting sitting timer")
            sittingStartTime = nil
            lastPersonDetectedTime = nil
            lastSignificantPosition = nil
        }
        
        return PostureReading.unknown(confidence: 0.0)
    }
    
    private func getCurrentSittingDuration() -> Int {
        guard let startTime = sittingStartTime else { return 0 }
        let duration = Date().timeIntervalSince(startTime)
        return Int(duration / 60.0)  // Convert to minutes
    }
    
    // MARK: - Reset
    
    func resetSittingTimer() {
        sittingStartTime = Date()
        print("🔄 Sitting timer manually reset")
    }
}

