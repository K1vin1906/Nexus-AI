//
//  QuickActionsView.swift
//  macai
//
//  Created by K1vin on 2026-04-04.
//  Nexus AI v1.1 — A4 Input Area Redesign
//

import SwiftUI

struct QuickActionItem: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let prompt: String
}

struct QuickActionsView: View {
    let onAction: (String) -> Void
    @State private var hoveredId: UUID?
    
    private let actions: [QuickActionItem] = [
        QuickActionItem(icon: "bolt.fill", label: "Summarize", prompt: "Please summarize the above content concisely."),
        QuickActionItem(icon: "globe", label: "Translate", prompt: "Please translate the above content to English. If it's already in English, translate to Chinese."),
        QuickActionItem(icon: "chevron.left.forwardslash.chevron.right", label: "Code Review", prompt: "Please review the code above. Check for bugs, performance issues, and suggest improvements."),
        QuickActionItem(icon: "pencil.line", label: "Rewrite", prompt: "Please rewrite the above content to be clearer and more professional."),
        QuickActionItem(icon: "text.magnifyingglass", label: "Explain", prompt: "Please explain the above content in simple terms."),
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(actions) { action in
                    QuickActionChip(
                        icon: action.icon,
                        label: action.label,
                        isHovered: hoveredId == action.id
                    )
                    .onTapGesture {
                        onAction(action.prompt)
                    }
                    .onHover { hovering in
                        withAnimation(.easeOut(duration: 0.15)) {
                            hoveredId = hovering ? action.id : nil
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }
}

struct QuickActionChip: View {
    let icon: String
    let label: String
    let isHovered: Bool
    @Environment(\.colorScheme) var colorScheme
    
    private var chipBackground: Color {
        if isHovered {
            return Color.accentColor.opacity(0.12)
        }
        return colorScheme == .dark
            ? Color.white.opacity(0.06)
            : Color.black.opacity(0.04)
    }
    
    private var chipBorder: Color {
        if isHovered {
            return Color.accentColor.opacity(0.3)
        }
        return colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color.black.opacity(0.08)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isHovered ? .accentColor : .secondary)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isHovered ? .accentColor : .secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(chipBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(chipBorder, lineWidth: 0.5)
                )
        )
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }
}
