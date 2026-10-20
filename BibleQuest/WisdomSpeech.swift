import AVFoundation
import SwiftUI

/// One reader shared by the garden and saved verses, so readings never overlap.
@MainActor
final class WisdomSpeech: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published private(set) var activeID: String?
    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?
    private lazy var voice = Self.preferredVoice()

    override init() {
        super.init()
        synthesizer.delegate = self
        // Let speech manage its own audio session without changing game/music settings.
        synthesizer.usesApplicationAudioSession = false
    }

    func toggle(id: String, text: String) {
        if activeID == id {
            stop()
            return
        }
        stop()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = 0.43
        utterance.pitchMultiplier = 0.96
        utterance.preUtteranceDelay = 0.15
        utterance.postUtteranceDelay = 0.25
        currentUtterance = utterance
        activeID = id
        synthesizer.speak(utterance)
    }

    func stop() {
        currentUtterance = nil
        activeID = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    private static func preferredVoice() -> AVSpeechSynthesisVoice? {
        let language = Locale.preferredLanguages.first(where: { $0.hasPrefix("en") }) ?? "en-US"
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("en") }
        return voices.sorted { a, b in
            // Prefer the most natural installed voice, then the user's English locale.
            if a.quality != b.quality { return a.quality.rawValue > b.quality.rawValue }
            if (a.language == language) != (b.language == language) { return a.language == language }
            if (a.gender == .female) != (b.gender == .female) { return a.gender == .female }
            return a.identifier < b.identifier
        }.first ?? AVSpeechSynthesisVoice(language: "en-US")
    }

    private func finished(_ utterance: AVSpeechUtterance) {
        // A cancelled older reading must not clear the state of a newer one.
        guard currentUtterance === utterance else { return }
        currentUtterance = nil
        activeID = nil
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in self?.finished(utterance) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in self?.finished(utterance) }
    }
}
