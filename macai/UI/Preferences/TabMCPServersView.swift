//
//  TabMCPServersView.swift
//  macai
//
//  Created by K1vin on 2026-04-05.
//  Nexus AI v2.0 — D3 MCP Integration
//
//  Settings UI for managing MCP server connections.

import SwiftUI

struct TabMCPServersView: View {
    @ObservedObject private var configStore = MCPConfigStore.shared
    @ObservedObject private var clientManager = MCPClientManager.shared
    @Environment(\.colorScheme) private var colorScheme

    @State private var showAddSheet = false
    @State private var editingServer: MCPServerConfig?
    @State private var showDeleteConfirmation = false
    @State private var serverToDelete: MCPServerConfig?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connect MCP servers to give AI access to local tools like file systems, databases, and custom functions.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Server List
            if configStore.servers.isEmpty {
                emptyState
            } else {
                serverList
            }

            // Bottom Actions
            HStack {
                Spacer()
                Button(action: { showAddSheet = true }) {
                    Label("Add Server", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            MCPServerEditView(server: nil) { newServer in
                configStore.addServer(newServer)
                Task { await clientManager.connect(server: newServer) }
            }
        }
        .sheet(item: $editingServer) { server in
            MCPServerEditView(server: server) { updated in
                configStore.updateServer(updated)
                Task {
                    await clientManager.disconnect(server: updated)
                    if updated.isEnabled {
                        await clientManager.connect(server: updated)
                    }
                }
            }
        }
        .alert("Remove Server", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                if let server = serverToDelete {
                    Task { await clientManager.disconnect(server: server) }
                    configStore.removeServer(server)
                }
            }
        } message: {
            Text("Are you sure you want to remove '\(serverToDelete?.name ?? "")'?")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "puzzlepiece.extension")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("No MCP Servers")
                .font(.headline)
            Text("Add an MCP server to extend AI with local tools.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding()
    }

    // MARK: - Server List

    private var serverList: some View {
        VStack(spacing: 8) {
            ForEach(configStore.servers) { server in
                serverRow(server)
            }
        }
    }

    // MARK: - Server Row

    private func serverRow(_ server: MCPServerConfig) -> some View {
        let state = clientManager.connectionStates[server.id] ?? .disconnected
        let toolCount = clientManager.allTools.filter { $0.serverName == server.name }.count

        return HStack(spacing: 12) {
            // Status dot
            Circle()
                .fill(stateColor(state))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(server.name)
                        .font(.system(size: 13, weight: .medium))
                    if !server.isEnabled {
                        Text("Disabled")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color.secondary.opacity(0.15)))
                    }
                }
                Text(stateText(state, toolCount: toolCount))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Toggle enable/disable
            Toggle("", isOn: Binding(
                get: { server.isEnabled },
                set: { newValue in
                    var updated = server
                    updated.isEnabled = newValue
                    configStore.updateServer(updated)
                    Task {
                        if newValue {
                            await clientManager.connect(server: updated)
                        } else {
                            await clientManager.disconnect(server: updated)
                        }
                    }
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()

            // Edit
            Button(action: { editingServer = server }) {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            .help("Edit server")

            // Delete
            Button(action: {
                serverToDelete = server
                showDeleteConfirmation = true
            }) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
            .help("Remove server")
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark
                      ? Color.white.opacity(0.04)
                      : Color.black.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func stateColor(_ state: MCPConnectionState) -> Color {
        switch state {
        case .disconnected: return .gray
        case .connecting: return .yellow
        case .connected: return .green
        case .error: return .red
        }
    }

    private func stateText(_ state: MCPConnectionState, toolCount: Int) -> String {
        switch state {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting…"
        case .connected: return "\(toolCount) tool\(toolCount == 1 ? "" : "s") available"
        case .error(let msg): return "Error: \(msg)"
        }
    }
}

// MARK: - Add / Edit Server Sheet

struct MCPServerEditView: View {
    @Environment(\.presentationMode) private var presentationMode

    let server: MCPServerConfig?
    let onSave: (MCPServerConfig) -> Void

    @State private var name: String = ""
    @State private var command: String = ""
    @State private var argsText: String = ""
    @State private var envText: String = ""
    @State private var isEnabled: Bool = true

    init(server: MCPServerConfig?, onSave: @escaping (MCPServerConfig) -> Void) {
        self.server = server
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(server == nil ? "Add MCP Server" : "Edit MCP Server")
                .font(.title2)
                .bold()

            VStack(alignment: .leading, spacing: 12) {
                LabeledField("Name") {
                    TextField("e.g. filesystem", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                LabeledField("Command") {
                    TextField("e.g. npx or /usr/local/bin/mcp-server", text: $command)
                        .textFieldStyle(.roundedBorder)
                }

                LabeledField("Arguments") {
                    TextField("e.g. -y @modelcontextprotocol/server-filesystem /tmp", text: $argsText)
                        .textFieldStyle(.roundedBorder)
                    Text("Space-separated arguments")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                LabeledField("Environment") {
                    TextField("e.g. KEY=value KEY2=value2", text: $envText)
                        .textFieldStyle(.roundedBorder)
                    Text("Space-separated KEY=VALUE pairs (optional)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Toggle("Enabled", isOn: $isEnabled)
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                Spacer()
                Button(server == nil ? "Add" : "Save") {
                    let args = argsText.isEmpty ? [] : argsText.components(separatedBy: " ")
                    var env: [String: String]? = nil
                    if !envText.isEmpty {
                        var dict: [String: String] = [:]
                        for pair in envText.components(separatedBy: " ") {
                            let parts = pair.components(separatedBy: "=")
                            if parts.count == 2 {
                                dict[parts[0]] = parts[1]
                            }
                        }
                        if !dict.isEmpty { env = dict }
                    }
                    let config = MCPServerConfig(
                        id: server?.id ?? UUID(),
                        name: name,
                        command: command,
                        args: args,
                        env: env,
                        isEnabled: isEnabled
                    )
                    onSave(config)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(name.isEmpty || command.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 440, minHeight: 360)
        .onAppear {
            if let server = server {
                name = server.name
                command = server.command
                argsText = server.args.joined(separator: " ")
                envText = server.env?.map { "\($0.key)=\($0.value)" }.joined(separator: " ") ?? ""
                isEnabled = server.isEnabled
            }
        }
    }
}

// MARK: - Labeled Field Helper

private struct LabeledField<Content: View>: View {
    let label: String
    let content: Content

    init(_ label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            content
        }
    }
}
