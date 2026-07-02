//
//  VisualFeedbackWindow.swift
//  PostureWellness
//
//

import SwiftUI
import AppKit

class VisualFeedbackWindowController: NSWindowController, NSWindowDelegate {
    
    convenience init(reading: PostureReading, image: NSImage?) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Posture Analysis"
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        
        // Create SwiftUI view
        let contentView = VisualFeedbackView(reading: reading, capturedImage: image)
        window.contentView = NSHostingView(rootView: contentView)
        
        self.init(window: window)
        
        // ✅ Set delegate to self
        window.delegate = self
    }
    
    // ✅ Implement NSWindowDelegate method
    func windowWillClose(_ notification: Notification) {
        // Return to accessory mode when window closes
        if SettingsWindowController.shared.window?.isVisible != true {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

// MARK: - SwiftUI View

struct VisualFeedbackView: View {
    let reading: PostureReading
    let capturedImage: NSImage?
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Main content
            ScrollView {
                VStack(spacing: 20) {
                    // Score card
                    scoreCard
                    
                    // Image preview (if available)
                    if let image = capturedImage {
                        imagePreview(image)
                    }
                    
                    // Issues list or status message
                    if reading.isValid {
                        if !reading.issues.isEmpty {
                            issuesSection
                        } else {
                            noIssuesView
                        }
                    } else {
                        // ✅ Show unknown state message
                        unknownStateView
                    }
                }
                .padding(20)
            }
            
            Divider()
            
            // Footer
            footerView
        }
        .frame(minWidth: 600, minHeight: 500)
    }
    
    // MARK: - Components
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Posture Analysis")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(reading.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(reading.status.emoji)
                .font(.system(size: 40))
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var scoreCard: some View {
        VStack(spacing: 12) {
            // Score circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: CGFloat(reading.overallScore) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(reading.overallScore)")
                        .font(.system(size: 36, weight: .bold))
                    Text("/ 100")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Status
            Text(reading.status.displayName)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(scoreColor)
            
            // Confidence
            HStack(spacing: 4) {
                Image(systemName: confidenceIcon)
                    .foregroundColor(confidenceColor)
                
                Text("Detection Confidence: \(reading.qualityLevel)")
                    .font(.caption)
                    .foregroundColor(confidenceColor)
                
                Text("(\(Int(reading.confidence * 100))%)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func imagePreview(_ image: NSImage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Captured Frame")
                .font(.headline)
            
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 300)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    /* private func imagePreview(_ image: NSImage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Captured Frame with Analysis")
                .font(.headline)
            
            GeometryReader { geometry in
                ZStack {
                    // Original image
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    
                    // Overlay canvas for drawing feedback
                    Canvas { context, size in
                        drawPostureFeedback(context: context, size: size, imageSize: image.size)
                    }
                }
                .frame(maxHeight: 300)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .frame(height: 300)
            
            // Legend
            HStack(spacing: 16) {
                legendItem(color: .green, text: "Good")
                legendItem(color: .yellow, text: "Minor Issue")
                legendItem(color: .orange, text: "Moderate Issue")
                legendItem(color: .red, text: "Significant Issue")
            }
            .font(.caption)
            .padding(.top, 4)
        }
    } */

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .foregroundColor(.secondary)
        }
    }

    private func drawPostureFeedback(context: GraphicsContext, size: CGSize, imageSize: CGSize) {
        guard let joints = reading.jointPositions else {
            // No joint data available
            return
        }
        
        // Helper to convert normalized Vision coordinates to canvas coordinates
        func toCanvasPoint(_ point: CGPoint) -> CGPoint {
            // Vision coordinates: (0,0) = bottom-left, (1,1) = top-right
            // Canvas coordinates: (0,0) = top-left
            return CGPoint(
                x: point.x * size.width,
                y: (1 - point.y) * size.height  // Flip Y axis
            )
        }
        
        // Draw skeleton connections
        
        // 1. Draw head/neck/shoulders skeleton
        /* if let neck = joints.neck {
            let neckPos = toCanvasPoint(neck)
            
            // Draw neck circle
            let neckIssue = reading.issues.first(where: { $0.type == .neck || $0.type == .neckSideTilt })
            let neckColor = neckIssue != nil ? issueColor(neckIssue!.severity) : Color.green
            
            var neckCircle = Path()
            neckCircle.addEllipse(in: CGRect(x: neckPos.x - 8, y: neckPos.y - 8, width: 16, height: 16))
            context.fill(neckCircle, with: .color(neckColor.opacity(0.3)))
            context.stroke(neckCircle, with: .color(neckColor), lineWidth: 2)
            
            // Draw line from neck to nose/ear if available
            if let nose = joints.nose {
                let nosePos = toCanvasPoint(nose)
                var path = Path()
                path.move(to: neckPos)
                path.addLine(to: nosePos)
                context.stroke(path, with: .color(neckColor), lineWidth: 2)
                
                // Draw nose circle
                var noseCircle = Path()
                noseCircle.addEllipse(in: CGRect(x: nosePos.x - 6, y: nosePos.y - 6, width: 12, height: 12))
                context.fill(noseCircle, with: .color(neckColor))
            }
            
            // Draw shoulders
            let shoulderIssue = reading.issues.first(where: { $0.type == .shoulderSymmetry || $0.type == .shoulderRounding })
            let shoulderColor = shoulderIssue != nil ? issueColor(shoulderIssue!.severity) : Color.green
            
            if let leftShoulder = joints.leftShoulder {
                let leftPos = toCanvasPoint(leftShoulder)
                
                // Line from neck to left shoulder
                var path = Path()
                path.move(to: neckPos)
                path.addLine(to: leftPos)
                context.stroke(path, with: .color(shoulderColor), lineWidth: 2)
                
                // Left shoulder circle
                var circle = Path()
                circle.addEllipse(in: CGRect(x: leftPos.x - 8, y: leftPos.y - 8, width: 16, height: 16))
                context.fill(circle, with: .color(shoulderColor.opacity(0.3)))
                context.stroke(circle, with: .color(shoulderColor), lineWidth: 2)
            }
            
            if let rightShoulder = joints.rightShoulder {
                let rightPos = toCanvasPoint(rightShoulder)
                
                // Line from neck to right shoulder
                var path = Path()
                path.move(to: neckPos)
                path.addLine(to: rightPos)
                context.stroke(path, with: .color(shoulderColor), lineWidth: 2)
                
                // Right shoulder circle
                var circle = Path()
                circle.addEllipse(in: CGRect(x: rightPos.x - 8, y: rightPos.y - 8, width: 16, height: 16))
                context.fill(circle, with: .color(shoulderColor.opacity(0.3)))
                context.stroke(circle, with: .color(shoulderColor), lineWidth: 2)
            }
            
            // Shoulder line (if both visible)
            if let leftShoulder = joints.leftShoulder, let rightShoulder = joints.rightShoulder {
                var shoulderLine = Path()
                shoulderLine.move(to: toCanvasPoint(leftShoulder))
                shoulderLine.addLine(to: toCanvasPoint(rightShoulder))
                context.stroke(shoulderLine, with: .color(shoulderColor), lineWidth: 3)
            }
            
            // Draw torso/spine if hips visible
            if let leftHip = joints.leftHip, let rightHip = joints.rightHip {
                let hipCenter = CGPoint(
                    x: (leftHip.x + rightHip.x) / 2,
                    y: (leftHip.y + rightHip.y) / 2
                )
                let hipPos = toCanvasPoint(hipCenter)
                
                let torsoIssue = reading.issues.first(where: { $0.type == .slouch })
                let torsoColor = torsoIssue != nil ? issueColor(torsoIssue!.severity) : Color.green
                
                // Spine line
                var spinePath = Path()
                spinePath.move(to: neckPos)
                spinePath.addLine(to: hipPos)
                context.stroke(spinePath, with: .color(torsoColor), lineWidth: 3)
                
                // Hip circles
                for hip in [leftHip, rightHip] {
                    let pos = toCanvasPoint(hip)
                    var circle = Path()
                    circle.addEllipse(in: CGRect(x: pos.x - 6, y: pos.y - 6, width: 12, height: 12))
                    context.fill(circle, with: .color(torsoColor.opacity(0.3)))
                    context.stroke(circle, with: .color(torsoColor), lineWidth: 2)
                }
            }
        }
        
        // Draw ears if visible
        for (ear, side) in [(joints.leftEar, "L"), (joints.rightEar, "R")] {
            if let ear = ear {
                let pos = toCanvasPoint(ear)
                var circle = Path()
                circle.addEllipse(in: CGRect(x: pos.x - 5, y: pos.y - 5, width: 10, height: 10))
                context.fill(circle, with: .color(.blue.opacity(0.5)))
            }
        } */
        
        // Add quality indicator badge
        //drawQualityBadge(context: context, size: size)
    }

    private func drawArrow(context: GraphicsContext, from: CGPoint, to: CGPoint, color: Color) {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        
        // Arrowhead
        let angle = atan2(to.y - from.y, to.x - from.x)
        let arrowSize: CGFloat = 10
        
        let arrowPoint1 = CGPoint(
            x: to.x - arrowSize * cos(angle - .pi/6),
            y: to.y - arrowSize * sin(angle - .pi/6)
        )
        let arrowPoint2 = CGPoint(
            x: to.x - arrowSize * cos(angle + .pi/6),
            y: to.y - arrowSize * sin(angle + .pi/6)
        )
        
        path.move(to: to)
        path.addLine(to: arrowPoint1)
        path.move(to: to)
        path.addLine(to: arrowPoint2)
        
        context.stroke(path, with: .color(color), lineWidth: 2)
    }

    private func drawQualityBadge(context: GraphicsContext, size: CGSize) {
        let badgePos = CGPoint(x: size.width - 60, y: 20)
        let badgeSize: CGFloat = 50
        
        // Background circle
        var circle = Path()
        circle.addEllipse(in: CGRect(x: badgePos.x, y: badgePos.y, width: badgeSize, height: badgeSize))
        context.fill(circle, with: .color(confidenceColor.opacity(0.8)))
        
        // Quality text
        let qualityText = Text("\(Int(reading.confidence * 100))%")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
        
        context.draw(qualityText, at: CGPoint(x: badgePos.x + badgeSize/2, y: badgePos.y + badgeSize/2))
    }

    private func issueColor(_ severity: Severity) -> Color {
        switch severity {
        case .minor:
            return .yellow
        case .moderate:
            return .orange
        case .significant:
            return .red
        }
    }
    
    private var issuesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Issues Detected (\(reading.issues.count))")
                .font(.headline)
            
            ForEach(reading.issues) { issue in
                issueCard(issue)
            }
        }
    }
    
    private func issueCard(_ issue: Issue) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: issue.type.icon)
                    .foregroundColor(severityColor(issue.severity))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(issue.type.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    // Text("\(issue.severity.displayName) - \(issue.formattedValue)")
                    Text("\(issue.severity.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(issue.guidance)
                .font(.callout)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(severityColor(issue.severity).opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(severityColor(issue.severity).opacity(0.3), lineWidth: 1)
        )
    }
    
    private var noIssuesView: some View {
        VStack(spacing: 12) {
            // ✅ Check if reading is actually valid
            if reading.isValid {
                // Valid reading with no issues - truly excellent!
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                
                Text("Excellent Posture!")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("No issues detected. Keep up the good work!")
                    .foregroundColor(.secondary)
            } else {
                // Invalid/unknown reading
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.gray)
                
                Text("Unable to Analyze")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Could not detect posture. Make sure you're visible in the camera with good lighting.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(reading.isValid ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var unknownStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Analysis Failed")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Unable to analyze posture due to low detection confidence.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Divider()
                .padding(.vertical)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Possible reasons:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                troubleshootingItem("💡", "Improve lighting conditions")
                troubleshootingItem("📐", "Ensure upper body is visible in frame")
                troubleshootingItem("👤", "Face the camera directly")
                troubleshootingItem("🧹", "Clean camera lens")
                troubleshootingItem("🪟", "Avoid backlighting (don't sit with window behind you)")
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    private func troubleshootingItem(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(icon)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var footerView: some View {
        HStack {
            Button("Dismiss for 15 min") {
                NotificationManager.shared.dismissNotifications()
                closeWindow()
            }
            
            Spacer()
            
            Button("Close") {
                closeWindow()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Helpers
    
    private var scoreColor: Color {
        switch reading.status {
        case .excellent:
            return .green
        case .good:
            return .blue
        case .fair:
            return .yellow
        case .poor:
            return .orange
        case .veryPoor:
            return .red
        case .unknown:
            return .gray
        }
    }
    
    private func severityColor(_ severity: Severity) -> Color {
        switch severity {
        case .minor:
            return .yellow
        case .moderate:
            return .orange
        case .significant:
            return .red
        }
    }
    
    private var confidenceIcon: String {
        if reading.confidence >= 0.7 {
            return "checkmark.circle.fill"
        } else if reading.confidence >= 0.4 {
            return "checkmark.circle"
        } else if reading.confidence >= 0.2 {
            return "exclamationmark.circle"
        } else {
            return "exclamationmark.triangle"
        }
    }

    private var confidenceColor: Color {
        if reading.confidence >= 0.7 {
            return .green
        } else if reading.confidence >= 0.4 {
            return .blue
        } else if reading.confidence >= 0.2 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func closeWindow() {
        if let window = NSApp.keyWindow {
            window.close()
        }
    }
}
