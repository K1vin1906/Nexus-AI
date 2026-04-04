//
//  PreferencesView.swift
//  macai
//
//  Created by Renat Notfullin on 11.03.2023.
//  A6 设置页现代化 — K1vin 2026-04-05
//

import Foundation
import SwiftUI

struct APIRequestData: Codable {
    let model: String
    let messages = [
        [
            "role": "system",
            "content": "You are ChatGPT, a large language model trained by OpenAI. Say hi, if you're there",
        ]
    ]
}

// MARK: - Settings Section Enum

enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case apiServices = "API Services"
    case aiAssistants = "AI Assistants"
    case backupRestore = "Backup & Restore"
    case mcpServers = "MCP Servers"
    case dangerZone = "Danger Zone"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gearshape.fill"
        case .apiServices: return "network"
        case .aiAssistants: return "person.2.fill"
        case .backupRestore: return "externaldrive.fill"
        case .mcpServers: return "puzzlepiece.extension.fill"
        case .dangerZone: return "exclamationmark.triangle.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .general: return .nexusPurple
        case .apiServices: return .nexusCyan
        case .aiAssistants: return .blue
        case .backupRestore: return .green
        case .mcpServers: return .orange
        case .dangerZone: return .red
        }
    }
}

// MARK: - Modern Preferences View

struct PreferencesView: View {
    @StateObject private var store = ChatStore(persistenceController: PersistenceController.shared)
    @State private var selectedSection: SettingsSection = .general
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationSplitView {
            settingsSidebar
        } detail: {
            settingsDetail
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 720, height: 520)
        .onAppear {
            store.saveInCoreData()
            if let window = NSApp.mainWindow {
                window.standardWindowButton(.zoomButton)?.isEnabled = false
            }
        }
    }

    // MARK: - Sidebar

    private var settingsSidebar: some View {
        List(SettingsSection.allCases, selection: $selectedSection) { section in
            HStack(spacing: 10) {
                Image(systemName: section.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(section.iconColor)
                    .frame(width: 22, height: 22)

                Text(section.rawValue)
                    .font(.system(size: 13))
            }
            .padding(.vertical, 3)
            .tag(section)
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 180, ideal: 190, max: 220)
    }

    // MARK: - Detail Content

    @ViewBuilder
    private var settingsDetail: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Section Header
                settingSectionHeader(selectedSection)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                // Section Content
                Group {
                    switch selectedSection {
                    case .general:
                        TabGeneralSettingsView()
                    case .apiServices:
                        TabAPIServicesView()
                    case .aiAssistants:
                        TabAIPersonasView()
                    case .backupRestore:
                        BackupRestoreView(store: store)
                    case .mcpServers:
                        TabMCPServersView()
                    case .dangerZone:
                        DangerZoneView(store: store)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Section Header

    private func settingSectionHeader(_ section: SettingsSection) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(section.iconColor.opacity(colorScheme == .dark ? 0.2 : 0.12))
                    .frame(width: 32, height: 32)

                Image(systemName: section.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(section.iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(section.rawValue)
                    .font(.system(size: 18, weight: .semibold))
                Text(sectionSubtitle(section))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private func sectionSubtitle(_ section: SettingsSection) -> String {
        switch section {
        case .general: return "Appearance, fonts, theme, and updates"
        case .apiServices: return "Configure AI model providers"
        case .aiAssistants: return "Manage AI persona presets"
        case .backupRestore: return "Backup, restore, and export data"
        case .mcpServers: return "Connect AI to local tools via MCP"
        case .dangerZone: return "Irreversible destructive actions"
        }
    }
}
