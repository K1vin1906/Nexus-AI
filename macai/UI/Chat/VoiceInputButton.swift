//
//  VoiceInputButton.swift
//  macai
//
//  Voice input button with audio level visualization
//

import SwiftUI

struct VoiceInputButton: View {
    @ObservedObject var speechManager: SpeechManager
    let onTranscriptionComplete: (String) -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var previousText: String = ""
    private let buttonSize: CGFloat = 32

    var body: some View {
        Button(action: { speechManager.toggleListening() }) {
            ZStack {
                if speechManager.isListening {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(
                            width: buttonSize + 12 + (speechManager.audioLevel * 16),
                            height: buttonSize + 12 + (speechManager.audioLevel * 16)
                        )
                        .animation(.easeInOut(duration: 0.1), value: speechManager.audioLevel)

                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: buttonSize + 24, height: buttonSize + 24)
                        .scaleEffect(pulseScale)
                }

                Circle()
                    .fill(speechManager.isListening ? Color.red : Color.secondary.opacity(0.1))
                    .frame(width: buttonSize, height: buttonSize)

                Image(systemName: speechManager.isListening ? "mic.fill" : "mic.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(speechManager.isListening ? .white : .secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .help(speechManager.isListening ? "Stop listening" : "Voice input")
        .disabled(!speechManager.isAuthorized)
        .opacity(speechManager.isAuthorized ? 1.0 : 0.4)
        .onAppear { startPulseAnimation() }
        .onChange(of: speechManager.isListening) { listening in
            if listening {
                previousText = ""
                startPulseAnimation()
            } else {
                pulseScale = 1.0
                let text = speechManager.recognizedText
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty && text != previousText {
                    previousText = text
                    onTranscriptionComplete(text)
                }
            }
        }
    }

    private func startPulseAnimation() {
        guard speechManager.isListening else { return }
        withAnimation(
            .easeInOut(duration: 1.0)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.3
        }
    }
}

// MARK: - Voice Status Overlay

struct VoiceStatusOverlay: View {
    @ObservedObject var speechManager: SpeechManager
    let onCancel: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 3) {
                ForEach(0..<7, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.red)
                        .frame(width: 4, height: barHeight(for: index))
                        .animation(.easeInOut(duration: 0.15).delay(Double(index) * 0.02),
                                   value: speechManager.audioLevel)
                }
            }
            .frame(height: 30)

            if !speechManager.recognizedText.isEmpty {
                Text(speechManager.recognizedText)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .truncationMode(.head)
                    .frame(maxWidth: 300)
            } else {
                Text("Listening...")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: onDone) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let base: CGFloat = 4
        let variation = speechManager.audioLevel * 26
        let offset = abs(CGFloat(index) - 3.0) / 3.0
        return base + variation * (1.0 - offset * 0.5)
    }
}
