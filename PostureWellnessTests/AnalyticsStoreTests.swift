//
//  AnalyticsStoreTests.swift
//  PostureWellness
//
//

import XCTest
@testable import PostureWellness

final class AnalyticsStoreTests: XCTestCase {
    
    var store: AnalyticsStore!
    
    override func setUpWithError() throws {
        store = AnalyticsStore.shared
        store.clearAllData() // Start fresh
    }
    
    override func tearDownWithError() throws {
        store.clearAllData() // Clean up after tests
    }
    
    // MARK: - Save/Load Tests
    
    func testSaveReading() throws {
        let reading = createMockReading(score: 85)
        
        store.saveReading(reading)
        
        let allReadings = store.getAllReadings()
        XCTAssertEqual(allReadings.count, 1, "Should have saved one reading")
        XCTAssertEqual(allReadings.first?.overallScore, 85)
    }
    
    func testSaveMultipleReadings() throws {
        for score in [80, 85, 90, 75, 88] {
            let reading = createMockReading(score: score)
            store.saveReading(reading)
        }
        
        let allReadings = store.getAllReadings()
        XCTAssertEqual(allReadings.count, 5, "Should have saved 5 readings")
    }
    
    func testDoesNotSaveInvalidReadings() throws {
        let invalidReading = PostureReading.unknown(confidence: 0.3)
        
        store.saveReading(invalidReading)
        
        let allReadings = store.getAllReadings()
        XCTAssertEqual(allReadings.count, 0, "Should not save invalid readings")
    }
    
    // MARK: - Statistics Tests
    
    func testAverageScore() throws {
        let scores = [80, 85, 90, 75, 88]
        for score in scores {
            store.saveReading(createMockReading(score: score))
        }
        
        let average = store.getAverageScore(for: store.getAllReadings())
        let expectedAverage = scores.reduce(0, +) / scores.count
        
        XCTAssertEqual(average, expectedAverage, "Average should be calculated correctly")
    }
    
    func testAverageScore_EmptyReadings() throws {
        let average = store.getAverageScore(for: [])
        XCTAssertEqual(average, 0, "Average of empty array should be 0")
    }
    
    func testIssueBreakdown() throws {
        let reading1 = createMockReading(score: 70, issues: [
            Issue(type: .neck, severity: .minor, measuredValue: 15, guidance: "Test")
        ])
        let reading2 = createMockReading(score: 75, issues: [
            Issue(type: .neck, severity: .moderate, measuredValue: 20, guidance: "Test"),
            Issue(type: .slouch, severity: .minor, measuredValue: 18, guidance: "Test")
        ])
        
        store.saveReading(reading1)
        store.saveReading(reading2)
        
        let breakdown = store.getIssueBreakdown(for: store.getAllReadings())
        
        XCTAssertEqual(breakdown[.neck], 2, "Should have 2 neck issues")
        XCTAssertEqual(breakdown[.slouch], 1, "Should have 1 slouch issue")
    }
    
    func testStatusDistribution() throws {
        store.saveReading(createMockReading(score: 95)) // Excellent
        store.saveReading(createMockReading(score: 85)) // Good
        store.saveReading(createMockReading(score: 80)) // Good
        store.saveReading(createMockReading(score: 65)) // Fair
        
        let distribution = store.getStatusDistribution(for: store.getAllReadings())
        
        XCTAssertEqual(distribution[.excellent], 1)
        XCTAssertEqual(distribution[.good], 2)
        XCTAssertEqual(distribution[.fair], 1)
    }
    
    // MARK: - Date Range Tests
    
    func testGetTodayReadings() throws {
        // Create readings for today
        store.saveReading(createMockReading(score: 85))
        store.saveReading(createMockReading(score: 90))
        
        let todayReadings = store.getTodayReadings()
        XCTAssertEqual(todayReadings.count, 2, "Should return today's readings")
    }
    
    // MARK: - Helper Methods
    
    private func createMockReading(score: Int, issues: [Issue] = []) -> PostureReading {
        let status: PostureStatus
        if score >= 90 {
            status = .excellent
        } else if score >= 75 {
            status = .good
        } else if score >= 60 {
            status = .fair
        } else {
            status = .poor
        }
        
        return PostureReading(
            neckAngle: 10,
            neckSideTilt: 10,
            shoulderSymmetry: 1,
            shoulderRounding: 12,
            torsoAngle: 8,
            screenDistance: 60,
            sittingDuration: 30,
            overallScore: score,
            status: status,
            issues: issues,
            confidence: 0.85
        )
    }
}
