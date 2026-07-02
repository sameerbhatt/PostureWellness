//
//  ConfigurationTests.swift
//  PostureWellness
//
//

import XCTest
@testable import PostureWellness

final class ConfigurationTests: XCTestCase {
    
    var configManager: ConfigurationManager!
    
    override func setUpWithError() throws {
        configManager = ConfigurationManager.shared
    }
    
    // MARK: - Configuration Loading Tests
    
    func testConfigurationLoads() throws {
        let config = configManager.config
        XCTAssertNotNil(config, "Configuration should load")
        XCTAssertEqual(config.version, "1.0", "Config version should be 1.0")
    }
    
    func testNeckThresholds() throws {
        let neck = configManager.config.neck
        
        XCTAssertGreaterThan(neck.minor_max, neck.good_max, "Minor threshold should be greater than good")
        XCTAssertGreaterThan(neck.poor_threshold, neck.minor_max, "Poor threshold should be greater than minor")
        
        XCTAssertGreaterThan(neck.weight_poor, 0, "Weight should be positive")
        XCTAssertGreaterThan(neck.weight_minor, 0, "Weight should be positive")
    }
    
    func testShoulderThresholds() throws {
        let shoulders = configManager.config.shoulders
        
        // Symmetry
        XCTAssertGreaterThan(shoulders.symmetry_minor_max, shoulders.symmetry_good_max)
        XCTAssertGreaterThan(shoulders.symmetry_poor_threshold, shoulders.symmetry_minor_max)
        
        // Rounding
        XCTAssertGreaterThan(shoulders.rounding_minor_max, shoulders.rounding_good_max)
        XCTAssertGreaterThan(shoulders.rounding_poor_threshold, shoulders.rounding_minor_max)
    }
    
    func testVisionThresholds() throws {
        let vision = configManager.config.vision
        
        XCTAssertGreaterThanOrEqual(vision.confidence_threshold, 0.0)
        XCTAssertLessThanOrEqual(vision.confidence_threshold, 1.0)
        XCTAssertGreaterThan(vision.confidence_warning_count, 0)
    }
    
    func testScoringThresholds() throws {
        let scoring = configManager.config.scoring
        
        XCTAssertEqual(scoring.base_score, 100, "Base score should be 100")
        XCTAssertGreaterThan(scoring.excellent_min, scoring.good_min)
        XCTAssertGreaterThan(scoring.good_min, scoring.fair_min)
        XCTAssertGreaterThan(scoring.fair_min, scoring.poor_min)
    }
}
