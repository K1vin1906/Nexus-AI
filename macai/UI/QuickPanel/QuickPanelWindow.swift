//
//  QuickPanelWindow.swift
//  macai
//
//  Created for Nexus AI
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// A floating panel window that behaves like Spotlight/Raycast:
/// - Floats above all windows
/// - Activates without stealing focus permanently
/// - Closes on Escape or focus loss
class QuickPanelWindow: NSPanel {

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Panel behavior
        self.level = .floating
        self.isFloatingPanel = true
        self.isMovableByWindowBackground = true
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true

        // Auto-hide when losing focus
        self.hidesOnDeactivate = false
        self.becomesKeyOnlyIfNeeded = false

        // Rounded corners
        self.isReleasedWhenClosed = false
        self.animationBehavior = .utilityWindow

        // Allow the panel to become key so TextField can receive input
        self.worksWhenModal = true

        // Register for drag and drop
        self.registerForDraggedTypes([.fileURL, .string, .tiff, .png])
    }

    /// Allow this panel to become the key window
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Close on Escape key
    override func cancelOperation(_ sender: Any?) {
        close()
    }
}
