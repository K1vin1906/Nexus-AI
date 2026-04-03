//
//  NexusAIShortcuts.swift
//  macai
//
//  Created for Nexus AI — Register App Shortcuts
//

import AppIntents

/// Provides pre-built shortcuts that appear in the Shortcuts app.
struct NexusAIShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AskAIIntent(),
            phrases: [
                "Ask \(.applicationName) a question",
                "Ask \(.applicationName)",
                "Quick question for \(.applicationName)"
            ],
            shortTitle: "Ask AI",
            systemImageName: "brain.head.profile"
        )

        AppShortcut(
            intent: SummarizeIntent(),
            phrases: [
                "Summarize with \(.applicationName)",
                "Use \(.applicationName) to summarize"
            ],
            shortTitle: "Summarize",
            systemImageName: "text.badge.checkmark"
        )

        AppShortcut(
            intent: TranslateIntent(),
            phrases: [
                "Translate with \(.applicationName)",
                "Use \(.applicationName) to translate"
            ],
            shortTitle: "Translate",
            systemImageName: "globe"
        )
    }
}
