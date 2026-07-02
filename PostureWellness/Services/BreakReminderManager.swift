//
//  BreakReminderManager.swift
//  PostureWellness
//
//

import Foundation
import UserNotifications
import AppKit

class BreakReminderManager {
    
    static let shared = BreakReminderManager()
    
    private let config: PostureConfig
    private var breakTimer: Timer?
    private var breakStartTime: Date?
    private var isOnBreak = false
    
    private init() {
        self.config = ConfigurationManager.shared.config
    }
    
    // MARK: - Start/Stop
    
    func start() {
        guard config.break_reminder.enabled else {
            print("⏰ Break reminders disabled in config")
            return
        }
        
        stop() // Clear any existing timer
        
        let interval = TimeInterval(config.break_reminder.interval_minutes * 60)
        
        breakTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.triggerBreakReminder()
        }
        
        print("⏰ Break reminders enabled (every \(config.break_reminder.interval_minutes) min)")
    }
    
    func stop() {
        breakTimer?.invalidate()
        breakTimer = nil
    }
    
    // MARK: - Break Reminder
    
    private func triggerBreakReminder() {
        guard !isOnBreak else {
            print("⏰ Already on break, skipping reminder")
            return
        }
        
        print("⏰ Break reminder triggered")
        
        // Send notification
        sendBreakNotification()
        
        // Show break window
        showBreakWindow()
        
        // Start break timer
        startBreakTimer()
    }
    
    private func sendBreakNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Time for a Break! 🧘"
        content.body = "You've been working for \(config.break_reminder.interval_minutes) minutes. Stand up, stretch, and rest your eyes."
        content.sound = .default
        
        // Add actions
        let takeBreakAction = UNNotificationAction(
            identifier: "TAKE_BREAK_ACTION",
            title: "Take Break",
            options: .foreground
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_BREAK_ACTION",
            title: "Snooze 10 min",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "BREAK_REMINDER",
            actions: [takeBreakAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "BREAK_REMINDER"
        
        let request = UNNotificationRequest(
            identifier: "break-reminder-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send break notification: \(error)")
            } else {
                print("🔔 Break notification sent")
            }
        }
    }
    
    private func showBreakWindow() {
        BreakWindowManager.shared.showBreakWindow()
    }
    
    private func startBreakTimer() {
        isOnBreak = true
        breakStartTime = Date()
        
        // Always pause monitoring during breaks
        NotificationCenter.default.post(name: .pauseMonitoring, object: nil)
        print("⏸️ Monitoring paused during break")
        
        // ✅ Notify that break state changed
        NotificationCenter.default.post(name: .breakStateChanged, object: nil)
        
        // Auto-end break after duration
        let duration = TimeInterval(config.break_reminder.duration_seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.endBreak()
        }
    }
    
    // MARK: - Break Control
    
    func snoozeBreak() {
        print("⏰ Break snoozed for 10 minutes")
        
        // Stop current timer
        breakTimer?.invalidate()
        
        // Schedule next break in 10 minutes
        breakTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: false) { [weak self] _ in
            self?.triggerBreakReminder()
        }
        
        // Then resume normal schedule
        DispatchQueue.main.asyncAfter(deadline: .now() + 600) { [weak self] in
            self?.start()
        }
    }
    
    func startBreakManually() {
        print("⏰ Break started manually")
        
        // ✅ Always pause monitoring during manual breaks
        NotificationCenter.default.post(name: .pauseMonitoring, object: nil)
        
        triggerBreakReminder()
    }
    
    func endBreak() {
        guard isOnBreak else { return }
        
        isOnBreak = false
        breakStartTime = nil
        
        print("✅ Break ended")
        
        // ✅ Always resume monitoring after break
        NotificationCenter.default.post(name: .resumeMonitoring, object: nil)
        
        // ✅ Notify that break state changed
        NotificationCenter.default.post(name: .breakStateChanged, object: nil)
        
        // Close break window
        BreakWindowManager.shared.closeBreakWindow()
    }
    
    func skipBreak() {
        print("⏭️ Break skipped")
        
        // End break and resume monitoring
        isOnBreak = false
        breakStartTime = nil
        NotificationCenter.default.post(name: .resumeMonitoring, object: nil)
        
        // ✅ Notify that break state changed
        NotificationCenter.default.post(name: .breakStateChanged, object: nil)
        
        BreakWindowManager.shared.closeBreakWindow()
    }
    
    // MARK: - Status
    
    func getRemainingBreakTime() -> TimeInterval? {
        guard isOnBreak, let startTime = breakStartTime else { return nil }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let total = TimeInterval(config.break_reminder.duration_seconds)
        return max(0, total - elapsed)
    }
    
    func isCurrentlyOnBreak() -> Bool {
        return isOnBreak
    }
}

// MARK: - Notification Handler Extension

extension BreakReminderManager {
    func handleNotificationAction(_ identifier: String) {
        switch identifier {
        case "TAKE_BREAK_ACTION":
            startBreakManually()
            
        case "SNOOZE_BREAK_ACTION":
            snoozeBreak()
            
        default:
            break
        }
    }
}
