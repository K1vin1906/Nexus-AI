//
//  QuickPanelController.swift
//  macai
//
//  Created for Nexus AI
//

import AppKit
import SwiftUI
import CoreData
import Combine

/// Manages the MenuBar status item, global hotkey, and QuickPanel window lifecycle.
class QuickPanelController: NSObject, ObservableObject {
    static let shared = QuickPanelController()

    private var statusItem: NSStatusItem?
    private var quickPanelWindow: QuickPanelWindow?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var viewContext: NSManagedObjectContext?

    @Published var isPanelVisible: Bool = false

    // MARK: - Setup

    func setup(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        setupStatusItem()
        registerGlobalHotkey()
        startClipboardMonitor()
    }

    // MARK: - MenuBar Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "brain.head.profile",
                                   accessibilityDescription: "Nexus AI")
            button.image?.size = NSSize(width: 18, height: 18)
            button.action = #selector(statusItemClicked)
            button.target = self
        }

        // Build the right-click menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quick Ask (⌥Space)", action: #selector(togglePanel), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Open Main Window", action: #selector(openMainWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = nil  // We handle click manually; menu on right-click

        // Store the menu for right-click
        statusItem?.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent else {
            togglePanel()
            return
        }

        if event.type == .rightMouseUp {
            // Show context menu on right-click
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Quick Ask (⌥Space)", action: #selector(togglePanel), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Open Main Window", action: #selector(openMainWindow), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
            // Reset menu so left-click works next time
            DispatchQueue.main.async { [weak self] in
                self?.statusItem?.menu = nil
            }
        } else {
            togglePanel()
        }
    }

    // MARK: - Global Hotkey (⌥Space)

    private func registerGlobalHotkey() {
        // Global monitor: catches ⌥Space when app is NOT focused
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleHotkeyEvent(event)
        }

        // Local monitor: catches ⌥Space when app IS focused
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleHotkeyEvent(event) == true {
                return nil // consume the event
            }
            return event
        }
    }

    @discardableResult
    private func handleHotkeyEvent(_ event: NSEvent) -> Bool {
        // ⌥Space: keyCode 49 = Space, modifierFlags contains .option
        guard event.keyCode == 49,
              event.modifierFlags.contains(.option),
              !event.modifierFlags.contains(.command),
              !event.modifierFlags.contains(.control),
              !event.modifierFlags.contains(.shift)
        else {
            return false
        }

        DispatchQueue.main.async { [weak self] in
            self?.togglePanel()
        }
        return true
    }

    // MARK: - Panel Management

    @objc func togglePanel() {
        if let window = quickPanelWindow, window.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        guard let viewContext = viewContext else { return }

        if quickPanelWindow == nil {
            createPanelWindow(viewContext: viewContext)
        }

        guard let window = quickPanelWindow else { return }

        // Position: center-top of the screen (like Spotlight)
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let panelWidth: CGFloat = 560
            let panelHeight: CGFloat = 56 // initial compact height
            let x = screenFrame.midX - panelWidth / 2
            let y = screenFrame.maxY - panelHeight - 200 // offset from top
            window.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true)
        }

        // Activate the app and show the panel
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        isPanelVisible = true

        // Auto-resize as content changes
        window.setContentSize(window.contentView?.fittingSize ?? NSSize(width: 560, height: 56))
    }

    private func hidePanel() {
        quickPanelWindow?.close()
        isPanelVisible = false
    }

    private func createPanelWindow(viewContext: NSManagedObjectContext) {
        let panelRect = NSRect(x: 0, y: 0, width: 560, height: 56)
        let window = QuickPanelWindow(contentRect: panelRect)

        let quickInputView = QuickInputView(
            onOpenInMainWindow: { [weak self] query in
                self?.hidePanel()
                self?.openMainWindow()
                // TODO: Pass query to main window's input field
            },
            onDismiss: { [weak self] in
                self?.hidePanel()
            }
        )
        .environment(\.managedObjectContext, viewContext)

        let hostingView = NSHostingView(rootView: quickInputView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        window.contentView = hostingView

        // Close panel when it loses focus
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.hidePanel()
        }

        quickPanelWindow = window
    }

    // MARK: - Actions

    @objc private func openMainWindow() {
        // Bring the main app window to front
        NSApp.activate(ignoringOtherApps: true)
        if let mainWindow = NSApp.windows.first(where: { !($0 is QuickPanelWindow) && $0.isVisible }) {
            mainWindow.makeKeyAndOrderFront(nil)
        } else {
            // No visible window? Open one
            NSApp.sendAction(Selector(("newWindowForTab:")), to: nil, from: nil)
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Clipboard Monitor

    private func startClipboardMonitor() {
        ClipboardMonitor.shared.startMonitoring()

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ClipboardContentChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.flashMenuBarIcon()
        }
    }

    /// Briefly change the MenuBar icon to indicate new clipboard content
    private func flashMenuBarIcon() {
        guard let button = statusItem?.button else { return }
        let originalImage = button.image

        // Flash to clipboard icon
        button.image = NSImage(systemSymbolName: "clipboard.fill",
                               accessibilityDescription: "New clipboard content")
        button.image?.size = NSSize(width: 18, height: 18)

        // Revert after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            button.image = originalImage
            button.image?.size = NSSize(width: 18, height: 18)
        }
    }

    // MARK: - Cleanup

    deinit {
        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        ClipboardMonitor.shared.stopMonitoring()
    }
}
