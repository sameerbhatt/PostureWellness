//
//  VisionTest.swift
//  PostureWellness
//
//

import Foundation
import Vision
import CoreImage
import AppKit

class VisionTest {
    
    static func runBasicTest(image: CIImage) {
        print("\n🧪 === VISION BASIC TEST ===")
        print("Image size: \(image.extent.size)")
        
        // Create the simplest possible Vision request
        let request = VNDetectHumanBodyPoseRequest()
        
        // Try with no options, default orientation
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        
        do {
            try handler.perform([request])
            
            if let results = request.results as? [VNHumanBodyPoseObservation] {
                print("✅ Request succeeded")
                print("📊 Detections: \(results.count)")
                
                if results.isEmpty {
                    print("⚠️ No people detected")
                    
                    // Try to get more diagnostic info
                    print("\n🔍 Diagnostics:")
                    print("   - Image might be too dark")
                    print("   - Person might be too small in frame")
                    print("   - Image might be corrupted")
                    print("   - Vision framework might need restart")
                    
                } else {
                    for (index, observation) in results.enumerated() {
                        print("\nPerson \(index + 1):")
                        
                        // Try to get ALL available points
                        // Try to get ALL available points
                        if let allPoints = try? observation.recognizedPoints(.all) {
                            print("   Available joints: \(allPoints.count)")
                            
                            // Print each point with confidence
                            let sortedPoints = allPoints.sorted { first, second in
                                first.key.rawValue.rawValue < second.key.rawValue.rawValue
                            }
                            
                            for (key, point) in sortedPoints {
                                if point.confidence > 0.1 {
                                    print("   - \(key.rawValue.rawValue): \(String(format: "%.2f", point.confidence))")
                                }
                            }
                        }
                    }
                }
            }
            
        } catch {
            print("❌ Vision request failed: \(error)")
        }
        
        print("=== END TEST ===\n")
    }
}
