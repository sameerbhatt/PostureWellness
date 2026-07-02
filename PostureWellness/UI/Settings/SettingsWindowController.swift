//
//  SettingsWindowController.swift
//  PostureWellness
//
//

import SwiftUI
import AppKit

class SettingsWindowController: NSWindowController, NSWindowDelegate {
    
    static let shared = SettingsWindowController()
    
    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Settings"
        window.center()
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("SettingsWindow")
        
        let contentView = SettingsView()
        window.contentView = NSHostingView(rootView: contentView)
        
        super.init(window: window)
        
        // ✅ Set delegate to self
        window.delegate = self
        
        // Listen for open settings notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(show),
            name: .openSettings,
            object: nil
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func show() {
        // Change activation policy temporarily to show window
        NSApp.setActivationPolicy(.regular)
        
        showWindow(nil)
        
        // Force window to front
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        
        print("⚙️ Settings window opened")
    }
    
    // ✅ Implement NSWindowDelegate method
    func windowWillClose(_ notification: Notification) {
        // Return to accessory mode when window closes
        NSApp.setActivationPolicy(.accessory)
    }
}
