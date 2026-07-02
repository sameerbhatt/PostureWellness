//
//  SettingsView.swift
//  PostureWellness
//
//  Created by Sameer Bhatt on 26/01/26.
//

import SwiftUI

struct SettingsView: View {
    
    @AppStorage("captureInterval") private var captureInterval: Double = 60
    @AppStorage("notificationMode") private var notificationMode: String = "active"
    @AppStorage("runOnBattery") private var runOnBattery: Bool = true
    @AppStorage("reduceFrequencyOnBattery") private var reduceFrequencyOnBattery: Bool = true
    @AppStorage("sittingWarningMinutes") private var sittingWarningMinutes: Int = 60
    @AppStorage("dataRetentionDays") private var dataRetentionDays: Int = 30
    @AppStorage("dismissDuration") private var dismissDuration: Int = 15
    @AppStorage("autoDetectDistance") private var autoDetectDistance: Bool = false
    @AppStorage("manualDistance") private var manualDistance: Double = 60
    @AppStorage("breakRemindersEnabled") private var breakRemindersEnabled: Bool = true
    @AppStorage("breakInterval") private var breakInterval: Int = 60
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Settings content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    monitoringSection
                    notificationsSection
                    advancedSection
                    aboutSection
                }
                .padding(20)
            }
            
            Divider()
            
            // Footer
            footerView
        }
        .frame(width: 500, height: 600)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Monitoring Section
    
    private var monitoringSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Monitoring")
            
            VStack(alignment: .leading, spacing: 16) {
                // Capture interval
                VStack(alignment: .leading, spacing: 6) {
                    Text("Capture Interval")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Slider(value: $captureInterval, in: 60...900, step: 60)
                            .onChange(of: captureInterval) {
                                saveSettings()
                            }
                        
                        Text(formatInterval(captureInterval))
                            .frame(width: 60, alignment: .trailing)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("How often to analyze your posture")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Battery options
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Run on battery power", isOn: $runOnBattery)
                        .onChange(of: runOnBattery) {
                            saveSettings()
                        }
                    
                    if runOnBattery {
                        Toggle("Reduce frequency on battery", isOn: $reduceFrequencyOnBattery)
                            .padding(.leading, 20)
                            .onChange(of: reduceFrequencyOnBattery) {
                                saveSettings()
                            }
                        
                        if reduceFrequencyOnBattery {
                            Text("Doubles interval when on battery")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 20)
                        }
                    }
                }
                
                Divider()
                
                // Sitting duration
                VStack(alignment: .leading, spacing: 6) {
                    Text("Sitting Duration Warning")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("", selection: $sittingWarningMinutes) {
                        Text("Off").tag(0)
                        Text("30 minutes").tag(30)
                        Text("45 minutes").tag(45)
                        Text("60 minutes").tag(60)
                        Text("90 minutes").tag(90)
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: sittingWarningMinutes) {
                        saveSettings()
                    }
                    
                    Text("Alert when sitting for too long")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Screen distance
                /* VStack(alignment: .leading, spacing: 8) {
                    Text("Screen Distance")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("", selection: $autoDetectDistance) {
                        Text("Auto-detect").tag(true)
                        Text("Manual").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                    .onChange(of: autoDetectDistance) {
                        saveSettings()
                    }
                    
                    if !autoDetectDistance {
                        HStack {
                            Slider(value: $manualDistance, in: 40...80, step: 5)
                                .onChange(of: manualDistance) {
                                    saveSettings()
                                }
                            
                            Text("\(Int(manualDistance)) cm")
                                .frame(width: 60, alignment: .trailing)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("Distance from screen for posture analysis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider() */

                // Break Reminders
                VStack(alignment: .leading, spacing: 8) {
                    Text("Break Reminders")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Toggle("Enable break reminders", isOn: $breakRemindersEnabled)
                        .onChange(of: breakRemindersEnabled) {
                            saveSettings()
                            updateBreakReminders()
                        }
                    
                    if breakRemindersEnabled {
                        Picker("Break interval:", selection: $breakInterval) {
                            Text("30 minutes").tag(30)
                            Text("45 minutes").tag(45)
                            Text("60 minutes").tag(60)
                            Text("90 minutes").tag(90)
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 20)
                        .onChange(of: breakInterval) {
                            saveSettings()
                            updateBreakReminders()
                        }
                        
                        Text("Reminds you to take breaks and stretch")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 20)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Notifications Section
    
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Notifications")
            
            VStack(alignment: .leading, spacing: 16) {
                // Notification mode
                VStack(alignment: .leading, spacing: 6) {
                    Text("Alert Mode")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("", selection: $notificationMode) {
                        Text("Silent (menu bar only)").tag("silent")
                        Text("Gentle (after 3 issues)").tag("gentle")
                        Text("Active (after 2 issues)").tag("active")
                        Text("Strict (immediate)").tag("strict")
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: notificationMode) { oldValue, newValue in
                        saveSettings()
                        updateNotificationMode(newValue)
                    }
                    
                    Text(notificationModeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Dismiss duration
                VStack(alignment: .leading, spacing: 6) {
                    Text("'I'm Aware' Duration")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("", selection: $dismissDuration) {
                        Text("5 minutes").tag(5)
                        Text("10 minutes").tag(10)
                        Text("15 minutes").tag(15)
                        Text("30 minutes").tag(30)
                        Text("1 hour").tag(60)
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: dismissDuration) {
                        saveSettings()
                    }
                    
                    Text("How long to suppress notifications")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Advanced Section
    
    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Advanced")
            
            VStack(alignment: .leading, spacing: 16) {
                // Data retention
                VStack(alignment: .leading, spacing: 6) {
                    Text("Data Retention")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("", selection: $dataRetentionDays) {
                        Text("7 days").tag(7)
                        Text("30 days").tag(30)
                        Text("90 days").tag(90)
                        Text("Forever").tag(0)
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: dataRetentionDays) {
                        saveSettings()
                    }
                    
                    Text("How long to keep posture history")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Config file
                /* VStack(alignment: .leading, spacing: 6) {
                    Text("Configuration")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Button("Edit Advanced Configuration...") {
                        openConfigFile()
                    }
                    
                    Text("Edit thresholds and detection parameters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider() */
                
                // Reset
                Button("Reset All Settings to Defaults") {
                    resetToDefaults()
                }
                .foregroundColor(.red)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("About")
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("© Sameer Bhatt. All rights reserved.")
                        .font(.headline)
                    Spacer()
                    Text("v1.0.0")
                        .foregroundColor(.secondary)
                }
                        
                Text("A posture monitoring app to make you better")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Label("All processing happens locally", systemImage: "lock.shield")
                        .font(.caption)
                    Label("No image data leaves your device", systemImage: "eye.slash")
                        .font(.caption)
                    Label("Camera only active during capture", systemImage: "camera")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            Spacer()
            
            Button("Done") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Helpers
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.secondary)
    }
    
    private func formatInterval(_ seconds: Double) -> String {
        let minutes = Int(seconds / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hr"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }
    
    private var notificationModeDescription: String {
        switch notificationMode {
        case "silent":
            return "Only updates menu bar icon, no notifications"
        case "gentle":
            return "Notifies after 3 consecutive poor posture readings"
        case "active":
            return "Notifies after 2 consecutive poor posture readings"
        case "strict":
            return "Notifies immediately on poor posture detection"
        default:
            return ""
        }
    }
    
    private func saveSettings() {
        print("💾 Settings saved")
        
        // Post notification that settings changed
        NotificationCenter.default.post(name: .settingsChanged, object: nil)
    }
    
    private func updateNotificationMode(_ mode: String) {
        let notificationMode: NotificationManager.NotificationMode
        switch mode {
        case "silent":
            notificationMode = .silent
        case "gentle":
            notificationMode = .gentle
        case "strict":
            notificationMode = .strict
        default:
            notificationMode = .active
        }
        
        NotificationManager.shared.setNotificationMode(notificationMode)
    }
    
    private func updateBreakReminders() {
        if breakRemindersEnabled {
            BreakReminderManager.shared.start()
        } else {
            BreakReminderManager.shared.stop()
        }
    }
    
    private func openConfigFile() {
        let path = ConfigurationManager.shared.getUserConfigPath()
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.open(url)
    }
    
    private func resetToDefaults() {
        captureInterval = 120
        notificationMode = "active"
        runOnBattery = true
        reduceFrequencyOnBattery = true
        sittingWarningMinutes = 60
        dataRetentionDays = 30
        dismissDuration = 15
        autoDetectDistance = false
        manualDistance = 60
        
        // Reset config file
        do {
            try ConfigurationManager.shared.resetToDefaults()
            try ConfigurationManager.shared.reloadConfig()
            print("✅ Settings reset to defaults")
        } catch {
            print("❌ Failed to reset settings: \(error)")
        }
        
        saveSettings()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let settingsChanged = Notification.Name("settingsChanged")
}
