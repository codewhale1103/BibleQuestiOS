import SwiftUI
import Combine
import AVFoundation

final class DoveVoyageController: NSObject,ObservableObject {
    private(set) var round = DoveVoyageRound()
    @Published private(set) var time = 0.0
    @Published private(set) var soundOn = true
    private(set) var camera = 260.0
    private(set) var discovery: DoveDiscovery?
    private(set) var discoveryUntil = 0.0
    private(set) var touch: DovePoint?
    var reduceMotion = false
    var onComplete: (() -> Void)?
    private var delivered = false
    private let audio = DoveVoyageAudio()
    private var display: CADisplayLink?
    private var proxy: DoveDisplayTarget?
    private var lastFrame: Double?
    private var lastWing = -10.0
    var voice: String {
        switch round.phase {
        case .intro,.launching: return ["first","second","third"][round.flight]
        case .seeking: return round.leg == 0 ? ["first","second","third"][round.flight] : round.flight == 0 ? "water" : "landscape"
        case .returning: return round.hasLeaf ? "leaf" : "homeward"
        case .leaf,.leafTaken: return "grove"
        case .landing: return "land"
        case .landed,.between: return round.flight == 0 ? "welcome" : "delivered"
        case .waiting,.ready: return "wait"
        case .settling,.settled: return "branch"
        case .finale,.won: return "finale"
        default: return "hint"
        }
    }
    func attach() {
        guard display == nil else { return };let proxy = DoveDisplayTarget();proxy.owner = self;self.proxy = proxy
        let link = CADisplayLink(target:proxy,selector:#selector(DoveDisplayTarget.frame(_:)))
        link.preferredFrameRateRange = .init(minimum:30,maximum:60,preferred:60);link.add(to:.main,forMode:.common);display = link
    }
    func detach() { display?.invalidate();display = nil;proxy = nil;audio.stop();onComplete = nil }
    func start() {
        audio.stop();round.start();time = 0;camera = 260;lastFrame = nil;delivered = false;discovery = nil;discoveryUntil = 0;touch = nil;lastWing = -10
        if soundOn { audio.begin();audio.narrate("first") };announce("Flight one. Explore the silver water.");objectWillChange.send()
    }
    func launch() { round.launch();camera = 260;lastFrame = nil;if soundOn { audio.narrate(["first","second","third"][round.flight],interrupt:true) };objectWillChange.send() }
    func steer(_ point:DovePoint) { touch = point;round.steer(direction:(point.x-0.5)*2,altitude:point.y);objectWillChange.send() }
    func release(_ point:DovePoint) { steer(point);touch = nil;round.release();objectWillChange.send() }
    func follow() { touch = nil;round.followBreeze();announce("Following a gentle breeze to the next discovery.");objectWillChange.send() }
    func pluck(from:DovePoint,to:DovePoint) { handle(round.pluck(from:from,to:to));objectWillChange.send() }
    func land(at:DovePoint) { handle(round.land(at:at));objectWillChange.send() }
    func settle(at:DovePoint) { handle(round.settle(at:at));objectWillChange.send() }
    func waitDays() { round.waitSevenDays();if soundOn { audio.narrate("wait",interrupt:true) };objectWillChange.send() }
    func explore() { round.explore();camera = round.position.x;if soundOn { audio.resume() };objectWillChange.send() }
    func pause() { round.pause();touch = nil;lastFrame = nil;audio.suspend();objectWillChange.send() }
    func resume() { round.resume();lastFrame = nil;if soundOn { audio.resume() };objectWillChange.send() }
    func read() { soundOn = true;audio.resume();audio.narrate(voice,interrupt:true);announce(round.objective);objectWillChange.send() }
    func readDiscovery(_ d:DoveDiscovery) { soundOn = true;audio.describe(["reflection","waterfall","olive"][d.rawValue]);announce(d.text) }
    func toggleSound() { soundOn.toggle();if soundOn && round.phase != .paused { audio.resume() } else { audio.mute() } }
    private func announce(_ text:String) { UIAccessibility.post(notification:.announcement,argument:text) }
    private func handle(_ events:[DoveVoyageRound.Event]) {
        for event in events {
            var speech: String?
            switch event {
            case .launched: if soundOn { audio.cue("wing",volume:0.16) }
            case .observed: speech = round.flight == 0 ? "water" : "landscape"
            case .homeward: if !round.hasLeaf { speech = "homeward" }
            case .grove: speech = "grove"
            case .leaf: speech = "leaf";if soundOn { audio.cue("leaf");audio.cue("glimmer",volume:0.17) };UIImpactFeedbackGenerator(style:.soft).impactOccurred()
            case .home: speech = "land"
            case .landed: if soundOn { audio.cue("coo",volume:0.13) };speech = round.flight == 0 ? "welcome" : "delivered";if soundOn { audio.cue("glimmer",volume:0.22) };UIImpactFeedbackGenerator(style:.soft).impactOccurred()
            case .week: break
            case .ready: announce("Seven days have passed. Ready for flight \(round.flight+1).")
            case .branch: speech = "branch"
            case .settled: if soundOn { audio.cue("glimmer",volume:0.2);audio.cue("coo",volume:0.18) };UIImpactFeedbackGenerator(style:.soft).impactOccurred()
            case .finished: if !delivered { delivered = true;onComplete?() };announce("Wings of Hope complete. Three flights, a fresh leaf, and a place to rest.")
            case .discovery(let d): discovery = d;discoveryUntil = time+5;if soundOn { audio.cue("glimmer",volume:0.13) };announce("Discovered: "+d.title)
            }
            if let speech,soundOn { audio.narrate(speech) }
        }
    }
    fileprivate func frame(_ link:CADisplayLink) {
        let dt = min(0.05,max(0,lastFrame.map { link.timestamp-$0 } ?? 1.0/60));lastFrame = link.timestamp
        guard round.phase != .paused else { return }
        let old = round.phase;handle(round.advance(dt));time += dt
        camera += (round.position.x-camera)*min(1,dt*2.8)
        if old != .finale && round.phase == .finale && soundOn { audio.narrate("finale",interrupt:true) }
        if round.flying && abs(round.velocity)>25 && time-lastWing>3.6 { lastWing = time;if soundOn { audio.cue("wing",volume:0.055) } }
    }
    deinit { display?.invalidate() }
}
private final class DoveDisplayTarget:NSObject {
    weak var owner:DoveVoyageController?
    @objc func frame(_ link:CADisplayLink) { owner?.frame(link) }
}
