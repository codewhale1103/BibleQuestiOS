import SwiftUI
import Combine
import AVFoundation

struct VictorySongSpark: Identifiable {
    let id = UUID()
    let lane: Int
    let born: Double
    let perfect: Bool
}

final class VictorySongController: NSObject, ObservableObject {
    private(set) var round = VictorySongRound()
    @Published private(set) var visualTime = 0.0
    @Published private(set) var soundOn = true
    @Published private(set) var bestScore = UserDefaults.standard.integer(forKey: "DavidVictorySongBest")
    private(set) var sparks: [VictorySongSpark] = []
    private(set) var lastPluck = [-10.0,-10,-10]
    private(set) var message = "Follow the light. Pluck when it reaches the jewel."
    private(set) var messageUntil = 0.0
    var onComplete: (() -> Void)?
    var reduceMotion = false
    private var displayLink: CADisplayLink?
    private var target: VictorySongDisplayTarget?
    private var previousTime: Double?
    private var lastCount = -1
    private var delivered = false
    private var automaticHolds: Set<Int> = []
    private let audio = VictorySongAudio()

    func attach() {
        guard displayLink == nil else { return }
        let target = VictorySongDisplayTarget(); target.owner = self; self.target = target
        let link = CADisplayLink(target: target, selector: #selector(VictorySongDisplayTarget.frame(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        link.add(to: .main, forMode: .common); displayLink = link; previousTime = nil
    }
    func detach() {
        displayLink?.invalidate(); displayLink = nil; target = nil
        audio.stop(); automaticHolds.removeAll(); onComplete = nil
    }
    func start(gentle: Bool) {
        round.start(gentle: gentle); previousTime = nil; visualTime = 0; lastCount = -1; delivered = false
        message = "Follow the light. Pluck when it reaches the jewel."; messageUntil = 0
        sparks.removeAll(); lastPluck = [-10,-10,-10]; automaticHolds.removeAll()
        audio.stop(); if soundOn { audio.ambience() }; objectWillChange.send()
    }
    func press(_ lane: Int) {
        guard (0..<3).contains(lane),round.phase == .playing,!round.pressed.contains(lane) else { return }
        let events = round.press(lane)
        lastPluck[lane] = visualTime
        if events.isEmpty, soundOn { audio.pluck([62,66,69][lane],volume: 0.20) }
        process(events); objectWillChange.send()
    }
    func release(_ lane: Int) {
        automaticHolds.remove(lane); process(round.release(lane)); objectWillChange.send()
    }
    func accessiblePluck(_ lane: Int) {
        guard round.phase == .playing else { return }
        // VoiceOver activation is a tap. Keep a caught ribbon ringing automatically.
        if round.pressed.contains(lane) { _ = round.release(lane) }
        press(lane)
        if VictorySongRound.notes.contains(where: { $0.lane == lane && round.states[$0.id] == .holding }) { automaticHolds.insert(lane) }
        else { release(lane) }
    }
    func pause() {
        guard round.active else { return }
        round.pause(); audio.stop(); automaticHolds.removeAll(); objectWillChange.send()
    }
    func resume() { round.resume(); previousTime = nil; lastCount = -1; objectWillChange.send() }
    func toggleSound() {
        soundOn.toggle()
        if soundOn && round.active { audio.ambience() } else { audio.stop() }
    }
    fileprivate func frame(_ link: CADisplayLink) {
        let dt = min(0.05,max(0,previousTime.map { link.timestamp-$0 } ?? 1.0/60)); previousTime = link.timestamp
        guard round.phase != .paused else { return }
        visualTime += dt
        if round.phase == .countIn,round.countdown != lastCount {
            lastCount = round.countdown
            if soundOn { audio.cue("victory-count",volume: 0.4) }
            UISelectionFeedbackGenerator().selectionChanged()
            UIAccessibility.post(notification: .announcement,argument: "\(lastCount)")
        }
        process(round.advance(dt))
        for lane in automaticHolds {
            if !VictorySongRound.notes.contains(where: { $0.lane == lane && round.states[$0.id] == .holding }) { _ = round.release(lane); automaticHolds.remove(lane) }
        }
        sparks.removeAll { visualTime-$0.born > 1.5 }
    }
    private func process(_ events: [VictorySongRound.Event]) {
        for event in events {
            switch event {
            case .began:
                if soundOn { audio.ambience() }
                message = "Follow the light. Pluck at the jewels."; messageUntil = visualTime+3
            case let .plucked(id,judgment):
                let note = VictorySongRound.notes[id]
                if soundOn { audio.pluck(note.midi,volume: 0.65) }
                let perfect = judgment == .perfect
                sparks.append(.init(lane: note.lane,born: visualTime,perfect: perfect))
                message = note.duration > 0 ? "Keep holding. Let the ribbon sing." : perfect ? "Perfect harmony." : "Beautiful. Keep the melody flowing."
                messageUntil = visualTime+1.25
                UIImpactFeedbackGenerator(style: perfect ? .light : .soft).impactOccurred(intensity: perfect ? 0.65 : 0.4)
            case let .sustained(id):
                let note = VictorySongRound.notes[id]
                sparks.append(.init(lane: note.lane,born: visualTime,perfect: true))
                message = "A full, ringing chord."; messageUntil = visualTime+1.2
                if soundOn { audio.pluck(note.midi+12 > 74 ? 74 : note.midi+12,volume: 0.22) }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .missed:
                message = "The next light is yours. Keep playing."; messageUntil = visualTime+1.4
            case let .passage(index):
                UIAccessibility.post(notification: .announcement,argument: VictorySongRound.passages[index])
            case .finale:
                message = "Let gratitude fill the valley."; messageUntil = visualTime+4
                if soundOn { audio.cue("victory-resolve",volume: 0.6) }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case let .finished(won):
                audio.stop()
                if won {
                    if round.score > bestScore { bestScore = round.score; UserDefaults.standard.set(bestScore,forKey: "DavidVictorySongBest") }
                    if !delivered { delivered = true; onComplete?() }
                    UIAccessibility.post(notification: .announcement,argument: "Song complete. \(round.stars) stars. David’s adventure is complete.")
                } else { UIAccessibility.post(notification: .announcement,argument: "A little more practice. Try again or use gentle tempo.") }
            }
        }
    }
    deinit { displayLink?.invalidate() }
}
private final class VictorySongDisplayTarget: NSObject {
    weak var owner: VictorySongController?
    @objc func frame(_ link: CADisplayLink) { owner?.frame(link) }
}
private final class VictorySongAudio {
    private var bed: AVAudioPlayer?
    private var voices: [AVAudioPlayer] = []
    private var prepared = false
    private func prepare() {
        if !prepared { try? AVAudioSession.sharedInstance().setCategory(.ambient,mode: .default,options: .mixWithOthers); prepared = true }
    }
    func ambience() {
        prepare()
        if bed == nil,let url = Bundle.main.url(forResource: "victory-night",withExtension: "wav") {
            bed = try? AVAudioPlayer(contentsOf: url); bed?.numberOfLoops = -1; bed?.volume = 0.5
        }
        bed?.play()
    }
    func pluck(_ midi: Int,volume: Float) { cue("victory-harp-\(midi)",volume: volume) }
    func cue(_ name: String,volume: Float) {
        prepare(); voices.removeAll { !$0.isPlaying }
        guard let url = Bundle.main.url(forResource: name,withExtension: "wav"),let voice = try? AVAudioPlayer(contentsOf: url) else { return }
        voice.volume = volume; voice.play(); voices.append(voice)
        if voices.count > 14 { voices.removeFirst().stop() }
    }
    func stop() { bed?.pause(); voices.forEach { $0.stop() }; voices.removeAll() }
}
