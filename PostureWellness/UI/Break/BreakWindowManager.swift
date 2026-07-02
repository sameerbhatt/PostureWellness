//
//  BreakWindowManager.swift
//  PostureWellness
//
//

import SwiftUI
import AppKit

class BreakWindowManager: NSWindowController, NSWindowDelegate {
    
    static let shared = BreakWindowManager()
    
    private var breakWindow: NSWindow?
    
    private init() {
        super.init(window: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showBreakWindow() {
        // Close existing window if any
        closeBreakWindow()
        
        // Create new window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 650),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Break Time"
        window.center()
        window.level = .floating  // Keep on top
        window.isReleasedWhenClosed = false
        
        // Create SwiftUI view
        let contentView = BreakView(
            onEndBreak: { [weak self] in
                BreakReminderManager.shared.endBreak()
                self?.closeBreakWindow()
            },
            onSkipBreak: { [weak self] in
                BreakReminderManager.shared.skipBreak()
                self?.closeBreakWindow()
            }
        )
        
        window.contentView = NSHostingView(rootView: contentView)
        window.delegate = self
        
        // Store reference before showing
        breakWindow = window
        
        // Show window
        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        print("🪟 Break window opened")
    }
    
    func closeBreakWindow() {
        // ✅ Safely close and clear reference
        guard let window = breakWindow else { return }
        
        // Remove delegate first to prevent recursion
        window.delegate = nil
        
        // Close window if it's still visible
        if window.isVisible {
            window.close()
        }
        
        // Clear reference
        breakWindow = nil
        
        // Return to accessory if no other windows
        DispatchQueue.main.async {
            if SettingsWindowController.shared.window?.isVisible != true &&
               DashboardWindowController.shared.window?.isVisible != true {
                NSApp.setActivationPolicy(.accessory)
            }
        }
        
        print("🪟 Break window closed")
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
        BreakReminderManager.shared.skipBreak()
        
        // Clear our reference
        breakWindow = nil
        
        if SettingsWindowController.shared.window?.isVisible != true &&
           DashboardWindowController.shared.window?.isVisible != true {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
