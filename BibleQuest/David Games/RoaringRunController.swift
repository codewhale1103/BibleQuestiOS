import SwiftUI
import SceneKit
import AVFoundation
import Combine

struct RoaringRunHUD: Equatable {
    var seconds = 30
    var progress: Double = 0
    var courage = 3
    var dodges = 0
    var meters = 0
    var countdown = 3
    var warning = ""
    var hitFlash: Double = 0
    var chapter: String { progress < 0.33 ? "THE OLIVE PASS" : (progress < 0.73 ? "LION’S GORGE" : "THE SUNLIT GATE") }
}

final class RoaringRunController: NSObject, ObservableObject {
    let world = RoaringCanyonScene()
    @Published private(set) var phase: RoaringRun.Phase = .ready
    @Published private(set) var hud = RoaringRunHUD()
    @Published private(set) var soundOn = true
    @Published private(set) var bestMeters = UserDefaults.standard.integer(forKey: "RoaringBeastBestMeters")
    var onComplete: (() -> Void)?
    var reduceMotion = false
    private(set) var run = RoaringRun()
    private var link: CADisplayLink?
    private var linkTarget: RoaringDisplayTarget?
    private var previousTime: CFTimeInterval?
    private var visualTime: Double = 0
    private var publishTime: Double = 0
    private var footstepTime: Double = 0
    private var flash: Double = 0
    private var deliveredCompletion = false
    private let audio = RoaringRunAudio()

    func attach() {
        guard link == nil else { return }
        let target = RoaringDisplayTarget(); target.owner = self; linkTarget = target
        let display = CADisplayLink(target: target, selector: #selector(RoaringDisplayTarget.update(_:)))
        display.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        display.add(to: .main, forMode: .common)
        link = display; previousTime = nil
    }
    func detach() {
        link?.invalidate(); link = nil; linkTarget = nil; previousTime = nil
        audio.stop(); onComplete = nil
    }
    func start() {
        run.start(seed: UInt64.random(in: 1...99999))
        deliveredCompletion = false; flash = 0; visualTime = 0; footstepTime = 0
        world.reset(); audio.stop(); publish()
    }
    func move(_ delta: Int) {
        let old = run.lane
        run.move(delta)
        if old != run.lane { UISelectionFeedbackGenerator().selectionChanged() }
    }
    func jump() {
        if run.jump() {
            if soundOn { audio.cue("beast-jump") }
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.65)
        }
    }
    func pause() {
        run.pause(); audio.pause(); publish()
    }
    func resume() {
        run.resume(); previousTime = nil
        if soundOn, run.phase == .running { audio.music() }
        publish()
    }
    func toggleSound() {
        soundOn.toggle()
        if !soundOn { audio.stop() }
        else if run.phase == .running { audio.music() }
    }
    fileprivate func frame(_ display: CADisplayLink) {
        let raw = previousTime.map { display.timestamp - $0 } ?? 1.0 / 60
        previousTime = display.timestamp
        if raw > 0.3, run.phase == .running || run.phase == .countdown { pause() }
        let dt = min(max(0, raw), 1.0 / 30)
        if run.phase != .paused { visualTime += dt }
        let oldPhase = run.phase
        let events = run.advance(dt)
        if oldPhase != .running, run.phase == .running, soundOn { audio.music() }
        for event in events {
            switch event {
            case .hit:
                flash = 1; world.registerHit()
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 0.8)
                if soundOn { audio.cue("beast-hit") }
            case .finished:
                audio.stop()
                if soundOn { audio.cue("shepherd-complete") }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                if !deliveredCompletion { deliveredCompletion = true; onComplete?() }
            case .dodged: break
            }
        }
        if run.phase == .caught { audio.pause() }
        if run.phase == .running {
            footstepTime += dt
            if footstepTime > 0.3, run.jumpHeight < 0.15 {
                footstepTime = 0
                if soundOn { audio.cue("shepherd-rustle", volume: 0.12) }
            }
        }
        flash = max(0, flash - dt * 3)
        world.update(run: run, time: visualTime, dt: dt, reduceMotion: reduceMotion)
        publishTime += dt
        if publishTime > 0.08 || phase != run.phase {
            publishTime = 0; publish()
        }
    }
    private func publish() {
        if phase != run.phase { phase = run.phase }
        var next = RoaringRunHUD()
        next.seconds = Int(ceil(run.remaining)); next.progress = run.progress
        next.courage = run.courage; next.dodges = run.dodges; next.meters = Int(run.distance)
        next.countdown = max(1, Int(ceil(run.countdown))); next.hitFlash = flash
        if let hazard = run.closestHazard, hazard.distance < 23, run.phase == .running {
            let lane = ["LEFT", "CENTER", "RIGHT"][hazard.lane]
            next.warning = hazard.spansTrack ? "WIDE GAP · JUMP" :
                "\(hazard.kind == .gap ? "GAP" : hazard.kind == .rock ? "ROCKS" : "THORNS") · \(lane) LANE"
        }
        hud = next
        if run.phase == .finished || run.phase == .caught, next.meters > bestMeters {
            bestMeters = next.meters
            UserDefaults.standard.set(bestMeters, forKey: "RoaringBeastBestMeters")
        }
    }
    deinit { link?.invalidate() }
}

private final class RoaringDisplayTarget: NSObject {
    weak var owner: RoaringRunController?
    @objc func update(_ link: CADisplayLink) { owner?.frame(link) }
}

struct RoaringSceneView: UIViewRepresentable {
    let controller: RoaringRunController
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero, options: [SCNView.Option.preferredRenderingAPI.rawValue: SCNRenderingAPI.metal.rawValue])
        view.scene = controller.world.scene
        view.pointOfView = controller.world.cameraNode
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 60
        view.isPlaying = true; view.rendersContinuously = true
        view.allowsCameraControl = false
        view.backgroundColor = UIColor(Color(hex: "#D6BE99"))
        return view
    }
    func updateUIView(_ uiView: SCNView, context: Context) {}
    static func dismantleUIView(_ uiView: SCNView, coordinator: ()) {
        uiView.isPlaying = false; uiView.rendersContinuously = false; uiView.scene = nil
    }
}

private final class RoaringRunAudio {
    private var soundtrack: AVAudioPlayer?
    private var effects: [String: AVAudioPlayer] = [:]
    private var configured = false
    private func prepare() {
        guard !configured else { return }
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: .mixWithOthers)
        configured = true
    }
    func music() {
        prepare()
        if soundtrack == nil, let url = Bundle.main.url(forResource: "runningBeastMusic", withExtension: "m4a") {
            soundtrack = try? AVAudioPlayer(contentsOf: url)
            soundtrack?.numberOfLoops = -1; soundtrack?.volume = 0.32
        }
        soundtrack?.play()
    }
    func cue(_ name: String, volume: Float = 0.5) {
        prepare()
        if effects[name] == nil, let url = Bundle.main.url(forResource: name, withExtension: "wav") {
            effects[name] = try? AVAudioPlayer(contentsOf: url)
        }
        effects[name]?.volume = volume; effects[name]?.currentTime = 0; effects[name]?.play()
    }
    func pause() { soundtrack?.pause(); effects.values.forEach { $0.stop() } }
    func stop() { pause(); soundtrack?.currentTime = 0 }
}
