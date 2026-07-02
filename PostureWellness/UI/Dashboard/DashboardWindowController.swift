//
//  DashboardWindowController.swift
//  PostureWellness
//
//

import SwiftUI
import AppKit

class DashboardWindowController: NSWindowController, NSWindowDelegate {
    
    static let shared = DashboardWindowController()
    
    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Posture Wellness Dashboard"
        window.center()
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("DashboardWindow")
        
        let contentView = DashboardView()
        window.contentView = NSHostingView(rootView: contentView)
        
        super.init(window: window)
        
        window.delegate = self
        
        // Listen for open dashboard notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(show),
            name: .openDashboard,
            object: nil
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func show() {
        NSApp.setActivationPolicy(.regular)
        
        showWindow(nil)
        // Force window to front
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        
        print("📊 Dashboard window opened")
    }
    
    func windowWillClose(_ notification: Notification) {
        if SettingsWindowController.shared.window?.isVisible != true {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
