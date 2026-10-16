import SwiftUI
import SceneKit
import Combine
import CoreMotion
import AVFoundation

struct ElahBalanceHUD: Equatable {
    var phase: ElahBalanceRound.Phase = .intro
    var offset = 0.0
    var danger = 0.0
    var progress = 0.0
    var focus = 0.35
    var calm = false
    var canBreathe = false
    var checkpoint = 0
    var countdown = 3
    var meters = 0
    var steady = 100
    var chapter = "QUIET STEPS"
    var message = "Soft steps. Steady heart."
    var markerMessage = ""
}

final class ElahBalanceController: NSObject,ObservableObject {
    enum Control: String,CaseIterable { case touch = "Touch",tilt = "Tilt" }
    let world = ElahCrossingScene()
    @Published private(set) var hud = ElahBalanceHUD()
    @Published private(set) var soundOn = true
    @Published private(set) var control: Control = .touch
    @Published private(set) var touchValue = 0.0
    let motionAvailable: Bool
    var reduceMotion = false
    var onComplete: (() -> Void)?
    private(set) var round = ElahBalanceRound()
    private let motion = CMMotionManager()
    private var link: CADisplayLink?
    private var displayTarget: ElahDisplayTarget?
    private var previousTime: Double?
    private var time = 0.0
    private var publishTime = 0.0
    private var footTime = 0.0
    private var dangerTime = 0.0
    private var tiltValue = 0.0
    private var calibrationSum = 0.0
    private var calibrationCount = 0
    private var baseline = 0.0
    private var orientation: UIInterfaceOrientation?
    private var markerUntil = 0.0
    private var markerText = ""
    private var focusAnnounced = false
    private var announcedGust = -1
    private var completed = false
    private let audio = ElahBalanceAudio()

    override init() {
        motionAvailable = motion.isAccelerometerAvailable
        super.init()
        if motionAvailable && !UIAccessibility.isVoiceOverRunning { control = .tilt }
    }
    func attach() {
        guard link == nil else { return }
        let target = ElahDisplayTarget(); target.owner = self; displayTarget = target
        let display = CADisplayLink(target: target,selector: #selector(ElahDisplayTarget.frame(_:)))
        display.preferredFrameRateRange = CAFrameRateRange(minimum: 30,maximum: 60,preferred: 60)
        display.add(to: .main,forMode: .common); link = display; previousTime = nil
    }
    func detach() { link?.invalidate(); link = nil; displayTarget = nil; motion.stopAccelerometerUpdates(); audio.stop(); onComplete = nil }
    func start(fromCheckpoint: Bool = false) {
        let checkpoint = fromCheckpoint ? round.checkpoint : 0
        round.start(from: checkpoint); completed = false; time = 0; footTime = 0; dangerTime = 0
        markerUntil = 0; markerText = ""; touchValue = 0; tiltValue = 0; focusAnnounced = false; announcedGust = -1
        previousTime = nil; world.reset(); recalibrate(); audio.stop(); startMotion(); publish()
        if soundOn { audio.start() }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.5)
    }
    func setControl(_ value: Control) {
        guard value != .tilt || motionAvailable else { return }
        control = value; touchValue = 0; tiltValue = 0; recalibrate()
        if value == .touch { motion.stopAccelerometerUpdates() }
        else if [.walking,.countdown].contains(round.phase) { startMotion() }
        UISelectionFeedbackGenerator().selectionChanged()
    }
    func setTouch(_ value: Double) { guard value.isFinite else { return }; touchValue = min(1,max(-1,value)) }
    func lean(_ direction: Double) {
        guard round.phase == .walking else { return }
        if control != .touch { setControl(.touch) }
        setTouch(touchValue + direction * 0.16)
        UISelectionFeedbackGenerator().selectionChanged()
    }
    func center() { setTouch(0); if control == .tilt { recalibrate() }; UISelectionFeedbackGenerator().selectionChanged() }
    func breathe() { process(round.breathe()); publish() }
    func pause() { round.pause(); motion.stopAccelerometerUpdates(); audio.stop(); publish() }
    func resume() {
        round.resume(); previousTime = nil; touchValue = 0; recalibrate(); startMotion(); publish()
        if soundOn && [.walking,.countdown].contains(round.phase) { audio.start() }
    }
    func toggleSound() {
        soundOn.toggle()
        if soundOn && [.walking,.countdown].contains(round.phase) { audio.start() } else { audio.stop() }
    }
    private func recalibrate() { calibrationCount = 0; calibrationSum = 0; baseline = 0; tiltValue = 0 }
    private func startMotion() {
        guard control == .tilt, motionAvailable, [.walking,.countdown].contains(round.phase) else { return }
        motion.accelerometerUpdateInterval = 1.0 / 60
        motion.startAccelerometerUpdates(to: .main) { [weak self] data,_ in
            guard let self, let acceleration = data?.acceleration else { return }
            let current = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first { $0.activationState == .foregroundActive }?.interfaceOrientation ?? .portrait
            if let orientation = self.orientation, orientation != current {
                self.orientation = current; self.recalibrate()
                if self.round.phase == .walking { self.pause(); return }
            }
            self.orientation = current
            let axis: Double
            switch current { case .landscapeLeft: axis = acceleration.y; case .landscapeRight: axis = -acceleration.y; case .portraitUpsideDown: axis = -acceleration.x; default: axis = acceleration.x }
            if self.calibrationCount < 20 {
                self.calibrationSum += axis; self.calibrationCount += 1
                self.baseline = self.calibrationSum / Double(self.calibrationCount)
                return
            }
            let value = min(1,max(-1,(axis-self.baseline)*3.2))
            self.tiltValue = self.tiltValue * 0.8 + value * 0.2
        }
    }
    fileprivate func frame(_ display: CADisplayLink) {
        let raw = previousTime.map { display.timestamp-$0 } ?? 1.0/60; previousTime = display.timestamp
        guard ![.paused,.won,.lost].contains(round.phase) else { return }
        let dt = min(0.05,max(0,raw))
        if round.phase != .paused { time += dt }
        process(round.advance(dt,input: control == .tilt ? tiltValue : touchValue))
        if round.phase == .walking {
            let gust = Int(round.elapsed/5.5)
            if round.gustWarning, gust != announcedGust {
                announcedGust = gust
                UIAccessibility.post(notification: .announcement,argument: "A gust is coming. Lean \(round.gustDirection > 0 ? "left" : "right").")
            }
            footTime += dt
            if footTime > 0.42 {
                footTime = 0
                if soundOn { audio.cue("armor-light-step",volume: 0.18) }
            }
            if round.danger > 0.2 {
                dangerTime += dt
                if dangerTime > 0.6 { dangerTime = 0; UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: min(0.8,round.danger)) }
            }
            if round.canBreathe && !focusAnnounced {
                focusAnnounced = true
                if soundOn { audio.cue("elah-focus-ready",volume: 0.4) }
                UIAccessibility.post(notification: .announcement,argument: "Breathe is ready. Double tap Breathe to steady David.")
            }
        }
        if round.phase != .paused { world.update(round: round,time: time,dt: dt,reduced: reduceMotion) }
        audio.wind(strength: abs(round.wind),calm: round.calmRemaining > 0)
        publishTime += dt
        if publishTime > 0.07 || hud.phase != round.phase { publishTime = 0; publish() }
    }
    private func process(_ events: [ElahBalanceRound.Event]) {
        for event in events {
            switch event {
            case .began:
                if control == .tilt && calibrationCount < 20 {
                    setControl(.touch); markerText = "Touch controls are ready."; markerUntil = time + 3
                }
                UIAccessibility.post(notification: .announcement,argument: "The crossing begins. Keep David in the middle and lean against the wind.")
            case let .marker(index):
                markerText = index == 1 ? "One step at a time." : "The Lord is with you."
                markerUntil = time + 3.3
                if soundOn { audio.cue("elah-marker",volume: 0.5) }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                UIAccessibility.post(notification: .announcement,argument: "Marker \(index) reached. \(markerText)")
            case .breathe:
                focusAnnounced = false
                if soundOn { audio.cue("elah-breathe",volume: 0.45) }
                UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.5)
            case .stumbled:
                motion.stopAccelerometerUpdates(); audio.stop()
                if soundOn { audio.cue("elah-stumble",volume: 0.35) }
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            case .lost: audio.stop()
            case .won:
                motion.stopAccelerometerUpdates(); audio.stop()
                if soundOn { audio.cue("shepherd-complete",volume: 0.55) }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                if !completed { completed = true; onComplete?() }
            }
        }
    }
    private func publish() {
        var next = ElahBalanceHUD()
        next.phase = round.phase; next.offset = round.offset; next.danger = round.danger
        next.progress = round.progress; next.focus = round.focus; next.calm = round.calmRemaining > 0
        next.canBreathe = round.canBreathe; next.checkpoint = round.phase == .won ? 3 : round.checkpoint
        next.countdown = max(1,Int(ceil(round.countdown))); next.meters = round.phase == .won ? 58 : Int(round.distance)
        next.steady = round.steadyPercent; next.chapter = round.chapter
        next.markerMessage = time < markerUntil ? markerText : ""
        let lean = round.gustDirection > 0 ? "left" : "right"
        if round.phase == .won { next.message = "Every faithful step brought you here." }
        else if next.calm { next.message = "Breathe in. Find your center." }
        else if next.danger > 0.12 { next.message = "Easy… guide David back to the middle." }
        else if round.gustWarning { next.message = "A gust is coming · lean \(lean)" }
        else if abs(round.wind) > 0.15 { next.message = "Wind \(round.wind > 0 ? "→" : "←") · lean \(round.wind > 0 ? "left" : "right")" }
        else { next.message = "Soft steps. Steady heart." }
        hud = next
    }
    deinit { link?.invalidate(); motion.stopAccelerometerUpdates() }
}

private final class ElahDisplayTarget: NSObject {
    weak var owner: ElahBalanceController?
    @objc func frame(_ link: CADisplayLink) { owner?.frame(link) }
}

struct ElahSceneView: UIViewRepresentable {
    let controller: ElahBalanceController
    func makeUIView(context: Context) -> SCNView {
        let view = ElahRenderView(frame: .zero,options: [SCNView.Option.preferredRenderingAPI.rawValue: SCNRenderingAPI.metal.rawValue])
        view.world = controller.world
        view.scene = controller.world.scene; view.pointOfView = controller.world.cameraNode
        view.antialiasingMode = .multisampling4X; view.preferredFramesPerSecond = 60
        view.isPlaying = true; view.rendersContinuously = true; view.backgroundColor = .clear; view.isOpaque = false
        view.isAccessibilityElement = false; return view
    }
    func updateUIView(_ view: SCNView,context: Context) {
        let active = ![.paused,.won,.lost].contains(controller.hud.phase)
        view.isPlaying = active; view.rendersContinuously = active
    }
    static func dismantleUIView(_ view: SCNView,coordinator: ()) { view.isPlaying = false; view.rendersContinuously = false; view.scene = nil }
}

private final class ElahBalanceAudio {
    private var ambience: AVAudioPlayer?
    private var breeze: AVAudioPlayer?
    private var cues: [String: AVAudioPlayer] = [:]
    private var prepared = false
    private func prepare() {
        if !prepared { try? AVAudioSession.sharedInstance().setCategory(.ambient,mode: .default,options: .mixWithOthers); prepared = true }
    }
    func start() {
        prepare()
        if ambience == nil, let url = Bundle.main.url(forResource: "elah-stream",withExtension: "wav") {
            ambience = try? AVAudioPlayer(contentsOf: url); ambience?.numberOfLoops = -1; ambience?.volume = 0.30
        }
        if breeze == nil, let url = Bundle.main.url(forResource: "elah-wind",withExtension: "wav") {
            breeze = try? AVAudioPlayer(contentsOf: url); breeze?.numberOfLoops = -1; breeze?.volume = 0.1
        }
        ambience?.play(); breeze?.play()
    }
    func wind(strength: Double,calm: Bool) { breeze?.volume = Float(calm ? 0.04 : 0.08+strength*0.24) }
    func cue(_ name: String,volume: Float) {
        prepare()
        if cues[name] == nil, let url = Bundle.main.url(forResource: name,withExtension: "wav") { cues[name] = try? AVAudioPlayer(contentsOf: url); cues[name]?.prepareToPlay() }
        cues[name]?.currentTime = 0; cues[name]?.volume = volume; cues[name]?.play()
    }
    func stop() { ambience?.pause(); breeze?.pause(); cues.values.forEach { $0.stop() } }
}

private final class ElahRenderView: SCNView {
    weak var world: ElahCrossingScene?
    override func layoutSubviews() {
        super.layoutSubviews()
        world?.wide = bounds.width > bounds.height * 1.3
    }
}
