import Foundation

struct PromisePoint: Equatable {
    var x: Double
    var y: Double
    var finite: Bool { x.isFinite && y.isFinite }
    func distance(to other: Self) -> Double { hypot(x-other.x,y-other.y) }
}
enum PromiseColor: Int, CaseIterable, Identifiable {
    case red,orange,yellow,green,blue,indigo,violet
    var id: Int { rawValue }
    var name: String { ["Red","Orange","Yellow","Green","Blue","Indigo","Violet"][rawValue] }
    var hex: String { ["#F0757E","#F4AD73","#F4DB79","#8DCFAD","#82C9E4","#9199DC","#C49DDF"][rawValue] }
    var symbol: String { ["circle.fill","diamond.fill","sun.max.fill","leaf.fill","drop.fill","moon.fill","sparkle"][rawValue] }
    var note: Int { [62,64,66,67,69,71,74][rawValue] }
}
struct PromiseArc {
    let band: Int
    var rx: Double { 0.43-Double(band.clamped(to: 0...6))*0.031 }
    var ry: Double { 0.62-Double(band.clamped(to: 0...6))*0.041 }
    func point(_ fraction: Double) -> PromisePoint {
        let t = fraction.clamped(to: 0...1) * .pi
        return PromisePoint(x: 0.5-cos(t)*rx,y: 0.82-sin(t)*ry)
    }
    func projection(_ point: PromisePoint) -> Double {
        atan2((0.82-point.y)/ry,(0.5-point.x)/rx).clamped(to: 0...Double.pi)/Double.pi
    }
}
struct PromiseDiscovery {
    let title: String
    let question: String
    let choices: [String]
    let correct: Int
    let explanation: String
    let hint: String
    let reference: String
    static let all: [Self] = [
        .init(title: "A promise of faithfulness",question: "What did God promise after the flood?",choices: ["It would never rain again.","Never again to destroy all life with a flood.","The oceans would disappear."],correct: 1,explanation: "God promised that a flood would never again destroy all life. This covenant was for generations to come.",hint: "Rain would still fall. Think about what God promised to protect.",reference: "GENESIS 9:11–12"),
        .init(title: "Room for every living creature",question: "Who was included in God’s covenant?",choices: ["Only Noah.","Only the animals inside the ark.","Noah, his descendants, and every living creature."],correct: 2,explanation: "A covenant is a solemn promise. God included Noah’s family, future generations, and every living creature.",hint: "God’s covenant reached beyond one person and one family.",reference: "GENESIS 9:9–10"),
        .init(title: "A sign to remember",question: "What does the rainbow signify in Noah’s story?",choices: ["God’s covenant with the earth.","That no rain would ever fall.","That Noah had built another ark."],correct: 0,explanation: "God placed the rainbow in the clouds as a sign of His covenant with the earth. Seven colors help us explore one promise.",hint: "The rainbow is a reminder of the covenant.",reference: "GENESIS 9:13–17")
    ]
}

/// Pure game state: ordered light weaving, guided taps and discoveries share the same completion rules.
struct RainbowPromiseRound {
    enum Phase: Equatable { case intro,choose,weaving,bloom,question,lesson,reveal,won,paused }
    enum Event: Equatable { case chosen(Int),tryColor,star(Int,Int),band(Int),discovery(Int),tryAnswer,learned(Int),won }
    static let stops = [0.0,0.25,0.5,0.75,1.0]
    private(set) var phase: Phase = .intro
    private(set) var completedBands = 0
    private(set) var progress = 0.0
    private(set) var checkpoint = 0
    private(set) var started = false
    private(set) var phaseTime = 0.0
    private(set) var score = 0
    private(set) var firstTries = 0
    private(set) var discoveries = 0
    private(set) var wrongColors: Set<Int> = []
    private(set) var wrongAnswers: Set<Int> = []
    private(set) var pointer: PromisePoint?
    private var previousPhase: Phase = .choose
    var color: PromiseColor { PromiseColor(rawValue: min(6,completedBands)) ?? .red }
    var arc: PromiseArc { PromiseArc(band: min(6,completedBands)) }
    var stars: Int { firstTries >= 8 ? 3 : firstTries >= 5 ? 2 : 1 }
    var question: PromiseDiscovery { PromiseDiscovery.all[min(2,discoveries)] }
    var choices: [PromiseColor] {
        let i = color.rawValue
        let options = [color,PromiseColor(rawValue: (i+2)%7)!,PromiseColor(rawValue: (i+4)%7)!]
        let shift = (i+1)%3
        return Array(options[shift...])+Array(options[..<shift])
    }
    mutating func start() { self = Self(); phase = .choose }
    mutating func choose(_ choice: PromiseColor) -> [Event] {
        guard phase == .choose else { return [] }
        guard choice == color else {
            guard wrongColors.insert(choice.rawValue).inserted else { return [] }
            return [.tryColor]
        }
        if wrongColors.isEmpty { firstTries += 1; score += 100 } else { score += 70 }
        phase = .weaving; phaseTime = 0; progress = 0; checkpoint = 0; started = false; pointer = nil
        return [.chosen(choice.rawValue)]
    }
    mutating func trace(_ point: PromisePoint) -> [Event] {
        guard phase == .weaving,point.finite else { return [] }
        let t = arc.projection(point),nearest = arc.point(t)
        guard point.distance(to: nearest) <= 0.085 else { return [] }
        if !started {
            guard t < 0.13 else { return [] }
            started = true; pointer = nearest
        }
        guard t <= progress+0.19,t >= progress-0.12 else { return [] }
        pointer = nearest; progress = max(progress,t)
        return collectStars()
    }
    mutating func tapStar(_ index: Int) -> [Event] {
        guard phase == .weaving,index == checkpoint,(0..<5).contains(index) else { return [] }
        started = true; progress = Self.stops[index]; pointer = arc.point(progress)
        return collectStars()
    }
    private mutating func collectStars() -> [Event] {
        var events: [Event] = []
        while checkpoint < 5 && progress >= Self.stops[checkpoint]-0.035 {
            events.append(.star(completedBands,checkpoint)); checkpoint += 1; score += 100
        }
        if checkpoint == 5 {
            let band = completedBands; completedBands += 1; progress = 1; pointer = nil
            score += 150; phase = .bloom; phaseTime = 0; events.append(.band(band))
        }
        return events
    }
    mutating func answer(_ index: Int) -> [Event] {
        guard phase == .question,question.choices.indices.contains(index) else { return [] }
        guard index == question.correct else {
            guard wrongAnswers.insert(index).inserted else { return [] }; return [.tryAnswer]
        }
        if wrongAnswers.isEmpty { firstTries += 1; score += 250 } else { score += 180 }
        phase = .lesson; return [.learned(discoveries)]
    }
    mutating func continueLesson() {
        guard phase == .lesson else { return }
        discoveries += 1; wrongAnswers.removeAll()
        if completedBands == 7 { phase = .reveal; phaseTime = 0 }
        else { nextBand() }
    }
    private mutating func nextBand() {
        phase = .choose; progress = 0; checkpoint = 0; started = false; pointer = nil; wrongColors.removeAll(); phaseTime = 0
    }
    mutating func pause() {
        guard ![.intro,.paused,.won].contains(phase) else { return }
        previousPhase = phase; phase = .paused
    }
    mutating func resume() { guard phase == .paused else { return }; phase = previousPhase }
    mutating func advance(_ delta: Double) -> [Event] {
        guard delta.isFinite,delta > 0,phase == .bloom || phase == .reveal else { return [] }
        phaseTime += min(0.1,delta)
        if phase == .bloom && phaseTime >= 1.05 {
            if [2,4,7].contains(completedBands) { phase = .question; wrongAnswers.removeAll(); return [.discovery(discoveries)] }
            nextBand()
        } else if phase == .reveal && phaseTime >= 4.2 { phase = .won; return [.won] }
        return []
    }
}
