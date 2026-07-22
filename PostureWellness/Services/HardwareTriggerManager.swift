//
//  HardwareTriggerManager.swift
//  PostureWellness
//
//  Experimental PoC: fires a local HTTP request to an Arduino UNO R4 WiFi
//  on the same network to trigger a physical nudge (servo) alongside a posture
//  notification. LAN only, no cloud - consistent with the app's
//  privacy-first design. Best-effort: failures are logged only, never
//  surfaced to the user or allowed to affect notification delivery.
//

import Foundation
    
class HardwareTriggerManager {

    static let shared = HardwareTriggerManager()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 2.0
        config.timeoutIntervalForResource = 2.0
        self.session = URLSession(configuration: config)
    }

    func trigger() {
        guard UserDefaults.standard.bool(forKey: "hardwareNudgeEnabled") else { return }

        guard let host = UserDefaults.standard.string(forKey: "hardwareNudgeIP"),
              !host.isEmpty,
              let url = URL(string: "http://\(host)/nudge") else {
            print("⚠️ Hardware nudge enabled but Arduino IP address is invalid")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        print("Hardware nudge URL: \(url)")

        session.dataTask(with: request) { _, _, error in
            if let error = error {
                print("🦿 Hardware nudge failed: \(error.localizedDescription)")
            } else {
                print("🦿 Hardware nudge sent")
            }
        }.resume()
    }
}
