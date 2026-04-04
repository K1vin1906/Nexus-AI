//
//  MCPConfigStore.swift
//  macai
//
//  Created by K1vin on 2026-04-05.
//  Nexus AI v2.0 — D3 MCP Integration
//
//  Manages user-configured MCP server definitions.
//  Config stored as JSON in ~/Library/Application Support/macai/mcp_servers.json

import Foundation
import SwiftUI

// MARK: - MCP Server Config Model

struct MCPServerConfig: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var command: String
    var args: [String]
    var env: [String: String]?
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        name: String,
        command: String,
        args: [String] = [],
        env: [String: String]? = nil,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.command = command
        self.args = args
        self.env = env
        self.isEnabled = isEnabled
    }
}

// MARK: - Config Store

class MCPConfigStore: ObservableObject {
    static let shared = MCPConfigStore()

    @Published var servers: [MCPServerConfig] = []

    private let fileURL: URL = {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!.appendingPathComponent("macai")
        try? FileManager.default.createDirectory(
            at: appSupport, withIntermediateDirectories: true
        )
        return appSupport.appendingPathComponent("mcp_servers.json")
    }()

    private init() {
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            servers = []
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            servers = try JSONDecoder().decode([MCPServerConfig].self, from: data)
        } catch {
            print("[MCP] Failed to load config: \(error)")
            servers = []
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(servers)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[MCP] Failed to save config: \(error)")
        }
    }

    func addServer(_ server: MCPServerConfig) {
        servers.append(server)
        save()
    }

    func removeServer(_ server: MCPServerConfig) {
        servers.removeAll { $0.id == server.id }
        save()
    }

    func updateServer(_ server: MCPServerConfig) {
        if let idx = servers.firstIndex(where: { $0.id == server.id }) {
            servers[idx] = server
            save()
        }
    }

    var enabledServers: [MCPServerConfig] {
        servers.filter(\.isEnabled)
    }
}
