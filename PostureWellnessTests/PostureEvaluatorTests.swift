//
//  PostureEvaluatorTests.swift
//  PostureWellness
//
//

import XCTest
@testable import PostureWellness

final class PostureEvaluatorTests: XCTestCase {
    
    var evaluator: PostureEvaluator!
    
    override func setUpWithError() throws {
        evaluator = PostureEvaluator()
    }
    
    // MARK: - Excellent Posture Tests
    
    func testExcellentPosture() throws {
        let reading = evaluator.evaluate(
            neckAngle: 5,      // Good
            neckSideTilt: 3,   // Good
            shoulderSymmetry: 1, // Good
            shoulderRounding: 10, // Good
            torsoAngle: 8,     // Good
            screenDistance: 60, // Good
            sittingDuration: 30, // Good
            confidence: 0.9
        )
        
        XCTAssertTrue(reading.isValid, "Reading should be valid")
        XCTAssertGreaterThanOrEqual(reading.overallScore, 90, "Excellent posture should score 90+")
        XCTAssertEqual(reading.status, .excellent, "Status should be excellent")
        XCTAssertEqual(reading.issues.count, 0, "Should have no issues")
    }
    
    // MARK: - Poor Posture Tests
    
    func testPoorNeckPosture() throws {
        let reading = evaluator.evaluate(
            neckAngle: 30,     // Poor (> 21)
            neckSideTilt: 20,
            shoulderSymmetry: 1,
            shoulderRounding: 10,
            torsoAngle: 8,
            screenDistance: 60,
            sittingDuration: 30,
            confidence: 0.9
        )
        
        XCTAssertTrue(reading.isValid)
        XCTAssertGreaterThan(reading.issues.count, 0, "Should detect neck issue")
        
        let neckIssues = reading.issues.filter { $0.type == .neck }
        XCTAssertEqual(neckIssues.count, 1, "Should have one neck issue")
        XCTAssertEqual(neckIssues.first?.severity, .significant, "Neck issue should be significant")
    }
    
    func testPoorShoulderAsymmetry() throws {
        let reading = evaluator.evaluate(
            neckAngle: 5,
            neckSideTilt: 3,
            shoulderSymmetry: 6,  // Poor (> 5)
            shoulderRounding: 10,
            torsoAngle: 8,
            screenDistance: 60,
            sittingDuration: 30,
            confidence: 0.9
        )
        
        let shoulderIssues = reading.issues.filter { $0.type == .shoulderSymmetry }
        XCTAssertGreaterThan(shoulderIssues.count, 0, "Should detect shoulder asymmetry")
    }
    
    func testLongSittingDuration() throws {
        let reading = evaluator.evaluate(
            neckAngle: 5,
            neckSideTilt: 3,
            shoulderSymmetry: 1,
            shoulderRounding: 10,
            torsoAngle: 8,
            screenDistance: 60,
            sittingDuration: 70,  // Over 60 min threshold
            confidence: 0.9
        )
        
        let sittingIssues = reading.issues.filter { $0.type == .sitting }
        XCTAssertGreaterThan(sittingIssues.count, 0, "Should detect sitting duration issue")
    }
    
    // MARK: - Score Calculation Tests
    
    func testScoreNeverNegative() throws {
        let reading = evaluator.evaluate(
            neckAngle: 50,     // Very poor
            neckSideTilt: 40,  // Very poor
            shoulderSymmetry: 10, // Very poor
            shoulderRounding: 40, // Very poor
            torsoAngle: 50,    // Very poor
            screenDistance: 30, // Very poor
            sittingDuration: 120, // Very poor
            confidence: 0.9
        )
        
        XCTAssertGreaterThanOrEqual(reading.overallScore, 0, "Score should never be negative")
        XCTAssertLessThanOrEqual(reading.overallScore, 100, "Score should never exceed 100")
    }
    
    // MARK: - Confidence Tests
    
    func testLowConfidenceReading() throws {
        let reading = evaluator.evaluate(
            neckAngle: 5,
            neckSideTilt: 3,
            shoulderSymmetry: 1,
            shoulderRounding: 10,
            torsoAngle: 8,
            screenDistance: 60,
            sittingDuration: 30,
            confidence: 0.1  // Below threshold
        )
        
        XCTAssertFalse(reading.isValid, "Low confidence reading should be invalid")
        XCTAssertEqual(reading.status, .unknown, "Status should be unknown")
    }
    
    func testMinimumConfidenceThreshold() throws {
        let config = ConfigurationManager.shared.config
        
        let validReading = evaluator.evaluate(
            neckAngle: 5,
            neckSideTilt: 3,
            shoulderSymmetry: 1,
            shoulderRounding: 10,
            torsoAngle: 8,
            screenDistance: 60,
            sittingDuration: 30,
            confidence: config.vision.confidence_threshold
        )
        
        XCTAssertTrue(validReading.isValid, "Reading at threshold should be valid")
    }
}
