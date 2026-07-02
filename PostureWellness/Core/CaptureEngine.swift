//
//  CaptureEngine.swift
//  PostureWellness
//
//

import Foundation
import AVFoundation
import CoreImage

// MARK: - Capture Engine Delegate

protocol CaptureEngineDelegate: AnyObject {
    func captureEngine(_ engine: CaptureEngine, didCaptureFrame image: CIImage)
    func captureEngine(_ engine: CaptureEngine, didFailWithError error: CaptureError)
}

// MARK: - Capture Errors

enum CaptureError: Error, LocalizedError {
    case cameraNotAvailable
    case permissionDenied
    case captureSessionFailed(String)
    case noFrameCaptured
    
    var errorDescription: String? {
        switch self {
        case .cameraNotAvailable:
            return "Camera is not available on this device"
        case .permissionDenied:
            return "Camera permission denied. Please enable in System Settings."
        case .captureSessionFailed(let reason):
            return "Camera capture failed: \(reason)"
        case .noFrameCaptured:
            return "Failed to capture camera frame"
        }
    }
}

// MARK: - Capture Engine

class CaptureEngine: NSObject {
    
    weak var delegate: CaptureEngineDelegate?
    
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var currentDevice: AVCaptureDevice?
    
    private let captureQueue = DispatchQueue(label: "com.posturewellness.capture", qos: .userInitiated)
    
    private var isCapturing = false
    private var shouldCaptureNextFrame = false
    
    // MARK: - Initialization
    
    override init() {
        super.init()
    }
    
    // MARK: - Permission Check
    
    func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
            
        case .denied, .restricted:
            completion(false)
            
        @unknown default:
            completion(false)
        }
    }
    
    // MARK: - Setup Camera
    
    func setupCamera(completion: @escaping (Result<Void, CaptureError>) -> Void) {
        checkCameraPermission { [weak self] granted in
            guard let self = self else { return }
            
            guard granted else {
                completion(.failure(.permissionDenied))
                return
            }
            
            self.captureQueue.async {
                do {
                    try self.configureCaptureSession()
                    DispatchQueue.main.async {
                        completion(.success(()))
                    }
                } catch let error as CaptureError {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(.captureSessionFailed(error.localizedDescription)))
                    }
                }
            }
        }
    }
    
    private func configureCaptureSession() throws {
        // Create capture session
        let session = AVCaptureSession()
        session.sessionPreset = .high  // Balance between quality and performance
        
        // Get camera device (prefer built-in wide angle)
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) ??
                           AVCaptureDevice.default(for: .video) else {
            throw CaptureError.cameraNotAvailable
        }
        
        // Create input
        let input = try AVCaptureDeviceInput(device: camera)
        guard session.canAddInput(input) else {
            throw CaptureError.captureSessionFailed("Cannot add camera input")
        }
        session.addInput(input)
        
        // Create output
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        output.setSampleBufferDelegate(self, queue: captureQueue)
        output.alwaysDiscardsLateVideoFrames = true  // Drop frames if processing is slow
        
        guard session.canAddOutput(output) else {
            throw CaptureError.captureSessionFailed("Cannot add video output")
        }
        session.addOutput(output)
        
        // Store references
        self.captureSession = session
        self.videoOutput = output
        self.currentDevice = camera
        
        print("✅ Camera configured successfully")
    }
    
    // MARK: - Start/Stop Capture
    
    func startCapture() {
        guard let session = captureSession else { return }
        
        captureQueue.async { [weak self] in
            guard let self = self else { return }
            
            if !session.isRunning {
                session.startRunning()
                print("📹 Camera session started")
                
                // ✅ Add small delay before marking as capturing
                Thread.sleep(forTimeInterval: 0.5)
            }
            
            self.isCapturing = true
            print("📹 Camera capture ready")
        }
    }
    
    func stopCapture() {
        guard let session = captureSession, session.isRunning else { return }
        
        captureQueue.async { [weak self] in
            session.stopRunning()
            self?.isCapturing = false
            print("⏸️ Camera capture stopped")
        }
    }
    
    // MARK: - Capture Single Frame
    
    /// Request capture of the next available frame
    func captureSingleFrame() {
        guard isCapturing else {
            print("⚠️ Cannot capture: session not running")
            delegate?.captureEngine(self, didFailWithError: .captureSessionFailed("Capture session not running"))
            return
        }
        
        print("📷 Capture requested, waiting for next frame...")
        shouldCaptureNextFrame = true
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        print("🧹 Starting camera cleanup...")
        
        // Make sure we're on the capture queue and run synchronously
        captureQueue.sync {
            // Stop session if running
            if let session = self.captureSession, session.isRunning {
                session.stopRunning()
                print("   ⏸️ Session stopped")
            }
            
            // Remove all inputs and outputs
            if let session = self.captureSession {
                for input in session.inputs {
                    session.removeInput(input)
                }
                for output in session.outputs {
                    session.removeOutput(output)
                }
                print("   🗑️ Inputs and outputs removed")
            }
            
            // Clear all references
            self.captureSession = nil
            self.videoOutput = nil
            self.currentDevice = nil
            self.isCapturing = false
        }
        
        print("✅ Camera cleanup complete")
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CaptureEngine: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {
        
        // Only process if we're waiting for a frame
        guard shouldCaptureNextFrame else { return }
        shouldCaptureNextFrame = false
        
        print("📸 Frame received from camera")
        
        // Convert CMSampleBuffer to CIImage
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("❌ Failed to get pixel buffer from sample")
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.captureEngine(self, didFailWithError: .noFrameCaptured)
            }
            return
        }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        print("✅ Frame converted to CIImage (\(ciImage.extent.width)x\(ciImage.extent.height))")
        
        // Notify delegate on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.captureEngine(self, didCaptureFrame: ciImage)
        }
    }
}
