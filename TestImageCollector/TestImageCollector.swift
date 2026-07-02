//
//  TestImageCollector.swift
//  PostureWellness
//
//

import Foundation
import AVFoundation
import AppKit

class TestImageCollector {
    
    enum ImageCategory: String, CaseIterable {
        case goodPosture = "01_GoodPosture"
        case forwardHead = "02_ForwardHead"
        case slouching = "03_Slouching"
        case roundedShoulders = "04_RoundedShoulders"
        case asymmetrical = "05_Asymmetrical"
        case tooClose = "06_TooClose"
        case tooFar = "07_TooFar"
        case partiallyVisible = "08_PartiallyVisible"
        case lowLight = "09_LowLight"
        case brightLight = "10_BrightLight"
        case backlit = "11_Backlit"
        case sideAngle = "12_SideAngle"
        case standing = "13_Standing"
        case multiplePostures = "14_MultiplePostures"
        case edgeCases = "15_EdgeCases"
        
        var description: String {
            switch self {
            case .goodPosture: return "Good Posture - Upright, aligned, proper distance"
            case .forwardHead: return "Forward Head - Neck jutting forward"
            case .slouching: return "Slouching - Rounded back, hunched"
            case .roundedShoulders: return "Rounded Shoulders - Shoulders forward"
            case .asymmetrical: return "Asymmetrical - Leaning to one side"
            case .tooClose: return "Too Close - Less than 40cm from screen"
            case .tooFar: return "Too Far - More than 80cm from screen"
            case .partiallyVisible: return "Partially Visible - Only upper body"
            case .lowLight: return "Low Light - Dim conditions"
            case .brightLight: return "Bright Light - Well lit"
            case .backlit: return "Backlit - Light source behind person"
            case .sideAngle: return "Side Angle - Profile or 45° view"
            case .standing: return "Standing - Person standing (not sitting)"
            case .multiplePostures: return "Multiple Postures - Combined issues"
            case .edgeCases: return "Edge Cases - Empty frame, multiple people, etc."
            }
        }
    }
    
    private let baseURL: URL
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let captureQueue = DispatchQueue(label: "test.image.capture")
    
    init() {
        // Create test images folder on Desktop
        let desktop = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        baseURL = desktop.appendingPathComponent("PostureWellness_TestImages")
        
        // Create directory structure
        try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        
        // Create subdirectories for each category
        for category in ImageCategory.allCases {
            let categoryURL = baseURL.appendingPathComponent(category.rawValue)
            try? FileManager.default.createDirectory(at: categoryURL, withIntermediateDirectories: true)
        }
        
        print("📁 Test image collection folder created at:")
        print("   \(baseURL.path)")
    }
    
    func setupCamera(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard granted else {
                print("❌ Camera permission denied")
                completion(false)
                return
            }
            
            self?.configureCaptureSession()
            completion(true)
        }
    }
    
    private func configureCaptureSession() {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) ??
                           AVCaptureDevice.default(for: .video) else {
            print("❌ Camera not available")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            
            self.captureSession = session
            self.videoOutput = output
            
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
                print("✅ Camera ready for test image collection")
            }
        } catch {
            print("❌ Camera setup failed: \(error)")
        }
    }
    
    func captureTestImage(category: ImageCategory, variant: String, notes: String = "") {
        guard let session = captureSession, session.isRunning else {
            print("❌ Camera not running")
            return
        }
        
        guard let output = videoOutput else {
            print("❌ Video output not configured")
            return
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        var capturedImage: NSImage?
        
        let delegate = CaptureDelegate { image in
            capturedImage = image
            semaphore.signal()
        }
        
        output.setSampleBufferDelegate(delegate, queue: captureQueue)
        
        // Wait for capture
        _ = semaphore.wait(timeout: .now() + 5)
        
        output.setSampleBufferDelegate(nil, queue: nil)
        
        if let image = capturedImage {
            saveImage(image, category: category, variant: variant, notes: notes)
        } else {
            print("❌ Failed to capture image")
        }
    }
    
    private func saveImage(_ image: NSImage, category: ImageCategory, variant: String, notes: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let filename = "\(variant)_\(timestamp).jpg"
        
        let categoryURL = baseURL.appendingPathComponent(category.rawValue)
        let fileURL = categoryURL.appendingPathComponent(filename)
        
        // Save image
        if let tiffData = image.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffData),
           let jpegData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) {
            
            do {
                try jpegData.write(to: fileURL)
                print("✅ Saved: \(category.rawValue)/\(filename)")
                
                // Save metadata
                if !notes.isEmpty {
                    let metadataURL = fileURL.deletingPathExtension().appendingPathExtension("txt")
                    let metadata = """
                    Category: \(category.rawValue)
                    Variant: \(variant)
                    Timestamp: \(timestamp)
                    Notes: \(notes)
                    """
                    try? metadata.write(to: metadataURL, atomically: true, encoding: .utf8)
                }
            } catch {
                print("❌ Failed to save image: \(error)")
            }
        }
    }
    
    func generateCollectionGuide() {
        let guideURL = baseURL.appendingPathComponent("COLLECTION_GUIDE.md")
        
        let guide = ImageCategory.allCases.map { "### \($0.rawValue)\n\($0.description)\n**Target:** 5-10 images per person\n" }.joined(separator: "\n"))

        try? guide.write(to: guideURL, atomically: true, encoding: .utf8)
                print("📄 Collection guide created: \(guideURL.path)")
    }
            
    func printStatus() {
        print("\n📊 Collection Status:")
        print("=" + String(repeating: "=", count: 50))
        
        for category in ImageCategory.allCases {
            let categoryURL = baseURL.appendingPathComponent(category.rawValue)
            let contents = try? FileManager.default.contentsOfDirectory(at: categoryURL, includingPropertiesForKeys: nil)
            let imageCount = contents?.filter { $0.pathExtension == "jpg" }.count ?? 0
            
            let status = imageCount >= 5 ? "✅" : imageCount > 0 ? "⚠️" : "❌"
            print("\(status) \(category.rawValue): \(imageCount) images")
        }
        
        print("=" + String(repeating: "=", count: 50))
    }
}

// MARK: - Capture Delegate

class CaptureDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let completion: (NSImage) -> Void
    
    init(completion: @escaping (NSImage) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            completion(nsImage)
        }
    }
}
