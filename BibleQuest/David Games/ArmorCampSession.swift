import SwiftUI
import Combine
import AVFoundation

struct ArmorCampEffect: Identifiable {
    enum Kind { case dock(ArmorCampRound.Piece), foot(Double) }
    let id = UUID()
    let kind: Kind
    let born: Double
}

final class ArmorCampSession: NSObject, ObservableObject {
    @Published private(set) var round = ArmorCampRound()
    @Published private(set) var clock: Double = 0
    @Published private(set) var soundEnabled = true
    @Published private(set) var effects: [ArmorCampEffect] = []
    @Published private(set) var note: String?
    var onComplete: (() -> Void)?
    var reduceMotion = false
    private var display: CADisplayLink?
    private var target: ArmorCampDisplayTarget?
    private var previousTime: Double?
    private var noteExpiry: Double = 0
    private var footTime: Double = 0
    private var completionDelivered = false
    private let audio = ArmorCampAudio()

    func attach() {
        guard display == nil else { return }
        let target = ArmorCampDisplayTarget(); target.owner = self; self.target = target
        let link = CADisplayLink(target: target,selector: #selector(ArmorCampDisplayTarget.frame(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30,maximum: 60,preferred: 30)
        link.add(to: .main,forMode: .common)
        display = link; previousTime = nil
    }
    func detach() {
        display?.invalidate(); display = nil; target = nil; previousTime = nil
        audio.stop(); onComplete = nil
    }
    func start() {
        effects.removeAll(); clock = 0; note = nil; footTime = 0; completionDelivered = false
        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.85,dampingFraction: 0.88)) { round.start() }
        if soundEnabled { audio.wind() }
    }
    func select(_ piece: ArmorCampRound.Piece) {
        guard round.select(piece) else { return }
        note = nil
        if soundEnabled { audio.cue("armor-lift",volume: 0.27) }
        UISelectionFeedbackGenerator().selectionChanged()
    }
    func drop(_ piece: ArmorCampRound.Piece,onto stand: ArmorCampRound.Piece?) {
        let outcome = round.drop(piece,onto: stand)
        switch outcome {
        case .accepted:
            note = "Letting go of the \(piece.title.lowercased())."
            noteExpiry = clock + 0.8
            if soundEnabled { audio.cue("armor-swish",volume: 0.27) }
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.5)
        case .wrongStand:
            note = "The \(piece.title.lowercased()) belongs on its matching stand."
            noteExpiry = clock + 3
            UISelectionFeedbackGenerator().selectionChanged()
        case .unavailable: break
        }
    }
    func tapStand(_ stand: ArmorCampRound.Piece) {
        guard let piece = round.selected else {
            guard round.phase == .fitting, !round.isTrying else { return }
            note = "Choose the \(stand.title.lowercased()), then tap this stand."
            noteExpiry = clock + 3
            return
        }
        withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.6,dampingFraction: 0.79)) {
            drop(piece,onto: stand)
        }
    }
    func tryStep() {
        let events = round.tryStep()
        guard !events.isEmpty else { return }
        note = nil; footTime = 0
        process(events)
    }
    func pause() { round.pause(); audio.stop() }
    func resume() { round.resume(); previousTime = nil; if soundEnabled { audio.wind() } }
    func toggleSound() {
        soundEnabled.toggle()
        if soundEnabled, round.phase != .paused, round.phase != .intro, round.phase != .completed { audio.wind() }
        else { audio.stop() }
    }
    var message: String {
        if round.phase == .ready { return "Lighter on his feet. Stronger in his trust." }
        if round.phase == .walking { return "God’s strength. David’s own stride." }
        if round.isTrying { return "Clank, clank… this armor is too heavy!" }
        if let note { return note }
        if let piece = round.selected { return "Take the \(piece.title.lowercased()) to its matching stand." }
        return "Drag a piece to its stand. Or tap a piece, then a stand."
    }
    fileprivate func frame(_ display: CADisplayLink) {
        let raw = previousTime.map { display.timestamp - $0 } ?? 1.0 / 30
        previousTime = display.timestamp
        guard round.phase != .paused else { return }
        let dt = min(0.1,max(0,raw)); clock += dt
        let events = round.advance(dt)
        process(events)
        effects.removeAll { clock - $0.born > 1.1 }
        if note != nil, clock > noteExpiry { note = nil }
        if round.isTrying || round.phase == .walking {
            footTime += dt
            if footTime > 0.26 {
                footTime = 0
                effects.append(ArmorCampEffect(kind: .foot(round.walkProgress),born: clock))
                if soundEnabled { audio.cue(round.isTrying ? "armor-heavy-step" : "armor-light-step",volume: 0.25) }
            }
        }
    }
    private func process(_ events: [ArmorCampRound.Event]) {
        for event in events {
            switch event {
            case let .docked(piece):
                effects.append(ArmorCampEffect(kind: .dock(piece),born: clock))
                if soundEnabled { audio.cue("armor-dock",volume: 0.45) }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.5)
            case .ready:
                note = nil
                if soundEnabled { audio.cue("shepherd-found",volume: 0.38) }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .heavyStep:
                if soundEnabled { audio.cue("armor-heavy-step",volume: 0.45) }
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.45)
            case .braveStep:
                if soundEnabled { audio.cue("armor-free",volume: 0.45) }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .completed:
                audio.stop()
                if soundEnabled { audio.cue("shepherd-complete",volume: 0.55) }
                guard !completionDelivered else { continue }
                completionDelivered = true; onComplete?()
            }
        }
    }
    deinit { display?.invalidate() }
}
private final class ArmorCampDisplayTarget: NSObject {
    weak var owner: ArmorCampSession?
    @objc func frame(_ display: CADisplayLink) { owner?.frame(display) }
}

private final class ArmorCampAudio {
    private var players: [String: AVAudioPlayer] = [:]
    private var breeze: AVAudioPlayer?
    private var prepared = false
    private func prepare() {
        guard !prepared else { return }
        try? AVAudioSession.sharedInstance().setCategory(.ambient,mode: .default,options: .mixWithOthers)
        prepared = true
    }
    func wind() {
        prepare()
        if breeze == nil, let url = Bundle.main.url(forResource: "armor-wind",withExtension: "wav") {
            breeze = try? AVAudioPlayer(contentsOf: url); breeze?.numberOfLoops = -1; breeze?.volume = 0.18
        }
        breeze?.play()
    }
    func cue(_ name: String,volume: Float) {
        prepare()
        if players[name] == nil, let url = Bundle.main.url(forResource: name,withExtension: "wav") {
            players[name] = try? AVAudioPlayer(contentsOf: url); players[name]?.prepareToPlay()
        }
        players[name]?.currentTime = 0; players[name]?.volume = volume; players[name]?.play()
    }
    func stop() { breeze?.pause(); players.values.forEach { $0.stop() } }
}
