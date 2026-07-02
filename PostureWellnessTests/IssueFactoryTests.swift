//
//  IssueFactoryTests.swift
//  PostureWellness
//
//

import XCTest
@testable import PostureWellness

final class IssueFactoryTests: XCTestCase {
    
    var config: PostureConfig!
    
    override func setUpWithError() throws {
        config = ConfigurationManager.shared.config
    }
    
    // MARK: - Neck Issue Tests
    
    func testNeckIssue_NoIssue() throws {
        let issue = IssueFactory.createNeckIssue(angle: 5, config: config.neck)
        XCTAssertNil(issue, "Good neck angle should produce no issue")
    }
    
    func testNeckIssue_Minor() throws {
        let issue = IssueFactory.createNeckIssue(angle: 15, config: config.neck)
        XCTAssertNotNil(issue, "Minor neck angle should produce issue")
        XCTAssertEqual(issue?.severity, .minor)
        XCTAssertEqual(issue?.type, .neck)
    }
    
    func testNeckIssue_Significant() throws {
        let issue = IssueFactory.createNeckIssue(angle: 25, config: config.neck)
        XCTAssertNotNil(issue)
        XCTAssertEqual(issue?.severity, .significant)
    }
    
    func testNeckIssue_HasGuidance() throws {
        let issue = IssueFactory.createNeckIssue(angle: 25, config: config.neck)
        XCTAssertNotNil(issue?.guidance)
        XCTAssertFalse(issue?.guidance.isEmpty ?? true, "Issue should have guidance text")
    }
    
    // MARK: - Shoulder Symmetry Tests
    
    func testShoulderSymmetry_Good() throws {
        let issue = IssueFactory.createShoulderSymmetryIssue(difference: 1, config: config.shoulders)
        XCTAssertNil(issue, "Good shoulder symmetry should produce no issue")
    }
    
    func testShoulderSymmetry_Poor() throws {
        let issue = IssueFactory.createShoulderSymmetryIssue(difference: 6, config: config.shoulders)
        XCTAssertNotNil(issue)
        XCTAssertEqual(issue?.type, .shoulderSymmetry)
    }
    
    // MARK: - Sitting Duration Tests
    
    func testSittingDuration_Good() throws {
        let issue = IssueFactory.createSittingIssue(minutes: 30, config: config.sitting)
        XCTAssertNil(issue, "Short sitting duration should produce no issue")
    }
    
    func testSittingDuration_Warning() throws {
        let issue = IssueFactory.createSittingIssue(minutes: 50, config: config.sitting)
        XCTAssertNotNil(issue)
        XCTAssertEqual(issue?.severity, .minor)
    }
    
    func testSittingDuration_Significant() throws {
        let issue = IssueFactory.createSittingIssue(minutes: 70, config: config.sitting)
        XCTAssertNotNil(issue)
        XCTAssertEqual(issue?.severity, .significant)
    }
    
    // MARK: - Formatted Values Tests
    
    func testFormattedValue_Angles() throws {
        let neckIssue = IssueFactory.createNeckIssue(angle: 25.7, config: config.neck)
        XCTAssertTrue(neckIssue?.formattedValue.contains("°") ?? false, "Angle should include degree symbol")
    }
    
    func testFormattedValue_Distance() throws {
        let distanceIssue = IssueFactory.createDistanceIssue(distance: 45.3, config: config.distance)
        XCTAssertTrue(distanceIssue?.formattedValue.contains("cm") ?? false, "Distance should include cm")
    }
    
    func testFormattedValue_Duration() throws {
        let sittingIssue = IssueFactory.createSittingIssue(minutes: 65, config: config.sitting)
        XCTAssertTrue(sittingIssue?.formattedValue.contains("min") ?? false, "Duration should include min")
    }
}
