//
//  PostureReading.swift
//  PostureWellness
//
//

import Foundation

// MARK: - Posture Status

enum PostureStatus: String, Codable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case veryPoor = "very_poor"
    case unknown = "unknown"  // When confidence is too low
    
    var displayName: String {
        switch self {
        case .excellent:
            return "Excellent"
        case .good:
            return "Good"
        case .fair:
            return "Fair"
        case .poor:
            return "Poor"
        case .veryPoor:
            return "Very Poor"
        case .unknown:
            return "Unknown"
        }
    }
    
    var color: String {
        switch self {
        case .excellent:
            return "green"
        case .good:
            return "blue"
        case .fair:
            return "yellow"
        case .poor:
            return "orange"
        case .veryPoor:
            return "red"
        case .unknown:
            return "gray"
        }
    }
    
    var emoji: String {
        switch self {
        case .excellent:
            return "🟢"
        case .good:
            return "🔵"
        case .fair:
            return "🟡"
        case .poor:
            return "🟠"
        case .veryPoor:
            return "🔴"
        case .unknown:
            return "⚪️"
        }
    }
}

// MARK: - Posture Reading

struct PostureReading: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    
    // Raw measurements
    let neckAngle: Double?           // Degrees from vertical (forward)
    let neckSideTilt: Double?        // Degrees tilted to side
    let shoulderSymmetry: Double?    // Cm difference
    let shoulderRounding: Double?    // Degrees forward
    let torsoAngle: Double?          // Degrees from vertical
    let screenDistance: Double?      // Cm from screen
    let sittingDuration: Int?        // Minutes
    
    // Add joint coordinates (normalized 0-1)
    let jointPositions: JointPositions?
    
    // Analysis results
    let overallScore: Int            // 0-100
    let status: PostureStatus
    let issues: [Issue]
    let confidence: Double           // Vision framework confidence (0-1)
    
    init(
        neckAngle: Double?,
        neckSideTilt: Double?,
        shoulderSymmetry: Double?,
        shoulderRounding: Double?,
        torsoAngle: Double?,
        screenDistance: Double?,
        sittingDuration: Int?,
        jointPositions: JointPositions?,
        overallScore: Int,
        status: PostureStatus,
        issues: [Issue],
        confidence: Double
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.neckAngle = neckAngle
        self.neckSideTilt = neckSideTilt
        self.shoulderSymmetry = shoulderSymmetry
        self.shoulderRounding = shoulderRounding
        self.torsoAngle = torsoAngle
        self.screenDistance = screenDistance
        self.sittingDuration = sittingDuration
        self.jointPositions = jointPositions
        self.overallScore = overallScore
        self.status = status
        self.issues = issues
        self.confidence = confidence
    }
    
    // For low confidence readings
    static func unknown(confidence: Double) -> PostureReading {
        return PostureReading(
            neckAngle: nil,
            neckSideTilt: nil,
            shoulderSymmetry: nil,
            shoulderRounding: nil,
            torsoAngle: nil,
            screenDistance: nil,
            sittingDuration: nil,
            jointPositions: nil,
            overallScore: 0,
            status: .unknown,
            issues: [],
            confidence: confidence
        )
    }
    
    // Check if reading is valid (sufficient confidence)
    var isValid: Bool {
        // Use hardcoded minimum instead of config (config is for warnings)
        return status != .unknown && confidence >= 0.15
        
        /* let config = ConfigurationManager.shared.config
        let threshold = config.vision.confidence_threshold
        let meetsThreshold = confidence >= threshold
        
        if !meetsThreshold {
            print("⚠️ Reading invalid: confidence \(String(format: "%.2f", confidence)) < threshold \(String(format: "%.2f", threshold))")
        }
        
        return status != .unknown && meetsThreshold*/
    }
    
    var qualityLevel: String {
        if confidence >= 0.7 {
            return "High"
        } else if confidence >= 0.4 {
            return "Medium"
        } else if confidence >= 0.2 {
            return "Low"
        } else {
            return "Very Low"
        }
    }
    
    // Get primary issue (most severe)
    var primaryIssue: Issue? {
        return issues.max(by: { $0.severity < $1.severity })
    }
    
    // Count issues by severity
    var issueBreakdown: (minor: Int, moderate: Int, significant: Int) {
        let minor = issues.filter { $0.severity == .minor }.count
        let moderate = issues.filter { $0.severity == .moderate }.count
        let significant = issues.filter { $0.severity == .significant }.count
        return (minor, moderate, significant)
    }
    
    // Summary text for notifications
    var notificationSummary: String {
        if let primary = primaryIssue {
            let otherCount = issues.count - 1
            if otherCount > 0 {
                return "\(primary.type.displayName) issue detected (+\(otherCount) more)"
            } else {
                return "\(primary.type.displayName) issue detected"
            }
        }
        return "Posture issues detected"
    }
}

// struct for joint positions
struct JointPositions: Codable {
    let nose: CGPoint?
    let neck: CGPoint?
    let leftShoulder: CGPoint?
    let rightShoulder: CGPoint?
    let leftEar: CGPoint?
    let rightEar: CGPoint?
    let leftHip: CGPoint?
    let rightHip: CGPoint?
    
    init(from joints: JointPoints) {
        self.nose = joints.nose
        self.neck = joints.neck
        self.leftShoulder = joints.leftShoulder
        self.rightShoulder = joints.rightShoulder
        self.leftEar = joints.leftEar
        self.rightEar = joints.rightEar
        self.leftHip = joints.leftHip
        self.rightHip = joints.rightHip
    }
}

// MARK: - Posture Evaluator

struct PostureEvaluator {
    let config: PostureConfig
    
    init(config: PostureConfig = ConfigurationManager.shared.config) {
        self.config = config
    }
    
    // Main evaluation function
    func evaluate(
        neckAngle: Double?,
        neckSideTilt: Double?,
        shoulderSymmetry: Double?,
        shoulderRounding: Double?,
        torsoAngle: Double?,
        screenDistance: Double?,
        sittingDuration: Int?,
        jointPositions: JointPositions?,
        confidence: Double
    ) -> PostureReading {
        
        // If confidence is too low, return unknown reading
        guard confidence >= config.vision.confidence_threshold else {
            return PostureReading.unknown(confidence: confidence)
        }
        
        // Detect issues
        var issues: [Issue] = []
        
        if let neck = neckAngle,
           let issue = IssueFactory.createNeckIssue(angle: neck, config: config.neck) {
            issues.append(issue)
        }

        // check for side tilt
        if let sideTilt = neckSideTilt, sideTilt > 5, // Only check if significant
           let issue = IssueFactory.createNeckSideTiltIssue(angle: sideTilt, config: config.neck) {
            issues.append(issue)
        }
        
        if let symmetry = shoulderSymmetry,
           let issue = IssueFactory.createShoulderSymmetryIssue(difference: symmetry, config: config.shoulders) {
            issues.append(issue)
        }
        
        if let rounding = shoulderRounding,
           let issue = IssueFactory.createShoulderRoundingIssue(angle: rounding, config: config.shoulders) {
            issues.append(issue)
        }
        
        if let torso = torsoAngle,
           let issue = IssueFactory.createTorsoIssue(angle: torso, config: config.torso) {
            issues.append(issue)
        }
        
        if let distance = screenDistance,
           let issue = IssueFactory.createDistanceIssue(distance: distance, config: config.distance) {
            issues.append(issue)
        }
        
        if let sitting = sittingDuration,
           let issue = IssueFactory.createSittingIssue(minutes: sitting, config: config.sitting) {
            issues.append(issue)
        }
        
        // Calculate score
        let score = calculateScore(issues: issues)
        
        // Determine status
        let status = determineStatus(score: score)
        
        return PostureReading(
            neckAngle: neckAngle,
            neckSideTilt: neckSideTilt,
            shoulderSymmetry: shoulderSymmetry,
            shoulderRounding: shoulderRounding,
            torsoAngle: torsoAngle,
            screenDistance: screenDistance,
            sittingDuration: sittingDuration,
            jointPositions: jointPositions,
            overallScore: score,
            status: status,
            issues: issues,
            confidence: confidence
        )
    }
    
    // Calculate overall score (0-100)
    private func calculateScore(issues: [Issue]) -> Int {
        var score = config.scoring.base_score
        
        for issue in issues {
            switch issue.type {
            case .neck, .neckSideTilt:
                score -= issue.severity == .significant ? config.neck.weight_poor : config.neck.weight_minor
                
            case .shoulderSymmetry, .shoulderRounding:
                // Check if both shoulder issues exist
                let hasSymmetry = issues.contains { $0.type == .shoulderSymmetry }
                let hasRounding = issues.contains { $0.type == .shoulderRounding }
                
                if hasSymmetry && hasRounding {
                    score -= config.shoulders.weight_both_issues
                } else {
                    score -= issue.severity == .significant ? config.shoulders.weight_poor : config.shoulders.weight_minor
                }
                
            case .slouch:
                score -= issue.severity == .significant ? config.torso.weight_poor : config.torso.weight_minor
                
            case .distance:
                score -= issue.severity == .significant ? config.distance.weight_poor : config.distance.weight_minor
                
            case .sitting:
                score -= issue.severity == .significant ? config.sitting.weight_poor : config.sitting.weight_minor
            }
        }
        
        return max(0, score)
    }
    
    // Determine status from score
    private func determineStatus(score: Int) -> PostureStatus {
        if score >= config.scoring.excellent_min {
            return .excellent
        } else if score >= config.scoring.good_min {
            return .good
        } else if score >= config.scoring.fair_min {
            return .fair
        } else if score >= config.scoring.poor_min {
            return .poor
        } else {
            return .veryPoor
        }
    }
}
