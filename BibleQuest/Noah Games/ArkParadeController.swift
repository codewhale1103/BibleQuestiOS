import SwiftUI
import Combine
import AVFoundation

final class ArkParadeController: NSObject, ObservableObject {
    private(set) var round = ArkParadeRound()
    @Published private(set) var time = 0.0
    @Published private(set) var soundOn = true
    private(set) var message = ""
    private(set) var messageUntil = 0.0
    private(set) var calling: ParadeAnimal?
    private(set) var callPoint = ArkParadeRound.start
    private(set) var callUntil = 0.0
    private(set) var hintUntil = 0.0
    private(set) var reactionIndex: Int?
    private(set) var reactionUntil = 0.0
    var onComplete: (() -> Void)?
    var reduceMotion = false
    private let audio = ParadeAudio()
    private var link: CADisplayLink?
    private var displayTarget: ParadeDisplayTarget?
    private var previous: Double?
    private var stepClock = 0.0
    private var delivered = false
    private var announcedTrace = false
    private var dragPoint: ParadePoint?
    func attach() {
        guard link == nil else { return }
        let target = ParadeDisplayTarget(); target.owner = self; displayTarget = target
        let display = CADisplayLink(target: target,selector: #selector(ParadeDisplayTarget.frame(_:)))
        display.preferredFrameRateRange = .init(minimum: 30,maximum: 60,preferred: 60)
        display.add(to: .main,forMode: .common); link = display
    }
    func detach() { link?.invalidate(); link = nil; displayTarget = nil; previous = nil; audio.stop(); onComplete = nil }
    func start() {
        round.start(seed: UInt64.random(in: 1...UInt64.max)); time = 0; previous = nil; delivered = false; announcedTrace = false
        message = ""; messageUntil = 0; calling = nil; reactionIndex = nil; hintUntil = 0; dragPoint = nil
        audio.stop(); if soundOn { audio.ambience() }
        prompt(); objectWillChange.send()
    }
    func choose(_ index: Int) { process(round.choose(index)); objectWillChange.send() }
    func beginTrail(_ p: ParadePoint) { if dragPoint == nil { trace(p) } }
    func trace(_ p: ParadePoint) {
        guard round.phase == .tracing,p.finite,(-0.5...1.5).contains(p.x),(-0.5...1.5).contains(p.y) else { return }
        if let previous = dragPoint {
            let steps = min(100,max(1,Int(ceil(previous.distance(to: p)/0.015))))
            for index in 1...steps { round.trace(previous.mix(p,Double(index)/Double(steps))) }
        } else { round.trace(p) }
        dragPoint = p; objectWillChange.send()
    }
    func endTrail(_ p: ParadePoint) { trace(p); dragPoint = nil; process(round.endTrail(p)); objectWillChange.send() }
    func guideAccessibly() { process(round.accessibleTrail()); objectWillChange.send() }
    func next() { process(round.next()); objectWillChange.send() }
    func listen() {
        guard ![.intro,.paused,.won].contains(round.phase) else { return }
        call(round.animal,at: ArkParadeRound.start)
    }
    func hint() {
        guard round.phase == .finding || round.phase == .tracing else { return }
        hintUntil = time+5
        say(round.phase == .finding ? round.animal.hint : "Start at the pair. Draw a trail all the way to the glowing ramp.",clip: round.phase == .finding ? "hint" : "trail-hint")
        objectWillChange.send()
    }
    func pause() { round.pause(); dragPoint = nil; audio.stop(); calling = nil; callUntil = 0; objectWillChange.send() }
    func resume() {
        round.resume(); previous = nil
        if soundOn { audio.ambience() }
        objectWillChange.send()
    }
    func toggleSound() {
        soundOn.toggle()
        if soundOn && ![.intro,.paused,.won].contains(round.phase) { audio.ambience() } else { audio.stop() }
    }
    func journalCall(_ animal: ParadeAnimal) {
        if soundOn { audio.call(animal) }
    }
    func readFact(_ animal: ParadeAnimal) { if soundOn { audio.narrate(["fact-\(animal.name.lowercased())"]) } }
    fileprivate func frame(_ display: CADisplayLink) {
        let dt = min(0.05,max(0,previous.map { display.timestamp-$0 } ?? 1.0/60)); previous = display.timestamp
        guard round.phase != .paused else { return }
        time += dt; process(round.advance(dt))
        if round.phase == .tracing && !announcedTrace {
            announcedTrace = true; say("Two together! Now draw a trail from the pair to the ark's glowing ramp.",clip: "trace")
        }
        if round.phase == .escorting {
            stepClock += dt
            if stepClock > (round.animal == .elephant ? 0.53 : round.animal == .wolf ? 0.29 : 0.36) {
                stepClock = 0; if soundOn { audio.footstep(round.animal) }
            }
        }
    }
    private func prompt() {
        let text = "This \(round.animal.name.lowercased()) is looking for its partner. Listen, then find the matching animal."
        if soundOn { audio.narrate(["listen"],then: round.animal) }
        calling = round.animal; callPoint = ArkParadeRound.start; callUntil = time+9
        UIAccessibility.post(notification: .announcement,argument: text)
    }
    private func say(_ text: String,clip: String) {
        message = text; messageUntil = time+6
        if soundOn { audio.narrate([clip]) }
        UIAccessibility.post(notification: .announcement,argument: text)
    }
    private func call(_ animal: ParadeAnimal,at point: ParadePoint) {
        calling = animal; callPoint = point; callUntil = time+3.1
        message = "\(animal.name) · \(animal.call.capitalized)"; messageUntil = time+3.1
        if soundOn { audio.call(animal) }
    }
    private func process(_ events: [ArkParadeRound.Event]) {
        for event in events {
            switch event {
            case let .wrong(animal):
                reactionIndex = round.choices.firstIndex(of: animal); reactionUntil = time+1.2
                call(animal,at: round.positions[reactionIndex ?? 0])
                message = "That's a \(animal.name.lowercased())! \(round.animal.hint)"; messageUntil = time+4
                UIAccessibility.post(notification: .announcement,argument: message)
            case .matched:
                calling = round.animal; callPoint = ArkParadeRound.start; callUntil = time+2
                if soundOn { audio.call(round.animal); audio.cue("parade-match",volume: 0.35) }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                message = "A perfect pair. Hello, friend!"; messageUntil = time+2
            case .trailHint: say("Start at the pair and finish on the glowing ramp. Try any trail you like!",clip: "trail-hint")
            case .walking:
                if soundOn { audio.stopVoice() }
                stepClock = 0; message = round.helpedAroundRock ? "A little detour around the rock. Together we go!" : "Your trail. Their little adventure."; messageUntil = time+5
                UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.7)
            case let .boarded(animal):
                if soundOn { audio.cue("parade-board",volume: 0.38); audio.narrate(["count-\(round.animalsAboard)","fact-\(animal.name.lowercased())"]) }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                UIAccessibility.post(notification: .screenChanged,argument: nil)
            case .next:
                announcedTrace = false; calling = nil
                if round.phase == .finding { prompt() }
                else if soundOn { audio.narrate(["finale"]); audio.cue("parade-finale",volume: 0.5) }
            case .won:
                if soundOn { audio.chorus() }
                if !delivered { delivered = true; onComplete?() }
                UIAccessibility.post(notification: .announcement,argument: "Ark Parade complete. Eight pairs safely aboard. You cared for every animal!")
            }
        }
    }
    deinit { link?.invalidate() }
}

private final class ParadeDisplayTarget: NSObject {
    weak var owner: ArkParadeController?
    @objc func frame(_ display: CADisplayLink) { owner?.frame(display) }
}

/// Anna's prerecorded narration plays offline and yields cleanly to animal calls.
private final class ParadeAudio: NSObject, AVAudioPlayerDelegate {
    private var bed: AVAudioPlayer?
    private var voice: AVAudioPlayer?
    private var effects: [AVAudioPlayer] = []
    private var narrationQueue: [String] = []
    private var isNarrating = false
    private var nextCall: ParadeAnimal?
    private var chorusQueue: [ParadeAnimal] = []
    private var chorusPending = false
    private var prepared = false
    private func prepare() {
        if !prepared { try? AVAudioSession.sharedInstance().setCategory(.ambient,mode: .default,options: [.mixWithOthers]); prepared = true }
    }
    func ambience() {
        prepare()
        if bed == nil,let url = Bundle.main.url(forResource: "parade-forest",withExtension: "wav") { bed = try? AVAudioPlayer(contentsOf: url); bed?.numberOfLoops = -1 }
        bed?.volume = 0.12; bed?.play()
    }
    func narrate(_ clips: [String],then animal: ParadeAnimal? = nil) {
        prepare(); stopVoice(); narrationQueue = clips; nextCall = animal; isNarrating = true
        playNextNarration()
    }
    private func playNextNarration() {
        while !narrationQueue.isEmpty {
            let clip = narrationQueue.removeFirst()
            if play("parade-voice-"+clip,extension: "m4a",volume: 0.82) { return }
        }
        isNarrating = false
        if let animal = nextCall { nextCall = nil; playCall(animal) }
        else if chorusPending { beginChorus() }
        else { restoreAmbience() }
    }
    @discardableResult private func play(_ name: String,extension ext: String,volume: Float) -> Bool {
        guard let url = Bundle.main.url(forResource: name,withExtension: ext),let player = try? AVAudioPlayer(contentsOf: url) else { return false }
        voice = player; player.delegate = self; player.volume = volume
        bed?.setVolume(0.04,fadeDuration: 0.15)
        return player.play()
    }
    func call(_ animal: ParadeAnimal) { prepare(); stopVoice(); playCall(animal) }
    private func playCall(_ animal: ParadeAnimal) {
        if !play("parade-\(animal.name.lowercased())",extension: "wav",volume: 0.66) { restoreAmbience() }
    }
    func cue(_ name: String,volume: Float) {
        prepare(); effects.removeAll { !$0.isPlaying }
        guard let url = Bundle.main.url(forResource: name,withExtension: "wav"),let effect = try? AVAudioPlayer(contentsOf: url) else { return }
        effect.volume = volume; effect.play(); effects.append(effect)
        if effects.count > 8 { effects.removeFirst().stop() }
    }
    func footstep(_ animal: ParadeAnimal) {
        cue(animal == .horse || animal == .sheep || animal == .cow ? "parade-hoofstep" : "parade-pawstep",volume: animal == .elephant ? 0.28 : 0.16)
    }
    // The celebration waits for Anna to finish instead of cutting her off.
    func chorus() {
        if isNarrating { chorusPending = true; return }
        stopVoice(); beginChorus()
    }
    private func beginChorus() {
        chorusPending = false; cue("parade-finale",volume: 0.32)
        chorusQueue = ParadeAnimal.allCases; playNextChorus()
    }
    private func playNextChorus() {
        guard !chorusQueue.isEmpty else { restoreAmbience(); return }
        playCall(chorusQueue.removeFirst())
    }
    private func restoreAmbience() { bed?.setVolume(0.12,fadeDuration: 0.4) }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer,successfully flag: Bool) {
        guard player === voice else { return }
        voice = nil
        if isNarrating { playNextNarration() }
        else if !chorusQueue.isEmpty { playNextChorus() }
        else { restoreAmbience() }
    }
    func stopVoice() {
        narrationQueue = []; isNarrating = false; nextCall = nil; chorusQueue = []; chorusPending = false
        voice?.stop(); voice = nil; restoreAmbience()
    }
    func stop() { stopVoice(); bed?.pause(); effects.forEach { $0.stop() }; effects.removeAll() }
}
