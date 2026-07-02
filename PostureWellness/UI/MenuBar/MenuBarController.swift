//
//  MenuBarController.swift
//  PostureWellness
//
//

import AppKit
import SwiftUI

class MenuBarController: NSObject {
    
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?
    
    // Current posture status
    private var currentStatus: PostureStatus = .unknown {
        didSet {
            updateStatusIcon()
        }
    }
    
    // MARK: - Setup
    
    func setup() {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem?.button else {
            print("❌ Failed to create status bar button")
            return
        }
        
        // Set initial icon
        button.image = getStatusIcon(for: .unknown)
        button.imagePosition = .imageLeading
        button.target = self
        button.action = #selector(statusBarButtonClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        
        // Create menu
        createMenu()
        
        // ✅ Listen for break state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateBreakMenuItem),
            name: .breakStateChanged,
            object: nil
        )
        
        print("✅ Menu bar controller initialized")
    }
    
    private func createMenu() {
        menu = NSMenu()
        
        // Header
        let headerItem = NSMenuItem()
        headerItem.view = createHeaderView()
        menu?.addItem(headerItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Status
        let statusItem = NSMenuItem(title: "Status: Unknown", action: nil, keyEquivalent: "")
        statusItem.tag = 100
        menu?.addItem(statusItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Quick actions
        let pauseItem = NSMenuItem(title: "Pause Monitoring", action: #selector(toggleMonitoring), keyEquivalent: "p")
        pauseItem.tag = 101
        pauseItem.target = self
        menu?.addItem(pauseItem)
        
        // Dismiss notifications (monitoring continues)
        let dismissItem = NSMenuItem(title: "I'm Aware (15 min)", action: #selector(dismissNotifications), keyEquivalent: "i")
        dismissItem.target = self
        menu?.addItem(dismissItem)
        
        let captureNowItem = NSMenuItem(title: "Analyze Now", action: #selector(analyzeNow), keyEquivalent: "a")
        captureNowItem.target = self
        menu?.addItem(captureNowItem)
        
        let takeBreakItem = NSMenuItem(title: "Take a Break Now", action: #selector(takeBreak), keyEquivalent: "b")
        takeBreakItem.tag = 102  // ✅ Add tag for updating later
        takeBreakItem.target = self
        menu?.addItem(takeBreakItem)
        
        let viewFeedbackItem = NSMenuItem(title: "View Last Analysis...", action: #selector(viewLastAnalysis), keyEquivalent: "v")
        viewFeedbackItem.target = self
        menu?.addItem(viewFeedbackItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Dashboard
        let dashboardItem = NSMenuItem(title: "Open Dashboard...", action: #selector(openDashboard), keyEquivalent: "d")
        dashboardItem.target = self
        menu?.addItem(dashboardItem)
        
        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu?.addItem(settingsItem)
        
        #if DEBUG
        let debugItem = NSMenuItem(title: "🔧 Force Cleanup Old Data", action: #selector(forceCleanup), keyEquivalent: "")
        debugItem.target = self
        menu?.addItem(debugItem)
        #endif
        
        menu?.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit Posture Wellness", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu?.addItem(quitItem)
    }
    
    @objc private func dismissNotifications() {
        NotificationManager.shared.dismissNotifications()
        print("🔕 User manually dismissed notifications")
    }
    
    private func createHeaderView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 40))
        
        let titleLabel = NSTextField(labelWithString: "Posture Wellness")
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.frame = NSRect(x: 12, y: 12, width: 180, height: 20)
        view.addSubview(titleLabel)
        
        return view
    }
    
    // MARK: - Icon Management
    
    private func getStatusIcon(for status: PostureStatus) -> NSImage? {
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        let imageName: String
        
        switch status {
        case .excellent:
            imageName = "checkmark.circle.fill"
        case .good:
            imageName = "checkmark.circle"
        case .fair:
            imageName = "exclamationmark.circle"
        case .poor:
            imageName = "exclamationmark.triangle"
        case .veryPoor:
            imageName = "exclamationmark.triangle.fill"
        case .unknown:
            imageName = "questionmark.circle"
        }
        
        let image = NSImage(systemSymbolName: imageName, accessibilityDescription: status.displayName)
        image?.isTemplate = true
        
        return image?.withSymbolConfiguration(config)
    }
    
    private func updateStatusIcon() {
        guard let button = statusItem?.button else { return }
        button.image = getStatusIcon(for: currentStatus)
        
        // Update status text in menu
        if let statusMenuItem = menu?.item(withTag: 100) {
            statusMenuItem.title = "Status: \(currentStatus.displayName) \(currentStatus.emoji)"
        }
    }
    
    // MARK: - Actions
    
    @objc private func statusBarButtonClicked() {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // Right click - show menu
            showMenu()
        } else {
            // Left click - show menu (we can change this to quick status later)
            showMenu()
        }
    }
    
    private func showMenu() {
        guard let menu = menu, let button = statusItem?.button else { return }
        statusItem?.menu = menu
        button.performClick(nil)
        statusItem?.menu = nil // Remove menu so click detection works again
    }
    
    @objc private func toggleMonitoring() {
        if let pauseItem = menu?.item(withTag: 101) {
            let isPaused = pauseItem.title.starts(with: "Resume")
            pauseItem.title = isPaused ? "Pause Monitoring" : "Resume Monitoring"
            
            // Post notification to pause/resume monitoring
            NotificationCenter.default.post(
                name: isPaused ? .resumeMonitoring : .pauseMonitoring,
                object: nil
            )
            
            print(isPaused ? "▶️ Monitoring resumed" : "⏸️ Monitoring paused")
        }
    }
    
    @objc private func analyzeNow() {
        print("📸 Manual capture triggered")
        // TODO: Trigger immediate capture
        NotificationCenter.default.post(name: .captureNow, object: nil)
    }
    
    @objc private func takeBreak() {
        if BreakReminderManager.shared.isCurrentlyOnBreak() {
            // End break
            print("🧘 Ending break from menu")
            BreakReminderManager.shared.endBreak()
        } else {
            // Start break
            print("🧘 Manual break triggered")
            BreakReminderManager.shared.startBreakManually()
        }
        
        // ✅ Update menu item
        updateBreakMenuItem()
    }
    
    @objc private func viewLastAnalysis() {
        print("👁️ Viewing last analysis")
        NotificationCenter.default.post(name: .showVisualFeedback, object: nil)
    }
    
    @objc private func openDashboard() {
        print("📊 Opening dashboard")
        // TODO: Open dashboard window
        NotificationCenter.default.post(name: .openDashboard, object: nil)
    }
    
    @objc private func openSettings() {
        print("⚙️ Opening settings")
        // TODO: Open settings window
        NotificationCenter.default.post(name: .openSettings, object: nil)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc private func updateBreakMenuItem() {
        if let breakItem = menu?.item(withTag: 102) {
            if BreakReminderManager.shared.isCurrentlyOnBreak() {
                breakItem.title = "End Break"
            } else {
                breakItem.title = "Take a Break Now"
            }
        }
    }
    
    #if DEBUG
    @objc private func forceCleanup() {
        AnalyticsStore.shared.clearOldData()
        print("🔧 Manual cleanup triggered")
    }
    #endif
    
    // MARK: - Public Interface
    
    func updateStatus(_ status: PostureStatus) {
        currentStatus = status
    }
    
    func updateWithReading(_ reading: PostureReading) {
        currentStatus = reading.status
        
        // Update tooltip with score
        statusItem?.button?.toolTip = """
        Posture Score: \(reading.overallScore)/100
        Status: \(reading.status.displayName)
        \(reading.issues.isEmpty ? "No issues detected" : "\(reading.issues.count) issue(s)")
        """
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let captureNow = Notification.Name("captureNow")
    static let pauseMonitoring = Notification.Name("pauseMonitoring")
    static let resumeMonitoring = Notification.Name("resumeMonitoring")
    static let openDashboard = Notification.Name("openDashboard")
    static let openSettings = Notification.Name("openSettings")
    static let breakStateChanged = Notification.Name("breakStateChanged")
}
