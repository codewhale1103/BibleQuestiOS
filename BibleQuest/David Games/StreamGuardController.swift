import SwiftUI
import SpriteKit
import AVFoundation
import Combine

struct StreamGuardHUD: Equatable {
    var seconds = 30
    var stones = 5
    var score = 0
    var shooed = 0
    var combo = 0
    var bestCombo = 0
    var charge = 0
    var countdown = 3
    var progress: Double = 0
    var chapter: String { progress < 0.35 ? "THE QUIET SPRING" : progress < 0.72 ? "WINGS ON THE WATER" : "THE FINAL FLIGHT" }
}
struct StreamBirdTarget: Identifiable, Equatable {
    let id: Int
    let x: Double
    let y: Double
    let scale: Double
}

final class StreamGuardController: NSObject, ObservableObject {
    let scene = StreamSanctuaryScene(size: CGSize(width: 390,height: 740))
    @Published private(set) var phase: StreamGuardRound.Phase = .ready
    @Published private(set) var hud = StreamGuardHUD()
    @Published private(set) var targets: [StreamBirdTarget] = []
    @Published private(set) var soundOn = true
    @Published private(set) var resultVisible = false
    @Published private(set) var best = UserDefaults.standard.integer(forKey: "StreamOfStonesBestScore")
    var onComplete: (() -> Void)?
    var reduceMotion = false { didSet { scene.reduceMotion = reduceMotion } }
    private(set) var round = StreamGuardRound()
    private var link: CADisplayLink?
    private var target: StreamDisplayTarget?
    private var previousTime: Double?
    private var visualTime: Double = 0
    private var publishTime: Double = 0
    private var birdSoundTime: Double = 0
    private var resultDelay: Double?
    private var completionDelivered = false
    private let audio = StreamGuardAudio()

    func attach() {
        guard link == nil else { return }
        scene.onBirdTap = { [weak self] id in self?.shoo(id) }
        let target = StreamDisplayTarget(); target.owner = self; self.target = target
        let display = CADisplayLink(target: target,selector: #selector(StreamDisplayTarget.update(_:)))
        display.preferredFrameRateRange = CAFrameRateRange(minimum: 30,maximum: 60,preferred: 60)
        display.add(to: .main,forMode: .common)
        link = display; previousTime = nil
    }
    func detach() {
        link?.invalidate(); link = nil; target = nil; previousTime = nil
        audio.stop(); scene.onBirdTap = nil; onComplete = nil
    }
    func start() {
        round.start(seed: UInt64.random(in: 1...999999))
        resultVisible = false; completionDelivered = false; resultDelay = nil
        visualTime = 0; birdSoundTime = 0; previousTime = nil
        scene.reset(); scene.setPhase(.countdown)
        audio.stop(); if soundOn { audio.ambience() }
        publish()
    }
    func shoo(_ id: Int) {
        let wasReady = round.callReady
        let events = round.shoo(id)
        guard !events.isEmpty else { return }
        process(events)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.55)
        if !wasReady, round.callReady {
            if soundOn { audio.cue("shepherd-found",volume: 0.25) }
            UISelectionFeedbackGenerator().selectionChanged()
        }
        publish()
    }
    func call() {
        let events = round.call()
        guard !events.isEmpty else { return }
        process(events); publish()
    }
    func pause() {
        round.pause(); scene.setPhase(round.phase); audio.stop(); publish()
    }
    func resume() {
        round.resume(); scene.setPhase(round.phase); previousTime = nil
        if soundOn { audio.ambience() }
        publish()
    }
    func toggleSound() {
        soundOn.toggle()
        if !soundOn { audio.stop() }
        else if round.phase == .playing || round.phase == .countdown { audio.ambience() }
    }
    fileprivate func frame(_ display: CADisplayLink) {
        let raw = previousTime.map { display.timestamp - $0 } ?? 1.0 / 60
        previousTime = display.timestamp
        if raw > 0.5, round.phase == .playing || round.phase == .countdown { pause() }
        guard round.phase != .paused else { return }
        let dt = min(0.1,max(0,raw))
        visualTime += dt; publishTime += dt; birdSoundTime += dt
        let oldPhase = round.phase, oldBirds = round.birds.count
        let events = round.advance(dt)
        process(events)
        if oldPhase != round.phase { scene.setPhase(round.phase) }
        if round.birds.count > oldBirds, soundOn, birdSoundTime > 1.6 {
            audio.cue("stream-bird",volume: 0.18); birdSoundTime = 0
        }
        scene.render(round: round,time: visualTime)
        if let delay = resultDelay {
            resultDelay = delay - dt
            if delay <= 0 {
                resultDelay = nil; resultVisible = true
                if round.score > best {
                    best = round.score; UserDefaults.standard.set(best,forKey: "StreamOfStonesBestScore")
                }
                if round.phase == .won, !completionDelivered {
                    completionDelivered = true
                    if soundOn { audio.cue("shepherd-complete",volume: 0.55) }
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    onComplete?()
                }
            }
        }
        if publishTime >= 0.075 || oldPhase != round.phase { publishTime = 0; publish() }
    }
    private func process(_ events: [StreamGuardRound.Event]) {
        for event in events {
            scene.handle(event)
            switch event {
            case let .shooed(_,_,fromCall):
                if soundOn, !fromCall { audio.cue("stream-wing",volume: 0.42) }
            case .stolen:
                if soundOn { audio.cue("stream-stone",volume: 0.5) }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.65)
            case .call:
                if soundOn { audio.cue("stream-call",volume: 0.5) }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .won,.lost:
                audio.stop(); resultDelay = 1.0
            }
        }
    }
    private func publish() {
        if phase != round.phase { phase = round.phase }
        hud = StreamGuardHUD(seconds: Int(ceil(round.remaining)),stones: round.stones,score: round.score,
                             shooed: round.shooed,combo: round.combo,bestCombo: round.bestCombo,
                             charge: round.callCharge,countdown: max(1,Int(ceil(round.countdown))),progress: round.progress)
        targets = round.phase == .playing ? round.birds.compactMap { bird in
            let p = bird.position
            guard p.x > -0.05, p.x < 1.05, p.y < 0.95 else { return nil }
            return StreamBirdTarget(id: bird.id,x: p.x,y: p.y,scale: 0.54 + bird.progress * 0.51)
        } : []
    }
    deinit { link?.invalidate() }
}
private final class StreamDisplayTarget: NSObject {
    weak var owner: StreamGuardController?
    @objc func update(_ display: CADisplayLink) { owner?.frame(display) }
}

private final class StreamGuardAudio {
    private var water: AVAudioPlayer?
    private var players: [String: AVAudioPlayer] = [:]
    private var prepared = false
    private func prepare() {
        guard !prepared else { return }
        try? AVAudioSession.sharedInstance().setCategory(.ambient,mode: .default,options: .mixWithOthers)
        prepared = true
    }
    func ambience() {
        prepare()
        if water == nil, let url = Bundle.main.url(forResource: "stream-water",withExtension: "wav") {
            water = try? AVAudioPlayer(contentsOf: url)
            water?.numberOfLoops = -1; water?.volume = 0.32
        }
        water?.play()
    }
    func cue(_ name: String,volume: Float) {
        prepare()
        if players[name] == nil, let url = Bundle.main.url(forResource: name,withExtension: "wav") {
            players[name] = try? AVAudioPlayer(contentsOf: url)
            players[name]?.prepareToPlay()
        }
        players[name]?.currentTime = 0; players[name]?.volume = volume; players[name]?.play()
    }
    func stop() { water?.pause(); players.values.forEach { $0.stop() } }
}
