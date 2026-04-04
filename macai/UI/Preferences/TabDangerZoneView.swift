//
//  TabDangerZoneView.swift
//  macai
//
//  Created by Renat Notfullin on 11.11.2023.
//  A6 设置页现代化 — K1vin 2026-04-05
//

import SwiftUI

struct DangerZoneView: View {
    @ObservedObject var store: ChatStore
    @State private var currentAlert: AlertType?
    @Environment(\.colorScheme) private var colorScheme

    enum AlertType: Identifiable {
        case deleteChats, deletePersonas, deleteAPIServices
        var id: Self { self }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("These actions are permanent and cannot be undone. Please proceed with caution.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            dangerCard(
                icon: "trash.fill",
                title: "Delete All Chats",
                description: "Remove all chat history, messages, and attachments.",
                buttonLabel: "Delete All Chats",
                action: { currentAlert = .deleteChats }
            )

            dangerCard(
                icon: "person.crop.circle.badge.minus",
                title: "Delete All AI Assistants",
                description: "Remove all custom AI persona presets.",
                buttonLabel: "Delete All Assistants",
                action: { currentAlert = .deletePersonas }
            )

            dangerCard(
                icon: "server.rack",
                title: "Delete All API Services",
                description: "Remove all API service configurations. API keys stored in Keychain will also be cleared.",
                buttonLabel: "Delete All Services",
                action: { currentAlert = .deleteAPIServices }
            )

            Spacer()
        }
        .alert(item: $currentAlert) { alertType in
            switch alertType {
            case .deleteChats:
                return Alert(
                    title: Text("Delete All Chats"),
                    message: Text("Are you sure you want to delete all chats? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        store.deleteAllChats()
                    },
                    secondaryButton: .cancel()
                )
            case .deletePersonas:
                return Alert(
                    title: Text("Delete All AI Assistants"),
                    message: Text("Are you sure you want to delete all AI Assistants?"),
                    primaryButton: .destructive(Text("Delete")) {
                        store.deleteAllPersonas()
                    },
                    secondaryButton: .cancel()
                )
            case .deleteAPIServices:
                return Alert(
                    title: Text("Delete All API Services"),
                    message: Text("Are you sure you want to delete all API Services?"),
                    primaryButton: .destructive(Text("Delete")) {
                        store.deleteAllAPIServices()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    // MARK: - Danger Card

    private func dangerCard(
        icon: String,
        title: String,
        description: String,
        buttonLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.red.opacity(0.7))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button(action: action) {
                Text(buttonLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.bordered)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.red.opacity(colorScheme == .dark ? 0.06 : 0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.red.opacity(colorScheme == .dark ? 0.15 : 0.1), lineWidth: 1)
        )
    }
}
