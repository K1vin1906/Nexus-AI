//
//  SpeechManager.swift
//  macai
//
//  Speech-to-Text and Text-to-Speech manager for voice mode
//

import AVFoundation
import Foundation
import Speech
import SwiftUI

class SpeechManager: ObservableObject {
    @Published var isListening = false
    @Published var recognizedText = ""
    @Published var isSpeaking = false
    @Published var isAuthorized = false
    @Published var errorMessage: String?
    @Published var audioLevel: CGFloat = 0.0
    @Published var autoSpeak = false
    @Published var ttsLanguage: String = "zh-CN"

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()
    private var ttsDelegate: TTSDelegate?
    private var locale: Locale
    private var silenceTimer: Timer?
    private let silenceTimeout: TimeInterval = 2.5
    private var hasReceivedSpeech = false

    init(locale: Locale = Locale(identifier: "zh-Hans")) {
        self.locale = locale
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
        self.ttsDelegate = TTSDelegate(manager: self)
        self.synthesizer.delegate = self.ttsDelegate
        checkAuthorization()
    }

    func checkAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.isAuthorized = (status == .authorized)
                if status != .authorized {
                    self?.errorMessage = "Speech recognition not authorized."
                }
            }
        }
    }

    func setLocale(_ newLocale: Locale) {
        cleanupAudio()
        self.locale = newLocale
        self.speechRecognizer = SFSpeechRecognizer(locale: newLocale)
    }

    private func cleanupAudio() {
        stopSilenceTimer()
        if audioEngine.isRunning { audioEngine.stop() }
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
    }

    // MARK: - STT

    func startListening() {
        guard isAuthorized else { return }
        if speechRecognizer == nil {
            speechRecognizer = SFSpeechRecognizer(locale: locale)
        }
        guard let sr = speechRecognizer, sr.isAvailable else { return }

        cleanupAudio()

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let req = recognitionRequest else { return }
        req.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let fmt = inputNode.outputFormat(forBus: 0)
        guard fmt.sampleRate > 0, fmt.channelCount > 0 else { return }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: fmt) { [weak self] buf, _ in
            self?.recognitionRequest?.append(buf)
            self?.updateAudioLevel(from: buf)
        }

        recognitionTask = sr.recognitionTask(with: req) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                    if !self.hasReceivedSpeech && !self.recognizedText.isEmpty {
                        self.hasReceivedSpeech = true
                    }
                    if self.hasReceivedSpeech { self.resetSilenceTimer() }
                }
                if result.isFinal { self.finishSTT() }
            }
            if let error = error {
                if (error as NSError).code == 216 { return }
                self.finishSTT()
            }
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isListening = true
                self.recognizedText = ""
                self.hasReceivedSpeech = false
                self.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Audio engine failed: \(error.localizedDescription)"
                self.isListening = false
            }
        }
    }

    private func finishSTT() {
        DispatchQueue.main.async {
            self.cleanupAudio()
            self.isListening = false
            self.audioLevel = 0.0
        }
    }

    func stopListening() {
        cleanupAudio()
        DispatchQueue.main.async {
            self.isListening = false
            self.audioLevel = 0.0
        }
    }

    func toggleListening() {
        if isListening { stopListening() } else { startListening() }
    }

    private func updateAudioLevel(from buffer: AVAudioPCMBuffer) {
        guard let data = buffer.floatChannelData?[0] else { return }
        let len = Int(buffer.frameLength)
        guard len > 0 else { return }
        var sum: Float = 0
        for i in 0..<len { sum += abs(data[i]) }
        let level = CGFloat(min((sum / Float(len)) * 10, 1.0))
        DispatchQueue.main.async { self.audioLevel = level }
    }

    // MARK: - Silence Timer

    private func startSilenceTimer() {
        stopSilenceTimer()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceTimeout, repeats: false) { [weak self] _ in
            guard let self = self, self.isListening else { return }
            self.finishSTT()
        }
    }
    private func resetSilenceTimer() { startSilenceTimer() }
    private func stopSilenceTimer() { silenceTimer?.invalidate(); silenceTimer = nil }

    // MARK: - TTS

    func speak(_ text: String, language: String? = nil) {
        stopSpeaking()
        let cleaned = Self.cleanTextForSpeech(text)
        guard !cleaned.isEmpty else { return }
        let lang = language ?? ttsLanguage
        let utterance = AVSpeechUtterance(string: cleaned)
        utterance.voice = AVSpeechSynthesisVoice(language: lang)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.volume = 1.0
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        isSpeaking = false
    }

    func autoSpeakIfEnabled(_ text: String) {
        guard autoSpeak else { return }
        speak(text)
    }

    static func cleanTextForSpeech(_ text: String) -> String {
        var r = text
        r = r.replacingOccurrences(of: "<think>[\\s\\S]*?</think>", with: "", options: .regularExpression)
        r = r.replacingOccurrences(of: "<(image|file)-uuid>[\\s\\S]*?</(image|file)-uuid>", with: "", options: .regularExpression)
        r = r.replacingOccurrences(of: "```[\\s\\S]*?```", with: " ", options: .regularExpression)
        r = r.replacingOccurrences(of: "`[^`]+`", with: "", options: .regularExpression)
        r = r.replacingOccurrences(of: "(?m)^#{1,6}\\s*", with: "", options: .regularExpression)
        r = r.replacingOccurrences(of: "**", with: "")
        r = r.replacingOccurrences(of: "__", with: "")
        r = r.replacingOccurrences(of: "*", with: "")
        r = r.replacingOccurrences(of: "\\[([^\\]]+)\\]\\([^)]+\\)", with: "$1", options: .regularExpression)
        r = r.replacingOccurrences(of: "https?://\\S+", with: "", options: .regularExpression)
        r = r.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return r.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private class TTSDelegate: NSObject, AVSpeechSynthesizerDelegate {
    weak var manager: SpeechManager?
    init(manager: SpeechManager) { self.manager = manager }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.manager?.isSpeaking = false }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.manager?.isSpeaking = false }
    }
}
