//
//  SummarizeIntent.swift
//  macai
//
//  Created for Nexus AI — Apple Shortcuts Integration
//

import AppIntents
import Foundation

/// Summarize a piece of text using AI.
struct SummarizeIntent: AppIntent {
    static var title: LocalizedStringResource = "Summarize with AI"
    static var description = IntentDescription("Summarize text content using AI.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Text to Summarize")
    var text: String

    @Parameter(title: "Provider", default: "gemini")
    var provider: String

    static var parameterSummary: some ParameterSummary {
        Summary("Summarize \(\.$text) using \(\.$provider)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let response = try await IntentAIService.shared.ask(
            question: "Please summarize the following text concisely:\n\n\(text)",
            provider: provider,
            systemPrompt: "You are an expert summarizer. Provide clear, concise summaries."
        )
        return .result(value: response)
    }
}

/// Translate text using AI.
struct TranslateIntent: AppIntent {
    static var title: LocalizedStringResource = "Translate with AI"
    static var description = IntentDescription("Translate text to another language using AI.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Text to Translate")
    var text: String

    @Parameter(title: "Target Language", default: "English")
    var targetLanguage: String

    @Parameter(title: "Provider", default: "gemini")
    var provider: String

    static var parameterSummary: some ParameterSummary {
        Summary("Translate \(\.$text) to \(\.$targetLanguage) using \(\.$provider)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let response = try await IntentAIService.shared.ask(
            question: "Translate the following text to \(targetLanguage). Output only the translation, nothing else.\n\n\(text)",
            provider: provider,
            systemPrompt: "You are a professional translator. Output only the translation."
        )
        return .result(value: response)
    }
}
