//
//  ChatWindowController.swift
//  Nexus AI
//
//  Created by K1vin on 2026-04-04.
//  v1.5 — C4 Multi-Window Support
//

import AppKit
import CoreData
import SwiftUI

/// Manages independent chat windows for side-by-side comparison
class ChatWindowManager {
    static let shared = ChatWindowManager()
    private var windows: [UUID: NSWindow] = [:]

    func openChat(_ chat: ChatEntity, viewContext: NSManagedObjectContext) {
        // If window already exists for this chat, bring it to front
        if let existingWindow = windows[chat.id] {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let chatView = StandaloneChatView(chat: chat, viewContext: viewContext)
            .environment(\.managedObjectContext, viewContext)

        let hostingView = NSHostingView(rootView: chatView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        let serviceName = chat.apiService?.name ?? "Chat"
        let chatTitle = chat.name.isEmpty ? "Untitled" : chat.name
        window.title = "\(chatTitle) — \(serviceName)"
        window.contentView = hostingView
        window.minSize = NSSize(width: 450, height: 400)
        window.isReleasedWhenClosed = false
        window.center()

        // Offset slightly so multiple windows don't stack exactly
        let offset = CGFloat(windows.count * 30)
        if let frame = window.screen?.visibleFrame {
            let x = min(window.frame.origin.x + offset, frame.maxX - window.frame.width)
            let y = max(window.frame.origin.y - offset, frame.minY)
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        windows[chat.id] = window

        // Clean up reference when window closes
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] notification in
            guard let closingWindow = notification.object as? NSWindow else { return }
            let keysToRemove = self?.windows.filter { $0.value === closingWindow }.map { $0.key } ?? []
            for key in keysToRemove { self?.windows.removeValue(forKey: key) }
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closeAll() {
        windows.values.forEach { $0.close() }
        windows.removeAll()
    }

    var openWindowCount: Int { windows.count }
}

// MARK: - Standalone Chat View (for independent windows)

struct StandaloneChatView: View {
    let chat: ChatEntity
    let viewContext: NSManagedObjectContext
    @State private var searchText = ""
    @StateObject private var previewStateManager = PreviewStateManager()

    var body: some View {
        HSplitView {
            ChatView(viewContext: viewContext, chat: chat, searchText: $searchText)
                .frame(minWidth: 400)

            if previewStateManager.isPreviewVisible {
                PreviewPane(stateManager: previewStateManager)
            }
        }
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search…")
        .environmentObject(previewStateManager)
    }
}
