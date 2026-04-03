//
//  IntentAIService.swift
//  macai
//
//  Created for Nexus AI — Shared AI service for App Intents
//

import CoreData
import Foundation

/// A lightweight AI service for App Intents.
/// Reads API configuration from CoreData and calls the appropriate provider.
class IntentAIService {
    static let shared = IntentAIService()

    func ask(question: String, provider: String, systemPrompt: String) async throws -> String {
        let config = try resolveConfig(for: provider)
        let service = APIServiceFactory.createAPIService(config: config)

        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": question]
        ]

        // Collect the full streamed response
        var result = ""
        let stream = try await service.sendMessageStream(messages, temperature: 0.7)
        for try await chunk in stream {
            result += chunk
        }

        guard !result.isEmpty else {
            throw IntentAIError.emptyResponse
        }

        return result
    }

    // MARK: - Config Resolution

    private func resolveConfig(for providerName: String) throws -> APIServiceConfiguration {
        let viewContext = PersistenceController.shared.container.viewContext
        let fetchRequest = NSFetchRequest<APIServiceEntity>(entityName: "APIServiceEntity")
        fetchRequest.predicate = NSPredicate(format: "type == %@", providerName)
        fetchRequest.fetchLimit = 1

        var config: APIServiceConfiguration?

        viewContext.performAndWait {
            if let service = try? viewContext.fetch(fetchRequest).first,
               let url = service.url,
               let serviceId = service.id {
                let apiKey = (try? TokenManager.getToken(for: serviceId.uuidString)) ?? ""
                let model = service.model ?? AppConstants.defaultModel(for: service.type)
                config = APIServiceConfig(
                    name: service.type ?? providerName,
                    apiUrl: url,
                    apiKey: apiKey,
                    model: model
                )
            }
        }

        guard let resolved = config else {
            throw IntentAIError.noProviderConfigured(providerName)
        }

        guard let cfg = resolved as? APIServiceConfig, !cfg.apiKey.isEmpty else {
            throw IntentAIError.noAPIKey(providerName)
        }

        return resolved
    }
}

// MARK: - Errors

enum IntentAIError: LocalizedError {
    case noProviderConfigured(String)
    case noAPIKey(String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .noProviderConfigured(let name):
            return "No \(name) API service configured. Please set it up in the app first."
        case .noAPIKey(let name):
            return "No API key found for \(name). Please add your API key in Settings."
        case .emptyResponse:
            return "AI returned an empty response."
        }
    }
}
