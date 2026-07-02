//
//  AnalyticsStore.swift
//  PostureWellness
//
//

import Foundation

class AnalyticsStore {
    static let shared = AnalyticsStore()
    
    private let storageURL: URL
    private var readings: [PostureReading] = []
    private var cleanupTimer: Timer?
    
    private init() {
        // Create storage directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("PostureWellness", isDirectory: true)
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        
        storageURL = appFolder.appendingPathComponent("analytics.json")
        
        // Load existing data
        loadReadings()
        
        //Start periodic cleanup
        startPeriodicCleanup()
    }
    
    private func startPeriodicCleanup() {
        // Clean up once on startup
        clearOldData()
        
        // Schedule daily cleanup at 3 AM
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { [weak self] _ in
            self?.clearOldData()
        }
        
        print("🗓️ Scheduled daily data cleanup")
    }
    
    // MARK: - Storage
    
    func saveReading(_ reading: PostureReading) {
        // Only save valid readings
        guard reading.isValid else { return }
        
        readings.append(reading)
        
        // Keep only recent readings (based on retention policy)
        let retentionDays = UserDefaults.standard.integer(forKey: "dataRetentionDays")
        if retentionDays > 0 {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date())!
            readings = readings.filter { $0.timestamp > cutoffDate }
        }
        
        // Persist to disk
        saveReadings()
    }
    
    private func saveReadings() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(readings)
            try data.write(to: storageURL)
            print("💾 Saved \(readings.count) readings to disk")
        } catch {
            print("❌ Failed to save readings: \(error)")
        }
    }
    
    private func loadReadings() {
        do {
            let data = try Data(contentsOf: storageURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            readings = try decoder.decode([PostureReading].self, from: data)
            print("📊 Loaded \(readings.count) readings from disk")
        } catch {
            print("📊 No existing readings found (this is normal on first run)")
            readings = []
        }
    }
    
    // MARK: - Queries
    
    func getReadings(from startDate: Date, to endDate: Date) -> [PostureReading] {
        return readings.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
    }
    
    func getTodayReadings() -> [PostureReading] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return getReadings(from: startOfDay, to: endOfDay)
    }
    
    func getWeekReadings() -> [PostureReading] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return getReadings(from: startOfWeek, to: Date())
    }
    
    func getAllReadings() -> [PostureReading] {
        return readings
    }
    
    // MARK: - Statistics
    
    func getAverageScore(for readings: [PostureReading]) -> Int {
        guard !readings.isEmpty else { return 0 }
        let sum = readings.reduce(0) { $0 + $1.overallScore }
        return sum / readings.count
    }
    
    func getIssueBreakdown(for readings: [PostureReading]) -> [IssueType: Int] {
        var breakdown: [IssueType: Int] = [:]
        
        for reading in readings {
            for issue in reading.issues {
                breakdown[issue.type, default: 0] += 1
            }
        }
        
        return breakdown
    }
    
    func getStatusDistribution(for readings: [PostureReading]) -> [PostureStatus: Int] {
        var distribution: [PostureStatus: Int] = [:]
        
        for reading in readings {
            distribution[reading.status, default: 0] += 1
        }
        
        return distribution
    }
    
    func getDailyAverages(for days: Int = 7) -> [(date: Date, score: Int)] {
        let calendar = Calendar.current
        var dailyScores: [(Date, Int)] = []
        
        for dayOffset in (0..<days).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let dayReadings = getReadings(from: startOfDay, to: endOfDay)
            let avgScore = getAverageScore(for: dayReadings)
            
            dailyScores.append((startOfDay, avgScore))
        }
        
        return dailyScores
    }
    
    // MARK: - Cleanup
    
    func clearOldData() {
        let retentionDays = UserDefaults.standard.integer(forKey: "dataRetentionDays")
        
        // If 0, keep forever
        guard retentionDays > 0 else {
            print("🗓️ Data retention: Forever (no cleanup)")
            return
        }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date())!
        let beforeCount = readings.count
        readings = readings.filter { $0.timestamp > cutoffDate }
        
        if readings.count < beforeCount {
            saveReadings()
            let removed = beforeCount - readings.count
            print("🧹 Cleaned up \(removed) old readings (retention: \(retentionDays) days, kept: \(readings.count))")
        } else {
            print("🗓️ No old data to clean (retention: \(retentionDays) days)")
        }
    }
    
    func clearAllData() {
        readings = []
        saveReadings()
        print("🗑️ All analytics data cleared")
    }
}
