import SwiftUI
import SpriteKit
import Combine
import AVFoundation

struct GoliathSlingHUD: Equatable {
    var phase: GoliathSlingRound.Phase = .intro
    var stones = 5
    var broken = 0
    var shots = 0
    var score = 0
    var perfects = 0
    var stars = 3
    var angle = 57.0
    var power = 0.76
    var aiming = false
    var message = "Pull back the glowing stone. Aim, then let go."
}

final class GoliathSlingController: NSObject,ObservableObject {
    let scene = GoliathArenaScene(size: CGSize(width: 390,height: 844))
    @Published private(set) var hud = GoliathSlingHUD()
    @Published private(set) var soundOn = true
    @Published private(set) var bestScore = UserDefaults.standard.integer(forKey: "GoliathSlingBestScore")
    var onComplete: (() -> Void)?
    var reduceMotion = false { didSet { scene.reduceMotion = reduceMotion } }
    private(set) var round = GoliathSlingRound()
    private var link: CADisplayLink?
    private var displayTarget: SlingDisplayTarget?
    private var previousTime: Double?
    private var visualTime = 0.0
    private var publishTime = 0.0
    private var note = ""
    private var noteUntil = 0.0
    private var lastPowerStep = 0
    private var completionDelivered = false
    private let audio = GoliathSlingAudio()

    func attach() {
        guard link == nil else { return }
        scene.onResize = { [weak self] in self?.resize($0) }
        resize(scene.size)
        let target = SlingDisplayTarget(); target.owner = self; displayTarget = target
        let display = CADisplayLink(target: target,selector: #selector(SlingDisplayTarget.frame(_:)))
        display.preferredFrameRateRange = CAFrameRateRange(minimum: 30,maximum: 60,preferred: 60)
        display.add(to: .main,forMode: .common); link = display; previousTime = nil
    }
    func detach() {
        link?.invalidate(); link = nil; displayTarget = nil; audio.stop(); onComplete = nil
        scene.onResize = nil
    }
    func start() {
        round.start(); visualTime = 0; previousTime = nil; note = ""; noteUntil = 0; lastPowerStep = 0; completionDelivered = false
        scene.reset(); scene.isPaused = false; scene.render(round: round,time: 0,dt: 0); audio.stop()
        if soundOn { audio.ambience() }
        publish()
    }
    func pull(_ point: SlingPoint) {
        let wasAiming = round.aiming
        round.setPull(point)
        if round.aiming && !wasAiming {
            if soundOn { audio.cue("sling-draw",volume: 0.32) }
            note = ""
        }
        let step = Int(round.pull.length/GoliathSlingRound.maxPull*5)
        if step != lastPowerStep { lastPowerStep = step; UISelectionFeedbackGenerator().selectionChanged() }
        publish()
    }
    func release() {
        let events = round.launch()
        if events.isEmpty { round.cancelAim() }
        process(events); publish()
    }
    func cancelAim() { round.cancelAim(); publish() }
    func setAngle(_ angle: Double) { round.setAim(angle: angle,power: round.power); publish() }
    func setPower(_ power: Double) { round.setAim(angle: round.angle,power: power); publish() }
    func firePreset() {
        guard round.phase == .ready else { return }
        if !round.aiming { round.setAim(angle: round.angle,power: round.power) }
        release()
    }
    func pause() { round.pause(); scene.isPaused = true; audio.stop(); publish() }
    func resume() { round.resume(); previousTime = nil; scene.isPaused = false; if soundOn { audio.ambience() }; publish() }
    func toggleSound() {
        soundOn.toggle()
        if soundOn && [.ready,.flight,.impact,.toppling].contains(round.phase) { audio.ambience() } else { audio.stop() }
    }
    private func resize(_ size: CGSize) {
        guard size.width > 0,size.height > 0 else { return }
        let oldHeight = round.arena.height
        round.resize(aspect: size.width/size.height)
        if abs(oldHeight-round.arena.height) > 30 {
            scene.reset()
            if [.ready,.flight,.impact,.toppling].contains(round.phase) { pause() }
        }
        scene.render(round: round,time: visualTime,dt: 0); publish()
    }
    fileprivate func frame(_ display: CADisplayLink) {
        let raw = previousTime.map { display.timestamp-$0 } ?? 1.0/60; previousTime = display.timestamp
        guard ![.paused,.won,.lost].contains(round.phase) else { return }
        let dt = min(0.05,max(0,raw)); visualTime += dt; publishTime += dt
        process(round.advance(dt))
        scene.render(round: round,time: visualTime,dt: dt)
        if publishTime > 0.07 || hud.phase != round.phase { publishTime = 0; publish() }
    }
    private func process(_ events: [GoliathSlingRound.Event]) {
        for event in events {
            scene.event(event)
            switch event {
            case .launched:
                note = ""; lastPowerStep = 0
                if soundOn { audio.cue("sling-release",volume: 0.5); audio.cue("sling-flight",volume: 0.22) }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.55)
            case let .hit(_,_,perfect,streak):
                note = perfect ? "Perfect shot. Right through the center." : streak > 1 ? "\(streak) in a row. His guard is breaking." : "Guard broken. Keep your aim steady."
                noteUntil = visualTime+2.7
                if soundOn { audio.cue(perfect ? "sling-perfect" : "sling-impact",volume: 0.6) }
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: perfect ? 0.9 : 0.65)
                UIAccessibility.post(notification: .announcement,argument: "\(perfect ? "Perfect shot." : "Shield hit.") \(round.broken.count) of 3 guards broken.")
            case .missed:
                note = "A little higher or lower. Follow the dotted arc."; noteUntil = visualTime+3.5
                if soundOn { audio.cue("sling-miss",volume: 0.32) }
                UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.3)
            case .reloaded:
                if soundOn { audio.cue("sling-load",volume: 0.24) }
            case .topple:
                note = "The giant’s guard is gone."; noteUntil = visualTime+3
                if soundOn { audio.cue("sling-topple",volume: 0.5) }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .won:
                audio.stop(); scene.isPaused = true
                if soundOn { audio.cue("shepherd-complete",volume: 0.55) }
                if round.score > bestScore { bestScore = round.score; UserDefaults.standard.set(bestScore,forKey: "GoliathSlingBestScore") }
                if !completionDelivered { completionDelivered = true; onComplete?() }
            case .lost:
                audio.stop(); scene.isPaused = true
                UIAccessibility.post(notification: .announcement,argument: "All five stones are used. Try the challenge again.")
            }
        }
    }
    private func publish() {
        var next = GoliathSlingHUD()
        next.phase = round.phase; next.stones = round.stones; next.broken = round.broken.count; next.score = round.score
        next.shots = round.shots; next.perfects = round.perfects; next.stars = round.stars
        next.angle = round.angle; next.power = round.power; next.aiming = round.aiming
        if round.phase == .flight { next.message = "Watch it fly…" }
        else if round.phase == .toppling { next.message = "A small stone. A great courage." }
        else if !note.isEmpty && visualTime < noteUntil { next.message = note }
        else if round.aiming {
            let prediction = round.prediction()
            next.message = prediction.target != nil ? "On target. Release when you’re ready." : "Draw back. Follow the arc. Find a bronze guard."
        } else if round.shots > 0 { next.message = "Pull the stone back for your next shot." }
        hud = next
    }
    deinit { link?.invalidate() }
}
private final class SlingDisplayTarget: NSObject {
    weak var owner: GoliathSlingController?
    @objc func frame(_ link: CADisplayLink) { owner?.frame(link) }
}
struct GoliathArenaView: UIViewRepresentable {
    let controller: GoliathSlingController
    func makeUIView(context: Context) -> SKView {
        let view = SKView(); view.ignoresSiblingOrder = true; view.preferredFramesPerSecond = 60
        view.isMultipleTouchEnabled = false; view.presentScene(controller.scene); return view
    }
    func updateUIView(_ view: SKView,context: Context) { view.isPaused = [.paused,.won,.lost].contains(controller.hud.phase) }
    static func dismantleUIView(_ view: SKView,coordinator: ()) { view.isPaused = true; view.presentScene(nil) }
}
private final class GoliathSlingAudio {
    private var bed: AVAudioPlayer?
    private var cues: [String: AVAudioPlayer] = [:]
    private var prepared = false
    private func prepare() { if !prepared { try? AVAudioSession.sharedInstance().setCategory(.ambient,mode: .default,options: .mixWithOthers); prepared = true } }
    func ambience() {
        prepare()
        if bed == nil,let url = Bundle.main.url(forResource: "sling-valley",withExtension: "wav") { bed = try? AVAudioPlayer(contentsOf: url); bed?.numberOfLoops = -1; bed?.volume = 0.24 }
        bed?.play()
    }
    func cue(_ name: String,volume: Float) {
        prepare()
        if cues[name] == nil,let url = Bundle.main.url(forResource: name,withExtension: "wav") { cues[name] = try? AVAudioPlayer(contentsOf: url); cues[name]?.prepareToPlay() }
        cues[name]?.currentTime = 0; cues[name]?.volume = volume; cues[name]?.play()
    }
    func stop() { bed?.pause(); cues.values.forEach { $0.stop() } }
}
