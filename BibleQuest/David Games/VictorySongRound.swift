import Foundation

/// A deterministic musical clock. Rendering and audio both follow this clock; no delayed callbacks survive a replay.
struct VictorySongRound {
    enum Phase: Equatable { case intro, countIn, playing, finale, paused, won, practice }
    enum Judgment: Equatable { case perfect, good }
    enum NoteState: Equatable { case waiting, holding, caught, missed }
    struct Note: Identifiable, Equatable {
        let id: Int
        let lane: Int
        let time: Double
        let duration: Double
        let passage: Int
        let midi: Int
        var end: Double { time + duration }
    }
    enum Event: Equatable {
        case began
        case plucked(Int, Judgment)
        case sustained(Int)
        case missed(Int)
        case passage(Int)
        case finale
        case finished(Bool)
    }
    static let passages = ["A shepherd’s courage", "A heart of faith", "A song of thanks"]
    static let notes: [Note] = {
        let patterns = [[0,1,2,1,0,2,0,1,2,2,1,0], [1,0,2,0,1,2,1,2,0,1,2,0], [0,2,1,2,0,1,2,1,0,2,1,0]]
        let pitches = [[62,66,69], [62,67,71], [62,69,74]]
        var result: [Note] = [], time = 2.5
        for section in 0..<3 {
            for (index,lane) in patterns[section].enumerated() {
                let hold = index == 5 || index == 11
                result.append(Note(id: result.count,lane: lane,time: time,duration: hold ? 1.05 : 0,passage: section,midi: pitches[section][lane]))
                time += hold ? 1.8 : (section == 2 ? 0.72 : 0.82)
            }
            time += 1.6
        }
        return result
    }()
    static var duration: Double { (notes.last?.end ?? 0) + 1.2 }
    private(set) var phase: Phase = .intro
    private(set) var time = 0.0
    private(set) var phaseTime = 0.0
    private(set) var states = Array(repeating: NoteState.waiting,count: notes.count)
    private(set) var judgments: [Int: Judgment] = [:]
    private(set) var pressed: Set<Int> = []
    private(set) var score = 0
    private(set) var hits = 0
    private(set) var perfects = 0
    private(set) var sustained = 0
    private(set) var streak = 0
    private(set) var bestStreak = 0
    private(set) var passage = 0
    private(set) var gentle = false
    private var previousPhase: Phase = .playing
    private var pausedPhaseTime = 0.0
    private var isResuming = false
    var window: Double { gentle ? 0.42 : 0.27 }
    var accuracy: Double { Double(hits) / Double(Self.notes.count) }
    var lanterns: Int { min(12, hits / 3) }
    var stars: Int { accuracy >= 0.9 ? 3 : accuracy >= 0.72 ? 2 : 1 }
    var active: Bool { phase == .countIn || phase == .playing || phase == .finale }
    var countdown: Int { max(1,3-Int(phaseTime)) }

    mutating func start(gentle: Bool = false) {
        self = Self(); self.gentle = gentle; phase = .countIn
    }
    mutating func press(_ lane: Int) -> [Event] {
        guard phase == .playing,(0..<3).contains(lane),!pressed.contains(lane) else { return [] }
        pressed.insert(lane)
        let candidates = Self.notes.filter { $0.lane == lane && states[$0.id] == .waiting && abs($0.time-time) <= window }
        guard let note = candidates.min(by: { abs($0.time-time) < abs($1.time-time) }) else { return [] }
        let judgment: Judgment = abs(note.time-time) <= (gentle ? 0.19 : 0.115) ? .perfect : .good
        judgments[note.id] = judgment
        if note.duration > 0 { states[note.id] = .holding }
        else { states[note.id] = .caught }
        hits += 1; streak += 1; bestStreak = max(bestStreak,streak)
        if judgment == .perfect { perfects += 1 }
        score += (judgment == .perfect ? 100 : 70) + min(30,(streak-1)*2)
        return [.plucked(note.id,judgment)]
    }
    mutating func release(_ lane: Int) -> [Event] {
        pressed.remove(lane)
        guard phase == .playing else { return [] }
        var events: [Event] = []
        for note in Self.notes where note.lane == lane && states[note.id] == .holding {
            if time >= note.end - 0.13 { finishHold(note,events: &events) }
            else { states[note.id] = .caught; streak = 0 }
        }
        return events
    }
    mutating func pause() {
        guard active else { return }
        if !(phase == .countIn && isResuming) { previousPhase = phase; pausedPhaseTime = phaseTime }
        phase = .paused
        // Preserve a sustained note. Resume uses a visible count-in before the musical clock moves again.
        pressed.removeAll()
    }
    mutating func resume() {
        guard phase == .paused else { return }
        phase = .countIn; phaseTime = 0; isResuming = true
    }
    mutating func advance(_ delta: Double) -> [Event] {
        guard delta.isFinite,delta > 0,active else { return [] }
        let dt = min(delta,0.1)
        phaseTime += dt
        if phase == .countIn {
            if phaseTime >= 3 {
                phase = isResuming ? previousPhase : .playing
                phaseTime = isResuming ? pausedPhaseTime : 0
                isResuming = false
                return [.began]
            }
            return []
        }
        if phase == .finale {
            if phaseTime >= 3.8 { phase = .won; return [.finished(true)] }
            return []
        }
        time += dt
        var events: [Event] = []
        for note in Self.notes {
            if states[note.id] == .waiting && time > note.time+window {
                states[note.id] = .missed; streak = 0; events.append(.missed(note.id))
            } else if states[note.id] == .holding && time >= note.end-0.04 {
                // A paused hold is re-armed by touching its string again before its tail arrives.
                if pressed.contains(note.lane) { finishHold(note,events: &events) }
                else { states[note.id] = .caught; streak = 0 }
            }
        }
        let current = Self.notes.last(where: { $0.time-1.8 <= time })?.passage ?? 0
        if current != passage { passage = current; events.append(.passage(current)) }
        if time >= Self.duration {
            pressed.removeAll(); phaseTime = 0
            if accuracy >= 0.55 { phase = .finale; events.append(.finale) }
            else { phase = .practice; events.append(.finished(false)) }
        }
        return events
    }
    private mutating func finishHold(_ note: Note, events: inout [Event]) {
        states[note.id] = .caught; sustained += 1; score += 70; events.append(.sustained(note.id))
    }
}
