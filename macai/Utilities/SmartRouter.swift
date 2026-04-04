//
//  SmartRouter.swift
//  Nexus AI
//
//  Created by K1vin on 2026-04-04.
//  v1.5 — B3 Smart Routing
//

import Foundation
import CoreData

// MARK: - Query Category

enum QueryCategory: String, CaseIterable {
    case code           = "code"
    case imageAnalysis   = "image_analysis"
    case imageGeneration = "image_generation"
    case translation    = "translation"
    case math           = "math"
    case search         = "search"
    case general        = "general"

    var displayName: String {
        switch self {
        case .code:            return "Code"
        case .imageAnalysis:   return "Image Analysis"
        case .imageGeneration: return "Image Generation"
        case .translation:     return "Translation"
        case .math:            return "Math"
        case .search:          return "Search"
        case .general:         return "General"
        }
    }

    /// Preferred provider types in priority order for each category
    var preferredProviders: [String] {
        switch self {
        case .code:
            return ["deepseek", "claude", "openai-responses", "gemini"]
        case .imageAnalysis:
            return ["gemini", "openai-responses", "openrouter", "claude"]
        case .imageGeneration:
            return ["gemini", "openai-responses"]
        case .translation:
            return ["deepseek", "gemini", "claude", "openai-responses"]
        case .math:
            return ["deepseek", "claude", "openai-responses", "gemini"]
        case .search:
            return ["perplexity", "gemini", "openai-responses"]
        case .general:
            return []  // use default
        }
    }
}

// MARK: - Smart Router

class SmartRouter {
    static let shared = SmartRouter()

    @UserDefaultsBacked(key: "smartRoutingEnabled", defaultValue: false)
    var isEnabled: Bool

    // MARK: - Classification

    /// Classify a user message into a category
    func classify(_ text: String, hasImages: Bool = false, hasFiles: Bool = false) -> QueryCategory {
        // Image attachments → image analysis
        if hasImages {
            return .imageAnalysis
        }

        let lower = text.lowercased()

        // Image generation detection
        if matchesImageGeneration(lower) {
            return .imageGeneration
        }

        // Code detection (highest signal patterns)
        if matchesCode(lower) {
            return .code
        }

        // Translation detection
        if matchesTranslation(lower) {
            return .translation
        }

        // Math detection
        if matchesMath(lower) {
            return .math
        }

        // Search / real-time info detection
        if matchesSearch(lower) {
            return .search
        }

        return .general
    }

    // MARK: - Resolve Best Provider

    /// Find the best available APIServiceEntity for a given category
    func resolve(
        category: QueryCategory,
        availableServices: [APIServiceEntity],
        currentService: APIServiceEntity?
    ) -> APIServiceEntity? {
        guard isEnabled, category != .general else { return nil }

        let preferred = category.preferredProviders
        guard !preferred.isEmpty else { return nil }

        // Check if current service is already optimal
        if let current = currentService,
           let currentType = current.type,
           preferred.first == currentType {
            return nil  // already on the best provider
        }

        // Find the first available preferred provider that has an API key
        for providerType in preferred {
            if let service = availableServices.first(where: {
                $0.type == providerType && Self.serviceHasToken(service: $0)
            }) {
                // Don't switch if already on this provider
                if service.objectID == currentService?.objectID { return nil }
                return service
            }
        }

        return nil  // no better option available
    }

    /// Check if a service has a token configured (ollama doesn't need one)
    private static func serviceHasToken(service: APIServiceEntity) -> Bool {
        if service.type == "ollama" { return true }
        guard let serviceId = service.id?.uuidString else { return false }
        let token = try? TokenManager.getToken(for: "apiService", identifier: serviceId)
        return token != nil && !(token?.isEmpty ?? true)
    }

    // MARK: - Pattern Matchers

    private func matchesCode(_ text: String) -> Bool {
        let codeKeywords = [
            "write code", "write a function", "write a script", "debug", "refactor",
            "implement", "algorithm", "compile", "syntax error", "stack trace",
            "api endpoint", "unit test", "pull request", "git ", "docker",
            "def ", "func ", "class ", "import ", "return ", "async ", "await ",
            "写代码", "写一个函数", "编程", "调试", "重构", "代码",
            "```", "function(", "=>", "int main", "#include", "println",
        ]
        let codePatterns = [
            "\\b(python|swift|java|kotlin|rust|typescript|javascript|go|ruby|php|c\\+\\+|html|css|sql)\\b",
            "\\b(npm|pip|brew|cargo|yarn|pod)\\s+(install|add|update)",
        ]
        if codeKeywords.contains(where: { text.contains($0) }) { return true }
        for pattern in codePatterns {
            if text.range(of: pattern, options: .regularExpression) != nil { return true }
        }
        return false
    }

    private func matchesImageGeneration(_ text: String) -> Bool {
        let keywords = [
            "generate an image", "generate image", "create an image", "draw ",
            "画一", "画个", "生成图", "生成一张", "make a picture", "design a logo",
            "illustration of", "render a", "create a poster", "generate a photo",
        ]
        return keywords.contains(where: { text.contains($0) })
    }

    private func matchesTranslation(_ text: String) -> Bool {
        let keywords = [
            "translate", "翻译", "translation",
            "translate to", "translate into", "translate from",
            "翻译成", "翻译为", "用中文", "用英文", "in english", "in chinese",
            "in japanese", "in korean", "in french", "in spanish", "in german",
        ]
        return keywords.contains(where: { text.contains($0) })
    }

    private func matchesMath(_ text: String) -> Bool {
        let keywords = [
            "calculate", "计算", "solve", "求解", "integral", "积分",
            "derivative", "导数", "equation", "方程", "matrix", "矩阵",
            "proof", "证明", "probability", "概率", "statistics", "统计",
        ]
        // Also detect math-heavy expressions
        let mathPattern = "\\d+\\s*[+\\-*/^=]\\s*\\d+"
        if text.range(of: mathPattern, options: .regularExpression) != nil { return true }
        return keywords.contains(where: { text.contains($0) })
    }

    private func matchesSearch(_ text: String) -> Bool {
        let keywords = [
            "latest news", "最新", "current price", "当前价格",
            "what happened today", "今天发生", "search for", "搜索",
            "weather", "天气", "stock price", "股价",
            "who won", "谁赢了", "score of", "比分",
        ]
        return keywords.contains(where: { text.contains($0) })
    }
}

// MARK: - UserDefaults Property Wrapper

extension Notification.Name {
    static let smartRouteApplied = Notification.Name("smartRouteApplied")
}

@propertyWrapper
struct UserDefaultsBacked<Value> {
    let key: String
    let defaultValue: Value

    var wrappedValue: Value {
        get { UserDefaults.standard.object(forKey: key) as? Value ?? defaultValue }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}
