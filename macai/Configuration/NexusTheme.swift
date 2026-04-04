//
//  NexusTheme.swift
//  macai
//
//  Created by K1vin on 2026-04-04.
//  Nexus AI v1.2 — A1 Theme System
//

import SwiftUI

// MARK: - Nexus Brand Colors

extension Color {
    static let nexusPurple = Color(red: 108/255, green: 92/255, blue: 231/255)
    static let nexusCyan = Color(red: 78/255, green: 205/255, blue: 196/255)
    static let nexusPurpleLight = Color(red: 139/255, green: 124/255, blue: 247/255)
    static let nexusCyanLight = Color(red: 120/255, green: 220/255, blue: 212/255)
}

// MARK: - Accent Color Options

enum NexusAccentColor: String, CaseIterable, Identifiable {
    case purple = "nexusPurple"
    case cyan = "nexusCyan"
    case blue = "systemBlue"
    case green = "systemGreen"
    case orange = "systemOrange"
    case pink = "systemPink"
    case red = "systemRed"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .purple: return .nexusPurple
        case .cyan: return .nexusCyan
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .pink: return .pink
        case .red: return .red
        }
    }

    var displayName: String {
        switch self {
        case .purple: return "Nexus Purple"
        case .cyan: return "Nexus Cyan"
        case .blue: return "Blue"
        case .green: return "Green"
        case .orange: return "Orange"
        case .pink: return "Pink"
        case .red: return "Red"
        }
    }
}

// MARK: - Theme Manager

class NexusThemeManager: ObservableObject {
    static let shared = NexusThemeManager()

    @AppStorage("nexusAccentColor") var accentColorRaw: String = NexusAccentColor.purple.rawValue {
        didSet { applyAccentColor() }
    }

    var accentColor: NexusAccentColor {
        get { NexusAccentColor(rawValue: accentColorRaw) ?? .purple }
        set { accentColorRaw = newValue.rawValue }
    }

    var currentAccentColor: Color {
        accentColor.color
    }

    /// Apply accent color globally via NSAppearance
    func applyAccentColor() {
        let color = accentColor.color
        let nsColor = NSColor(color)
        // Set the global accent color for the app
        UserDefaults.standard.set(nsColor.hexString, forKey: "AppleAccentColor_Custom")
        // Post notification so views can update
        NotificationCenter.default.post(name: .nexusAccentColorChanged, object: nil)
    }

    func setup() {
        applyAccentColor()
    }
}

extension Notification.Name {
    static let nexusAccentColorChanged = Notification.Name("nexusAccentColorChanged")
}

extension NSColor {
    var hexString: String {
        guard let rgb = usingColorSpace(.sRGB) else { return "#6C5CE7" }
        return String(format: "#%02X%02X%02X",
                      Int(rgb.redComponent * 255),
                      Int(rgb.greenComponent * 255),
                      Int(rgb.blueComponent * 255))
    }
}

extension Color {
    var hexString: String {
        NSColor(self).hexString
    }
}
