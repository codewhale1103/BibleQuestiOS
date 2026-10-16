import SwiftUI
import SceneKit
import AVFoundation
import Combine

final class ArkWorkshopController: NSObject,ObservableObject {
    @Published private(set) var round = ArkWorkshopRound()
    @Published private(set) var time = 0.0
    @Published private(set) var soundOn = true
    @Published private(set) var targets: [ArkWorkshopPoint] = []
    @Published private(set) var message = ""
    @Published private(set) var burst = 0
    @Published private(set) var brushLocation: CGPoint?
    @Published private(set) var timberHint: Int?
    let art = ArkWorkshopScene()
    weak var surface: SCNView?
    var reduceMotion = false
    var onComplete: (() -> Void)?
    private let speech = AVSpeechSynthesizer()
    private var bed: AVAudioPlayer?
    private var voices: [AVAudioPlayer] = []
    private var link: CADisplayLink?
    private var clockTarget: ArkWorkshopClockTarget?
    private var previousTime: Double?
    private var delivered = false
    private var lastBrush: ArkWorkshopPoint?
    private var messageUntil = 0.0
    func attach() {
        guard link == nil else { return }
        try? AVAudioSession.sharedInstance().setCategory(.ambient,mode: .default,options: .mixWithOthers)
        let target = ArkWorkshopClockTarget(); target.owner = self; clockTarget = target
        let link = CADisplayLink(target: target,selector: #selector(ArkWorkshopClockTarget.frame(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30,maximum: 60,preferred: 60)
        link.add(to: .main,forMode: .common); self.link = link
    }
    func detach() { link?.invalidate(); link = nil; clockTarget = nil; previousTime = nil; stopAudio(); onComplete = nil; lastBrush = nil; brushLocation = nil }
    func start() {
        art.resetPaint(); brushLocation = nil; timberHint = nil; round.start(); time = 0; previousTime = nil; delivered = false; message = ""; messageUntil = 0; lastBrush = nil
        ambience(); narrate(round.step.instruction)
    }
    func begin() { round.beginTask(); message = round.step.prompt; messageUntil = time+8 }
    func uncover(_ id: Int) { process(round.uncover(id)) }
    func dropTimber(_ id: Int,at point: CGPoint,basket: CGRect) {
        guard point.x.isFinite,point.y.isFinite,basket.width > 0,basket.height > 0 else { return }
        process(round.storeTimber(id,inBasket: basket.insetBy(dx: -20,dy: -20).contains(point)))
    }
    func timberClue() {
        timberHint = (0..<ArkWorkshopRound.timberCount).first { !round.wood.contains($0) }
        message = "Look for the glowing leaves. Sweep them aside, then carry the beam to the basket."; messageUntil = time+8; narrate(message)
    }
    func accessibleTimber(_ id: Int) { process(round.uncover(id)); process(round.storeTimber(id,inBasket: true)) }
    func selectDeck(_ index: Int) {
        round.selectDeck(index)
        if round.selectedDeck == index { UISelectionFeedbackGenerator().selectionChanged(); message = "Drag this deck onto shadow \(index+1)."; messageUntil = time+5 }
    }
    func placeDeck(_ index: Int) {
        if round.selectedDeck == nil { message = "Choose a deck below, then tap its number."; messageUntil = time+5; narrate(message) }
        else { process(round.placeDeck(at: index)) }
    }
    func dropDeck(_ index: Int,point: ArkWorkshopPoint) {
        guard point.finite,round.phase == .playing,round.step == .decks,targets.count == 3 else { return }
        round.selectDeck(index)
        if let target = targets.indices.min(by: { targets[$0].distance(to: point) < targets[$1].distance(to: point) }),targets[target].distance(to: point) < 0.19 { placeDeck(target) }
    }
    func chooseColor(_ color: ArkPaintColor) {
        round.chooseColor(color); lastBrush = nil; art.endPaintStroke()
        message = "\(color.name) is ready. Drag the brush onto your ark!"; messageUntil = time+5
        UISelectionFeedbackGenerator().selectionChanged()
    }
    func pickUpBrush() -> Bool {
        guard round.pickUpBrush() else { message = "Choose a color from the palette first."; messageUntil = time+5; narrate(message); return false }
        return true
    }
    func flipSide() {
        round.flipSide(); lastBrush = nil; brushLocation = nil; art.endPaintStroke()
        message = "Paint the \(round.inside ? "inside" : "outside"). Your colors stay on both sides!"; messageUntil = time+5
        narrate(message)
    }
    func paintStroke(from start: ArkWorkshopPoint,to point: ArkWorkshopPoint,ended: Bool = false,boardFrame: CGRect) {
        guard round.phase == .playing,round.step == .pitch,round.brushEquipped,let color = round.selectedColor,let surface,
              start.finite,point.finite,(-3...3).contains(start.x),(-3...3).contains(start.y),(-3...3).contains(point.x),(-3...3).contains(point.y) else { return }
        brushLocation = CGPoint(x: boardFrame.minX+point.x*boardFrame.width,y: boardFrame.minY+point.y*boardFrame.height)
        let from = lastBrush ?? start
        let steps = min(180,max(1,Int(ceil(from.distance(to: point)/0.008))))
        var samples: [CGPoint?] = []
        for i in 0...steps {
            let t = Double(i)/Double(steps)
            let p = ArkWorkshopPoint(x: from.x+(point.x-from.x)*t,y: from.y+(point.y-from.y)*t)
            let uv = art.paintUV(at: p,in: surface,inside: round.inside); samples.append(uv)
            if let uv { process(round.paint(at: .init(x: uv.x,y: uv.y))) }
        }
        art.applyPaint(samples,inside: round.inside,color: color)
        lastBrush = point
        if ended { lastBrush = nil; brushLocation = nil; art.endPaintStroke() }
    }
    func dragBrush(from start: CGPoint,to point: CGPoint,ended: Bool,bounds: CGRect) {
        guard bounds.width > 0,bounds.height > 0,pickUpBrush() else { return }
        paintStroke(from: .init(x: (start.x-bounds.minX)/bounds.width,y: (start.y-bounds.minY)/bounds.height),to: .init(x: (point.x-bounds.minX)/bounds.width,y: (point.y-bounds.minY)/bounds.height),ended: ended,boardFrame: bounds)
    }
    func accessiblePaint() {
        guard pickUpBrush(),let color = round.selectedColor else { return }
        guard let cell = (0..<ArkWorkshopRound.paintCellCount).first(where: { !round.coverage[round.side].contains($0) }) else { return }
        let uv = CGPoint(x: (Double(cell%12)+0.5)/12,y: (Double(cell/12)+0.5)/4)
        process(round.paint(at: .init(x: uv.x,y: uv.y))); art.endPaintStroke(); art.applyPaint([uv],inside: round.inside,color: color); art.endPaintStroke()
    }
    func finishPainting() { process(round.finishPainting()) }
    func next() {
        round.continueDiscovery(); message = ""; lastBrush = nil
        if round.phase == .listening { narrate(round.step.instruction) }
        else if round.phase == .reveal { cue("call-finish",volume: 0.6); narrate("Your ark is ready! You found the wood, fitted the decks, and made a colorful creation.") }
    }
    func pause() { round.pause(); stopAudio(); lastBrush = nil; brushLocation = nil; art.endPaintStroke() }
    func resume() { round.resume(); previousTime = nil; ambience(); if round.phase == .listening { narrate(round.step.instruction) } }
    func toggleSound() { soundOn.toggle(); if soundOn && ![.intro,.paused,.won].contains(round.phase) { ambience() } else { stopAudio() } }
    func readAgain() {
        if !soundOn { soundOn = true; ambience() }
        narrate(round.phase == .discovery ? round.step.discovery : round.phase == .intro ? "Help Noah build the ark! Hunt for timber, fit the decks, and paint your own colorful design." : round.step.instruction)
    }
    func narrate(_ text: String) {
        guard soundOn else { return }; speech.stopSpeaking(at: .immediate)
        if UIAccessibility.isVoiceOverRunning { UIAccessibility.post(notification: .announcement,argument: text); return }
        let line = AVSpeechUtterance(string: text); line.voice = AVSpeechSynthesisVoice(language: "en-US"); line.rate = 0.44; line.pitchMultiplier = 1.04; line.volume = 0.9
        speech.speak(line)
    }
    func projectTargets(in view: SCNView) {
        let step = round.step,inside = round.inside
        let points = art.targets(in: view,step: step,inside: inside)
        guard points.count != targets.count || zip(points,targets).contains(where: { pair in pair.0.distance(to: pair.1) > 0.002 }) else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self,self.round.step == step,self.round.inside == inside,self.surface === view else { return }
            if self.targets != points { self.targets = points }
        }
    }
    fileprivate func frame(_ display: CADisplayLink) {
        let dt = min(0.05,max(0,previousTime.map { display.timestamp-$0 } ?? 1.0/60)); previousTime = display.timestamp
        guard round.phase != .paused else { return }
        time += dt; process(round.advance(dt))
        art.animate(time: time,celebrating: [.intro,.reveal,.won].contains(round.phase),reduceMotion: reduceMotion)
        if !message.isEmpty,time > messageUntil { message = "" }
    }
    private func process(_ events: [ArkWorkshopRound.Event]) {
        for event in events {
            switch event {
            case .uncovered:
                cue("call-brush",volume: 0.3); UISelectionFeedbackGenerator().selectionChanged(); message = "You found timber! Drag it to the basket."; messageUntil = time+5
            case .timber:
                timberHint = nil; cue("call-wood",volume: 0.55); celebrate(); message = "\(round.wood.count) of 5 beams in the basket!"; messageUntil = time+3
            case let .deck(index):
                cue("call-fit",volume: 0.5); celebrate(); narrate(["Lower deck!","Middle deck!","Upper deck!"][index])
            case .painted:
                if round.coveragePercent%10 < 4 { cue("call-brush",volume: 0.1) }
                if round.paintReady { message = "Beautiful! Keep decorating, or reveal your ark."; messageUntil = time+10 }
            case .hint:
                message = round.step == .timber ? "Carry the beam into the timber basket below. You can try again!" : "Match the same number and color. You can try again!"
                messageUntil = time+7; narrate(message)
            case .discovery:
                cue("call-discovery",volume: 0.45); celebrate(); narrate(round.step.discovery)
                UIAccessibility.post(notification: .screenChanged,argument: nil)
            case .won:
                stopAudio()
                if !delivered { delivered = true; onComplete?() }
                UIAccessibility.post(notification: .announcement,argument: "Build the Ark complete. Your creation is ready!")
            }
        }
    }
    private func celebrate() { burst += 1; UINotificationFeedbackGenerator().notificationOccurred(.success) }
    private func ambience() {
        guard soundOn else { return }
        if bed == nil,let url = Bundle.main.url(forResource: "call-workshop",withExtension: "wav") { bed = try? AVAudioPlayer(contentsOf: url); bed?.numberOfLoops = -1 }
        bed?.volume = 0.16; bed?.play()
    }
    private func cue(_ name: String,volume: Float) {
        guard soundOn,let url = Bundle.main.url(forResource: name,withExtension: "wav"),let player = try? AVAudioPlayer(contentsOf: url) else { return }
        voices.removeAll { !$0.isPlaying }; if voices.count >= 10 { voices.removeFirst().stop() }
        player.volume = volume; player.play(); voices.append(player)
    }
    private func stopAudio() { speech.stopSpeaking(at: .immediate); bed?.pause(); voices.forEach { $0.stop() }; voices.removeAll() }
    deinit { link?.invalidate() }
}
private final class ArkWorkshopClockTarget: NSObject {
    weak var owner: ArkWorkshopController?
    @objc func frame(_ display: CADisplayLink) { owner?.frame(display) }
}
