import SwiftUI
import Combine
import AVFoundation

struct FloodRipple: Identifiable {
    let id = UUID()
    let point: FloodPoint
    let born: Double
}

final class ArkAfloatController: NSObject, ObservableObject {
    private(set) var round = ArkAfloatRound()
    @Published private(set) var time = 0.0
    @Published private(set) var soundOn = true
    @Published private(set) var outside = 0.0
    private(set) var dragPoint: FloodPoint?
    private(set) var draggedTask: FloodTask?
    private(set) var draggedApple: Int?
    private(set) var ripples: [FloodRipple] = []
    private(set) var wipes: [FloodPoint] = []
    private(set) var lastStroke: FloodPoint?
    private(set) var hintUntil = 0.0
    private(set) var successUntil = 0.0
    private(set) var message = ""
    private(set) var messageUntil = 0.0
    var reduceMotion = false
    var onComplete: (() -> Void)?
    private let audio = FloodAudio()
    private var link: CADisplayLink?
    private var target: FloodDisplayTarget?
    private var previous: Double?
    private var delivered = false
    private var nextPrompt: Double?
    func attach() {
        guard link == nil else { return }
        let target = FloodDisplayTarget(); target.owner = self; self.target = target
        let link = CADisplayLink(target: target,selector: #selector(FloodDisplayTarget.frame(_:)))
        link.preferredFrameRateRange = .init(minimum: 30,maximum: 60,preferred: 60)
        link.add(to: .main,forMode: .common); self.link = link
    }
    func detach() { link?.invalidate(); link = nil; target = nil; previous = nil; clearDrag(); audio.stop(); onComplete = nil }
    func start() {
        round.start(); time = 0; delivered = false; previous = nil; outside = 1; clearDrag(); wipes = []; ripples = []; message = ""; messageUntil = 0; hintUntil = 0; successUntil = 0; nextPrompt = nil; audio.stop()
        if soundOn { audio.ambience(outside: 1); audio.speak(["rain"]) }; objectWillChange.send()
    }
    func comeInside() {
        guard round.phase == .rain else { return }; round.comeInside(); setOutside(0); clearDrag()
        if soundOn { audio.speak(["welcome","basket"]) }; announce("Explore the ark. Drag the basket into its cradle."); objectWillChange.send()
    }
    func select(_ room: FloodRoom) { guard round.active else { return }; round.select(room); clearDrag(); nextPrompt = nil; setOutside(0); prompt(); objectWillChange.send() }
    func setOutside(_ amount: Double) {
        guard amount.isFinite else { return }
        outside = max(0,min(1,amount)); if soundOn { audio.ambience(outside: outside) }
        if outside > 0.2 { clearDrag() }
    }
    func settleView() { withAnimation(.easeInOut(duration: reduceMotion ? 0.1 : 0.45)) { setOutside(outside > 0.5 ? 1 : 0) } }
    func peek(_ exterior: Bool) { withAnimation(.easeInOut(duration: reduceMotion ? 0.1 : 0.55)) { setOutside(exterior ? 1 : 0) } }
    func launch() { process(round.launch()); objectWillChange.send() }
    func finish() {
        guard round.caredFor else { return }; round.finish(); setOutside(1); clearDrag()
        if soundOn { audio.speak(["finale"]); audio.cue("flood-finale",volume: 0.5) }; objectWillChange.send()
    }
    func pause() { round.pause(); clearDrag(); nextPrompt = nil; audio.stop(); objectWillChange.send() }
    func resume() { round.resume(); previous = nil; if soundOn { audio.ambience(outside: outside) }; objectWillChange.send() }
    func toggleSound() {
        soundOn.toggle()
        if soundOn && ![.intro,.paused].contains(round.phase) { audio.ambience(outside: outside) } else { audio.stop() }
    }
    func help() { hintUntil = time+7; if outside > 0.5 { if soundOn { audio.speak(["explore"]) } } else { prompt() } }
    func drag(_ task: FloodTask,to point: FloodPoint) {
        guard round.active,outside < 0.2,round.task == task,point.finite else { return }
        draggedTask = task; dragPoint = bounded(point); objectWillChange.send()
    }
    func drop(_ task: FloodTask,at point: FloodPoint) { process(round.drop(task,at: point)); clearDrag(); objectWillChange.send() }
    func pullRope(_ amount: Double) {
        guard outside < 0.2 else { return }; let previous = Int(round.rope*5)
        process(round.pullRope(amount))
        if Int(round.rope*5) != previous { if soundOn { audio.cue("flood-creak",volume: 0.15) }; UISelectionFeedbackGenerator().selectionChanged() }
        objectWillChange.send()
    }
    func shutter(left: Bool,amount: Double) {
        guard outside < 0.2 else { return }; let previous = left ? round.shutterLeft : round.shutterRight
        process(round.slideShutter(left: left,amount: amount))
        if previous < 0.9 && (left ? round.shutterLeft : round.shutterRight) >= 0.9 { if soundOn { audio.cue("flood-clunk",volume: 0.2) }; UISelectionFeedbackGenerator().selectionChanged() }
        objectWillChange.send()
    }
    func dragApple(_ index: Int,to point: FloodPoint) {
        guard round.task == .apples,outside < 0.2,point.finite else { return }; draggedApple = index; dragPoint = bounded(point); objectWillChange.send()
    }
    func dropApple(_ index: Int,at point: FloodPoint) { process(round.catchApple(index,at: point)); clearDrag(); objectWillChange.send() }
    func stroke(_ point: FloodPoint) {
        guard outside < 0.2,point.finite,point.distance(to: ArkAfloatRound.lamb) < 0.3 else { lastStroke = nil; return }
        if let previous = lastStroke {
            let distance = min(0.4,previous.distance(to: point))
            let steps = max(1,Int(ceil(distance/0.025)))
            for _ in 0..<steps { process(round.stroke(distance/Double(steps))) }
        }
        lastStroke = point; objectWillChange.send()
    }
    func endStroke() { lastStroke = nil }
    func cancelTouch() { clearDrag(); objectWillChange.send() }
    func wipe(_ point: FloodPoint) { guard point.finite else { return }; wipes.append(point); if wipes.count > 50 { wipes.removeFirst() }; objectWillChange.send() }
    func splash(_ point: FloodPoint) {
        guard point.finite,round.phase != .paused else { return }
        ripples.append(.init(point: bounded(point),born: time)); if ripples.count > 24 { ripples.removeFirst() }; process(round.touchRain()); objectWillChange.send()
    }
    func accessibleAction() { guard outside < 0.2 else { return }; process(round.accessibleAction()); objectWillChange.send() }
    func applePoint(_ index: Int) -> FloodPoint {
        if draggedApple == index,let dragPoint { return dragPoint }
        let t = reduceMotion ? Double(index) : time
        return .init(x: 0.24+Double(index)*0.23+sin(t*0.75+Double(index)*2.3)*0.12,y: 0.85+sin(t*0.65+Double(index))*0.025)
    }
    private func bounded(_ p: FloodPoint) -> FloodPoint { .init(x: min(0.96,max(0.04,p.x)),y: min(0.95,max(0.04,p.y))) }
    private func clearDrag() { dragPoint = nil; draggedTask = nil; draggedApple = nil; lastStroke = nil }
    private func prompt() {
        let clip = round.task?.voice ?? (round.ready && round.phase == .preparing ? "ready" : "cozy")
        if soundOn { audio.speak([clip]) }
        announce(round.task?.instruction ?? "This room is ready. Explore another room.")
    }
    private func announce(_ text: String) { UIAccessibility.post(notification: .announcement,argument: text) }
    private func process(_ events: [ArkAfloatRound.Event]) {
        for event in events {
            switch event {
            case .task(let task):
                successUntil = time+1.3; clearDrag(); hintUntil = 0
                if soundOn { audio.cue(task == .shutters || task == .stormShutters ? "flood-clunk" : "flood-kindness",volume: 0.4) }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                message = task == .soothe ? "Soft wool. A happy little heart." : task == .lantern ? "Look at that lovely glow." : "Beautifully done. A little care makes a difference."; messageUntil = time+3
                nextPrompt = time+1.4
                announce(task == .soothe ? "Your lamb is settled." : "Well done. \(round.count) caring actions complete.")
            case .apple:
                if soundOn { audio.cue("flood-plop",volume: 0.25) }; UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.45)
            case .prepared:
                nextPrompt = nil; setOutside(1); clearDrag()
                if soundOn { audio.speak(["launch"]); audio.cue("flood-lift",volume: 0.5) }; announce("The waters are rising. Watch the ark lift!")
            case .lifted:
                setOutside(0); if soundOn { audio.speak(["afloat","apples"]) }; announce("The ark is afloat. Let's keep everyone cozy.")
            case .splash: if soundOn { audio.splash() }
            case .won:
                if !delivered { delivered = true; onComplete?() }
                announce("Ark Afloat complete. Everyone is safe and cared for.")
            }
        }
    }
    fileprivate func frame(_ display: CADisplayLink) {
        let dt = min(0.05,max(0,previous.map { display.timestamp-$0 } ?? 1.0/60)); previous = display.timestamp
        guard round.phase != .paused else { return }
        time += dt; process(round.advance(dt)); ripples.removeAll { time-$0.born > 1.6 }
        if let next = nextPrompt,time >= next { nextPrompt = nil; if round.active { prompt() } }
    }
    deinit { link?.invalidate() }
}
private final class FloodDisplayTarget: NSObject {
    weak var owner: ArkAfloatController?
    @objc func frame(_ display: CADisplayLink) { owner?.frame(display) }
}
private final class FloodAudio: NSObject,AVAudioPlayerDelegate {
    private var rain: AVAudioPlayer?
    private var sea: AVAudioPlayer?
    private var voice: AVAudioPlayer?
    private var queue: [String] = []
    private var effects: [AVAudioPlayer] = []
    private var prepared = false
    private var exterior = 1.0
    private var lastSplash = 0.0
    private func prepare() {
        guard !prepared else { return }; prepared = true
        try? AVAudioSession.sharedInstance().setCategory(.ambient,mode: .default,options: [.mixWithOthers])
    }
    private func player(_ name: String,_ ext: String = "wav") -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name,withExtension: ext) else { return nil }; return try? AVAudioPlayer(contentsOf: url)
    }
    func ambience(outside: Double) {
        prepare(); exterior = outside
        if rain == nil { rain = player("flood-rain"); rain?.numberOfLoops = -1 }
        if sea == nil { sea = player("flood-sea"); sea?.numberOfLoops = -1 }
        rain?.setVolume(Float(0.07+outside*0.16)*(voice?.isPlaying == true ? 0.45 : 1),fadeDuration: 0.4)
        sea?.setVolume(Float(0.07+outside*0.08),fadeDuration: 0.4)
        if rain?.isPlaying == false { rain?.play() }; if sea?.isPlaying == false { sea?.play() }
    }
    func speak(_ clips: [String]) { prepare(); voice?.stop(); voice = nil; queue = clips; next() }
    private func next() {
        while !queue.isEmpty {
            let clip = queue.removeFirst()
            if let player = player("flood-voice-"+clip,"m4a") { voice = player; player.delegate = self; player.volume = 0.85; player.play(); ambience(outside: exterior); return }
        }
        voice = nil; ambience(outside: exterior)
    }
    func cue(_ name: String,volume: Float) {
        prepare(); effects.removeAll { !$0.isPlaying }; guard let p = player(name) else { return }; p.volume = volume; p.play(); effects.append(p)
        if effects.count > 10 { effects.removeFirst().stop() }
    }
    func splash() { let now = ProcessInfo.processInfo.systemUptime; guard now-lastSplash > 0.16 else { return }; lastSplash = now; cue("flood-plop",volume: 0.14) }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer,successfully flag: Bool) { if player === voice { next() } }
    func stop() { queue = []; voice?.stop(); voice = nil; rain?.pause(); sea?.pause(); effects.forEach { $0.stop() }; effects = [] }
}
