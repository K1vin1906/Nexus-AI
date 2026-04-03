//
//  AskAIIntent.swift
//  macai
//
//  Created for Nexus AI — Apple Shortcuts Integration
//

import AppIntents
import CoreData
import Foundation

/// Ask AI a question and get a text response.
/// Available in Shortcuts as "Ask Nexus AI"
struct AskAIIntent: AppIntent {
    static var title: LocalizedStringResource = "Ask Nexus AI"
    static var description = IntentDescription("Ask AI a question and get a text response.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Question", description: "The question to ask AI")
    var question: String

    @Parameter(title: "Provider", default: "gemini",
               requestValueDialog: "Which AI provider?")
    var provider: String

    static var parameterSummary: some ParameterSummary {
        Summary("Ask \(\.$provider) about \(\.$question)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let response = try await IntentAIService.shared.ask(
            question: question,
            provider: provider,
            systemPrompt: "You are a helpful assistant. Be concise."
        )
        return .result(value: response)
    }
}
