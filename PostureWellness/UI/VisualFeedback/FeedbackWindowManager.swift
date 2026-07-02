//
//  FeedbackWindowManager.swift
//  PostureWellness
//
//

import Foundation
import AppKit

class FeedbackWindowManager {
    static let shared = FeedbackWindowManager()
    
    private var currentWindow: VisualFeedbackWindowController?
    private var lastReading: PostureReading?
    private var lastImage: NSImage?
    
    private init() {
        // Listen for show feedback notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showFeedback),
            name: .showVisualFeedback,
            object: nil
        )
    }
    
    func updateLatestCapture(reading: PostureReading, image: NSImage?) {
        lastReading = reading
        lastImage = image
    }
    
    @objc private func showFeedback() {
        guard let reading = lastReading else {
            print("⚠️ No reading available to show")
            return
        }
        
        showFeedbackWindow(reading: reading, image: lastImage)
    }
    
    func showFeedbackWindow(reading: PostureReading, image: NSImage?) {
        // Close existing window if any
        currentWindow?.close()
        
        // CRITICAL: Change activation policy temporarily to show window
        NSApp.setActivationPolicy(.regular)
        
        // Create and show new window
        let windowController = VisualFeedbackWindowController(reading: reading, image: image)
        windowController.showWindow(nil)
        
        // Force window to front
        windowController.window?.makeKeyAndOrderFront(nil)
        windowController.window?.orderFrontRegardless()
        windowController.window?.level = .floating
        
        // Bring app to front
        NSApp.activate(ignoringOtherApps: true)
        
        currentWindow = windowController
        
        print("📊 Visual feedback window opened")
    }
}
