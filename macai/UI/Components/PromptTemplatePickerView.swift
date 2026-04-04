//
//  PromptTemplatePickerView.swift
//  Nexus AI
//
//  Created by K1vin on 2026-04-04.
//  v1.5 — B4 Prompt Template Picker
//

import SwiftUI

struct PromptTemplatePickerView: View {
    @ObservedObject var manager = PromptTemplateManager.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedCategory: TemplateCategory? = nil
    @State private var searchText = ""
    @State private var showingAddSheet = false
    var onSelect: (PromptTemplate) -> Void
    var onDismiss: () -> Void

    private var filteredTemplates: [PromptTemplate] {
        var result = manager.templates
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Prompt Templates")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // Search
            TextField("Search templates...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))
                .padding(.horizontal, 12)
                .padding(.bottom, 6)

            // Category filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    categoryChip(nil, label: "All")
                    ForEach(TemplateCategory.allCases) { cat in
                        categoryChip(cat, label: cat.displayName)
                    }
                }
                .padding(.horizontal, 12)
            }
            .padding(.bottom, 6)

            Divider()

            // Template list
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filteredTemplates) { template in
                        templateRow(template)
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 300)
        }
        .frame(width: 340)
        .background(colorScheme == .dark
            ? Color(nsColor: .controlBackgroundColor)
            : Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .sheet(isPresented: $showingAddSheet) {
            PromptTemplateEditorView(onSave: { template in
                manager.add(template)
            })
        }
    }

    @ViewBuilder
    private func categoryChip(_ cat: TemplateCategory?, label: String) -> some View {
        let isSelected = selectedCategory == cat
        Button(action: { selectedCategory = cat }) {
            Text(label)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(isSelected
                        ? Color.nexusPurple.opacity(0.2)
                        : Color.secondary.opacity(0.1))
                )
                .foregroundColor(isSelected ? .nexusPurple : .secondary)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func templateRow(_ template: PromptTemplate) -> some View {
        Button(action: { onSelect(template) }) {
            HStack(spacing: 10) {
                Image(systemName: template.icon)
                    .font(.system(size: 14))
                    .foregroundColor(.nexusPurple)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.title)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    Text(template.content.prefix(60) + "...")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                if !template.isBuiltIn {
                    Button(action: { manager.delete(template) }) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.05))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Template Editor (Add/Edit)

struct PromptTemplateEditorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var category: TemplateCategory = .general
    @State private var icon = "text.bubble"
    var onSave: (PromptTemplate) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("New Prompt Template")
                .font(.headline)

            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)

            Picker("Category", selection: $category) {
                ForEach(TemplateCategory.allCases) { cat in
                    Text(cat.displayName).tag(cat)
                }
            }
            .pickerStyle(.segmented)

            TextEditor(text: $content)
                .font(.system(size: 13))
                .frame(minHeight: 120)
                .border(Color.secondary.opacity(0.2))

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    let template = PromptTemplate(
                        title: title,
                        content: content,
                        category: category,
                        icon: category.icon
                    )
                    onSave(template)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.isEmpty || content.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 400, height: 350)
    }
}
