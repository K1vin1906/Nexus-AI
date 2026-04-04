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

    /// Nexus AI gradient: purple → cyan
    static let nexusGradient = LinearGradient(
        colors: [.nexusPurple, .nexusCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
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

// MARK: - Semantic Color System

struct NexusTheme {

    // MARK: Sidebar
    struct Sidebar {
        static func background(_ scheme: ColorScheme) -> Color {
            scheme == .dark
                ? Color(red: 26/255, green: 26/255, blue: 46/255).opacity(0.7)
                : Color(red: 237/255, green: 235/255, blue: 245/255).opacity(0.97)
        }
        static func rowHover(_ scheme: ColorScheme) -> Color {
            Color.nexusPurple.opacity(scheme == .dark ? 0.15 : 0.08)
        }
        static func rowActive(_ scheme: ColorScheme) -> Color {
            Color.nexusPurple.opacity(scheme == .dark ? 0.35 : 0.18)
        }
        static func sectionHeader(_ scheme: ColorScheme) -> Color {
            scheme == .dark
                ? Color.white.opacity(0.45)
                : Color.black.opacity(0.45)
        }
    }

    // MARK: Chat Area
    struct Chat {
        static func background(_ scheme: ColorScheme) -> Color {
            scheme == .dark
                ? Color(red: 22/255, green: 22/255, blue: 42/255).opacity(0.75)
                : Color.white.opacity(0.95)
        }
        static func userBubble(_ scheme: ColorScheme) -> Color {
            Color.nexusPurple.opacity(scheme == .dark ? 0.25 : 0.12)
        }
        static func assistantBubble(_ scheme: ColorScheme) -> Color {
            scheme == .dark
                ? Color(red: 35/255, green: 35/255, blue: 64/255)   // #232340
                : Color(red: 240/255, green: 238/255, blue: 255/255) // #F0EEFF
        }
        static func inputBackground(_ scheme: ColorScheme) -> Color {
            scheme == .dark
                ? Color(red: 30/255, green: 30/255, blue: 58/255)   // #1E1E3A
                : Color(red: 248/255, green: 247/255, blue: 255/255) // #F8F7FF
        }
        static func inputBorder(_ scheme: ColorScheme) -> Color {
            Color.nexusPurple.opacity(scheme == .dark ? 0.3 : 0.2)
        }
    }

    // MARK: Text Colors
    struct Text {
        static func primary(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? .white : Color(red: 26/255, green: 26/255, blue: 46/255)
        }
        static func secondary(_ scheme: ColorScheme) -> Color {
            scheme == .dark
                ? Color.white.opacity(0.6)
                : Color.black.opacity(0.55)
        }
        static func tertiary(_ scheme: ColorScheme) -> Color {
            scheme == .dark
                ? Color.white.opacity(0.35)
                : Color.black.opacity(0.35)
        }
    }

    // MARK: Toolbar / Window Chrome
    struct Chrome {
        static func divider(_ scheme: ColorScheme) -> Color {
            scheme == .dark
                ? Color.white.opacity(0.08)
                : Color.black.opacity(0.08)
        }
        static func toolbarBackground(_ scheme: ColorScheme) -> Color {
            scheme == .dark
                ? Color(red: 26/255, green: 26/255, blue: 46/255).opacity(0.75)
                : Color(red: 237/255, green: 235/255, blue: 245/255).opacity(0.97)
        }
    }

    // MARK: Quick Panel
    struct QuickPanel {
        static func background(_ scheme: ColorScheme) -> Color {
            scheme == .dark
                ? Color(red: 28/255, green: 28/255, blue: 52/255).opacity(0.97)
                : Color(red: 253/255, green: 252/255, blue: 255/255).opacity(0.97)
        }
    }

    // MARK: Provider Icon Tint
    static func providerColor(for type: String?) -> Color {
        switch type?.lowercased() {
        case "gemini":       return Color(red: 66/255, green: 133/255, blue: 244/255)
        case "claude":       return Color(red: 217/255, green: 119/255, blue: 87/255)
        case "deepseek":     return Color(red: 77/255, green: 107/255, blue: 254/255)
        case "ollama":       return .white
        case "openai-responses", "chatgpt":
                             return Color(red: 16/255, green: 163/255, blue: 127/255)
        case "openrouter":   return Color(red: 100/255, green: 103/255, blue: 242/255)
        case "perplexity":   return Color(red: 32/255, green: 128/255, blue: 141/255)
        case "xai":          return .white
        default:             return .nexusPurple
        }
    }

    /// Returns a compact SF Symbol name for each provider type
    static func providerIcon(for type: String?) -> String {
        switch type?.lowercased() {
        case "gemini":                       return "diamond.fill"
        case "claude":                       return "brain.head.profile.fill"
        case "deepseek":                     return "magnifyingglass.circle.fill"
        case "ollama":                       return "desktopcomputer"
        case "openai-responses", "chatgpt":  return "circle.hexagonpath.fill"
        case "openrouter":                   return "arrow.triangle.branch"
        case "perplexity":                   return "globe"
        case "xai":                          return "bolt.fill"
        default:                             return "cpu.fill"
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

    func applyAccentColor() {
        let nsColor = NSColor(accentColor.color)
        UserDefaults.standard.set(nsColor.hexString, forKey: "AppleAccentColor_Custom")
        NotificationCenter.default.post(name: .nexusAccentColorChanged, object: nil)
    }

    func setup() {
        applyAccentColor()
    }
}

extension Notification.Name {
    static let nexusAccentColorChanged = Notification.Name("nexusAccentColorChanged")
}

// MARK: - NSColor Hex Support

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

// MARK: - Convenience View Modifiers

extension View {
    /// Apply the Nexus brand accent tint
    func nexusAccent() -> some View {
        self.tint(.nexusPurple)
    }

    /// Nexus-styled rounded card background
    func nexusCard(_ scheme: ColorScheme, cornerRadius: CGFloat = 12) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(NexusTheme.Chat.assistantBubble(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(NexusTheme.Chrome.divider(scheme), lineWidth: 0.5)
            )
    }
}
