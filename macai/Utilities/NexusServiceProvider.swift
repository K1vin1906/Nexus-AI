//
//  NexusServiceProvider.swift
//  Nexus AI
//
//  Created by K1vin on 2026-04-04.
//  v1.2 — C1 System Services Integration
//

import AppKit
import CoreData

/// Handles macOS Services menu: "Ask Nexus AI" for selected text
class NexusServiceProvider: NSObject {

    /// Called by the system when user selects text → right-click → Services → "Ask Nexus AI"
    @objc func askNexusAI(
        _ pboard: NSPasteboard,
        userData: String,
        error: AutoreleasingUnsafeMutablePointer<NSString>
    ) {
        guard let text = pboard.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            error.pointee = "No text was selected." as NSString
            return
        }

        // Bring our app to front
        NSApp.activate(ignoringOtherApps: true)

        // Send the selected text to Quick Panel
        DispatchQueue.main.async {
            let controller = QuickPanelController.shared
            controller.showPanel()

            // Post notification to fill the Quick Panel input with selected text
            NotificationCenter.default.post(
                name: .nexusServiceTextReceived,
                object: nil,
                userInfo: ["text": text]
            )
        }
    }

    /// Called by "Summarize with Nexus AI"
    @objc func summarizeWithNexusAI(
        _ pboard: NSPasteboard,
        userData: String,
        error: AutoreleasingUnsafeMutablePointer<NSString>
    ) {
        guard let text = pboard.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            error.pointee = "No text was selected." as NSString
            return
        }

        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.main.async {
            let controller = QuickPanelController.shared
            controller.showPanel()

            let prompt = "Summarize the following text:\n\n\(text)"
            NotificationCenter.default.post(
                name: .nexusServiceTextReceived,
                object: nil,
                userInfo: ["text": prompt, "autoSend": true]
            )
        }
    }

    /// Called by "Translate with Nexus AI"
    @objc func translateWithNexusAI(
        _ pboard: NSPasteboard,
        userData: String,
        error: AutoreleasingUnsafeMutablePointer<NSString>
    ) {
        guard let text = pboard.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            error.pointee = "No text was selected." as NSString
            return
        }

        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.main.async {
            let controller = QuickPanelController.shared
            controller.showPanel()

            let prompt = "Translate the following text to English. If it's already in English, translate to Chinese:\n\n\(text)"
            NotificationCenter.default.post(
                name: .nexusServiceTextReceived,
                object: nil,
                userInfo: ["text": prompt, "autoSend": true]
            )
        }
    }

    // MARK: - Registration

    /// Register the service provider and send types with the system
    static func register() {
        let provider = NexusServiceProvider()
        // Keep a strong reference
        _sharedProvider = provider
        NSApp.registerServicesMenuSendTypes([.string], returnTypes: [])
        NSApp.servicesProvider = provider

        // Force the system to update its services menu
        NSUpdateDynamicServices()
    }

    private static var _sharedProvider: NexusServiceProvider?
}

// MARK: - Notification

extension Notification.Name {
    /// Posted when text is received via macOS Services menu
    static let nexusServiceTextReceived = Notification.Name("nexusServiceTextReceived")
}
