//
//  PostureConfig.swift
//  PostureWellness
//
//

import Foundation

// MARK: - Main Configuration Structure

struct PostureConfig: Codable {
    let version: String
    let neck: NeckThresholds
    let shoulders: ShoulderThresholds
    let torso: TorsoThresholds
    let distance: DistanceThresholds
    let sitting: SittingThresholds
    let break_reminder: BreakReminderConfig
    let vision: VisionConfig
    let notifications: NotificationConfig
    let scoring: ScoringConfig
    let performance: PerformanceConfig
}

// MARK: - Neck Configuration

struct NeckThresholds: Codable {
    let good_max: Double
    let minor_max: Double
    let poor_threshold: Double
    let weight_minor: Int
    let weight_poor: Int
    
    enum CodingKeys: String, CodingKey {
        case good_max, minor_max, poor_threshold, weight_minor, weight_poor
    }
}

// MARK: - Shoulder Configuration

struct ShoulderThresholds: Codable {
    let symmetry_good_max: Double
    let symmetry_minor_max: Double
    let symmetry_poor_threshold: Double
    let rounding_good_max: Double
    let rounding_minor_max: Double
    let rounding_poor_threshold: Double
    let weight_minor: Int
    let weight_poor: Int
    let weight_both_issues: Int
    
    enum CodingKeys: String, CodingKey {
        case symmetry_good_max, symmetry_minor_max, symmetry_poor_threshold
        case rounding_good_max, rounding_minor_max, rounding_poor_threshold
        case weight_minor, weight_poor, weight_both_issues
    }
}

// MARK: - Torso Configuration

struct TorsoThresholds: Codable {
    let good_max: Double
    let minor_max: Double
    let poor_threshold: Double
    let weight_minor: Int
    let weight_poor: Int
    
    enum CodingKeys: String, CodingKey {
        case good_max, minor_max, poor_threshold, weight_minor, weight_poor
    }
}

// MARK: - Distance Configuration

struct DistanceThresholds: Codable {
    let good_min: Double
    let good_max: Double
    let minor_min: Double
    let minor_max: Double
    let poor_min: Double
    let poor_max: Double
    let weight_minor: Int
    let weight_poor: Int
    let auto_detect_enabled: Bool
    let manual_distance: Double
    
    enum CodingKeys: String, CodingKey {
        case good_min, good_max, minor_min, minor_max
        case poor_min, poor_max, weight_minor, weight_poor
        case auto_detect_enabled, manual_distance
    }
}

// MARK: - Sitting Configuration

struct SittingThresholds: Codable {
    let good_max: Int
    let minor_max: Int
    let poor_threshold: Int
    let weight_minor: Int
    let weight_poor: Int
    let reset_on_movement: Bool
    let movement_threshold: Double
    
    enum CodingKeys: String, CodingKey {
        case good_max, minor_max, poor_threshold
        case weight_minor, weight_poor
        case reset_on_movement, movement_threshold
    }
}

// MARK: - Break Reminder Configuration

struct BreakReminderConfig: Codable {
    let enabled: Bool
    let interval_minutes: Int
    let duration_seconds: Int
    let show_exercises: Bool
    let auto_pause_monitoring: Bool
    
    enum CodingKeys: String, CodingKey {
        case enabled, interval_minutes, duration_seconds
        case show_exercises, auto_pause_monitoring
    }
}

// MARK: - Vision Configuration

struct VisionConfig: Codable {
    let confidence_threshold: Double
    let confidence_warning_count: Int
    
    enum CodingKeys: String, CodingKey {
        case confidence_threshold, confidence_warning_count
    }
}

// MARK: - Notification Configuration

struct NotificationConfig: Codable {
    let poor_score_threshold: Int
    let min_interval_minutes: Int
    let dismiss_duration_minutes: Int
    let dismiss_until_improvement: Bool
    let strict_consecutive: Int
    let active_consecutive: Int
    let gentle_consecutive: Int
    
    enum CodingKeys: String, CodingKey {
        case poor_score_threshold, min_interval_minutes
        case dismiss_duration_minutes, dismiss_until_improvement
        case strict_consecutive, active_consecutive, gentle_consecutive
    }
}

// MARK: - Scoring Configuration

struct ScoringConfig: Codable {
    let base_score: Int
    let excellent_min: Int
    let good_min: Int
    let fair_min: Int
    let poor_min: Int
    
    enum CodingKeys: String, CodingKey {
        case base_score, excellent_min, good_min, fair_min, poor_min
    }
}

// MARK: - Performance Configuration

struct PerformanceConfig: Codable {
    let max_analysis_time_seconds: Int
    let target_memory_mb: Int
    
    enum CodingKeys: String, CodingKey {
        case max_analysis_time_seconds, target_memory_mb
    }
}

// MARK: - Configuration Errors

enum ConfigError: Error, LocalizedError {
    case fileNotFound(String)
    case invalidJSON(String)
    case invalidRange(String)
    case invalidValue(String)
    case migrationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Configuration file not found at: \(path)"
        case .invalidJSON(let reason):
            return "Invalid JSON format: \(reason)"
        case .invalidRange(let detail):
            return "Invalid configuration range: \(detail)"
        case .invalidValue(let detail):
            return "Invalid configuration value: \(detail)"
        case .migrationFailed(let reason):
            return "Configuration migration failed: \(reason)"
        }
    }
}
