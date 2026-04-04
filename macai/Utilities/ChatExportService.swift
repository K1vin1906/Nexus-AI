//
//  ChatExportService.swift
//  macai
//
//  Created by K1vin on 2026-04-04.
//  Nexus AI v1.1 — B6 Chat Export
//

import AppKit
import Foundation
import WebKit

enum ExportFormat {
    case markdown
    case html
    case pdf
}

class ChatExportService {

    static func export(chat: ChatEntity, format: ExportFormat) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.title = "Export Conversation"

        let chatName = sanitizeFilename(chat.name)

        switch format {
        case .markdown:
            panel.allowedContentTypes = [.plainText]
            panel.nameFieldStringValue = "\(chatName).md"
        case .html:
            panel.allowedContentTypes = [.html]
            panel.nameFieldStringValue = "\(chatName).html"
        case .pdf:
            panel.allowedContentTypes = [.pdf]
            panel.nameFieldStringValue = "\(chatName).pdf"
        }

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                switch format {
                case .markdown:
                    let content = generateMarkdown(chat: chat)
                    try content.write(to: url, atomically: true, encoding: .utf8)
                case .html:
                    let content = generateHTML(chat: chat)
                    try content.write(to: url, atomically: true, encoding: .utf8)
                case .pdf:
                    let htmlContent = generateHTML(chat: chat)
                    exportHTMLToPDF(html: htmlContent, outputURL: url)
                }
            } catch {
                print("Export failed: \(error)")
            }
        }
    }

    // MARK: - Markdown

    static func generateMarkdown(chat: ChatEntity) -> String {
        var md = "# \(chat.name)\n\n"
        md += "**Model:** \(chat.gptModel)\n"
        md += "**Date:** \(formatDate(chat.createdDate))\n\n"
        md += "---\n\n"

        for message in chat.messagesArray {
            let role = message.own ? "**You**" : "**\(message.name ?? "AI")**"
            let time = formatTime(message.timestamp)
            md += "\(role) · \(time)\n\n"
            md += "\(message.body)\n\n"
            md += "---\n\n"
        }

        return md
    }

    // MARK: - HTML

    static func generateHTML(chat: ChatEntity) -> String {
        let messages = chat.messagesArray
        var body = ""

        for message in messages {
            let role = message.own ? "You" : (message.name ?? "AI")
            let time = formatTime(message.timestamp)
            let cssClass = message.own ? "user" : "ai"
            let escapedBody = escapeHTML(message.body)
                .replacingOccurrences(of: "\n", with: "<br>")

            body += """
            <div class="message \(cssClass)">
              <div class="meta">\(role) · \(time)</div>
              <div class="body">\(escapedBody)</div>
            </div>
            """
        }

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>\(escapeHTML(chat.name))</title>
        <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, 'Helvetica Neue', sans-serif; background: #f5f5f7; color: #1d1d1f; padding: 24px; max-width: 800px; margin: 0 auto; }
        h1 { font-size: 24px; font-weight: 600; margin-bottom: 4px; }
        .header { margin-bottom: 24px; padding-bottom: 16px; border-bottom: 1px solid #d2d2d7; }
        .header .meta { font-size: 13px; color: #86868b; margin-top: 4px; }
        .message { margin-bottom: 16px; padding: 14px 18px; border-radius: 16px; }
        .message.user { background: \(NexusThemeManager.shared.currentAccentColor.hexString); color: #fff; margin-left: 60px; border-bottom-right-radius: 4px; }
        .message.ai { background: #fff; border: 1px solid #e5e5ea; margin-right: 60px; border-bottom-left-radius: 4px; }
        .message .meta { font-size: 11px; opacity: 0.7; margin-bottom: 6px; }
        .message.user .meta { color: rgba(255,255,255,0.7); }
        .message.ai .meta { color: #86868b; }
        .message .body { font-size: 14px; line-height: 1.6; white-space: pre-wrap; word-wrap: break-word; }
        .footer { margin-top: 24px; padding-top: 16px; border-top: 1px solid #d2d2d7; font-size: 12px; color: #86868b; text-align: center; }
        @media (prefers-color-scheme: dark) {
          body { background: #1c1c1e; color: #f5f5f7; }
          .header { border-color: #38383a; }
          .message.ai { background: #2c2c2e; border-color: #38383a; }
          .message.ai .meta { color: #98989d; }
          .footer { border-color: #38383a; color: #98989d; }
        }
        </style>
        </head>
        <body>
        <div class="header">
          <h1>\(escapeHTML(chat.name))</h1>
          <div class="meta">Model: \(chat.gptModel) · Exported \(formatDate(Date()))</div>
        </div>
        \(body)
        <div class="footer">Exported from Nexus AI</div>
        </body>
        </html>
        """
    }

    // MARK: - PDF Export

    private static var pdfWebView: WKWebView?

    static func exportHTMLToPDF(html: String, outputURL: URL) {
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 612, height: 792))
        pdfWebView = webView  // Retain until export completes
        webView.loadHTMLString(html, baseURL: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            webView.createPDF { result in
                switch result {
                case .success(let data):
                    do {
                        try data.write(to: outputURL)
                        NSWorkspace.shared.selectFile(outputURL.path, inFileViewerRootedAtPath: outputURL.deletingLastPathComponent().path)
                    } catch {
                        print("PDF write failed: \(error)")
                    }
                case .failure(let error):
                    print("PDF export failed: \(error)")
                }
                pdfWebView = nil  // Release
            }
        }
    }

    // MARK: - Helpers

    private static func sanitizeFilename(_ name: String) -> String {
        let cleaned = name
            .replacingOccurrences(of: "⚡ ", with: "")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "conversation" : String(cleaned.prefix(50))
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private static func escapeHTML(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
