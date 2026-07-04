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

    /// Analyze a captured image for posture.
    ///
    /// Face-first hybrid: face detection is the primary signal because it is far
    /// more reliable than body pose on close-up webcam framing (head + shoulders
    /// filling the frame), and it reports head roll/pitch/yaw directly. Body pose
    /// is used opportunistically for shoulder symmetry when shoulders are visible.
    ///
    /// Metrics a frontal 2D camera cannot measure (shoulder rounding, hip-based
    /// torso slouch - both sagittal-plane angles) are intentionally not reported.
    func analyzePosture(image: CIImage, imageWidth: CGFloat = 1920) -> PostureReading {

        // Convert to CGImage - ensures proper format for Vision framework
        let context = CIContext()
        guard let cgImage = context.createCGImage(image, from: image.extent) else {
            print("❌ Failed to convert to CGImage")
            return PostureReading.unknown(confidence: 0.0)
        }

        print("🎯 Analyzing frame (\(cgImage.width)x\(cgImage.height))")

        // Mac cameras deliver upright frames, so a single .up pass suffices.
        let faceRequest = VNDetectFaceRectanglesRequest()
        let bodyRequest = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])

        do {
            try handler.perform([faceRequest, bodyRequest])
        } catch {
            print("❌ Vision request failed: \(error.localizedDescription)")
            return PostureReading.unknown(confidence: 0.0)
        }

        // Largest face in frame = the user (ignores smaller faces in the background)
        let face = faceRequest.results?.max(by: { $0.boundingBox.width < $1.boundingBox.width })
        let joints = bodyRequest.results?.first.map { JointPoints(from: $0) }

        if let face = face {
            print("   ✅ Face detected (confidence \(String(format: "%.2f", face.confidence)))")
        } else {
            print("   ⚠️ No face detected")
        }
        if let joints = joints {
            print("   📊 Body pose: core joint confidence \(String(format: "%.2f", joints.averageConfidence)), minimum joints: \(joints.hasMinimumJoints)")
        } else {
            print("   ⚠️ No body pose detected")
        }

        guard face != nil || (joints?.hasMinimumJoints ?? false) else {
            return handleNoPersonDetected()
        }

        // Presence position for sitting/movement tracking: face center, else head/neck
        let presencePosition: CGPoint?
        if let box = face?.boundingBox {
            presencePosition = CGPoint(x: box.midX, y: box.midY)
        } else {
            presencePosition = joints?.neck ?? joints?.nose
        }
        updateSittingDuration(position: presencePosition)

        // --- Head pose (from face - the reliable source) ---
        var neckAngle: Double? = nil
        var neckSideTilt: Double = 0

        if let face = face {
            if let roll = face.roll?.doubleValue {
                neckSideTilt = abs(roll * 180.0 / .pi)
            }
            if let pitch = face.pitch?.doubleValue {
                let pitchDegrees = pitch * 180.0 / .pi
                // Use the nod magnitude - tilting far up or down both strain the
                // neck. Vision's pitch sign convention is not clearly documented,
                // so the raw signed value is logged to let beta feedback refine
                // direction-specific guidance later.
                neckAngle = abs(pitchDegrees)
                print("   📐 Head pitch: \(String(format: "%+.1f°", pitchDegrees))")
            }
            if let yaw = face.yaw?.doubleValue {
                // Logged only for now - sustained head rotation (monitor off to
                // the side) is a candidate future metric.
                print("   📐 Head yaw: \(String(format: "%+.1f°", yaw * 180.0 / .pi))")
            }
        } else if let joints = joints,
                  let angles = PostureCalculator.calculateNeckAngle(joints: joints) {
            // Body-pose fallback: only side tilt is trustworthy from the frontal
            // projection (both-ears formula); forward tilt stays nil because the
            // frontal 2D view cannot measure it.
            neckSideTilt = angles.side
        }

        // --- Shoulders (from body pose, when visible) ---
        let shoulderSymmetry = joints.flatMap { PostureCalculator.calculateShoulderSymmetry(joints: $0) }

        // --- Screen distance ---
        let screenDistance: Double?
        if config.distance.auto_detect_enabled {
            screenDistance = face.flatMap { PostureCalculator.estimateScreenDistance(faceBoundingBoxWidth: $0.boundingBox.width) }
        } else {
            screenDistance = config.distance.manual_distance
        }

        let sittingMinutes = getCurrentSittingDuration()

        // Overall confidence: face detection confidence when a face was found
        // (the primary signal), otherwise core body-joint confidence.
        let confidence: Double
        if let face = face {
            confidence = Double(face.confidence)
        } else {
            confidence = Double(joints?.averageConfidence ?? 0)
        }

        print("   📊 Measurements:")
        if let neck = neckAngle {
            print("      Neck pitch: \(String(format: "%.1f°", neck))")
        }
        print("      Side tilt: \(String(format: "%.1f°", neckSideTilt))")
        if let symmetry = shoulderSymmetry {
            print("      Shoulder symmetry: \(String(format: "%.1f cm", symmetry))")
        } else {
            print("      Shoulder symmetry: N/A (shoulders not visible)")
        }

        return evaluator.evaluate(
            neckAngle: neckAngle,
            neckSideTilt: neckSideTilt,
            shoulderSymmetry: shoulderSymmetry,
            shoulderRounding: nil,   // not measurable from a frontal 2D view
            torsoAngle: nil,         // needs hips + side view; revisit with baseline calibration
            screenDistance: screenDistance,
            sittingDuration: sittingMinutes,
            jointPositions: joints.map { JointPositions(from: $0) },
            confidence: confidence
        )
    }

    // MARK: - Sitting Duration Tracking

    private func updateSittingDuration(position: CGPoint?) {
        let now = Date()

        // Initialize if first detection
        if sittingStartTime == nil {
            sittingStartTime = now
            lastPersonDetectedTime = now
            lastSignificantPosition = position
            return
        }

        lastPersonDetectedTime = now

        // Check for significant movement (if enabled)
        if config.sitting.reset_on_movement,
           let currentPos = position,
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

    private func handleNoPersonDetected() -> PostureReading {
        // If person not detected for >5 seconds, reset sitting timer.
        // With captures minutes apart, a single empty capture qualifies -
        // resetting too eagerly is the safe direction (fewer false sitting alarms).
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
