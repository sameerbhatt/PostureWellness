//
//  DashboardView.swift
//  PostureWellness
//
//

import SwiftUI
import Charts

struct DashboardView: View {
    
    @State private var selectedTab: Tab = .today
    @State private var todayReadings: [PostureReading] = []
    @State private var weekReadings: [PostureReading] = []
    @State private var dailyAverages: [(date: Date, score: Int)] = []
    
    enum Tab {
        case today
        case week
        case history
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Tab selector
            tabSelector
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    switch selectedTab {
                    case .today:
                        todayView
                    case .week:
                        weekView
                    case .history:
                        historyView
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 800, height: 600)
        .onAppear {
            loadData()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dashboard")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Track your posture over time")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Refresh") {
                loadData()
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton("Today", tab: .today)
            tabButton("This Week", tab: .week)
            tabButton("History", tab: .history)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func tabButton(_ title: String, tab: Tab) -> some View {
        Button(action: { selectedTab = tab }) {
            Text(title)
                .font(.subheadline)
                .fontWeight(selectedTab == tab ? .semibold : .regular)
                .foregroundColor(selectedTab == tab ? .primary : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    selectedTab == tab ?
                    Color.accentColor.opacity(0.1) : Color.clear
                )
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Today View
    
    private var todayView: some View {
        VStack(spacing: 20) {
            if todayReadings.isEmpty {
                emptyStateView("No data for today yet")
            } else {
                todayStatsCards
                todayChart
                todayIssuesBreakdown
            }
        }
    }
    
    private var todayStatsCards: some View {
        HStack(spacing: 16) {
            statCard(
                title: "Average Score",
                value: "\(AnalyticsStore.shared.getAverageScore(for: todayReadings))",
                subtitle: "out of 100",
                color: .blue
            )
            
            statCard(
                title: "Sessions",
                value: "\(todayReadings.count)",
                subtitle: "analyzed today",
                color: .green
            )
            
            statCard(
                title: "Issues",
                value: "\(todayReadings.reduce(0) { $0 + $1.issues.count })",
                subtitle: "detected",
                color: .orange
            )
        }
    }
    
    private var todayChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Score Trend")
                .font(.headline)
            
            if #available(macOS 13.0, *) {
                Chart(todayReadings) { reading in
                    LineMark(
                        x: .value("Time", reading.timestamp),
                        y: .value("Score", reading.overallScore)
                    )
                    .foregroundStyle(Color.blue)
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Time", reading.timestamp),
                        y: .value("Score", reading.overallScore)
                    )
                    .foregroundStyle(Color.blue)
                    .symbolSize(80)
                    .annotation(position: .top, alignment: .center) {
                        Text("\(reading.overallScore)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(4)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.9))
                            .cornerRadius(4)
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel(format: .dateTime.hour().minute())
                        AxisGridLine()
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let score = value.as(Int.self) {
                                Text("\(score)")
                            }
                        }
                        AxisGridLine()
                    }
                }
                .chartXAxisLabel("Time", alignment: .center)
                .chartYAxisLabel("Posture Score", alignment: .center)
            } else {
                Text("Charts require macOS 13+")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Static info overlay below chart
            if !todayReadings.isEmpty {
                HStack(spacing: 16) {
                    statLabel("Sessions", "\(todayReadings.count)")
                    Divider().frame(height: 20)
                    statLabel("Average", "\(AnalyticsStore.shared.getAverageScore(for: todayReadings))")
                    Divider().frame(height: 20)
                    statLabel("Best", "\(todayReadings.map { $0.overallScore }.max() ?? 0)")
                    Divider().frame(height: 20)
                    statLabel("Worst", "\(todayReadings.map { $0.overallScore }.min() ?? 0)")
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private func statLabel(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
    
    private func scoreColor(_ score: Int) -> Color {
        if score >= 90 {
            return .green
        } else if score >= 75 {
            return .blue
        } else if score >= 60 {
            return .yellow
        } else if score >= 40 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var todayIssuesBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Common Issues Today")
                .font(.headline)
            
            let breakdown = AnalyticsStore.shared.getIssueBreakdown(for: todayReadings)
            
            if breakdown.isEmpty {
                Text("No issues detected today! 🎉")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(Array(breakdown.sorted { $0.value > $1.value }), id: \.key) { issue, count in
                    HStack {
                        Image(systemName: issue.icon)
                            .foregroundColor(.orange)
                        
                        Text(issue.displayName)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(count) time(s)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - Week View
    
    private var weekView: some View {
        VStack(spacing: 20) {
            if weekReadings.isEmpty {
                emptyStateView("No data for this week yet")
            } else {
                weekStatsCards
                weekChart
            }
        }
    }
    
    private var weekStatsCards: some View {
        HStack(spacing: 16) {
            statCard(
                title: "Week Average",
                value: "\(AnalyticsStore.shared.getAverageScore(for: weekReadings))",
                subtitle: "out of 100",
                color: .blue
            )
            
            statCard(
                title: "Total Sessions",
                value: "\(weekReadings.count)",
                subtitle: "this week",
                color: .green
            )
            
            statCard(
                title: "Best Day",
                value: bestDayScore(),
                subtitle: "score",
                color: .purple
            )
        }
    }
    
    private var weekChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("7-Day Trend")
                .font(.headline)
            
            if #available(macOS 13.0, *) {
                Chart(dailyAverages, id: \.date) { item in
                    BarMark(
                        x: .value("Day", item.date, unit: .day),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .annotation(position: .top, alignment: .center) {
                        if item.score > 0 {
                            Text("\(item.score)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(4)
                                .background(Color(NSColor.controlBackgroundColor).opacity(0.9))
                                .cornerRadius(4)
                        }
                    }
                }
                .frame(height: 250)
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        AxisGridLine()
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let score = value.as(Int.self) {
                                Text("\(score)")
                            }
                        }
                        AxisGridLine()
                    }
                }
                .chartXAxisLabel("Day of Week", alignment: .center)
                .chartYAxisLabel("Average Score", alignment: .center)
            } else {
                Text("Charts require macOS 13+")
                    .foregroundColor(.secondary)
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Static info overlay below chart
            if !dailyAverages.isEmpty {
                let scores = dailyAverages.map { $0.score }
                HStack(spacing: 16) {
                    statLabel("Week Avg", "\(scores.reduce(0, +) / max(scores.count, 1))")
                    Divider().frame(height: 20)
                    statLabel("Best Day", "\(scores.max() ?? 0)")
                    Divider().frame(height: 20)
                    statLabel("Worst Day", "\(scores.min() ?? 0)")
                    Divider().frame(height: 20)
                    statLabel("Trend", trendIndicator(scores))
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private func trendIndicator(_ scores: [Int]) -> String {
        guard scores.count >= 2 else { return "—" }
        let recent = scores.suffix(3).reduce(0, +) / 3
        let older = scores.prefix(3).reduce(0, +) / 3
        
        if recent > older + 5 {
            return "↗ Improving"
        } else if recent < older - 5 {
            return "↘ Declining"
        } else {
            return "→ Stable"
        }
    }
    
    // MARK: - History View
    
    private var historyView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Time Statistics")
                .font(.headline)
            
            let allReadings = AnalyticsStore.shared.getAllReadings()
            
            if allReadings.isEmpty {
                emptyStateView("No historical data yet")
            } else {
                VStack(spacing: 16) {
                    HStack {
                        Text("Total Sessions:")
                        Spacer()
                        Text("\(allReadings.count)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Average Score:")
                        Spacer()
                        Text("\(AnalyticsStore.shared.getAverageScore(for: allReadings))/100")
                            .fontWeight(.semibold)
                    }
                    
                    Divider()
                    
                    Text("Status Distribution")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    let distribution = AnalyticsStore.shared.getStatusDistribution(for: allReadings)
                    ForEach(Array(distribution.sorted { $0.value > $1.value }), id: \.key) { status, count in
                        HStack {
                            Text(status.emoji)
                            Text(status.displayName)
                            Spacer()
                            Text("\(count) sessions")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func statCard(title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func emptyStateView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(message)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(60)
    }
    
    private func bestDayScore() -> String {
        let scores = dailyAverages.map { $0.score }
        return scores.max().map { "\($0)" } ?? "—"
    }
    
    private func loadData() {
        todayReadings = AnalyticsStore.shared.getTodayReadings()
        weekReadings = AnalyticsStore.shared.getWeekReadings()
        dailyAverages = AnalyticsStore.shared.getDailyAverages(for: 7)
        print("📊 Loaded dashboard data")
    }
}

