# CLAUDE.md

This file provides context for AI assistants (like Claude) working on this codebase.

---

## Project Overview

**Posture Wellness** is a privacy-first macOS menu bar application that monitors user posture using the built-in camera and Apple's Vision framework. All processing happens locally on-device with no cloud dependencies.

**Status:** ✅ MVP Complete - Ready for beta testing and refinement

---

## Core Architecture

### Technology Stack
- **Platform:** macOS 12.0+ (MACOSX_DEPLOYMENT_TARGET = 12.0; floor set by VNFaceObservation.pitch. Analytics charts need 13.0+, guarded with #available)
- **Language:** Swift 5.x
- **UI Framework:** SwiftUI + AppKit hybrid
- **Computer Vision:** Apple Vision framework (`VNDetectFaceRectanglesRequest` primary + `VNDetectHumanBodyPoseRequest` for shoulders)
- **Storage:** JSON (configuration), file-based (analytics)
- **App Type:** Menu bar agent (LSUIElement, no dock icon)

### Key Design Principles
1. **Privacy First:** All processing on-device, no telemetry, no cloud
2. **Unobtrusive:** Menu bar only, minimal interruption
3. **Configurable:** User can adjust all thresholds and behavior
4. **Graceful Degradation:** Works with partial body visibility

---

## Project Structure

```
PostureWellness/
├── App/
│   └── PostureWellnessApp.swift
│       - AppDelegate (app lifecycle)
│       - MonitoringService (capture orchestration)
│       - Main app entry point
│
├── Configuration/
│   ├── PostureConfig.swift (all threshold data structures)
│   ├── ConfigurationManager.swift (load/save/validate config)
│   └── default_config.json (bundled defaults)
│
├── Core/
│   ├── VisionAnalyzer.swift (Vision framework integration)
│   ├── PostureCalculator.swift (geometric angle calculations)
│   └── CaptureEngine.swift (camera capture management)
│
├── Models/
│   ├── PostureReading.swift (analysis results model)
│   └── Issue.swift (detected posture issues)
│
├── Services/
│   ├── NotificationManager.swift (macOS notification system)
│   └── AnalyticsStore.swift (local data persistence)
│
└── UI/
    ├── MenuBar/MenuBarController.swift (status bar menu)
    ├── VisualFeedback/VisualFeedbackWindow.swift (analysis display)
    ├── Settings/SettingsView.swift (configuration UI)
    └── Dashboard/DashboardView.swift (analytics charts)
```

---

## Critical Implementation Details

### 1. Camera Capture Flow (MOST IMPORTANT)

The camera capture system was carefully designed to avoid "session not running" errors:

```
Timer fires every N seconds
  ↓
performCapture() - checks isPaused flag
  ↓
Cleanup previous session (SYNCHRONOUS via captureQueue.sync)
  ↓
setupAndCapture() - fresh AVCaptureSession
  ↓
2-second warmup delay
  ↓
captureSingleFrame()
  ↓
Delegate: didCaptureFrame → analyze on background thread
  ↓
cleanupAfterCapture() - SYNCHRONOUS cleanup
```

**Key Points:**
- Cleanup is FULLY SYNCHRONOUS using `captureQueue.sync` (not async)
- Fresh session setup for each capture (no session reuse)
- 2-second warmup required before capture
- All cleanup happens AFTER analysis completes

**DO NOT:**
- Make cleanup async - causes race conditions
- Reuse camera session - leads to "session not running" errors
- Skip warmup delay - frames won't be ready

### 2. Detection Pipeline (Face-First Hybrid)

Face detection (`VNDetectFaceRectanglesRequest`) is the PRIMARY signal:
- Near-100% reliable on close-up webcam framing, unlike body pose
- Provides head roll (side tilt), pitch (forward/back nod), yaw directly
- Face confidence gates reading validity (floor: 0.15 in PostureEvaluator)

Body pose (`VNDetectHumanBodyPoseRequest`) is used opportunistically:
- Only for shoulder symmetry when shoulders are visible
- Its confidence is computed from core joints only (hips excluded - Vision
  emits phantom low-confidence hip guesses when hips are out of frame)

NOT reported (a frontal 2D camera cannot measure these sagittal-plane angles):
- Shoulder rounding
- Torso slouch (revisit with per-user baseline calibration - see Phase 2)

**DO NOT:**
- Return to body-pose-only detection (fails on head-and-shoulders framing)
- Compute forward neck tilt from 2D body-pose angles (measures lateral lean, not forward tilt)
- Include hip joints in confidence averages
- Reintroduce the multi-orientation retry loop (a mirrored/rotated guess can win by noise and scramble left/right + vertical axes)

### 3. Configuration System

**File location:** `~/Library/Application Support/PostureWellness/posture_config.json`

**Loading order:**
1. Try load user config
2. If missing, copy from bundled `default_config.json`
3. Validate all ranges (good < minor < poor)
4. Cache in `ConfigurationManager.shared`

**Version:** 1.0 (for future migrations)

**DO NOT:**
- Load config on every use (use cached singleton)
- Skip validation (prevents invalid thresholds)
- Modify default_config.json (user changes go to user config)

### 4. Window Management in Menu Bar Apps

Menu bar apps run with `NSApp.setActivationPolicy(.accessory)` which hides windows by default.

**Solution:**
```swift
// When showing window:
NSApp.setActivationPolicy(.regular)
window.makeKeyAndOrderFront(nil)
window.orderFrontRegardless()  // Force to front
NSApp.activate(ignoringOtherApps: true)

// On window close (via NSWindowDelegate):
func windowWillClose(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
}
```

### 5. Notification System

**Flow:**
```
Poor posture detected (score < 60)
  ↓
Increment consecutivePoorReadings
  ↓
Check notification mode threshold:
  - Strict: 1 reading
  - Active: 2 readings (default)
  - Gentle: 3 readings
  ↓
Check minimum interval (5 min since last)
  ↓
Send notification with guidance
```

**"I'm Aware" dismissal:** Suppresses notifications for 15 minutes

---

## Posture Analysis Metrics

### Detected Issues
1. **Neck Forward Tilt** - Head pitch from face detection (nod magnitude)
2. **Neck Side Tilt** - Head roll from face detection (body-pose both-ears fallback)
3. **Shoulder Symmetry** - Height difference between shoulders (body pose, scaled by in-frame shoulder width)
4. **Shoulder Rounding** - NOT REPORTED (sagittal-plane angle, unmeasurable from frontal 2D view)
5. **Torso Slouch** - NOT REPORTED (pending per-user baseline calibration, Phase 2)
6. **Screen Distance** - Manual configuration (auto-detect estimates from face size)
7. **Sitting Duration** - Time elapsed; resets on absence from frame or significant movement

### Calculation Methods

All in `PostureCalculator.swift`:
- Uses Vision framework normalized coordinates (0-1, Y-inverted)
- Calculates angles via dot product: `acos(v1·v2 / |v1||v2|)`
- Returns nil for missing data (graceful degradation)
- Handles partial visibility (not all joints required)

---

## Settings & User Preferences

Stored in `UserDefaults` with `@AppStorage`:

```swift
captureInterval: 60s (default)
notificationMode: "active" (silent/gentle/active/strict)
runOnBattery: true
reduceFrequencyOnBattery: true (doubles interval on battery)
sittingWarningMinutes: 60
dataRetentionDays: 30
dismissDuration: 15 (minutes)
autoDetectDistance: false
manualDistance: 60 (cm)
```

**Battery Behavior:**
- Monitors `ProcessInfo.processInfo.isOperatingOnACPower`
- Can disable monitoring on battery
- Can double capture interval on battery
- Updates automatically on power state change

---

## Data Storage

### Configuration
- **User config:** `~/Library/Application Support/PostureWellness/posture_config.json`
- **Format:** JSON with version field
- **Validation:** All thresholds validated on load

### Analytics
- **File:** `~/Library/Application Support/PostureWellness/analytics.json`
- **Format:** JSON array of PostureReading objects
- **Retention:** Configurable (7/30/90 days, or forever)
- **Cleanup:** Daily automatic cleanup + on settings change

### Images
- **Storage:** NEVER stored to disk
- **Lifetime:** In-memory during analysis only
- **Privacy:** No images persist after analysis

---

## Known Issues & Limitations

### 1. VFX Console Warnings (HARMLESS)
```
Error: patching invalid duplicated core entity handle for <VFXNode...
[ParticleQuadRenderer] couldn't remap entity...
```
- System-level macOS visual effects warnings
- Completely safe to ignore
- Not related to app functionality

### 2. Camera Light Stays On
- By design - camera session fully stops after capture
- Light may briefly stay on during 2-second warmup
- Trade-off: reliability vs. perfect privacy indicator

### 3. Multi-Capture Was Difficult
- Many iterations to get reliable multi-capture working
- Final solution: full teardown/rebuild each cycle
- DO NOT try to "optimize" by reusing sessions

### 4. Detection Accuracy Varies
- Depends heavily on lighting conditions
- Partial visibility is expected and handled
- Confidence 0.2-0.5 is normal for real-world use

---

## Testing Approach

### Manual Testing
1. **Use sample images:** Test with various postures/lighting from URLs
2. **Battery behavior:** Unplug Mac, verify interval changes
3. **Settings application:** Change values, verify they apply immediately
4. **Window management:** Ensure windows appear in foreground
5. **Multi-capture:** Let app run 5+ minutes, verify captures continue

### Key Test Scenarios
- Good posture → No notifications
- Poor posture (2x) → Notification appears
- "I'm Aware" → Suppresses for 15 min
- Change interval → Next capture uses new timing
- Unplug Mac → Interval doubles (if enabled)
- Pause monitoring → Captures stop

---

## Common Pitfalls for AI Assistants

### ❌ DON'T:
1. Make camera cleanup async (causes "session not running")
2. Raise confidence thresholds above 0.30
3. Require hip joints for detection
4. Skip `orderFrontRegardless()` when showing windows
5. Use localStorage/sessionStorage in artifacts (not supported)
6. Change activation policy without switching back
7. Modify the working camera capture flow "for optimization"

### ✅ DO:
1. Keep camera cleanup synchronous with `captureQueue.sync`
2. Handle partial body visibility gracefully
3. Return nil for uncalculable metrics (don't error)
4. Test multi-capture reliability after any camera changes
5. Respect the privacy-first design philosophy
6. Maintain backward compatibility with config versions

---

## Next Development Priorities

### Phase 2 Features (Not Implemented)
1. Apply settings without restart (partially done)
2. Exercise recommendations based on detected issues
3. Break reminders with guided stretches
4. Personalized baseline calibration
5. Multi-user profiles
6. Cloud sync (optional, encrypted)
7. Gamification (streaks, achievements)
8. Export analytics (CSV, PDF)
9. Apple Health integration

### Analytics & Crash Reporting (Post-MVP)
- TelemetryDeck for privacy-first analytics
- Sentry or Crashlytics for crash reporting
- All opt-in with clear disclosure

---

## Development Commands

```bash
# Clean build
Product → Clean Build Folder (Shift + Cmd + K)

# View user config
open ~/Library/Application\ Support/PostureWellness/

# Delete config (reset to defaults)
rm ~/Library/Application\ Support/PostureWellness/posture_config.json

# Reset camera permissions
tccutil reset Camera com.org.PostureWellness

# View analytics data
cat ~/Library/Containers/com.org.PostureWellness/Data/Library/Application\ Support/PostureWellness/analytics.json

# Filter console noise
# In Xcode console: -VFXNode -ParticleQuadRenderer -GraphScript
```

---

## Code Style & Conventions

- Use `print()` for debug logging (extensive throughout)
- Emoji prefixes for log readability: 📸 🔍 ✅ ❌ ⚠️
- Singletons use `.shared` pattern
- NotificationCenter for cross-component communication
- Delegates for typed callbacks (e.g., CaptureEngineDelegate)
- `@AppStorage` for user preferences
- SwiftUI for UI, AppKit for menu bar/window management

---

## Important Context for New Features

When adding features, consider:

1. **Privacy:** Does it require sending data externally?
2. **Battery:** Does it increase power consumption?
3. **Reliability:** Could it break the camera capture flow?
4. **Settings:** Should users be able to configure it?
5. **Analytics:** Is it worth tracking usage (post-MVP)?

---

## Questions to Ask When Modifying Code

- **Camera code:** Will this break multi-capture reliability?
- **Vision code:** Does this handle partial visibility?
- **Threshold code:** Have I validated the ranges?
- **Window code:** Does it force to foreground properly?
- **Settings code:** Does it apply immediately?
- **Battery code:** Is power state checked?

---

## Current App State (As of Last Session)

**Working:**
- ✅ Camera multi-capture (reliable after many iterations)
- ✅ Vision detection with lenient thresholds
- ✅ Notification system with all modes
- ✅ Settings panel with live updates
- ✅ Battery-aware monitoring
- ✅ Analytics dashboard with charts
- ✅ Data retention and cleanup
- ✅ Pause/resume functionality
- ✅ Window management (foreground display)

**Testing Phase:**
- 🧪 Threshold refinement (ongoing)
- 🧪 Real-world detection accuracy
- 🧪 Battery behavior validation

**Not Yet Implemented:**
- ❌ Analytics/crash reporting
- ❌ Phase 2 features (exercises, breaks, etc.)

---

## For Future AI Assistants

This project was built iteratively with careful attention to:
- Privacy and user trust
- Reliability (especially camera capture)
- Real-world conditions (not lab-perfect scenarios)
- User experience (unobtrusive, helpful)

When making changes, prioritize reliability over optimization. The camera capture flow especially has been battle-tested and should not be "improved" without extensive testing.

If you encounter "session not running" errors, check the camera cleanup synchronization first.

---

**Last Updated:** June 2026
**App Version:** 1.0-beta
**Status:** Beta testing ready
