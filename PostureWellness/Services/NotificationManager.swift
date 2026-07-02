//
//  NotificationManager.swift
//  PostureWellness
//
//

import Foundation
import UserNotifications

class NotificationManager: NSObject {
    
    static let shared = NotificationManager()
    
    private let config: PostureConfig
    private var consecutivePoorReadings: Int = 0
    private var lastNotificationTime: Date?
    private var isDismissed: Bool = false
    private var dismissUntilTime: Date?
    
    // Notification mode (from user preferences)
    enum NotificationMode {
        case silent
        case gentle
        case active
        case strict
        
        var consecutiveReadingsRequired: Int {
            let config = ConfigurationManager.shared.config
            switch self {
            case .silent:
                return Int.max // Never notify
            case .gentle:
                return config.notifications.gentle_consecutive
            case .active:
                return config.notifications.active_consecutive
            case .strict:
                return config.notifications.strict_consecutive
            }
        }
    }
    
    private var currentMode: NotificationMode = .active // Default, will be configurable
    
    // MARK: - Initialization
    
    private override init() {
        self.config = ConfigurationManager.shared.config
        super.init()
        
        // Load notification mode from settings
        loadNotificationModeFromSettings()
    }
    
    func loadNotificationModeFromSettings() {
        let modeString = UserDefaults.standard.string(forKey: "notificationMode") ?? "active"
        let mode: NotificationMode
        switch modeString {
        case "silent": mode = .silent
        case "gentle": mode = .gentle
        case "strict": mode = .strict
        default: mode = .active
        }
        currentMode = mode
        print("🔔 Loaded notification mode: \(mode)")
    }
    
    func setup() {
        requestNotificationPermission()
    }
    
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            } else if granted {
                print("✅ Notification permission granted")
            } else {
                print("⚠️ Notification permission denied")
            }
        }
    }
    
    // MARK: - Process Reading
    
    func processReading(_ reading: PostureReading) {
        // Check if currently dismissed
        if isDismissed {
            if let dismissTime = dismissUntilTime, Date() < dismissTime {
                // Still in dismiss period
                return
            } else {
                // Dismiss period expired
                isDismissed = false
                dismissUntilTime = nil
                consecutivePoorReadings = 0
                print("⏰ Dismiss period expired, resuming monitoring")
            }
        }
        
        // Check if posture is poor
        let isPoor = reading.overallScore < config.notifications.poor_score_threshold
        
        print("🔍 Processing reading - Score: \(reading.overallScore), isPoor: \(isPoor), mode: \(currentMode), consecutive: \(consecutivePoorReadings)")
            
        if isPoor && reading.isValid {
            consecutivePoorReadings += 1
            print("⚠️ Poor posture detected (\(consecutivePoorReadings) consecutive)")
            
            // Check if we should notify
            let requiredReadings = currentMode.consecutiveReadingsRequired
            print("   Required readings for \(currentMode): \(requiredReadings)")
            
            if consecutivePoorReadings >= requiredReadings {
                // Check minimum interval since last notification
                if shouldSendNotification() {
                    sendNotification(for: reading)
                    consecutivePoorReadings = 0 // Reset after notifying
                }
            }
        } else {
            // Good posture, reset counter
            if consecutivePoorReadings > 0 {
                print("✅ Posture improved, resetting counter")
            }
            consecutivePoorReadings = 0
        }
    }
    
    private func shouldSendNotification() -> Bool {
        guard let lastTime = lastNotificationTime else {
            return true // Never sent before
        }
        
        let minInterval = TimeInterval(config.notifications.min_interval_minutes * 60)
        let timeSinceLastNotification = Date().timeIntervalSince(lastTime)
        
        if timeSinceLastNotification < minInterval {
            print("🔕 Skipping notification (too soon, \(Int(minInterval - timeSinceLastNotification))s remaining)")
            return false
        }
        
        return true
    }
    
    // MARK: - Send Notification
    
    private func sendNotification(for reading: PostureReading) {
        let content = UNMutableNotificationContent()
        
        // Title
        content.title = "Posture Issue Detected"
        
        // Body - show primary issue or general message
        if let primaryIssue = reading.primaryIssue {
            content.body = primaryIssue.guidance
            content.subtitle = "\(primaryIssue.type.displayName): \(primaryIssue.severity.displayName)"
        } else {
            content.body = "Your posture needs attention. Score: \(reading.overallScore)/100"
        }
        
        // Sound
        content.sound = .default
        
        // Badge (optional)
        content.badge = NSNumber(value: reading.issues.count)
        
        // User info for handling actions
        content.userInfo = [
            "score": reading.overallScore,
            "issueCount": reading.issues.count
        ]
        
        // Add "I'm Aware" action
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "I'm Aware",
            options: []
        )
        
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "View Details",
            options: .foreground
        )
        
        let category = UNNotificationCategory(
            identifier: "POSTURE_ALERT",
            actions: [dismissAction, viewAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "POSTURE_ALERT"
        
        // Create request
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )
        
        // Send notification
        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error = error {
                print("❌ Failed to send notification: \(error.localizedDescription)")
            } else {
                print("🔔 Notification sent: \(content.body)")
                self?.lastNotificationTime = Date()
            }
        }
    }
    
    // MARK: - Dismiss
    
    func dismissNotifications(duration: TimeInterval? = nil) {
        isDismissed = true
        
        let dismissDuration = duration ?? TimeInterval(config.notifications.dismiss_duration_minutes * 60)
        dismissUntilTime = Date().addingTimeInterval(dismissDuration)
        
        consecutivePoorReadings = 0
        
        let minutes = Int(dismissDuration / 60)
        print("🔕 Notifications dismissed for \(minutes) minutes")
        
        // Clear existing notifications
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    func resumeNotifications() {
        isDismissed = false
        dismissUntilTime = nil
        consecutivePoorReadings = 0
        print("🔔 Notifications resumed")
    }
    
    // MARK: - Mode
    
    func setNotificationMode(_ mode: NotificationMode) {
        currentMode = mode
        print("🔔 Notification mode set to: \(mode)")
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is "active" (menu bar apps are always active)
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification actions
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        switch response.actionIdentifier {
        case "DISMISS_ACTION":
            print("👤 User dismissed notification")
            dismissNotifications()
            
        case "VIEW_ACTION":
            print("👤 User wants to view details")
            NotificationCenter.default.post(name: .showVisualFeedback, object: nil)
        
        case "TAKE_BREAK_ACTION":
            print("👤 User taking break")
            BreakReminderManager.shared.startBreakManually()
        
        case "SNOOZE_BREAK_ACTION":
            print("👤 User snoozed break")
            BreakReminderManager.shared.snoozeBreak()
        
        case UNNotificationDefaultActionIdentifier:
            // User tapped notification body
            print("👤 User tapped notification")
            NotificationCenter.default.post(name: .showVisualFeedback, object: nil)
            
        default:
            break
        }
        
        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let showVisualFeedback = Notification.Name("showVisualFeedback")
}
