//
//  MCPClientManager.swift
//  macai
//
//  Created by K1vin on 2026-04-05.
//  Nexus AI v2.0 — D3 MCP Integration
//
//  Manages MCP client connections to multiple servers.
//  Discovers tools, calls tools, and manages lifecycle.

import Foundation
import MCP
import System
import os.log

private let mcpLog = OSLog(subsystem: "com.k1vin.nexusai", category: "MCP")

// MARK: - MCP Tool Info (simplified for UI)

struct MCPToolInfo: Identifiable, Hashable {
    let id: String          // "serverName::toolName"
    let serverName: String
    let name: String
    let description: String
    let inputSchemaJSON: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: MCPToolInfo, rhs: MCPToolInfo) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Connection State

enum MCPConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
}

// MARK: - Server Connection

actor MCPServerConnection {
    let config: MCPServerConfig
    let client: Client
    private var process: Process?
    private var transport: StdioTransport?
    private(set) var state: MCPConnectionState = .disconnected
    private(set) var tools: [Tool] = []

    init(config: MCPServerConfig) {
        self.config = config
        self.client = Client(name: "NexusAI", version: "2.0.0")
    }

    func connect() async throws {
        state = .connecting

        // Launch subprocess for MCP server
        // Use /usr/bin/env as the launcher to avoid macOS Process issues
        // with symlinks and script executables (npx, uvx, etc.)
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        proc.arguments = [config.command] + config.args

        // Set environment — ensure PATH includes homebrew
        var environment = ProcessInfo.processInfo.environment
        let homebrewPath = "/opt/homebrew/bin:/opt/homebrew/sbin"
        if let existingPath = environment["PATH"] {
            if !existingPath.contains("/opt/homebrew/bin") {
                environment["PATH"] = homebrewPath + ":" + existingPath
            }
        } else {
            environment["PATH"] = homebrewPath + ":/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        }
        if let env = config.env {
            environment.merge(env) { _, new in new }
        }
        proc.environment = environment

        // Create pipes for stdio communication
        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        proc.standardInput = stdinPipe
        proc.standardOutput = stdoutPipe
        proc.standardError = stderrPipe

        // Log stderr in background for debugging
        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let str = String(data: data, encoding: .utf8) {
                os_log("[MCP stderr] %{public}@", log: mcpLog, type: .debug, str)
            }
        }

        do {
            NSLog("[MCP] Starting process: %@ args: %@", config.command, "\(config.args)")
            try proc.run()
            NSLog("[MCP] Process started, PID: %d", proc.processIdentifier)
            self.process = proc

            // Create StdioTransport with the pipe file descriptors
            let inputFD = FileDescriptor(rawValue: stdoutPipe.fileHandleForReading.fileDescriptor)
            let outputFD = FileDescriptor(rawValue: stdinPipe.fileHandleForWriting.fileDescriptor)
            let stdioTransport = StdioTransport(input: inputFD, output: outputFD)
            self.transport = stdioTransport

            // Connect with timeout
            let result = try await withThrowingTaskGroup(of: Initialize.Result.self) { group in
                group.addTask {
                    try await self.client.connect(transport: stdioTransport)
                }
                group.addTask {
                    try await Task.sleep(for: .seconds(15))
                    throw MCPManagerError.connectionTimeout
                }
                let result = try await group.next()!
                group.cancelAll()
                return result
            }
            // Discover tools if server supports them
            if result.capabilities.tools != nil {
                let (discoveredTools, _) = try await client.listTools()
                self.tools = discoveredTools
            }
            state = .connected
            os_log("[MCP] Connected to '%{public}@' — %d tools available", log: mcpLog, type: .info, config.name, tools.count)
        } catch {
            process?.terminate()
            process = nil
            state = .error(error.localizedDescription)
            throw error
        }
    }

    func disconnect() async {
        process?.terminate()
        process = nil
        transport = nil
        tools = []
        state = .disconnected
    }

    func callTool(name: String, arguments: [String: Value]?) async throws -> String {
        let args = arguments ?? [:]
        let (content, isError) = try await client.callTool(
            name: name,
            arguments: args
        )

        var result = ""
        for item in content {
            switch item {
            case .text(let text, _, _):
                result += text
            default:
                result += "[non-text content]"
            }
        }

        if isError == true {
            return "[MCP Error] \(result)"
        }
        return result
    }
}

// MARK: - MCP Client Manager

@MainActor
class MCPClientManager: ObservableObject {
    static let shared = MCPClientManager()

    @Published var connectionStates: [UUID: MCPConnectionState] = [:]
    @Published var allTools: [MCPToolInfo] = []

    private var connections: [UUID: MCPServerConnection] = [:]
    private let configStore = MCPConfigStore.shared

    private init() {
        // Auto-connect after a delay when singleton is first accessed
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            Task { @MainActor in
                await self?.connectAll()
            }
        }
    }

    // MARK: - Connect All Enabled Servers

    func connectAll() async {
        let servers = configStore.enabledServers
        // Debug: write to file to confirm execution
        let debugMsg = "[MCP] connectAll called at \(Date()) with \(servers.count) servers: \(servers.map { "\($0.name)=\($0.command)" })\n"
        try? debugMsg.write(toFile: "/tmp/nexus_mcp_debug.log", atomically: true, encoding: .utf8)
        for server in servers {
            await connect(server: server)
        }
    }

    func connect(server: MCPServerConfig) async {
        // Debug file
        let msg = "[MCP] connect called for '\(server.name)' command='\(server.command)' args=\(server.args)\n"
        try? msg.write(toFile: "/tmp/nexus_mcp_connect.log", atomically: true, encoding: .utf8)
        let connection = MCPServerConnection(config: server)
        connections[server.id] = connection
        connectionStates[server.id] = .connecting

        do {
            try await connection.connect()
            let state = await connection.state
            connectionStates[server.id] = state
            await rebuildToolList()
        } catch {
            connectionStates[server.id] = .error(error.localizedDescription)
            os_log("[MCP] Failed to connect '%{public}@': %{public}@", log: mcpLog, type: .error, server.name, error.localizedDescription)
        }
    }

    func disconnect(server: MCPServerConfig) async {
        if let connection = connections[server.id] {
            await connection.disconnect()
            connections.removeValue(forKey: server.id)
            connectionStates.removeValue(forKey: server.id)
            await rebuildToolList()
        }
    }

    func disconnectAll() async {
        for (_, connection) in connections {
            await connection.disconnect()
        }
        connections.removeAll()
        connectionStates.removeAll()
        allTools = []
    }

    // MARK: - Tool Discovery

    private func rebuildToolList() async {
        var tools: [MCPToolInfo] = []
        for (serverId, connection) in connections {
            guard connectionStates[serverId] == .connected else { continue }
            let serverName = connection.config.name
            let serverTools = await connection.tools
            for tool in serverTools {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let schemaJSON: String
                if let data = try? encoder.encode(tool.inputSchema),
                   let str = String(data: data, encoding: .utf8) {
                    schemaJSON = str
                } else {
                    schemaJSON = "{}"
                }

                tools.append(MCPToolInfo(
                    id: "\(serverName)::\(tool.name)",
                    serverName: serverName,
                    name: tool.name,
                    description: tool.description ?? "",
                    inputSchemaJSON: schemaJSON
                ))
            }
        }
        self.allTools = tools
        // Update cached tools prompt
        _ = MCPToolRouter.shared.toolsSystemPrompt()
    }

    // MARK: - Call Tool

    func callTool(serverName: String, toolName: String, arguments: [String: Value]?) async throws -> String {
        guard let connection = connections.values.first(where: { $0.config.name == serverName }) else {
            throw MCPManagerError.serverNotFound(serverName)
        }
        return try await connection.callTool(name: toolName, arguments: arguments)
    }

    // MARK: - Generate Tool Definitions for AI

    /// Converts discovered MCP tools into the function-calling format
    /// that providers like OpenAI/Gemini/Claude expect.
    func toolDefinitionsJSON() -> [[String: Any]] {
        allTools.map { tool in
            [
                "type": "function",
                "function": [
                    "name": "mcp_\(tool.serverName)__\(tool.name)",
                    "description": "[\(tool.serverName)] \(tool.description)",
                    "parameters": (try? JSONSerialization.jsonObject(
                        with: Data(tool.inputSchemaJSON.utf8)
                    )) ?? ["type": "object", "properties": [:] as [String: Any]]
                ] as [String: Any]
            ]
        }
    }

    /// Parse an MCP tool call name back to server + tool
    func parseMCPToolName(_ name: String) -> (serverName: String, toolName: String)? {
        guard name.hasPrefix("mcp_") else { return nil }
        let stripped = String(name.dropFirst(4))
        guard let range = stripped.range(of: "__") else { return nil }
        let server = String(stripped[stripped.startIndex..<range.lowerBound])
        let tool = String(stripped[range.upperBound...])
        return (server, tool)
    }
}

// MARK: - Errors

enum MCPManagerError: LocalizedError {
    case serverNotFound(String)
    case toolNotFound(String)
    case connectionTimeout

    var errorDescription: String? {
        switch self {
        case .serverNotFound(let name): return "MCP server '\(name)' not found"
        case .toolNotFound(let name): return "MCP tool '\(name)' not found"
        case .connectionTimeout: return "Connection timed out after 15 seconds"
        }
    }
}
