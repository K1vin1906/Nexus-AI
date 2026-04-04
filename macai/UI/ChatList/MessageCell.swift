//
//  MessageCell.swift
//  macai
//
//  Created by Renat Notfullin on 25.03.2023.
//  Redesigned for Nexus AI v1.2 — A2 Sidebar
//

import CoreData
import SwiftUI

struct MessageCell: View, Equatable {
    static func == (lhs: MessageCell, rhs: MessageCell) -> Bool {
        lhs.chatObjectID == rhs.chatObjectID &&
        lhs.timestamp == rhs.timestamp &&
        lhs.message == rhs.message &&
        lhs.showsAttentionIndicator == rhs.showsAttentionIndicator &&
        lhs.$isActive.wrappedValue == rhs.$isActive.wrappedValue &&
        lhs.isPinned == rhs.isPinned &&
        lhs.searchText == rhs.searchText &&
        lhs.providerType == rhs.providerType
    }

    let chatObjectID: NSManagedObjectID
    let personaName: String?
    let chatName: String
    @State var timestamp: Date
    var message: String
    let showsAttentionIndicator: Bool
    let isPinned: Bool
    @Binding var isActive: Bool
    let searchText: String
    let providerType: String?
    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme

    private var filteredMessage: String {
        if !message.starts(with: "<think>") {
            return message
        }
        let messageWithoutNewlines = message.replacingOccurrences(of: "\n", with: " ")
        let messageWithoutThinking = messageWithoutNewlines.replacingOccurrences(
            of: "<think>.*?</think>",
            with: "",
            options: .regularExpression
        )
        return messageWithoutThinking.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    var body: some View {
        Button {
            isActive = true
        } label: {
            HStack(spacing: 10) {
                // Provider icon badge
                ZStack {
                    Circle()
                        .fill(
                            isActive
                                ? Color.white.opacity(0.2)
                                : NexusTheme.providerColor(for: providerType).opacity(0.15)
                        )
                        .frame(width: 34, height: 34)
                    Image(systemName: NexusTheme.providerIcon(for: providerType))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(
                            isActive
                                ? .white
                                : NexusTheme.providerColor(for: providerType)
                        )
                }

                VStack(alignment: .leading, spacing: 3) {
                    // Title row: chat name + timestamp
                    HStack {
                        if chatName != "" {
                            HighlightedText(chatName, highlight: searchText, elementType: "chatlist")
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        Spacer()

                        HStack(spacing: 5) {
                            if showsAttentionIndicator && !isActive {
                                ChatAttentionDot()
                            }
                            if isPinned {
                                Image(systemName: "pin.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(isActive ? .white.opacity(0.7) : NexusTheme.Text.tertiary(colorScheme))
                            }
                            Text(relativeTime)
                                .font(.system(size: 11))
                                .foregroundColor(
                                    isActive
                                        ? .white.opacity(0.7)
                                        : NexusTheme.Text.tertiary(colorScheme)
                                )
                        }
                    }

                    // Persona subtitle
                    if let personaName {
                        HighlightedText(personaName, highlight: searchText, elementType: "chatlist")
                            .font(.system(size: 11))
                            .foregroundColor(isActive ? .white.opacity(0.7) : NexusTheme.Text.secondary(colorScheme))
                            .lineLimit(1)
                    }

                    // Message preview
                    if filteredMessage != "" {
                        if message.starts(with: "<image-uuid>") {
                            Text("🖼️ Image")
                                .font(.system(size: 12))
                                .foregroundColor(isActive ? .white.opacity(0.6) : NexusTheme.Text.secondary(colorScheme))
                                .lineLimit(1)
                        } else {
                            HighlightedText(filteredMessage, highlight: searchText, elementType: "chatlist")
                                .font(.system(size: 12))
                                .foregroundColor(isActive ? .white.opacity(0.6) : NexusTheme.Text.secondary(colorScheme))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(isActive ? .white : NexusTheme.Text.primary(colorScheme))
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(cellBackground)
            )
            .onHover { hovering in
                isHovered = hovering
            }
        }
        .buttonStyle(.borderless)
        .background(Color.clear)
    }

    private var cellBackground: Color {
        if isActive {
            return Color.nexusPurple
        } else if isHovered {
            return NexusTheme.Sidebar.rowHover(colorScheme)
        } else {
            return Color.clear
        }
    }
}

private struct ChatAttentionDot: View {
    var body: some View {
        Circle()
            .fill(Color.nexusCyan)
            .frame(width: 7, height: 7)
            .shadow(color: Color.nexusCyan.opacity(0.5), radius: 2, x: 0, y: 0)
            .accessibilityLabel("New response")
    }
}

struct MessageCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            previewCell(name: "Regular Chat", message: "Hello!", isActive: false, isPinned: false, provider: "gemini")
            previewCell(name: "Selected Chat", message: "This is selected", isActive: true, isPinned: true, provider: "claude")
            previewCell(name: "Long Message", message: "This is a very long message that should truncate", isActive: false, isPinned: false, provider: "deepseek")
        }
        .previewLayout(.fixed(width: 280, height: 80))
    }

    static func previewCell(name: String, message: String, isActive: Bool, isPinned: Bool, provider: String) -> some View {
        let chat = createPreviewChat(name: name, isPinned: isPinned)
        return MessageCell(
            chatObjectID: chat.objectID,
            personaName: "Default Assistant",
            chatName: name,
            timestamp: Date(),
            message: message,
            showsAttentionIndicator: false,
            isPinned: isPinned,
            isActive: .constant(isActive),
            searchText: "",
            providerType: provider
        )
    }

    static func createPreviewChat(name: String, isPinned: Bool) -> ChatEntity {
        let context = PersistenceController.preview.container.viewContext
        let chat = ChatEntity(context: context)
        chat.id = UUID()
        chat.name = name
        chat.isPinned = isPinned
        chat.createdDate = Date()
        chat.updatedDate = Date()
        chat.systemMessage = AppConstants.chatGptSystemMessage
        chat.gptModel = AppConstants.defaultPrimaryModel
        chat.lastSequence = 0
        return chat
    }
}
