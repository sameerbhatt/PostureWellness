# Posture Wellness - Manual Test Cases

**Version:** 1.0  
**Last Updated:** 20 June 2026
**Test Environment:** macOS 11.0+

---

## Table of Contents

1. [Setup & Installation](#setup--installation)
2. [Core Monitoring](#core-monitoring)
3. [Posture Detection](#posture-detection)
4. [Notifications](#notifications)
5. [Break Reminders](#break-reminders)
6. [Visual Feedback](#visual-feedback)
7. [Settings](#settings)
8. [Analytics Dashboard](#analytics-dashboard)
9. [Menu Bar Interactions](#menu-bar-interactions)
10. [Edge Cases & Error Handling](#edge-cases--error-handling)
11. [Performance & Resources](#performance--resources)

---

## Setup & Installation

### TC-001: First Launch - Camera Permission
**Objective:** Verify camera permission request on first launch

**Steps:**
1. Launch PostureWellness for the first time
2. Observe system permission dialog

**Expected Result:**
- ✅ macOS camera permission dialog appears
- ✅ Dialog shows app name "PostureWellness"
- ✅ Permission description is clear and explains usage

**Success Criteria:**
- Permission dialog appears within 5 seconds
- Text is readable and professional
- User can grant or deny permission

---

### TC-002: First Launch - Notification Permission
**Objective:** Verify notification permission request

**Steps:**
1. Grant camera permission (TC-001)
2. Observe notification permission dialog

**Expected Result:**
- ✅ macOS notification permission dialog appears
- ✅ Test notification sent: "Posture Wellness Active"

**Success Criteria:**
- Permission requested on first launch
- Test notification visible in Notification Center
- User can grant or deny permission

---

### TC-003: Menu Bar Icon Appears
**Objective:** Verify app runs as menu bar application

**Steps:**
1. Launch app with permissions granted
2. Check menu bar (top right of screen)
3. Check Dock

**Expected Result:**
- ✅ Icon appears in menu bar
- ✅ Icon shows question mark (⚪️) initially
- ✅ App does NOT appear in Dock

**Success Criteria:**
- Menu bar icon visible within 10 seconds
- Icon is appropriately sized (matches other menu bar apps)
- Dock remains clear (menu bar only app)

---

## Core Monitoring

### TC-004: First Posture Capture
**Objective:** Verify first automatic posture analysis

**Prerequisites:** Camera and notification permissions granted

**Steps:**
1. Launch app
2. Sit normally in front of camera
3. Wait 60 seconds (default interval)
4. Observe menu bar icon and console

**Expected Result:**
- ✅ Console shows: "📸 Initiating capture..."
- ✅ Camera activates briefly (LED may light up)
- ✅ Console shows: "✅ Frame captured successfully!"
- ✅ Console shows analysis results with score
- ✅ Menu bar icon updates (🟢🔵🟡🟠🔴 based on posture)
- ✅ Camera deactivates after capture

**Success Criteria:**
- First capture completes within 65 seconds of launch
- Analysis completes within 5 seconds of capture
- Menu bar icon reflects posture status accurately
- No errors in console

---

### TC-005: Subsequent Captures
**Objective:** Verify monitoring continues over time

**Steps:**
1. Complete TC-004
2. Wait for 2 more capture cycles (120 seconds)
3. Observe each capture

**Expected Result:**
- ✅ Captures occur at 60-second intervals
- ✅ Each capture shows same flow as TC-004
- ✅ No crashes or errors
- ✅ Menu bar icon updates each time

**Success Criteria:**
- All captures succeed
- Timing is consistent (±5 seconds)
- Camera starts and stops cleanly each time
- Memory usage remains stable

---

### TC-006: Camera Session Lifecycle
**Objective:** Verify camera properly starts/stops

**Steps:**
1. Monitor Activity Monitor during captures
2. Observe camera LED behavior
3. Check console logs

**Expected Result:**
- ✅ Camera starts only during capture
- ✅ Camera stops 2-3 seconds after capture
- ✅ Console shows: "✅ Camera stopped (until next capture)"
- ✅ Camera LED turns off between captures

**Success Criteria:**
- Camera not continuously running
- Clean start/stop cycle each capture
- No "session not running" errors

---

## Posture Detection

### TC-007: Good Posture Detection
**Objective:** Verify detection of excellent posture

**Steps:**
1. Sit upright with:
   - Head aligned over shoulders
   - Shoulders back and level
   - Back straight
   - Arms length from screen
2. Trigger manual capture (Menu → Analyze Now)
3. Check menu bar icon and "View Last Analysis"

**Expected Result:**
- ✅ Score: 85-100
- ✅ Status: Excellent (🟢) or Good (🔵)
- ✅ Issues: 0 or minimal
- ✅ Console shows good confidence (>0.7)

**Success Criteria:**
- High score reflects good posture
- Menu bar shows green/blue indicator
- Visual feedback confirms no major issues

---

### TC-008: Poor Neck Posture Detection
**Objective:** Verify forward head posture detection

**Steps:**
1. Sit with head/neck jutting forward
2. Trigger manual capture
3. View analysis results

**Expected Result:**
- ✅ Issue detected: "Neck Posture"
- ✅ Severity: Moderate or Significant
- ✅ Guidance provided: "Raise your monitor..." or similar
- ✅ Score reduced appropriately
- ✅ Measured angle shown (e.g., "25.0°")

**Success Criteria:**
- Neck issue specifically identified
- Actionable guidance provided
- Score reflects poor posture (< 75)

---

### TC-009: Slouching Detection
**Objective:** Verify slouch/hunching detection

**Steps:**
1. Sit with rounded back, hunched forward
2. Trigger manual capture
3. View analysis results

**Expected Result:**
- ✅ Issue detected: "Back Posture" or "Torso"
- ✅ Severity appropriately assigned
- ✅ Guidance mentions sitting upright, back support
- ✅ Score reduced

**Success Criteria:**
- Torso/slouch issue identified
- Multiple issues may appear (neck + shoulders + torso)
- Guidance is helpful and specific

---

### TC-010: Shoulder Asymmetry Detection
**Objective:** Verify uneven shoulder detection

**Steps:**
1. Sit leaning to one side (uneven shoulders)
2. Trigger manual capture
3. View analysis results

**Expected Result:**
- ✅ Issue detected: "Shoulder Alignment"
- ✅ Difference shown in cm
- ✅ Guidance suggests checking lean/chair level

**Success Criteria:**
- Shoulder issue identified when visually leaning
- Measurement provided

---

### TC-011: Low Confidence Handling
**Objective:** Verify behavior when person not detected

**Steps:**
1. Move away from camera (out of frame)
2. Wait for automatic capture
3. Check menu bar and console

**Expected Result:**
- ✅ Console shows: "No person detected in frame"
- ✅ Menu bar icon shows ⚪️ (unknown/gray)
- ✅ Status: Unknown
- ✅ Score: 0
- ✅ No false posture issues reported

**Success Criteria:**
- App doesn't crash
- Unknown state clearly indicated
- No notification sent for unknown readings

---

### TC-012: Partial Visibility Detection
**Objective:** Verify detection with only upper body visible

**Steps:**
1. Sit so only head, neck, shoulders visible (torso/hips cut off)
2. Trigger manual capture
3. View results

**Expected Result:**
- ✅ Detection succeeds with head/neck/shoulders
- ✅ Torso issues may not be detected (acceptable)
- ✅ Confidence still reasonable (>0.4)
- ✅ Analysis provides partial results

**Success Criteria:**
- Detection works without full body
- Confidence threshold met (>0.4)
- Available metrics analyzed correctly

---

## Notifications

### TC-013: First Poor Posture Notification (Active Mode)
**Objective:** Verify notification triggers on poor posture

**Prerequisites:** Notification mode set to "Active" (default)

**Steps:**
1. Ensure good posture initially
2. Adopt poor posture (slouch + forward head)
3. Wait for 2 consecutive poor readings (~120 seconds)
4. Observe notification

**Expected Result:**
- ✅ After 2nd poor reading, notification appears
- ✅ Title: "Posture Issue Detected"
- ✅ Body: Describes primary issue with guidance
- ✅ Actions: "I'm Aware" and "View Details"
- ✅ Sound plays (if not in Do Not Disturb)

**Success Criteria:**
- Notification appears after exactly 2 poor readings
- Content is helpful and specific
- Actions are clickable

---

### TC-014: "I'm Aware" Dismissal
**Objective:** Verify notification dismissal

**Steps:**
1. Trigger posture notification (TC-013)
2. Click "I'm Aware" action
3. Continue with poor posture
4. Wait 15 minutes
5. Observe notification behavior

**Expected Result:**
- ✅ Notification dismissed
- ✅ Console shows: "🔕 Notifications dismissed for 15 minutes"
- ✅ No new notifications for 15 minutes
- ✅ Monitoring continues (menu bar updates)
- ✅ After 15 minutes, notifications resume

**Success Criteria:**
- 15-minute suppression works
- Monitoring not paused
- Notifications resume automatically

---

### TC-015: "View Details" Action
**Objective:** Verify visual feedback opens from notification

**Steps:**
1. Trigger posture notification
2. Click "View Details" action
3. Observe window

**Expected Result:**
- ✅ Visual Feedback window opens
- ✅ Shows captured image
- ✅ Shows score and issues
- ✅ App activates to foreground

**Success Criteria:**
- Window appears within 2 seconds
- Content matches current posture reading
- Window is interactive

---

### TC-016: Notification Modes
**Objective:** Verify different notification sensitivity levels

**Test Cases:**

#### TC-016a: Silent Mode
**Steps:**
1. Settings → Notifications → Silent
2. Adopt poor posture for 5 captures
3. Observe behavior

**Expected:**
- ✅ Menu bar icon updates (still monitoring)
- ✅ NO notifications sent
- ✅ Analytics still recorded

#### TC-016b: Gentle Mode
**Steps:**
1. Settings → Notifications → Gentle
2. Adopt poor posture
3. Count captures until notification

**Expected:**
- ✅ Notification after 3 consecutive poor readings

#### TC-016c: Strict Mode
**Steps:**
1. Settings → Notifications → Strict
2. Adopt poor posture
3. Observe first capture

**Expected:**
- ✅ Notification after 1st poor reading

**Success Criteria:**
- Each mode triggers at documented threshold
- Silent mode never sends notifications

---

### TC-017: Minimum Notification Interval
**Objective:** Verify notifications don't spam

**Steps:**
1. Adopt poor posture continuously
2. Do NOT click "I'm Aware"
3. Observe notification timing

**Expected Result:**
- ✅ First notification after threshold met
- ✅ Second notification at least 5 minutes later
- ✅ Console shows: "🔕 Skipping notification (too soon...)"

**Success Criteria:**
- Minimum 5-minute gap between notifications
- Not spamming user with alerts

---

## Break Reminders

### TC-018: Scheduled Break Reminder
**Objective:** Verify break reminder triggers at interval

**Prerequisites:** Break reminders enabled, interval set to 60 minutes

**Steps:**
1. Launch app
2. Wait 60 minutes
3. Observe notification and window

**Expected Result:**
- ✅ At 60 minutes: notification "Time for a Break! 🧘"
- ✅ Break window opens automatically
- ✅ Window shows 5:00 countdown timer
- ✅ Exercises listed
- ✅ Console shows: "⏸️ Monitoring paused during break"

**Success Criteria:**
- Timing accurate (±30 seconds)
- Window appears automatically
- Monitoring pauses during break
- Timer counts down correctly

---

### TC-019: Manual Break Trigger
**Objective:** Verify "Take a Break Now" menu item

**Steps:**
1. Click menu bar icon
2. Click "Take a Break Now"
3. Observe window and menu

**Expected Result:**
- ✅ Break window opens immediately
- ✅ Timer starts at 5:00
- ✅ Monitoring pauses
- ✅ Menu item changes to "End Break"

**Success Criteria:**
- Immediate response (< 1 second)
- Menu updates correctly
- Monitoring paused

---

### TC-020: Complete Break
**Objective:** Verify break completion flow

**Steps:**
1. Trigger break (TC-019)
2. Click "I'm Back" button
3. Observe behavior

**Expected Result:**
- ✅ Break window closes
- ✅ Console shows: "✅ Break ended"
- ✅ Console shows: "▶️ Monitoring resumed"
- ✅ Menu item reverts to "Take a Break Now"
- ✅ Next capture proceeds normally

**Success Criteria:**
- Clean break end
- Monitoring resumes
- Menu updates correctly

---

### TC-021: Skip Break
**Objective:** Verify skip break functionality

**Steps:**
1. Trigger break
2. Click "Skip Break" button
3. Observe behavior

**Expected Result:**
- ✅ Break window closes immediately
- ✅ Console shows: "⏭️ Break skipped"
- ✅ Monitoring resumes
- ✅ Menu item updates

**Success Criteria:**
- Same as TC-020 (skip = immediate end)

---

### TC-022: Break Timer Expiry
**Objective:** Verify auto-end after 5 minutes

**Steps:**
1. Trigger break
2. Wait 5 minutes without clicking anything
3. Observe behavior

**Expected Result:**
- ✅ Timer counts down: 5:00 → 4:59 → ... → 0:01 → 0:00
- ✅ At 0:00, break automatically ends
- ✅ Window closes
- ✅ Monitoring resumes

**Success Criteria:**
- Timer accurate (±2 seconds)
- Auto-end works correctly

---

### TC-023: Close Break Window
**Objective:** Verify closing window ends break

**Steps:**
1. Trigger break
2. Click window's close button (X)
3. Observe behavior

**Expected Result:**
- ✅ Window closes
- ✅ Break is skipped (not completed)
- ✅ Monitoring resumes
- ✅ **NO CRASH**

**Success Criteria:**
- No EXC_BAD_ACCESS or crash
- Clean window close handling

---

### TC-024: Break Snooze
**Objective:** Verify snooze from notification

**Steps:**
1. Wait for scheduled break notification
2. Click "Snooze 10 min" action
3. Wait 10 minutes
4. Observe behavior

**Expected Result:**
- ✅ Notification dismissed
- ✅ Console shows: "⏰ Break snoozed for 10 minutes"
- ✅ No break window opens yet
- ✅ After 10 minutes, break notification reappears
- ✅ Then normal schedule resumes

**Success Criteria:**
- 10-minute delay works
- Break still happens, just delayed

---

### TC-025: End Break from Menu
**Objective:** Verify ending break via menu bar

**Steps:**
1. Trigger break (manual or automatic)
2. Click menu bar icon
3. Observe "End Break" menu item
4. Click "End Break"

**Expected Result:**
- ✅ Break window closes
- ✅ Break ends
- ✅ Monitoring resumes
- ✅ Menu item changes back

**Success Criteria:**
- Menu action works same as window button
- All state transitions correct

---

## Visual Feedback

### TC-026: View Last Analysis - Good Posture
**Objective:** Verify visual feedback for good posture

**Steps:**
1. Adopt good posture
2. Wait for capture or trigger manual
3. Menu → "View Last Analysis..."

**Expected Result:**
- ✅ Window opens showing:
  - Score: 85-100
  - Status: Excellent 🟢 or Good 🔵
  - Captured image (if available)
  - Green checkmark
  - "Excellent Posture!" message
  - "No issues detected"
- ✅ Clean, professional UI

**Success Criteria:**
- Window opens within 2 seconds
- All data accurate
- Image shows (if camera captured)
- Positive feedback clear

---

### TC-027: View Last Analysis - Poor Posture
**Objective:** Verify visual feedback for poor posture

**Steps:**
1. Adopt poor posture (multiple issues)
2. Wait for capture
3. Menu → "View Last Analysis..."

**Expected Result:**
- ✅ Window shows:
  - Score: < 75
  - Status: Fair/Poor/Very Poor
  - Captured image
  - "Issues Detected (X)" section
  - Each issue listed with:
    - Icon
    - Issue type
    - Severity
    - Measured value
    - Specific guidance
- ✅ Issues color-coded by severity

**Success Criteria:**
- All issues from reading shown
- Guidance is specific and helpful
- Visual hierarchy clear

---

### TC-028: View Last Analysis - Unknown Status
**Objective:** Verify visual feedback for failed detection

**Steps:**
1. Move out of camera frame
2. Wait for capture (should fail)
3. Menu → "View Last Analysis..."

**Expected Result:**
- ✅ Window shows:
  - Score: 0
  - Status: Unknown ⚪️
  - Warning icon (⚠️ or ❓)
  - "Unable to Analyze Posture" message
  - Troubleshooting tips:
    - Improve lighting
    - Ensure upper body visible
    - Face camera directly
    - Clean camera lens
- ✅ **NOT** showing "Excellent Posture!"

**Success Criteria:**
- Unknown state clearly differentiated
- Helpful troubleshooting provided
- No false positive messages

---

### TC-029: Dismiss for 15 Minutes from Visual Feedback
**Objective:** Verify dismiss action in visual feedback window

**Steps:**
1. Open visual feedback (any status)
2. Click "Dismiss for 15 min" button
3. Adopt poor posture
4. Wait 15+ minutes

**Expected Result:**
- ✅ Window closes
- ✅ Console shows: "🔕 Notifications dismissed for 15 minutes"
- ✅ No notifications for 15 minutes
- ✅ After 15 minutes, notifications resume

**Success Criteria:**
- Same behavior as "I'm Aware" from notification
- Window closes smoothly

---

## Settings

### TC-030: Open Settings
**Objective:** Verify settings window opens

**Steps:**
1. Menu → "Settings..." (or Cmd+,)
2. Observe window

**Expected Result:**
- ✅ Settings window opens
- ✅ Window size: ~500x600
- ✅ Sections visible:
  - Monitoring
  - Notifications
  - Advanced
  - About
- ✅ All controls accessible

**Success Criteria:**
- Window opens within 1 second
- Layout is clean and organized
- No overlapping text or controls

---

### TC-031: Change Capture Interval
**Objective:** Verify capture interval setting works

**Steps:**
1. Open Settings
2. Monitoring → Capture Interval slider
3. Change from 60s to 120s
4. Close settings
5. Observe capture timing

**Expected Result:**
- ✅ Slider moves smoothly
- ✅ Value updates (shows "120s")
- ✅ Console shows: "💾 Settings saved"
- ✅ Next captures occur at 120-second intervals

**Success Criteria:**
- Setting persists after app restart
- Captures honor new interval
- No errors

---

### TC-032: Toggle Break Reminders
**Objective:** Verify break reminder enable/disable

**Steps:**
1. Settings → Enable break reminders: OFF
2. Close settings
3. Wait 60 minutes
4. Observe behavior

**Expected Result:**
- ✅ Console shows: "⏰ Break reminders disabled in config"
- ✅ No break notifications at 60 minutes
- ✅ "Take a Break Now" menu item still works (manual)

**Success Criteria:**
- Scheduled breaks disabled
- Manual breaks still available
- No errors

---

### TC-033: Change Notification Mode
**Objective:** Verify notification mode changes apply

**Steps:**
1. Settings → Notifications → Alert mode: Strict
2. Close settings
3. Adopt poor posture
4. Observe notification timing

**Expected Result:**
- ✅ Notification after 1st poor reading (Strict mode)
- ✅ Console confirms mode change

**Success Criteria:**
- Mode applies immediately
- Behavior matches selected mode

---

### TC-034: Edit Advanced Configuration
**Objective:** Verify config file opens

**Steps:**
1. Settings → Advanced → "Edit Advanced Configuration..."
2. Observe behavior

**Expected Result:**
- ✅ JSON file opens in default text editor
- ✅ File path: `~/Library/Application Support/PostureWellness/posture_config.json`
- ✅ Valid JSON structure
- ✅ All config values present

**Success Criteria:**
- File opens successfully
- User can edit if needed
- App handles config changes on restart

---

### TC-035: Reset All Settings
**Objective:** Verify reset to defaults

**Steps:**
1. Change multiple settings (interval, notification mode, etc.)
2. Settings → Advanced → "Reset All Settings to Defaults"
3. Confirm
4. Check all settings

**Expected Result:**
- ✅ All settings revert to defaults:
  - Capture interval: 60s
  - Notification mode: Active
  - Break reminders: Enabled
  - Etc.
- ✅ Console shows: "✅ Settings reset to defaults"

**Success Criteria:**
- All settings restored
- Config file reset
- No errors

---

## Analytics Dashboard

### TC-036: Open Dashboard
**Objective:** Verify dashboard window opens

**Steps:**
1. Menu → "Open Dashboard..."
2. Observe window

**Expected Result:**
- ✅ Dashboard window opens
- ✅ Window size: ~800x600
- ✅ Tabs visible: Today, This Week, History
- ✅ "Today" tab selected by default

**Success Criteria:**
- Window opens within 2 seconds
- Layout renders correctly
- No blank/missing sections

---

### TC-037: Today Tab - With Data
**Objective:** Verify today's analytics display

**Prerequisites:** At least 5 captures performed today

**Steps:**
1. Open Dashboard
2. View "Today" tab
3. Observe content

**Expected Result:**
- ✅ Stats cards show:
  - Average Score (calculated from today's readings)
  - Sessions count
  - Total issues count
- ✅ Score trend chart shows today's captures over time
- ✅ Common issues breakdown (if any issues)
- ✅ All data accurate

**Success Criteria:**
- Numbers match actual captures
- Chart renders (macOS 13+) or shows fallback message
- No "0" or "NaN" values unless truly empty

---

### TC-038: Today Tab - No Data
**Objective:** Verify empty state

**Prerequisites:** No captures yet today (fresh app or new day)

**Steps:**
1. Open Dashboard
2. View "Today" tab

**Expected Result:**
- ✅ Empty state message: "No data for today yet"
- ✅ Placeholder icon
- ✅ No errors or crashes

**Success Criteria:**
- Graceful empty state
- Clear messaging

---

### TC-039: This Week Tab
**Objective:** Verify weekly analytics

**Prerequisites:** Multiple days of usage

**Steps:**
1. Open Dashboard
2. Click "This Week" tab

**Expected Result:**
- ✅ Week stats cards show:
  - Week average score
  - Total sessions this week
  - Best day score
- ✅ 7-day trend bar chart (if macOS 13+)
- ✅ Days with no data show as 0 or empty bars

**Success Criteria:**
- Data spans correct week (Sunday-Saturday or Monday-Sunday)
- Calculations accurate
- Chart readable

---

### TC-040: History Tab
**Objective:** Verify all-time statistics

**Steps:**
1. Open Dashboard
2. Click "History" tab

**Expected Result:**
- ✅ All-time stats:
  - Total sessions
  - Average score
  - Status distribution (Excellent: X, Good: Y, etc.)
- ✅ Numbers reflect all stored readings

**Success Criteria:**
- Counts match actual data
- Distribution adds up correctly

---

### TC-041: Refresh Dashboard
**Objective:** Verify refresh button updates data

**Steps:**
1. Open Dashboard
2. Note current stats
3. Trigger new capture (Menu → Analyze Now)
4. Return to Dashboard
5. Click "Refresh" button

**Expected Result:**
- ✅ Stats update to include new reading
- ✅ Charts refresh
- ✅ Session count increments

**Success Criteria:**
- Data refreshes without closing window
- New capture included

---

## Menu Bar Interactions

### TC-042: Menu Structure
**Objective:** Verify complete menu structure

**Steps:**
1. Click menu bar icon
2. Observe menu items

**Expected Result:**
- ✅ Menu items in order:
  - Header: "Posture Wellness"
  - Status: "Status: [Current Status]"
  - ---
  - Pause/Resume Monitoring
  - I'm Aware (Dismiss for 15 min)
  - Analyze Now
  - Take a Break Now / End Break
  - View Last Analysis...
  - ---
  - Open Dashboard...
  - Settings...
  - ---
  - Quit Posture Wellness
- ✅ Keyboard shortcuts shown (where applicable)

**Success Criteria:**
- All items present
- Separators in correct positions
- Text is clear

---

### TC-043: Pause/Resume Monitoring
**Objective:** Verify monitoring pause toggle

**Steps:**
1. Menu → "Pause Monitoring"
2. Wait for scheduled capture time
3. Menu → "Resume Monitoring"
4. Wait for next capture

**Expected Result:**
- ✅ After pause: Menu item changes to "Resume Monitoring"
- ✅ Console shows: "⏸️ Monitoring paused"
- ✅ During pause: "⏸️ Capture skipped (monitoring paused)"
- ✅ After resume: Menu item changes back to "Pause Monitoring"
- ✅ Console shows: "▶️ Monitoring resumed"
- ✅ Captures resume normally

**Success Criteria:**
- Toggle works reliably
- State persists until toggled
- Menu item text updates correctly

---

### TC-044: Analyze Now (Manual Capture)
**Objective:** Verify manual capture trigger

**Steps:**
1. Note current menu bar icon state
2. Menu → "Analyze Now" (or Cmd+A)
3. Observe immediate behavior

**Expected Result:**
- ✅ Capture initiates immediately (within 1 second)
- ✅ Console shows: "🎯 Manual capture triggered"
- ✅ Camera activates
- ✅ Analysis completes
- ✅ Menu bar icon updates

**Success Criteria:**
- Immediate response to menu click
- Does not wait for scheduled interval
- Results appear within 5 seconds

---

### TC-045: Status Display in Menu
**Objective:** Verify status line updates

**Steps:**
1. Adopt excellent posture
2. Trigger capture
3. Open menu
4. Note status
5. Adopt poor posture
6. Trigger capture
7. Open menu again

**Expected Result:**
- ✅ After good posture: "Status: Excellent 🟢" or "Status: Good 🔵"
- ✅ After poor posture: "Status: Poor 🟠" or "Status: Fair 🟡"
- ✅ Status emoji matches menu bar icon

**Success Criteria:**
- Status text updates correctly
- Emoji reflects current state
- Consistent with menu bar icon

---

### TC-046: Quit Application
**Objective:** Verify clean shutdown

**Steps:**
1. Menu → "Quit Posture Wellness" (or Cmd+Q)
2. Observe shutdown

**Expected Result:**
- ✅ Console shows: "👋 Shutting down..."
- ✅ App quits completely within 2 seconds
- ✅ Menu bar icon disappears
- ✅ No crash or hang
- ✅ No orphaned processes in Activity Monitor

**Success Criteria:**
- Clean shutdown
- All resources released
- Camera deactivated
- No background processes remain

---

## Edge Cases & Error Handling

### TC-047: Camera Unavailable
**Objective:** Verify behavior when camera is in use

**Steps:**
1. Open another app that uses camera (Photo Booth, Zoom, etc.)
2. Keep that app using camera
3. Let PostureWellness try to capture
4. Observe behavior

**Expected Result:**
- ✅ Console shows error: "❌ Camera setup failed" or "Camera is not available"
- ✅ Menu bar icon shows ⚪️ (unknown)
- ✅ App doesn't crash
- ✅ Retry on next interval

**Success Criteria:**
- Graceful error handling
- No crash
- Recovery when camera becomes available

---

### TC-048: Camera Permission Denied
**Objective:** Verify behavior without camera permission

**Steps:**
1. Deny camera permission (System Settings → Privacy & Security → Camera → PostureWellness: OFF)
2. Launch app
3. Observe behavior

**Expected Result:**
- ✅ Error message or notification
- ✅ Console shows permission denied error
- ✅ App continues running (doesn't crash)
- ✅ Menu bar icon shows error state

**Success Criteria:**
- Clear error communication
- No crash
- User can grant permission and restart

---

### TC-049: Low Memory Conditions
**Objective:** Verify stability under memory pressure

**Steps:**
1. Open many memory-intensive apps
2. Monitor PostureWellness in Activity Monitor
3. Observe multiple capture cycles

**Expected Result:**
- ✅ Memory usage stays < 200MB
- ✅ No memory leaks (stable over time)
- ✅ Continues functioning
- ✅ No crashes

**Success Criteria:**
- Memory footprint remains reasonable
- No degradation over time
- Captures still succeed

---

### TC-050: Long-Running Session
**Objective:** Verify stability over extended use

**Steps:**
1. Launch app
2. Leave running for 8+ hours
3. Periodically check functionality

**Expected Result:**
- ✅ Continues capturing at intervals
- ✅ Memory usage stable
- ✅ No crashes or hangs
- ✅ All features still work
- ✅ Data continues saving to analytics

**Success Criteria:**
- App runs indefinitely without issues
- No memory leaks
- Performance doesn't degrade

---

### TC-051: Rapid Menu Interactions
**Objective:** Verify UI responsiveness under stress

**Steps:**
1. Rapidly open/close menu bar menu (10+ times quickly)
2. Rapidly toggle Pause/Resume
3. Rapidly open/close Settings
4. Observe behavior

**Expected Result:**
- ✅ No crashes
- ✅ Menu responds correctly
- ✅ No UI glitches
- ✅ No state corruption

**Success Criteria:**
- Stable under rapid clicks
- No race conditions
- UI remains responsive

---

### TC-052: System Sleep
**Objective:** Verify behavior across sleep cycles
**Steps:**
1. Launch app
2. Put Mac to sleep (close laptop or Apple Menu → Sleep)
3. Wait 5+ minutes
4. Wake Mac
5. Observe app behavior

**Expected Result:**
- ✅ App still running after wake
- ✅ Next capture proceeds normally
- ✅ Timers recalculated correctly
- ✅ No errors

**Success Criteria:**
- Survives sleep/wake cycles
- Timers adjust appropriately
- No stuck states

---

### TC-053: Config File Corruption
**Objective:** Verify recovery from bad config

**Steps:**
1. Quit app
2. Edit config file with invalid JSON (remove a bracket, etc.)
3. Launch app
4. Observe behavior

**Expected Result:**
- ✅ App detects invalid config
- ✅ Falls back to default config
- ✅ Console shows error message
- ✅ App continues to function
- ✅ Valid config regenerated

**Success Criteria:**
- Doesn't crash on bad config
- Automatic recovery
- User notified of issue

---


### TC-054: Disk Space Full
**Objective:** Verify behavior when storage full
**Prerequisites:** Simulate low disk space

**Steps:**
1. Fill disk to < 1GB free
2. Use app normally
3. Observe analytics saving

**Expected Result:**
- ✅ App continues monitoring
- ✅ May fail to save analytics (gracefully)
- ✅ No crash
- ✅ Error logged to console

**Success Criteria:**
- Core monitoring unaffected
- Graceful degradation
- Clear error messages

---

## Performance & Resources

### TC-055: CPU Usage - Idle
**Objective:** Measure CPU usage between captures

**Steps:**
1. Launch app
2. Wait for first capture to complete
3. Monitor CPU in Activity Monitor for 30 seconds
4. Record average CPU %

**Expected Result:**
- ✅ CPU usage: < 1% when idle
- ✅ Minimal background processing

**Success Criteria:**
- Negligible CPU usage between captures
- No spinning or high CPU

---

### TC-056: CPU Usage - During Capture
**Objective:** Measure CPU usage during analysis

**Steps:**
1. Monitor Activity Monitor during capture
2. Observe CPU spike during Vision analysis
3. Observe return to idle

Expected Result:
- ✅ CPU spike to 10-30% during capture/analysis
- ✅ Duration: < 5 seconds
- ✅ Returns to < 1% after analysis

**Success Criteria:**
- Brief, acceptable spike
- Quick return to idle
- No sustained high CPU

---

### TC-057: Memory Usage
**Objective:** Measure and verify memory footprint

**Steps:**
1. Launch app
2. Run for 1 hour with normal usage
3. Monitor memory in Activity Monitor

**Expected Result:**
- ✅ Initial memory: 50-100MB
- ✅ After 1 hour: < 200MB
- ✅ No continuous growth (no leaks)

**Success Criteria:**
- Memory usage stays within target (< 200MB)
- No memory leaks over time

---

### TC-058: Battery Impact
**Objective:** Verify battery impact on laptops

**Steps:**
1. On MacBook with battery
2. Use app for 2 hours
3. Compare battery drain with app ON vs OFF

**Expected Result:**
- ✅ Additional battery drain: < 5% per hour
- ✅ Negligible impact between captures

**Success Criteria:**
- Minimal battery impact
- Within expected range for camera usage

---

### TC-059: Network Usage
**Objective:** Verify no network activity

**Steps:**
1. Monitor Network activity in Activity Monitor
2. Use app normally for 30 minutes
3. Observe network statistics

**Expected Result:**
- ✅ Network sent: 0 bytes
- ✅ Network received: 0 bytes
- ✅ No external connections

**Success Criteria:**
- Zero network usage
- Confirms privacy-first design

---

### TC-060: Camera Light Behavior
**Objective:** Verify camera LED is off between captures

**Steps:**
1. Observe camera LED during normal operation
2. Note when it turns on/off

**Expected Result:**
- ✅ LED on only during capture (~2 seconds)
- ✅ LED off between captures
- ✅ LED behavior consistent

**Success Criteria:**
- Camera not continuously active
- Clear visual indication of camera state

---

## Regression Test Suite (Quick Smoke Test)
**Time Estimate:** 15 minutes

Run these critical tests before each release:
1. ✅ TC-001: Camera permission on first launch
2. ✅ TC-004: First posture capture
3. ✅ TC-005: Subsequent captures (2 cycles)
4. ✅ TC-007: Good posture detection
5. ✅ TC-008: Poor posture detection
6. ✅ TC-013: Notification triggers
7. ✅ TC-019: Manual break
8. ✅ TC-030: Settings open
9. ✅ TC-036: Dashboard open
10. ✅ TC-043: Pause/Resume monitoring
11. ✅ TC-046: Quit application

**All must pass for release approval.**

---

## Test Environment Setup
**Hardware Requirements:**
- Mac with built-in camera or external webcam
- macOS 11.0 (Big Sur) or later
- Recommended: 8GB RAM, 2GB free disk space

**Software Requirements:**
- Xcode (for console viewing during testing)
- Activity Monitor (for performance tests)
- Console app (for log viewing)

**Before Testing:**
- Delete app data: ~/Library/Application Support/PostureWellness/
- Reset permissions: tccutil reset Camera com.yourname.PostureWellness
- Ensure good lighting and clear camera view
- Close other camera-using apps

---

## Bug Reporting Template
When reporting bugs, include:

**Test Case:** TC-XXX
**Expected:** [What should happen]
**Actual:** [What actually happened]
**Steps to Reproduce:**
1. 
2. 
3. 

**Environment:**
- macOS version: 
- App version: 
- Hardware: 

**Console Logs:**
[Paste relevant console output]

**Screenshots/Screen Recording:**
[Attach if applicable]

**Severity:**
[ ] Critical (crash, data loss)
[ ] Major (feature broken)
[ ] Minor (cosmetic, workaround exists)

---

## Test Sign-Off
**Tester Name:**
**Date:**
**Build Version:**
**Results Summary:**

**Total Tests Run:** - / 60
**Passed:**
**Failed:**
**Blocked:**

**Release Recommendation:**
[ ] Approve for Release
[ ] Approve with Known Issues (list below)
[ ] Do Not Approve (major issues found)

**Notes:**
