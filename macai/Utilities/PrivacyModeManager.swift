//
//  PrivacyModeManager.swift
//  macai
//
//  Created for Nexus AI — Privacy Mode (force local Ollama)
//

import Foundation
import Combine

/// Manages privacy mode state.
/// When enabled, all new chats are forced to use Ollama (local model).
class PrivacyModeManager: ObservableObject {
    static let shared = PrivacyModeManager()

    private let privacyModeKey = "NexusAI_PrivacyModeEnabled"

    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: privacyModeKey)
            NotificationCenter.default.post(
                name: NSNotification.Name("PrivacyModeChanged"),
                object: nil,
                userInfo: ["enabled": isEnabled]
            )
        }
    }

    /// Whether Ollama is reachable at localhost:11434
    @Published var isOllamaAvailable: Bool = false

    private var checkTimer: Timer?

    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: privacyModeKey)
        checkOllamaStatus()
        // Periodically check Ollama availability
        checkTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.checkOllamaStatus()
        }
    }

    /// Check if Ollama is running locally
    func checkOllamaStatus() {
        guard let url = URL(string: "http://localhost:11434/api/tags") else { return }

        var request = URLRequest(url: url)
        request.timeoutInterval = 2

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    self?.isOllamaAvailable = true
                } else {
                    self?.isOllamaAvailable = false
                }
            }
        }.resume()
    }

    /// Get list of locally installed Ollama models
    func fetchLocalModels(completion: @escaping ([String]) -> Void) {
        guard let url = URL(string: "http://localhost:11434/api/tags") else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let models = json["models"] as? [[String: Any]]
            else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            let names = models.compactMap { $0["name"] as? String }
            DispatchQueue.main.async { completion(names) }
        }.resume()
    }

    deinit {
        checkTimer?.invalidate()
    }
}
