//
//  PostureWellnessApp.swift
//  PostureWellness
//
//

import SwiftUI
import Combine
import AVFoundation
#if os(macOS)
import IOKit.ps
#endif

@main
struct PostureWellnessApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // We don't want a main window - just menu bar
        Settings {
            EmptyView()
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var menuBarController: MenuBarController?
    private var monitoringService: MonitoringService?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("\n🚀 Posture Wellness Starting...")
        
        // Register default values
        UserDefaults.standard.register(defaults: [
            "captureInterval": 120.0,  // 2 minutes default
            "runOnBattery": true,
            "reduceFrequencyOnBattery": true
        ])
        
        NSApp.setActivationPolicy(.accessory)
        
        NotificationManager.shared.setup()
        
        menuBarController = MenuBarController()
        menuBarController?.setup()
        
        monitoringService = MonitoringService()
        monitoringService?.delegate = self
        monitoringService?.start()
        
        BreakReminderManager.shared.start()
        
        _ = DashboardWindowController.shared
        _ = SettingsWindowController.shared
        
        // Observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleManualCapture),
            name: .captureNow,
            object: nil
        )
        
        // ✅ Add pause/resume observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePauseMonitoring),
            name: .pauseMonitoring,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleResumeMonitoring),
            name: .resumeMonitoring,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsChanged),
            name: .settingsChanged,
            object: nil
        )
        
        print("✅ App initialization complete\n")
    }

    @objc private func handlePauseMonitoring() {
        monitoringService?.pause()
    }

    @objc private func handleResumeMonitoring() {
        monitoringService?.resume()
    }
    
    @objc private func handleManualCapture() {
        print("🎯 Manual capture requested from menu")
        monitoringService?.triggerManualCapture()
    }
    
    @objc private func handleSettingsChanged() {
        print("⚙️ Settings changed, applying...")
        
        // Update monitoring service
        monitoringService?.reloadSettings()
        
        // Reload notification mode
        NotificationManager.shared.loadNotificationModeFromSettings()
        
        // Apply data retention policy
        AnalyticsStore.shared.clearOldData()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("👋 Shutting down...")
        monitoringService?.stop()
    }
}

// MARK: - Monitoring Service Delegate

extension AppDelegate: MonitoringServiceDelegate {
    func monitoringService(_ service: MonitoringService, didAnalyze reading: PostureReading) {
        // Update menu bar
        menuBarController?.updateWithReading(reading)
        
        // Process for notifications
        NotificationManager.shared.processReading(reading)
        
        // ✅ Save to analytics
        AnalyticsStore.shared.saveReading(reading)
        
        // Log
        print("📊 \(reading.status.emoji) Score: \(reading.overallScore) | Issues: \(reading.issues.count)")
    }
    
    func monitoringService(_ service: MonitoringService, didEncounterError error: Error) {
        print("❌ Monitoring error: \(error.localizedDescription)")
    }
}

// MARK: - Monitoring Service Protocol

protocol MonitoringServiceDelegate: AnyObject {
    func monitoringService(_ service: MonitoringService, didAnalyze reading: PostureReading)
    func monitoringService(_ service: MonitoringService, didEncounterError error: Error)
}

// MARK: - Monitoring Service

class MonitoringService: NSObject, CaptureEngineDelegate {
    weak var delegate: MonitoringServiceDelegate?
    
    private let captureEngine = CaptureEngine()
    private let visionAnalyzer = VisionAnalyzer()
    private var captureTimer: Timer?
    private var isCameraReady = false
    private var isPaused = false
    
    // battery monitoring
    private var isOnBattery: Bool {
        #if os(macOS)
        // Use IOKit to determine external power adapter presence
        if let adapterDetails = IOPSCopyExternalPowerAdapterDetails()?.takeRetainedValue() as? [String: Any],
           !adapterDetails.isEmpty {
            // External power adapter is present => on AC power
            return false
        }
        // No external power adapter => likely on battery
        return true
        #else
        return false
        #endif
    }
    
    func start() {
        print("▶️ Starting monitoring service...")
        
        captureEngine.delegate = self
        
        // Monitor power state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(powerStateChanged),
            name: NSNotification.Name("NSProcessInfoPowerStateDidChange"),
            object: nil
        )
        
        // Start periodic capture timer
        startPeriodicCapture()
    }
    
    func stop() {
        captureTimer?.invalidate()
        if isCameraReady {
            captureEngine.stopCapture()
            captureEngine.cleanup()
            isCameraReady = false
        }
        print("⏹️ Monitoring stopped")
    }
    
    func pause() {
        isPaused = true
        print("⏸️ Monitoring paused")
    }

    func resume() {
        isPaused = false
        print("▶️ Monitoring resumed")
    }
    
    private func startPeriodicCapture() {
        // Get interval from user settings
        var interval = TimeInterval(UserDefaults.standard.double(forKey: "captureInterval"))
        interval = interval > 0 ? interval : 60.0 // Default to 60 if not set

        // Adjust for battery if needed
        let finalInterval = getAdjustedInterval(baseInterval: interval)

        // If monitoring is disabled (infinite interval), don't schedule a timer
        if finalInterval.isInfinite || finalInterval.isNaN {
            captureTimer?.invalidate()
            captureTimer = nil
            print("⏱️ Periodic capture disabled due to settings/power state")
            return
        }

        // Schedule timer with valid interval
        captureTimer = Timer.scheduledTimer(withTimeInterval: finalInterval, repeats: true) { [weak self] _ in
            self?.performCapture()
        }

        // Perform first capture immediately
        performCapture()

        // Log without forcing conversion to Int to avoid crash on edge cases
        print("⏱️ Periodic capture scheduled (every \(finalInterval)s)")
    }
    
    @objc private func powerStateChanged() {
        print("🔌 Power state changed")
        
        // Restart timer with new interval
        updateCaptureInterval()
    }
    
    // ✅ Add this helper method
    private func getAdjustedInterval(baseInterval: TimeInterval) -> TimeInterval {
        let runOnBattery = UserDefaults.standard.bool(forKey: "runOnBattery")
        let reduceFrequency = UserDefaults.standard.bool(forKey: "reduceFrequencyOnBattery")
        
        // If on battery
        if isOnBattery {
            // Check if we should run at all
            if !runOnBattery {
                print("🔋 On battery - monitoring disabled (user setting)")
                return .infinity // Effectively disables timer
            }
            
            // Check if we should reduce frequency
            if reduceFrequency {
                let adjustedInterval = baseInterval * 2
                print("🔋 On battery - doubling interval to \(Int(adjustedInterval))s")
                return adjustedInterval
            }
        }
        
        return baseInterval
    }
    
    func updateCaptureInterval() {
        // Invalidate existing timer
        captureTimer?.invalidate()
        
        // Restart with new interval (startPeriodicCapture handles disabled state)
        startPeriodicCapture()
        
        let powerSource = isOnBattery ? "battery" : "AC power"
        print("⏱️ Capture interval updated (on \(powerSource))")
    }
    
    private func performCapture() {
        // ✅ Check if paused first
        guard !isPaused else {
            print("⏸️ Capture skipped (monitoring paused)")
            return
        }
        
        // ✅ Check battery settings
        let runOnBattery = UserDefaults.standard.bool(forKey: "runOnBattery")
        if isOnBattery && !runOnBattery {
            print("🔋 Capture skipped (on battery, user disabled)")
            return
        }
            
        // Skip capture if the interval is effectively disabled
        var interval = TimeInterval(UserDefaults.standard.double(forKey: "captureInterval"))
        interval = interval > 0 ? interval : 60.0
        let finalInterval = getAdjustedInterval(baseInterval: interval)
        if finalInterval.isInfinite || finalInterval.isNaN {
            print("🔕 Capture skipped (monitoring disabled by settings)")
            return
        }
        
        print("\n📸 === Starting New Capture Cycle ===")
        
        // Cleanup first if needed (synchronous, no delay)
        if isCameraReady {
            print("🧹 Cleaning up previous camera session...")
            captureEngine.cleanup()
            isCameraReady = false
        }
        
        // Setup immediately
        setupAndCapture()
    }

    private func setupAndCapture() {
        print("🔧 Setting up camera...")
        
        captureEngine.setupCamera { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                print("✅ Camera setup successful")
                self.isCameraReady = true
                self.captureEngine.startCapture()
                
                // ✅ Increase warmup time to 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    guard self.isCameraReady else {
                        print("⚠️ Camera session lost during warmup")
                        return
                    }
                    
                    print("📸 Requesting frame capture...")
                    self.captureEngine.captureSingleFrame()
                }
                
            case .failure(let error):
                print("❌ Camera setup failed: \(error.localizedDescription)")
                self.isCameraReady = false
                self.delegate?.monitoringService(self, didEncounterError: error)
            }
        }
    }
    
    func reloadSettings() {
        // Reload interval
        updateCaptureInterval()
        
        // Other settings will be read on-demand from UserDefaults
        print("⚙️ Settings reloaded")
    }
    
    private func cleanupAfterCapture() {
        guard isCameraReady else { return }
        
        print("🧹 Stopping and cleaning up camera...")
        
        // Stop immediately (synchronous)
        captureEngine.stopCapture()
        
        // Cleanup immediately (synchronous)
        captureEngine.cleanup()
        
        isCameraReady = false
        print("✅ Camera fully stopped and cleaned up\n")
    }
    
    func triggerManualCapture() {
        print("🎯 Manual capture triggered")
        performCapture()
    }
    
    // MARK: - CaptureEngineDelegate
    
    func captureEngine(_ engine: CaptureEngine, didCaptureFrame image: CIImage) {
        print("✅ Frame captured successfully!")
        
        // Convert to NSImage for display
        let context = CIContext()
        var nsImage: NSImage?
        if let cgImage = context.createCGImage(image, from: image.extent) {
            nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        }
        
        // Analyze on background thread at .default QoS - Vision's internal
        // worker threads run at default, so calling perform() from a
        // higher-QoS thread trips a priority-inversion hang-risk warning.
        DispatchQueue.global(qos: .default).async { [weak self] in
            guard let self = self else { return }
            
            let reading = self.visionAnalyzer.analyzePosture(image: image, imageWidth: image.extent.width)
            
            DispatchQueue.main.async {
                self.delegate?.monitoringService(self, didAnalyze: reading)
                FeedbackWindowManager.shared.updateLatestCapture(reading: reading, image: nsImage)
                
                // ✅ Cleanup after successful analysis
                self.cleanupAfterCapture()
            }
        }
    }

    func captureEngine(_ engine: CaptureEngine, didFailWithError error: CaptureError) {
        print("❌ Capture failed: \(error.localizedDescription)")
        delegate?.monitoringService(self, didEncounterError: error)
        
        // ✅ Cleanup on error too
        cleanupAfterCapture()
    }
}

