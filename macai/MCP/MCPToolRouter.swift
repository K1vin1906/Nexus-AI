//
//  MCPToolRouter.swift
//  macai
//
//  Created by K1vin on 2026-04-05.
//  Nexus AI v2.0 — D3 MCP Integration
//
//  Bridges MCP tools into the chat flow.
//  Injects tool descriptions into system prompts and
//  parses AI responses for tool call requests.

import Foundation
import MCP

@MainActor
class MCPToolRouter {
    static let shared = MCPToolRouter()

    private let manager = MCPClientManager.shared

    private init() {}

    // MARK: - System Prompt Injection

    /// Cached tools prompt — updated whenever tools change
    nonisolated(unsafe) private var _cachedToolsPrompt: String?

    /// Generate a tools description block to append to system prompts
    func toolsSystemPrompt() -> String? {
        let tools = manager.allTools
        guard !tools.isEmpty else {
            _cachedToolsPrompt = nil
            return nil
        }

        var prompt = "\n\n[MCP Tools Available]\n"
        prompt += "You have access to the following tools. "
        prompt += "To use a tool, respond with EXACTLY this format on its own line:\n"
        prompt += "<tool_call>{\"server\": \"SERVER_NAME\", \"tool\": \"TOOL_NAME\", \"arguments\": {ARGS_JSON}}</tool_call>\n"
        prompt += "Wait for the tool result before continuing.\n\n"

        for tool in tools {
            prompt += "- \(tool.serverName)::\(tool.name): \(tool.description)\n"
            prompt += "  Parameters: \(tool.inputSchemaJSON)\n\n"
        }
        _cachedToolsPrompt = prompt
        return prompt
    }

    /// Get cached tools prompt without MainActor requirement
    nonisolated func cachedToolsPrompt() -> String? {
        return _cachedToolsPrompt
    }

    // MARK: - Tool Call Parsing

    struct ToolCallRequest {
        let server: String
        let tool: String
        let arguments: [String: Any]
    }

    /// Parse a tool call from AI response text
    nonisolated func parseToolCall(from text: String) -> ToolCallRequest? {
        // Look for <tool_call>...</tool_call> pattern
        guard let startRange = text.range(of: "<tool_call>"),
              let endRange = text.range(of: "</tool_call>")
        else { return nil }

        let jsonStr = String(text[startRange.upperBound..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = jsonStr.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let server = json["server"] as? String,
              let tool = json["tool"] as? String
        else { return nil }

        let arguments = json["arguments"] as? [String: Any] ?? [:]
        return ToolCallRequest(server: server, tool: tool, arguments: arguments)
    }

    // MARK: - Execute Tool Call

    /// Execute a parsed tool call and return the result string
    func executeToolCall(_ request: ToolCallRequest) async throws -> String {
        // Convert [String: Any] arguments to MCP [String: Value]
        var mcpArgs: [String: Value] = [:]
        for (key, val) in request.arguments {
            mcpArgs[key] = anyToMCPValue(val)
        }

        return try await manager.callTool(
            serverName: request.server,
            toolName: request.tool,
            arguments: mcpArgs
        )
    }

    /// Check if response contains a tool call
    nonisolated func containsToolCall(_ text: String) -> Bool {
        return text.contains("<tool_call>") && text.contains("</tool_call>")
    }

    // MARK: - Format Tool Result

    /// Format a tool result to inject back into conversation
    nonisolated func formatToolResult(server: String, tool: String, result: String) -> String {
        return "<tool_result server=\"\(server)\" tool=\"\(tool)\">\n\(result)\n</tool_result>"
    }

    /// Strip tool_call tags from response for display
    nonisolated func cleanResponseForDisplay(_ text: String) -> String {
        var cleaned = text
        // Remove <tool_call>...</tool_call> blocks
        while let startRange = cleaned.range(of: "<tool_call>"),
              let endRange = cleaned.range(of: "</tool_call>") {
            let fullRange = startRange.lowerBound..<endRange.upperBound
            cleaned.removeSubrange(fullRange)
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Value Conversion

    private func anyToMCPValue(_ value: Any) -> Value {
        switch value {
        case let s as String:
            return .string(s)
        case let n as Int:
            return .int(n)
        case let n as Double:
            return .double(n)
        case let b as Bool:
            return .bool(b)
        case let arr as [Any]:
            return .array(arr.map { anyToMCPValue($0) })
        case let dict as [String: Any]:
            return .object(dict.mapValues { anyToMCPValue($0) })
        default:
            return .string(String(describing: value))
        }
    }
}
