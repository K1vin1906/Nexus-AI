//
//  QuickInputView.swift
//  macai
//
//  Created for Nexus AI
//

import SwiftUI
import CoreData
import PDFKit
import UniformTypeIdentifiers

/// The SwiftUI view rendered inside QuickPanelWindow.
/// Provides a compact input field with model selector and multi-turn streaming conversation.
struct QuickPanelMessage: Identifiable {
    let id = UUID()
    let role: String      // "user" or "assistant"
    let content: String
    let timestamp: Date
}

struct QuickInputView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var inputText: String = ""
    @State private var currentStreamText: String = ""
    @State private var isLoading: Bool = false
    @State private var conversationMessages: [QuickPanelMessage] = []
    @State private var selectedProviderName: String = "gemini"
    @ObservedObject private var clipboardMonitor = ClipboardMonitor.shared
    @ObservedObject private var privacyMode = PrivacyModeManager.shared
    @State private var droppedFileContent: String = ""
    @State private var droppedFileName: String = ""
    @State private var isDragOver: Bool = false
    @State private var savedChatEntity: ChatEntity? = nil

    var onOpenInMainWindow: ((String) -> Void)?
    var onDismiss: (() -> Void)?

    private let panelWidth: CGFloat = 560
    private let maxResponseHeight: CGFloat = 300

    var body: some View {
        VStack(spacing: 0) {
            // Top: Input area
            HStack(spacing: 8) {
                // Privacy mode toggle
                privacyToggle

                // Model indicator (disabled in privacy mode)
                if !privacyMode.isEnabled {
                    modelIndicator
                }

                // Clipboard paste button
                clipboardButton

                // Text input
                TextField(conversationMessages.isEmpty ? "Ask anything... (⌥Space)" : "Follow up...", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .onSubmit {
                        sendMessage()
                    }

                // Send / Loading indicator
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 24, height: 24)
                } else {
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(inputText.isEmpty ? .secondary : .accentColor)
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.isEmpty)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // File attachment indicator
            if !droppedFileName.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: fileIcon(for: droppedFileName))
                        .font(.system(size: 11))
                        .foregroundColor(.accentColor)
                    Text(droppedFileName)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Text("(\(droppedFileContent.count) chars)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.7))
                    Spacer()
                    Button(action: clearAttachment) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.08))
            }

            // Conversation thread (shown when there are messages)
            if !conversationMessages.isEmpty || isLoading {
                Divider()

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(conversationMessages) { msg in
                                QuickPanelBubble(message: msg)
                                    .id(msg.id)
                            }
                            // Show streaming response
                            if isLoading && !currentStreamText.isEmpty {
                                QuickPanelBubble(message: QuickPanelMessage(
                                    role: "assistant",
                                    content: currentStreamText,
                                    timestamp: Date()
                                ))
                                .id("streaming")
                            } else if isLoading && currentStreamText.isEmpty {
                                HStack(spacing: 6) {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                    Text("Thinking...")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .id("thinking")
                            }
                        }
                        .padding(12)
                    }
                    .frame(maxHeight: maxResponseHeight)
                    .onChange(of: conversationMessages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(conversationMessages.last?.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: currentStreamText) { _ in
                        withAnimation {
                            proxy.scrollTo("streaming", anchor: .bottom)
                        }
                    }
                }

                Divider()

                // Bottom bar: actions
                HStack {
                    Button(action: copyLastResponse) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .disabled(conversationMessages.isEmpty)

                    Spacer()

                    // Turn count
                    Text("\(conversationMessages.filter { $0.role == "user" }.count) turns")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.6))

                    Spacer()
                    
                    Button(action: resetConversation) {
                        Label("New Chat", systemImage: "plus.circle")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)

                    Spacer()

                    Button(action: { onOpenInMainWindow?(inputText) }) {
                        Label("Open in Main", systemImage: "arrow.up.forward.square")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .frame(width: panelWidth)
        .background(VisualEffectBlur())
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isDragOver ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onDrop(of: [UTType.fileURL, UTType.plainText], isTargeted: $isDragOver) { providers in
            handleFileDrop(providers)
        }
    }

    // MARK: - Privacy Toggle

    private var privacyToggle: some View {
        Button(action: { privacyMode.isEnabled.toggle() }) {
            HStack(spacing: 3) {
                Image(systemName: privacyMode.isEnabled ? "lock.fill" : "lock.open")
                    .font(.system(size: 11))
                if privacyMode.isEnabled {
                    Text("Local")
                        .font(.system(size: 11, weight: .medium))
                }
            }
            .foregroundColor(privacyMode.isEnabled ? .green : .secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(privacyMode.isEnabled ? Color.green.opacity(0.15) : Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .help(privacyMode.isEnabled ? "Privacy Mode ON — Using local Ollama" : "Privacy Mode OFF — Click to enable")
    }

    // MARK: - Clipboard Button

    private var clipboardButton: some View {
        Button(action: pasteClipboard) {
            HStack(spacing: 3) {
                Image(systemName: clipboardMonitor.hasNewContent ? "clipboard.fill" : "clipboard")
                    .font(.system(size: 12))
                if clipboardMonitor.lastContentType != .empty {
                    Text(clipboardMonitor.lastContentType == .text ? "Paste" : clipboardMonitor.lastTextPreview)
                        .font(.system(size: 11))
                        .lineLimit(1)
                }
            }
            .foregroundColor(clipboardMonitor.hasNewContent ? .accentColor : .secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(clipboardMonitor.hasNewContent ? Color.accentColor.opacity(0.15) : Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .help("Paste clipboard content as question")
    }

    // MARK: - Model Indicator

    private var modelIndicator: some View {
        Menu {
            ForEach(availableProviders, id: \.self) { provider in
                Button(action: { selectedProviderName = provider }) {
                    HStack {
                        Text(displayName(for: provider))
                        if provider == selectedProviderName {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Circle()
                    .fill(providerColor(for: selectedProviderName))
                    .frame(width: 8, height: 8)
                Text(displayName(for: selectedProviderName))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userContent = buildUserMessage()
        
        // Add user message to conversation
        let userMsg = QuickPanelMessage(role: "user", content: userContent, timestamp: Date())
        conversationMessages.append(userMsg)
        
        // Clear input for next message
        let sentText = inputText
        inputText = ""
        droppedFileName = ""
        droppedFileContent = ""
        
        isLoading = true
        currentStreamText = ""
        
        // Give SwiftUI a moment to layout, then resize
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.resizePanel()
        }

        // Find the first APIService matching selected provider
        let effectiveProvider = privacyMode.isEnabled ? "ollama" : selectedProviderName
        let config = resolveAPIConfig(for: effectiveProvider)
        
        guard !config.apiKey.isEmpty || effectiveProvider == "ollama" else {
            let errorMsg = QuickPanelMessage(
                role: "assistant",
                content: "⚠️ No API key found for \(displayName(for: effectiveProvider)). Please configure it in Settings → API Services.",
                timestamp: Date()
            )
            conversationMessages.append(errorMsg)
            isLoading = false
            resizePanel()
            return
        }
        
        let service = APIServiceFactory.createAPIService(config: config)

        // Build full conversation context
        var messages: [[String: String]] = [
            ["role": "system", "content": "You are a helpful assistant. Be concise."]
        ]
        for msg in conversationMessages {
            messages.append(["role": msg.role, "content": msg.content])
        }

        Task {
            do {
                let stream = try await service.sendMessageStream(messages, temperature: 0.7)
                for try await chunk in stream {
                    await MainActor.run {
                        currentStreamText += chunk
                        resizePanel()
                    }
                }
                await MainActor.run {
                    // Add completed response to conversation
                    let assistantMsg = QuickPanelMessage(
                        role: "assistant",
                        content: currentStreamText,
                        timestamp: Date()
                    )
                    conversationMessages.append(assistantMsg)
                    currentStreamText = ""
                    isLoading = false
                    resizePanel()
                    // Save/update conversation in main chat list
                    saveToMainChatList()
                }
            } catch {
                await MainActor.run {
                    let errorMsg = QuickPanelMessage(
                        role: "assistant",
                        content: "Error: \(error.localizedDescription)",
                        timestamp: Date()
                    )
                    conversationMessages.append(errorMsg)
                    currentStreamText = ""
                    isLoading = false
                    resizePanel()
                }
            }
        }
    }

    private func copyLastResponse() {
        guard let lastAssistant = conversationMessages.last(where: { $0.role == "assistant" }) else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(lastAssistant.content, forType: .string)
    }

    /// Reset to start a new conversation
    private func resetConversation() {
        inputText = ""
        currentStreamText = ""
        conversationMessages = []
        isLoading = false
        droppedFileName = ""
        droppedFileContent = ""
        savedChatEntity = nil
        // Shrink panel back to compact size
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            resizePanel()
        }
    }

    /// Build the user message, optionally including file content
    private func buildUserMessage() -> String {
        if droppedFileContent.isEmpty {
            return inputText
        }
        return "\(inputText)\n\n--- File: \(droppedFileName) ---\n\(droppedFileContent)"
    }

    // MARK: - Sync to Main Chat List

    /// Save or update the Quick Panel conversation in CoreData
    private func saveToMainChatList() {
        guard !conversationMessages.isEmpty else { return }
        
        let firstUserMsg = conversationMessages.first(where: { $0.role == "user" })?.content ?? ""
        
        // Find the API service for this provider
        let fetchRequest = NSFetchRequest<APIServiceEntity>(entityName: "APIServiceEntity")
        fetchRequest.predicate = NSPredicate(format: "type == %@", selectedProviderName)
        fetchRequest.fetchLimit = 1
        let apiService = try? viewContext.fetch(fetchRequest).first

        let chat: ChatEntity
        if let existing = savedChatEntity {
            // Update existing chat
            chat = existing
            // Remove old messages
            if let oldMessages = chat.messages as? Set<MessageEntity> {
                for msg in oldMessages {
                    viewContext.delete(msg)
                }
            }
        } else {
            // Create new chat
            chat = ChatEntity(context: viewContext)
            chat.id = UUID()
            chat.newChat = false
            chat.temperature = 0.7
            chat.top_p = 1.0
            chat.behavior = "default"
            chat.draftMessage = ""
            chat.createdDate = Date()
            chat.systemMessage = "You are a helpful assistant. Be concise."
            chat.gptModel = apiService?.model ?? AppConstants.defaultModel(for: selectedProviderName)
            chat.apiService = apiService
            chat.persona = apiService?.defaultPersona

            // Generate chat name from first user message
            let namePreview = String(firstUserMsg.prefix(30))
            chat.name = "⚡ \(namePreview)\(firstUserMsg.count > 30 ? "..." : "")"
            
            savedChatEntity = chat
        }
        
        chat.updatedDate = Date()
        chat.lastSequence = Int64(conversationMessages.count)

        // Re-create all messages
        for (index, msg) in conversationMessages.enumerated() {
            let messageEntity = MessageEntity(context: viewContext)
            messageEntity.id = Int64(index + 1)
            messageEntity.sequence = Int64(index + 1)
            messageEntity.body = msg.content
            messageEntity.own = (msg.role == "user")
            messageEntity.timestamp = msg.timestamp
            messageEntity.waitingForResponse = false
            if msg.role == "assistant" {
                messageEntity.name = displayName(for: selectedProviderName)
            }
            messageEntity.chat = chat
            chat.addToMessages(messageEntity)
        }

        // Build requestMessages for conversation continuity
        var requestMessages: [[String: String]] = [
            ["role": "system", "content": "You are a helpful assistant. Be concise."]
        ]
        for msg in conversationMessages {
            requestMessages.append(["role": msg.role, "content": msg.content])
        }
        chat.requestMessages = requestMessages

        // Save
        do {
            try viewContext.save()
        } catch {
            print("QuickPanel: Failed to save conversation: \(error)")
        }
    }

    /// Paste clipboard content into the input field and optionally auto-send
    private func pasteClipboard() {
        guard let message = clipboardMonitor.buildClipboardMessage() else { return }
        
        if clipboardMonitor.lastContentType == .text {
            // For text: fill the input field so user can edit before sending
            if let text = clipboardMonitor.getClipboardText() {
                inputText = text
            }
        } else {
            // For images/files: set the full prompt and auto-send
            inputText = message
            sendMessage()
        }
        
        clipboardMonitor.hasNewContent = false
    }

    // MARK: - File Drop

    private func handleFileDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        // Try file URL first
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil)
                else { return }

                DispatchQueue.main.async {
                    self.loadFile(from: url)
                }
            }
            return true
        }

        // Fall back to plain text
        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, error in
                guard let text = item as? String else { return }
                DispatchQueue.main.async {
                    self.inputText = text
                }
            }
            return true
        }

        return false
    }

    private func loadFile(from url: URL) {
        let ext = url.pathExtension.lowercased()
        let fileName = url.lastPathComponent
        let maxChars = 15000  // limit to avoid huge prompts

        // Supported text-based file types
        let textExtensions = [
            "swift", "py", "js", "ts", "jsx", "tsx", "java", "kt", "go", "rs", "c", "cpp", "h", "m",
            "rb", "php", "html", "css", "scss", "json", "yaml", "yml", "toml", "xml", "sql",
            "sh", "bash", "zsh", "fish", "bat", "ps1",
            "txt", "md", "csv", "log", "conf", "cfg", "ini", "env",
            "dockerfile", "makefile", "gitignore"
        ]

        if textExtensions.contains(ext) || ext.isEmpty {
            // Read as text
            do {
                var content = try String(contentsOf: url, encoding: .utf8)
                if content.count > maxChars {
                    content = String(content.prefix(maxChars)) + "\n\n... (truncated at \(maxChars) chars)"
                }
                droppedFileContent = content
                droppedFileName = fileName
                if inputText.isEmpty {
                    inputText = "Please analyze this file:"
                }
                resizePanel()
            } catch {
                print("QuickPanel: Failed to read file: \(error)")
            }
        } else if ext == "pdf" {
            // Extract PDF text using PDFKit
            loadPDFText(from: url, fileName: fileName, maxChars: maxChars)
        } else {
            droppedFileName = fileName
            droppedFileContent = "(Binary file - cannot read as text)"
            if inputText.isEmpty {
                inputText = "I have a file: \(fileName). What can you tell me about this file type?"
            }
        }
    }

    private func loadPDFText(from url: URL, fileName: String, maxChars: Int) {
        guard let pdfDoc = PDFDocument(url: url) else {
            droppedFileName = fileName
            droppedFileContent = "(Could not read PDF)"
            return
        }

        var text = ""
        for i in 0..<min(pdfDoc.pageCount, 50) {  // limit to 50 pages
            if let page = pdfDoc.page(at: i), let pageText = page.string {
                text += pageText + "\n"
            }
            if text.count > maxChars { break }
        }

        if text.count > maxChars {
            text = String(text.prefix(maxChars)) + "\n\n... (truncated at \(maxChars) chars)"
        }

        droppedFileContent = text
        droppedFileName = fileName
        if inputText.isEmpty {
            inputText = "Please analyze this PDF:"
        }
        resizePanel()
    }

    private func clearAttachment() {
        droppedFileName = ""
        droppedFileContent = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            resizePanel()
        }
    }

    private func fileIcon(for filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "swift": return "swift"
        case "py": return "chevron.left.forwardslash.chevron.right"
        case "js", "ts", "jsx", "tsx": return "chevron.left.forwardslash.chevron.right"
        case "pdf": return "doc.richtext"
        case "md", "txt": return "doc.text"
        case "json", "yaml", "yml", "xml": return "curlybraces"
        case "csv": return "tablecells"
        default: return "doc"
        }
    }

    /// Resize the QuickPanelWindow to fit the current SwiftUI content
    private func resizePanel() {
        DispatchQueue.main.async {
            guard let window = NSApp.windows.first(where: { $0 is QuickPanelWindow }),
                  let contentView = window.contentView
            else { return }
            
            let fittingSize = contentView.fittingSize
            let currentFrame = window.frame
            // Grow downward from the top (keep top edge position)
            let newHeight = max(min(fittingSize.height, 500), 56)
            let newOriginY = currentFrame.origin.y + currentFrame.height - newHeight
            let newFrame = NSRect(
                x: currentFrame.origin.x,
                y: newOriginY,
                width: currentFrame.width,
                height: newHeight
            )
            window.setFrame(newFrame, display: true, animate: true)
        }
    }

    // MARK: - Provider Helpers

    private var availableProviders: [String] {
        // Return providers that have API keys configured
        // For now, return a static list; will be dynamic from CoreData later
        return ["gemini", "deepseek", "claude", "ollama"]
    }

    private func displayName(for provider: String) -> String {
        switch provider {
        case "gemini": return "Gemini"
        case "deepseek": return "DeepSeek"
        case "claude": return "Claude"
        case "ollama": return "Ollama"
        case "openai-responses": return "OpenAI"
        default: return provider.capitalized
        }
    }

    private func providerColor(for provider: String) -> Color {
        switch provider {
        case "gemini": return .blue
        case "deepseek": return .cyan
        case "claude": return .orange
        case "ollama": return .green
        case "openai-responses": return .mint
        default: return .gray
        }
    }

    /// Build an APIServiceConfiguration from CoreData or defaults
    private func resolveAPIConfig(for providerName: String) -> APIServiceConfiguration {
        // Fetch the first APIServiceEntity matching the provider type from CoreData
        let fetchRequest: NSFetchRequest<APIServiceEntity> = APIServiceEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "type == %@", providerName)
        fetchRequest.fetchLimit = 1

        do {
            let results = try viewContext.fetch(fetchRequest)
            if let service = results.first,
               let url = service.url,
               let serviceId = service.id {
                let apiKey = (try? TokenManager.getToken(for: serviceId.uuidString)) ?? ""
                let model = service.model ?? AppConstants.defaultModel(for: service.type)
                return APIServiceConfig(
                    name: service.type ?? providerName,
                    apiUrl: url,
                    apiKey: apiKey,
                    model: model
                )
            }
        } catch {
            print("QuickPanel: Error fetching API service: \(error)")
        }

        // Fallback to default configuration
        if let defaultConfig = AppConstants.defaultApiConfigurations[providerName] {
            return APIServiceConfig(
                name: providerName,
                apiUrl: URL(string: defaultConfig.url)!,
                apiKey: "",
                model: defaultConfig.defaultModel
            )
        }

        // Ultimate fallback
        return APIServiceConfig(
            name: providerName,
            apiUrl: URL(string: "https://generativelanguage.googleapis.com/v1beta/models")!,
            apiKey: "",
            model: "gemini-2.5-flash"
        )
    }
}

// MARK: - Chat Bubble for Quick Panel

struct QuickPanelBubble: View {
    let message: QuickPanelMessage
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            if message.role == "user" { Spacer(minLength: 40) }
            
            VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 13))
                    .textSelection(.enabled)
                    .foregroundColor(message.role == "user" ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(message.role == "user"
                                ? NexusThemeManager.shared.currentAccentColor
                                : (colorScheme == .dark
                                    ? Color.white.opacity(0.08)
                                    : Color.black.opacity(0.05)))
                    )
            }
            
            if message.role == "assistant" { Spacer(minLength: 40) }
        }
    }
}

// MARK: - Visual Effect Blur (macOS native blur background)

struct VisualEffectBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .hudWindow
        view.wantsLayer = true
        view.layer?.cornerRadius = 12
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
