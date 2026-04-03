//
//  ClipboardMonitor.swift
//  macai
//
//  Created for Nexus AI
//

import AppKit
import Combine
import SwiftUI

/// Monitors the system clipboard for new content and notifies observers.
/// Polls NSPasteboard every 0.5s (macOS has no push notification for clipboard changes).
class ClipboardMonitor: ObservableObject {
    static let shared = ClipboardMonitor()

    @Published var hasNewContent: Bool = false
    @Published var lastContentType: ClipboardContentType = .empty
    @Published var lastTextPreview: String = ""

    enum ClipboardContentType: String {
        case empty = "empty"
        case text = "text"
        case image = "image"
        case fileURL = "file"
    }

    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var isMonitoring: Bool = false

    // MARK: - Start/Stop

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        lastChangeCount = NSPasteboard.general.changeCount

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    // MARK: - Check

    private func checkClipboard() {
        let currentCount = NSPasteboard.general.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        // Determine content type
        let pasteboard = NSPasteboard.general

        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            lastContentType = .text
            // Truncate preview to 80 chars
            lastTextPreview = String(string.prefix(80))
                .replacingOccurrences(of: "\n", with: " ")
        } else if pasteboard.data(forType: .tiff) != nil || pasteboard.data(forType: .png) != nil {
            lastContentType = .image
            lastTextPreview = "📷 Image"
        } else if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
            lastContentType = .fileURL
            lastTextPreview = urls.first?.lastPathComponent ?? "File"
        } else {
            lastContentType = .empty
            lastTextPreview = ""
            return
        }

        DispatchQueue.main.async {
            self.hasNewContent = true
            // Auto-reset after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.hasNewContent = false
            }
        }

        // Notify QuickPanelController to flash the MenuBar icon
        NotificationCenter.default.post(
            name: NSNotification.Name("ClipboardContentChanged"),
            object: nil,
            userInfo: ["type": lastContentType.rawValue]
        )
    }

    // MARK: - Content Retrieval

    /// Get clipboard text content
    func getClipboardText() -> String? {
        return NSPasteboard.general.string(forType: .string)
    }

    /// Get clipboard image as Data + mime type
    func getClipboardImage() -> (data: Data, mimeType: String)? {
        let pasteboard = NSPasteboard.general
        if let pngData = pasteboard.data(forType: .png) {
            return (pngData, "image/png")
        }
        if let tiffData = pasteboard.data(forType: .tiff),
           let image = NSImage(data: tiffData),
           let pngData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: pngData),
           let png = bitmap.representation(using: .png, properties: [:]) {
            return (png, "image/png")
        }
        return nil
    }

    /// Get clipboard file URLs
    func getClipboardFileURLs() -> [URL] {
        return NSPasteboard.general.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] ?? []
    }

    /// Build a message string from current clipboard content
    func buildClipboardMessage() -> String? {
        switch lastContentType {
        case .text:
            guard let text = getClipboardText() else { return nil }
            return "Please analyze the following content from my clipboard:\n\n\(text)"
        case .image:
            return "Please analyze this image from my clipboard."
        case .fileURL:
            let urls = getClipboardFileURLs()
            let names = urls.map { $0.lastPathComponent }.joined(separator: ", ")
            return "I have the following files in my clipboard: \(names)"
        case .empty:
            return nil
        }
    }

    deinit {
        stopMonitoring()
    }
}
