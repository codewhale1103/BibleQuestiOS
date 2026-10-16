import SwiftUI
import Combine
import AVFoundation

struct PromiseSpark: Identifiable {
    let id = UUID()
    let point: PromisePoint
    let band: Int
    let born: Double
}
final class RainbowPromiseController: NSObject,ObservableObject {
    private(set) var round = RainbowPromiseRound()
    @Published private(set) var visualTime = 0.0
    @Published private(set) var soundOn = true
    @Published private(set) var bestScore = UserDefaults.standard.integer(forKey: "RainbowPromiseBestScore")
    private(set) var sparks: [PromiseSpark] = []
    private(set) var message = ""
    private(set) var messageUntil = 0.0
    var onComplete: (() -> Void)?
    var reduceMotion = false
    private var link: CADisplayLink?
    private var target: PromiseDisplayTarget?
    private var previousTime: Double?
    private var lastDrag: PromisePoint?
    private var delivered = false
    private let audio = PromiseAudio()
    func attach() {
        guard link == nil else { return }
        let target = PromiseDisplayTarget(); target.owner = self; self.target = target
        let link = CADisplayLink(target: target,selector: #selector(PromiseDisplayTarget.frame(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30,maximum: 60,preferred: 60)
        link.add(to: .main,forMode: .common); self.link = link
    }
    func detach() { link?.invalidate(); link = nil; target = nil; previousTime = nil; audio.stop(); lastDrag = nil; onComplete = nil }
    func start() {
        round.start(); visualTime = 0; previousTime = nil; lastDrag = nil; sparks.removeAll(); delivered = false; message = ""; messageUntil = 0
        audio.stop(); if soundOn { audio.ambience() }; objectWillChange.send()
    }
    func choose(_ color: PromiseColor) { process(round.choose(color)); objectWillChange.send() }
    func drag(_ point: PromisePoint) {
        guard round.phase == .weaving,point.finite,(-1...2).contains(point.x),(-1...2).contains(point.y) else { return }
        if let previous = lastDrag {
            let steps = min(100,max(1,Int(ceil(previous.distance(to: point)/0.018))))
            for index in 1...steps {
                let t = Double(index)/Double(steps)
                process(round.trace(PromisePoint(x: previous.x+(point.x-previous.x)*t,y: previous.y+(point.y-previous.y)*t)))
            }
        } else { process(round.trace(point)) }
        lastDrag = point; objectWillChange.send()
    }
    func endDrag(_ point: PromisePoint) { drag(point); lastDrag = nil }
    func tapStar(_ index: Int) { process(round.tapStar(index)); objectWillChange.send() }
    func answer(_ index: Int) { process(round.answer(index)); objectWillChange.send() }
    func continueLesson() { round.continueLesson(); message = ""; lastDrag = nil; if round.phase == .choose && soundOn { audio.ambience() }; if round.phase == .reveal, soundOn { audio.cue("promise-resolve",volume: 0.65) }; objectWillChange.send() }
    func pause() { round.pause(); audio.stop(); lastDrag = nil; objectWillChange.send() }
    func resume() { round.resume(); previousTime = nil; if soundOn { audio.ambience() }; objectWillChange.send() }
    func toggleSound() { soundOn.toggle(); if soundOn && ![.intro,.won,.paused].contains(round.phase) { audio.ambience() } else { audio.stop() } }
    fileprivate func frame(_ display: CADisplayLink) {
        let dt = min(0.05,max(0,previousTime.map { display.timestamp-$0 } ?? 1.0/60)); previousTime = display.timestamp
        guard round.phase != .paused else { return }
        visualTime += dt; process(round.advance(dt)); sparks.removeAll { visualTime-$0.born > 1.4 }
    }
    private func process(_ events: [RainbowPromiseRound.Event]) {
        for event in events {
            switch event {
            case let .chosen(band):
                message = "Start at the bright star. Let the light follow you."; messageUntil = visualTime+4
                if soundOn { audio.note(band,volume: 0.3) }
                UISelectionFeedbackGenerator().selectionChanged()
            case .tryColor:
                message = "Look for \(round.color.name.lowercased()). Every color has its place."; messageUntil = visualTime+4
                UIAccessibility.post(notification: .announcement,argument: message)
            case let .star(band,index):
                sparks.append(.init(point: PromiseArc(band: band).point(RainbowPromiseRound.stops[index]),band: band,born: visualTime))
                if soundOn { audio.note(band,volume: 0.38) }
                UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.55)
                message = index == 4 ? "A ribbon of light, beautifully woven." : "Beautiful. Follow the next star."; messageUntil = visualTime+1.7
            case let .band(band):
                lastDrag = nil
                if soundOn { audio.cue("promise-bloom",volume: 0.45) }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                UIAccessibility.post(notification: .announcement,argument: "\(PromiseColor(rawValue: band)!.name) complete. \(round.completedBands) of 7 colors.")
            case .discovery:
                audio.soft(); UIAccessibility.post(notification: .screenChanged,argument: nil)
            case .tryAnswer:
                UIAccessibility.post(notification: .announcement,argument: round.question.hint)
            case .learned:
                if soundOn { audio.cue("promise-bloom",volume: 0.35) }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .won:
                audio.stop()
                if round.score > bestScore { bestScore = round.score; UserDefaults.standard.set(bestScore,forKey: "RainbowPromiseBestScore") }
                if !delivered { delivered = true; onComplete?() }
                UIAccessibility.post(notification: .announcement,argument: "Rainbow complete. \(round.stars) stars. Seven colors, one promise.")
            }
        }
    }
    deinit { link?.invalidate() }
}
private final class PromiseDisplayTarget: NSObject {
    weak var owner: RainbowPromiseController?
    @objc func frame(_ link: CADisplayLink) { owner?.frame(link) }
}
private final class PromiseAudio {
    private var bed: AVAudioPlayer?
    private var voices: [AVAudioPlayer] = []
    private var prepared = false
    func ambience() {
        prepare()
        if bed == nil,let url = Bundle.main.url(forResource: "promise-valley",withExtension: "wav") { bed = try? AVAudioPlayer(contentsOf: url); bed?.numberOfLoops = -1 }
        bed?.volume = 0.28; bed?.play()
    }
    func soft() { bed?.setVolume(0.12,fadeDuration: 0.4) }
    private func prepare() { if !prepared { try? AVAudioSession.sharedInstance().setCategory(.ambient,mode: .default,options: .mixWithOthers); prepared = true } }
    func note(_ band: Int,volume: Float) { cue("promise-note-\(band)",volume: volume) }
    func cue(_ name: String,volume: Float) {
        prepare(); voices.removeAll { !$0.isPlaying }
        guard let url = Bundle.main.url(forResource: name,withExtension: "wav"),let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.volume = volume; player.play(); voices.append(player)
        if voices.count > 14 { voices.removeFirst().stop() }
    }
    func stop() { bed?.pause(); voices.forEach { $0.stop() }; voices.removeAll() }
}
