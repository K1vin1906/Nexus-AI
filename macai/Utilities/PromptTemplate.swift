//
//  PromptTemplate.swift
//  Nexus AI
//
//  Created by K1vin on 2026-04-04.
//  v1.5 — B4 Prompt Template Library
//

import Foundation

// MARK: - Prompt Template Model

struct PromptTemplate: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var content: String
    var category: TemplateCategory
    var icon: String          // SF Symbol name
    var isBuiltIn: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        category: TemplateCategory = .general,
        icon: String = "text.bubble",
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
        self.icon = icon
        self.isBuiltIn = isBuiltIn
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Template Categories

enum TemplateCategory: String, Codable, CaseIterable, Identifiable {
    case coding     = "coding"
    case writing    = "writing"
    case analysis   = "analysis"
    case translation = "translation"
    case creative   = "creative"
    case general    = "general"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .coding:       return "Coding"
        case .writing:      return "Writing"
        case .analysis:     return "Analysis"
        case .translation:  return "Translation"
        case .creative:     return "Creative"
        case .general:      return "General"
        }
    }

    var icon: String {
        switch self {
        case .coding:       return "chevron.left.forwardslash.chevron.right"
        case .writing:      return "doc.text"
        case .analysis:     return "chart.bar"
        case .translation:  return "globe"
        case .creative:     return "paintbrush"
        case .general:      return "star"
        }
    }
}

// MARK: - Template Manager

class PromptTemplateManager: ObservableObject {
    static let shared = PromptTemplateManager()

    @Published var templates: [PromptTemplate] = []

    private let fileURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("macai", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("prompt_templates.json")
    }()

    init() {
        load()
        if templates.isEmpty {
            templates = Self.builtInTemplates
            save()
        }
    }

    // MARK: CRUD

    func add(_ template: PromptTemplate) {
        templates.append(template)
        save()
    }

    func update(_ template: PromptTemplate) {
        if let idx = templates.firstIndex(where: { $0.id == template.id }) {
            var updated = template
            updated.updatedAt = Date()
            templates[idx] = updated
            save()
        }
    }

    func delete(_ template: PromptTemplate) {
        templates.removeAll { $0.id == template.id }
        save()
    }

    func templates(for category: TemplateCategory) -> [PromptTemplate] {
        templates.filter { $0.category == category }
    }

    // MARK: Persistence

    private func save() {
        do {
            let data = try JSONEncoder().encode(templates)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save templates: \(error)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            templates = try JSONDecoder().decode([PromptTemplate].self, from: data)
        } catch {
            print("Failed to load templates: \(error)")
        }
    }

    // MARK: Built-in Templates

    static let builtInTemplates: [PromptTemplate] = [
        PromptTemplate(
            title: "Code Review",
            content: "Review the following code for bugs, performance issues, and best practices. Suggest improvements:\n\n```\n[paste code here]\n```",
            category: .coding, icon: "magnifyingglass", isBuiltIn: true
        ),
        PromptTemplate(
            title: "Explain Code",
            content: "Explain what the following code does, step by step:\n\n```\n[paste code here]\n```",
            category: .coding, icon: "questionmark.circle", isBuiltIn: true
        ),
        PromptTemplate(
            title: "Write Unit Tests",
            content: "Write comprehensive unit tests for the following code:\n\n```\n[paste code here]\n```",
            category: .coding, icon: "checkmark.shield", isBuiltIn: true
        ),
        PromptTemplate(
            title: "Summarize",
            content: "Summarize the following text concisely, keeping the key points:\n\n[paste text here]",
            category: .writing, icon: "doc.text", isBuiltIn: true
        ),
        PromptTemplate(
            title: "Improve Writing",
            content: "Improve the following text for clarity, grammar, and readability while keeping the original meaning:\n\n[paste text here]",
            category: .writing, icon: "pencil.and.outline", isBuiltIn: true
        ),
        PromptTemplate(
            title: "Email Draft",
            content: "Draft a professional email about the following topic:\n\nTopic: [describe topic]\nTone: [formal/casual/friendly]\nRecipient: [who is this for]",
            category: .writing, icon: "envelope", isBuiltIn: true
        ),
        PromptTemplate(
            title: "Translate to English",
            content: "Translate the following text to English. Preserve the original tone and style:\n\n[paste text here]",
            category: .translation, icon: "globe", isBuiltIn: true
        ),
        PromptTemplate(
            title: "Translate to Chinese",
            content: "将以下文本翻译成中文，保持原文的语气和风格：\n\n[paste text here]",
            category: .translation, icon: "globe", isBuiltIn: true
        ),
        PromptTemplate(
            title: "Data Analysis",
            content: "Analyze the following data and provide key insights, trends, and recommendations:\n\n[paste data here]",
            category: .analysis, icon: "chart.bar", isBuiltIn: true
        ),
        PromptTemplate(
            title: "Pros & Cons",
            content: "List the pros and cons of the following decision/option:\n\n[describe the decision]",
            category: .analysis, icon: "list.bullet.rectangle", isBuiltIn: true
        ),
        PromptTemplate(
            title: "Brainstorm Ideas",
            content: "Brainstorm 10 creative ideas for:\n\n[describe your project/problem]",
            category: .creative, icon: "lightbulb", isBuiltIn: true
        ),
        PromptTemplate(
            title: "ELI5",
            content: "Explain the following concept as if I'm 5 years old:\n\n[describe the concept]",
            category: .general, icon: "person.crop.circle.badge.questionmark", isBuiltIn: true
        ),
    ]
}
