//
//  WebSearchService.swift
//  macai
//
//  Created by K1vin on 2026-04-05.
//  Uses Gemini Google Search grounding as a search backend
//  for providers that lack native web search capability.
//

import CoreData
import Foundation
import KeychainAccess
import os.log

// MARK: - Search Result Model

struct WebSearchResult {
    let query: String
    let sources: [Source]
    let summary: String
    
    struct Source {
        let title: String
        let url: String
    }
    
    /// Format results for injection into a system prompt
    func formattedContext() -> String {
        guard !sources.isEmpty || !summary.isEmpty else { return "" }
        var context = "\n\n---\n[Web Search Results for: \"\(query)\"]\n\n"
        
        if !summary.isEmpty {
            context += summary + "\n\n"
        }
        
        if !sources.isEmpty {
            context += "Sources:\n"
            for (i, source) in sources.prefix(5).enumerated() {
                context += "\(i + 1). \(source.title) — \(source.url)\n"
            }
        }
        
        context += "\n---\n"
        context += "Use the above web search results to provide an informed, "
        context += "up-to-date response. Cite sources when possible.\n"
        return context
    }
}

// MARK: - Gemini Search Request/Response (private)

private struct GeminiSearchRequest: Encodable {
    let contents: [GeminiSearchContent]
    let generationConfig: GeminiSearchGenConfig
    let tools: [GeminiSearchTool]
}

private struct GeminiSearchContent: Encodable {
    let role: String
    let parts: [GeminiSearchPart]
}

private struct GeminiSearchPart: Encodable {
    let text: String
}

private struct GeminiSearchGenConfig: Encodable {
    let temperature: Float
    let maxOutputTokens: Int
}

private struct GeminiSearchTool: Encodable {
    let googleSearch: GeminiGoogleSearchEmpty
    enum CodingKeys: String, CodingKey {
        case googleSearch = "google_search"
    }
}

private struct GeminiGoogleSearchEmpty: Encodable {}

// Response structs
private struct GeminiSearchResponse: Decodable {
    let candidates: [GeminiSearchCandidate]?
}

private struct GeminiSearchCandidate: Decodable {
    let content: GeminiSearchContentResp?
    let groundingMetadata: GeminiSearchGroundingMeta?
}

private struct GeminiSearchContentResp: Decodable {
    let parts: [GeminiSearchPartResp]?
}

private struct GeminiSearchPartResp: Decodable {
    let text: String?
}

private struct GeminiSearchGroundingMeta: Decodable {
    let groundingChunks: [GeminiSearchChunk]?
    let webSearchQueries: [String]?
}

private struct GeminiSearchChunk: Decodable {
    let web: GeminiSearchWebChunk?
}

private struct GeminiSearchWebChunk: Decodable {
    let uri: String?
    let title: String?
}

// MARK: - WebSearchService

@MainActor
class WebSearchService {
    static let shared = WebSearchService()
    
    private let logger = Logger(subsystem: "com.k1vin.nexusai", category: "WebSearch")
    private let session: URLSession = APIServiceFactory.session
    
    /// Providers that handle web search natively
    static let nativeSearchProviders: Set<String> = [
        "gemini", "perplexity", "openai-responses", "openai"
    ]
    
    nonisolated static func supportsNativeSearch(_ providerName: String) -> Bool {
        nativeSearchProviders.contains(providerName.lowercased())
    }
    
    // MARK: - Public Search API
    
    /// Perform a web search using Gemini Google Search grounding.
    /// Returns nil if Gemini API key is not available or search fails.
    func search(query: String) async -> WebSearchResult? {
        guard let apiKey = getGeminiAPIKey() else {
            logger.warning("No Gemini API key available for web search")
            return nil
        }
        
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15 // Keep search fast
        
        let searchPrompt = "Search the web for: \(query). Provide a brief, factual summary of the most relevant and recent information."
        
        let body = GeminiSearchRequest(
            contents: [
                GeminiSearchContent(
                    role: "user",
                    parts: [GeminiSearchPart(text: searchPrompt)]
                )
            ],
            generationConfig: GeminiSearchGenConfig(
                temperature: 0.1,
                maxOutputTokens: 1024
            ),
            tools: [GeminiSearchTool(googleSearch: GeminiGoogleSearchEmpty())]
        )
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                logger.error("Web search HTTP error")
                return nil
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let geminiResp = try decoder.decode(GeminiSearchResponse.self, from: data)
            
            guard let candidate = geminiResp.candidates?.first else {
                return nil
            }
            
            // Extract summary text
            let summary = candidate.content?.parts?
                .compactMap { $0.text }
                .joined(separator: "\n") ?? ""
            
            // Extract grounding sources
            let sources: [WebSearchResult.Source] = candidate.groundingMetadata?
                .groundingChunks?
                .compactMap { chunk in
                    guard let web = chunk.web,
                          let uri = web.uri,
                          let title = web.title else { return nil }
                    return WebSearchResult.Source(title: title, url: uri)
                } ?? []
            
            logger.info("Web search completed: \(sources.count) sources found")
            return WebSearchResult(query: query, sources: sources, summary: summary)
            
        } catch {
            logger.error("Web search failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Gemini API Key Retrieval
    
    /// Finds the Gemini API key by directly scanning the Keychain
    /// Bypasses CoreData entirely to avoid UUID mismatch issues
    private func getGeminiAPIKey() -> String? {
        let keychain = Keychain(service: TokenManager.keychainService)
        
        do {
            let allKeys = try keychain.allKeys()
            for key in allKeys where key.hasPrefix("api_token_") {
                if let token = try keychain.get(key),
                   !token.isEmpty,
                   token.hasPrefix("AIza") {
                    return token
                }
            }
        } catch {
            print("WebSearchService: Keychain scan failed: \(error)")
        }
        
        return nil
    }
}
