//
//  TestImageCollectorApp.swift
//  TestImageCollector
//
//

import SwiftUI

@main
struct TestImageCollectorApp: App {
    var body: some Scene {
        WindowGroup {
            CollectorView()
        }
    }
}

struct CollectorView: View {
    @State private var collector = TestImageCollector()
    @State private var cameraReady = false
    @State private var selectedCategory: TestImageCollector.ImageCategory = .goodPosture
    @State private var variantName = ""
    @State private var notes = ""
    @State private var statusMessage = "Click 'Setup Camera' to begin"
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Test Image Collector")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(statusMessage)
                .foregroundColor(.secondary)
            
            Divider()
            
            if !cameraReady {
                // Setup
                Button("Setup Camera") {
                    setupCamera()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                // Collection interface
                VStack(alignment: .leading, spacing: 16) {
                    // Category picker
                    VStack(alignment: .leading) {
                        Text("Category:")
                            .font(.headline)
                        
                        Picker("", selection: $selectedCategory) {
                            ForEach(TestImageCollector.ImageCategory.allCases, id: \.self) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Text(selectedCategory.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Variant name
                    VStack(alignment: .leading) {
                        Text("Variant Name:")
                            .font(.headline)
                        
                        TextField("e.g., mild, front_view, person1", text: $variantName)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Notes
                    VStack(alignment: .leading) {
                        Text("Notes (optional):")
                            .font(.headline)
                        
                        TextField("Any special conditions or observations", text: $notes)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Capture button
                    Button("📸 Capture Image") {
                        captureImage()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(variantName.isEmpty)
                    
                    Divider()
                    
                    // Quick actions
                    HStack {
                        Button("View Collection Status") {
                            collector.printStatus()
                        }
                        
                        Button("Open Folder") {
                            openCollectionFolder()
                        }
                        
                        Button("Generate Guide") {
                            collector.generateCollectionGuide()
                            statusMessage = "✅ Guide generated"
                        }
                    }
                }
                .padding()
            }
        }
        .padding(40)
        .frame(width: 600, height: 500)
    }
    
    private func setupCamera() {
        statusMessage = "Setting up camera..."
        collector.setupCamera { success in
            DispatchQueue.main.async {
                cameraReady = success
                statusMessage = success ? "✅ Camera ready - Position yourself and capture!" : "❌ Camera setup failed"
            }
        }
    }
    
    private func captureImage() {
        guard !variantName.isEmpty else { return }
        
        statusMessage = "📸 Capturing..."
        
        DispatchQueue.global().async {
            collector.captureTestImage(
                category: selectedCategory,
                variant: variantName,
                notes: notes
            )
            
            DispatchQueue.main.async {
                statusMessage = "✅ Captured: \(selectedCategory.rawValue)/\(variantName)"
                variantName = ""
                notes = ""
            }
        }
    }
    
    private func openCollectionFolder() {
        let desktop = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        let folderURL = desktop.appendingPathComponent("PostureWellness_TestImages")
        NSWorkspace.shared.open(folderURL)
    }
}
