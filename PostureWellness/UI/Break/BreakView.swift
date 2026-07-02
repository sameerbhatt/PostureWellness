//
//  BreakView.swift
//  PostureWellness
//
//  Created by Sameer Bhatt on 02/02/26.
//

import SwiftUI

struct BreakView: View {
    
    @State private var remainingTime: TimeInterval = 300
    @State private var timer: Timer?
    
    let onEndBreak: () -> Void
    let onSkipBreak: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "figure.stand")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
            
            // Title
            Text("Time for a Break!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Timer
            Text(timeString)
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundColor(.secondary)
            
            // Message
            Text("Stand up, stretch, and rest your eyes")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Divider()
                .padding(.vertical)
            
            // Exercises
            VStack(alignment: .leading, spacing: 16) {
                Text("Recommended Exercises:")
                    .font(.headline)
                
                exerciseRow("🧘", "Neck rolls", "Slowly roll your head in circles")
                exerciseRow("💪", "Shoulder shrugs", "Lift shoulders up and down")
                exerciseRow("🙆", "Arm stretches", "Reach arms overhead and stretch")
                exerciseRow("👀", "Eye rest", "Look at distant objects for 20 seconds")
                exerciseRow("🚶", "Walk around", "Take a short walk")
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            
            // Actions
            HStack(spacing: 16) {
                Button("Skip Break") {
                    stopTimer()
                    onSkipBreak()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("I'm Back") {
                    stopTimer()
                    onEndBreak()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 32)
        .frame(width: 500, height: 700)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // MARK: - Components
    
    private func exerciseRow(_ icon: String, _ title: String, _ description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(.title)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Timer
    
    private var timeString: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func startTimer() {
        remainingTime = BreakReminderManager.shared.getRemainingBreakTime() ?? 300
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                stopTimer()
                onEndBreak()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
