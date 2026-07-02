//
//  Issue.swift
//  PostureWellness
//
//

import Foundation

// MARK: - Issue Type

enum IssueType: String, Codable, CaseIterable {
    case neck = "neck"
    case neckSideTilt = "neck_side_tilt"
    case shoulderSymmetry = "shoulder_symmetry"
    case shoulderRounding = "shoulder_rounding"
    case slouch = "slouch"
    case distance = "distance"
    case sitting = "sitting"
    
    var displayName: String {
        switch self {
        case .neck:
            return "Neck Posture"
        case .neckSideTilt:
            return "Head Tilt"
        case .shoulderSymmetry:
            return "Shoulder Alignment"
        case .shoulderRounding:
            return "Shoulder Position"
        case .slouch:
            return "Back Posture"
        case .distance:
            return "Screen Distance"
        case .sitting:
            return "Sitting Duration"
        }
    }
    
    var icon: String {
        switch self {
        case .neck:
            return "figure.stand"
        case .neckSideTilt:
            return "arrow.left.and.right"
        case .shoulderSymmetry:
            return "figure.arms.open"
        case .shoulderRounding:
            return "arrow.down.forward.and.arrow.up.backward"
        case .slouch:
            return "figure.wave"
        case .distance:
            return "eye"
        case .sitting:
            return "clock.fill"
        }
    }
}

// MARK: - Issue Severity

enum Severity: String, Codable, Comparable {
    case minor = "minor"
    case moderate = "moderate"
    case significant = "significant"
    
    var displayName: String {
        switch self {
        case .minor:
            return "Minor"
        case .moderate:
            return "Moderate"
        case .significant:
            return "Significant"
        }
    }
    
    var color: String {
        switch self {
        case .minor:
            return "yellow"
        case .moderate:
            return "orange"
        case .significant:
            return "red"
        }
    }
    
    // For sorting by severity
    static func < (lhs: Severity, rhs: Severity) -> Bool {
        let order: [Severity] = [.minor, .moderate, .significant]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

// MARK: - Issue Model

struct Issue: Codable, Identifiable {
    let id: UUID
    let type: IssueType
    let severity: Severity
    let measuredValue: Double  // Actual measured value (angle, distance, etc.)
    let guidance: String        // Actionable correction advice
    let timestamp: Date
    
    init(type: IssueType, severity: Severity, measuredValue: Double, guidance: String) {
        self.id = UUID()
        self.type = type
        self.severity = severity
        self.measuredValue = measuredValue
        self.guidance = guidance
        self.timestamp = Date()
    }
    
    // Formatted display of measured value
    var formattedValue: String {
        switch type {
        case .neck, .slouch, .shoulderRounding, .neckSideTilt:
            return String(format: "%.1f°", measuredValue)
        case .shoulderSymmetry:
            return String(format: "%.1f cm", measuredValue)
        case .distance:
            return String(format: "%.0f cm", measuredValue)
        case .sitting:
            let minutes = Int(measuredValue)
            return "\(minutes) min"
        }
    }
    
    // Short summary for notifications
    var summary: String {
        "\(type.displayName): \(severity.displayName) - \(formattedValue)"
    }
}

// MARK: - Issue Factory

struct IssueFactory {
    static func createNeckIssue(angle: Double, config: NeckThresholds) -> Issue? {
        let severity: Severity
        let guidance: String
        
        if angle > config.poor_threshold {
            severity = .significant
            // (\(String(format: "%.1f°", angle)))
            guidance = "Significant forward head posture. Raise your monitor 3-4 inches or use a laptop stand. Your ears should align above your shoulders."
        } else if angle > config.minor_max {
            severity = .moderate
            guidance = "Moderate forward head tilt. Adjust your screen height and pull your chin slightly back."
        } else if angle > config.good_max {
            severity = .minor
            guidance = "Slight forward head posture. Try to align your ears over your shoulders."
        } else {
            return nil  // No issue
        }
        
        return Issue(type: .neck, severity: severity, measuredValue: angle, guidance: guidance)
    }
    
    static func createNeckSideTiltIssue(angle: Double, config: NeckThresholds) -> Issue? {
        let severity: Severity
        let guidance: String
        
        // Use same thresholds as forward tilt for now
        if angle > Double(config.poor_threshold) {
            severity = .significant
            guidance = "Significant head tilt to the side. Center your head over your shoulders and keep your ears level."
        } else if angle > Double(config.minor_max) {
            severity = .moderate
            guidance = "Moderate head tilt. Adjust your monitor position or chair height to keep your head centered."
        } else if angle > Double(config.good_max) {
            severity = .minor
            guidance = "Slight head tilt. Try to keep your head level."
        } else {
            return nil
        }
        
        return Issue(type: .neckSideTilt, severity: severity, measuredValue: angle, guidance: guidance)
    }
    
    static func createShoulderSymmetryIssue(difference: Double, config: ShoulderThresholds) -> Issue? {
        let severity: Severity
        let guidance: String
        
        if difference > config.symmetry_poor_threshold {
            severity = .significant
            // (\(String(format: "%.1f cm", difference)))
            guidance = "Significant shoulder asymmetry. You may be leaning heavily to one side. Adjust your sitting position and check if your chair is level."
        } else if difference > config.symmetry_minor_max {
            severity = .moderate
            guidance = "Moderate shoulder unevenness. Try to distribute your weight evenly on both sides."
        } else if difference > config.symmetry_good_max {
            severity = .minor
            guidance = "Slight shoulder asymmetry. Check if you're leaning to one side."
        } else {
            return nil
        }
        
        return Issue(type: .shoulderSymmetry, severity: severity, measuredValue: difference, guidance: guidance)
    }
    
    static func createShoulderRoundingIssue(angle: Double, config: ShoulderThresholds) -> Issue? {
        let severity: Severity
        let guidance: String
        
        if angle > config.rounding_poor_threshold {
            severity = .significant
            // (\(String(format: "%.1f°", angle)))
            guidance = "Significantly rounded shoulders. Roll your shoulders back, open your chest, and sit back fully in your chair."
        } else if angle > config.rounding_minor_max {
            severity = .moderate
            guidance = "Moderate shoulder rounding. Pull your shoulder blades together and maintain an open chest."
        } else if angle > config.rounding_good_max {
            severity = .minor
            guidance = "Slight shoulder rounding. Roll shoulders back gently."
        } else {
            return nil
        }
        
        return Issue(type: .shoulderRounding, severity: severity, measuredValue: angle, guidance: guidance)
    }
    
    static func createTorsoIssue(angle: Double, config: TorsoThresholds) -> Issue? {
        let severity: Severity
        let guidance: String
        
        if angle > config.poor_threshold {
            severity = .significant
            // (\(String(format: "%.1f°", angle)))
            guidance = "Significant slouching. Sit back fully in your chair with back support. Keep your spine aligned."
        } else if angle > config.minor_max {
            severity = .moderate
            guidance = "Moderate slouch detected. Adjust your chair back and sit upright with proper lumbar support."
        } else if angle > config.good_max {
            severity = .minor
            guidance = "Slight slouch. Sit back fully in your chair."
        } else {
            return nil
        }
        
        return Issue(type: .slouch, severity: severity, measuredValue: angle, guidance: guidance)
    }
    
    static func createDistanceIssue(distance: Double, config: DistanceThresholds) -> Issue? {
        let severity: Severity
        let guidance: String
        
        if distance < config.minor_min {
            severity = .significant
            // (\(String(format: "%.0f cm", distance)))
            guidance = "Too close to screen. Move back to arm's length (~60 cm) to reduce eye strain."
        } else if distance < config.good_min {
            severity = .minor
            guidance = "Slightly too close. Ideal distance is 50-70 cm."
        } else if distance > config.minor_max {
            severity = .moderate
            guidance = "Screen is too far. Move closer for comfortable viewing."
        } else if distance > config.good_max {
            severity = .minor
            guidance = "Slightly far from screen. Ideal distance is 50-70 cm."
        } else {
            return nil
        }
        
        return Issue(type: .distance, severity: severity, measuredValue: distance, guidance: guidance)
    }
    
    static func createSittingIssue(minutes: Int, config: SittingThresholds) -> Issue? {
        let severity: Severity
        let guidance: String
        
        if minutes >= config.poor_threshold {
            severity = .significant
            guidance = "You've been sitting for \(minutes) minutes. Time for a break! Stand up, stretch, and walk around for at least 5 minutes."
        } else if minutes >= config.minor_max {
            severity = .moderate
            guidance = "You've been sitting for \(minutes) minutes. Consider taking a short break soon."
        } else if minutes >= config.good_max {
            severity = .minor
            guidance = "Approaching \(minutes) minutes of sitting. Plan to take a break soon."
        } else {
            return nil
        }
        
        return Issue(type: .sitting, severity: severity, measuredValue: Double(minutes), guidance: guidance)
    }
}
