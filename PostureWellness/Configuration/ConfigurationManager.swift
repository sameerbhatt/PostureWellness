//
//  ConfigurationManager.swift
//  PostureWellness
//
//

import Foundation
import AppKit

class ConfigurationManager {
    static let shared = ConfigurationManager()
    
    private(set) var config: PostureConfig
    
    private let defaultConfigFilename = "default_config"
    private let userConfigFilename = "posture_config.json"
    
    // ✅ FIX: Make this static so it doesn't reference 'shared'
    private static var userConfigURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("PostureWellness", isDirectory: true)
        
        // Create folder if it doesn't exist
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        
        return appFolder.appendingPathComponent("posture_config.json")
    }
    
    // MARK: - Initialization
    
    private init() {
        // Load configuration on initialization
        do {
            self.config = try Self.loadConfiguration()
            print("✅ Configuration loaded successfully (version \(config.version))")
        } catch {
            fatalError("Failed to load configuration: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Loading Configuration
    
    private static func loadConfiguration() throws -> PostureConfig {
        let defaultConfig = try loadDefaultConfig()

        // Try to load user config first
        if let userConfig = try? loadUserConfig() {
            // Refresh stale configs: when the bundled defaults version changes
            // (e.g., recalibrated scoring weights), replace the saved user copy -
            // otherwise threshold fixes never reach machines that saved an older
            // config. Note: this discards manual edits to the user config file
            // on version bumps (acceptable during beta).
            if userConfig.version == defaultConfig.version {
                print("📄 Loaded user configuration")
                return userConfig
            }
            print("🔄 User config v\(userConfig.version) is outdated (bundled v\(defaultConfig.version)) - refreshing to new defaults")
        } else {
            print("📄 Loading default configuration")
        }

        // Save default as user config for future edits
        try? saveUserConfig(defaultConfig)

        return defaultConfig
    }
    
    private static func loadDefaultConfig() throws -> PostureConfig {
        guard let url = Bundle.main.url(forResource: "default_config", withExtension: "json") else {
            throw ConfigError.fileNotFound("default_config.json not found in bundle")
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        
        do {
            let config = try decoder.decode(PostureConfig.self, from: data)
            try validateConfig(config)
            return config
        } catch let decodingError as DecodingError {
            throw ConfigError.invalidJSON(decodingError.localizedDescription)
        }
    }
    
    private static func loadUserConfig() throws -> PostureConfig {
        // ✅ FIX: Use static userConfigURL instead of instance property
        let url = userConfigURL
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ConfigError.fileNotFound("User config not found")
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        
        let config = try decoder.decode(PostureConfig.self, from: data)
        try validateConfig(config)
        
        return config
    }
    
    // MARK: - Saving Configuration
    
    private static func saveUserConfig(_ config: PostureConfig) throws {
        // ✅ FIX: Use static userConfigURL
        let url = userConfigURL
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(config)
        try data.write(to: url, options: .atomic)
        
        print("💾 Configuration saved to: \(url.path)")
    }
    
    func saveConfig() throws {
        try Self.saveUserConfig(config)
    }
    
    // MARK: - Validation
    
    private static func validateConfig(_ config: PostureConfig) throws {
        // Validate neck thresholds
        guard config.neck.good_max < config.neck.minor_max,
              config.neck.minor_max < config.neck.poor_threshold else {
            throw ConfigError.invalidRange("Neck: good_max < minor_max < poor_threshold")
        }
        
        // Validate shoulder thresholds
        guard config.shoulders.symmetry_good_max < config.shoulders.symmetry_minor_max,
              config.shoulders.symmetry_minor_max < config.shoulders.symmetry_poor_threshold else {
            throw ConfigError.invalidRange("Shoulders symmetry: good_max < minor_max < poor_threshold")
        }
        
        guard config.shoulders.rounding_good_max < config.shoulders.rounding_minor_max,
              config.shoulders.rounding_minor_max < config.shoulders.rounding_poor_threshold else {
            throw ConfigError.invalidRange("Shoulders rounding: good_max < minor_max < poor_threshold")
        }
        
        // Validate torso thresholds
        guard config.torso.good_max < config.torso.minor_max,
              config.torso.minor_max < config.torso.poor_threshold else {
            throw ConfigError.invalidRange("Torso: good_max < minor_max < poor_threshold")
        }
        
        // Validate distance thresholds
        guard config.distance.good_min < config.distance.good_max else {
            throw ConfigError.invalidRange("Distance: good_min < good_max")
        }
        
        // Validate sitting duration
        guard config.sitting.good_max < config.sitting.minor_max,
              config.sitting.minor_max < config.sitting.poor_threshold else {
            throw ConfigError.invalidRange("Sitting: good_max < minor_max < poor_threshold")
        }
        
        // Validate vision confidence
        guard (0.2...1.0).contains(config.vision.confidence_threshold) else {
            throw ConfigError.invalidValue("Vision confidence must be 0.2-1.0")
        }
        
        // Validate notification thresholds
        guard config.notifications.strict_consecutive <= config.notifications.active_consecutive,
              config.notifications.active_consecutive <= config.notifications.gentle_consecutive else {
            throw ConfigError.invalidRange("Notifications: strict <= active <= gentle")
        }
        
        // Validate scoring
        guard config.scoring.poor_min < config.scoring.fair_min,
              config.scoring.fair_min < config.scoring.good_min,
              config.scoring.good_min < config.scoring.excellent_min else {
            throw ConfigError.invalidRange("Scoring: poor < fair < good < excellent")
        }
    }
    
    // MARK: - Reset to Defaults
    
    func resetToDefaults() throws {
        let defaultConfig = try Self.loadDefaultConfig()
        self.config = defaultConfig
        try Self.saveUserConfig(defaultConfig)
        print("🔄 Configuration reset to defaults")
    }
    
    // MARK: - Reload Configuration
    
    func reloadConfig() throws {
        self.config = try Self.loadConfiguration()
        print("🔄 Configuration reloaded")
    }
    
    // MARK: - User Config Path
    
    func getUserConfigPath() -> String {
        return Self.userConfigURL.path
    }
    
    func openUserConfigInEditor() {
        NSWorkspace.shared.open(Self.userConfigURL)
    }
}
