import Foundation

struct ArmorCampRound {
    enum Piece: String, CaseIterable, Identifiable {
        case helmet, breastplate, sword
        var id: String { rawValue }
        var title: String {
            switch self { case .helmet: return "Helmet"; case .breastplate: return "Breastplate"; case .sword: return "Sword" }
        }
        var artwork: String {
            switch self { case .helmet: return "ArmorCampHelmet"; case .breastplate: return "ArmorCampBreastplate"; case .sword: return "ArmorCampSword" }
        }
        var place: String {
            switch self { case .helmet: return "first"; case .breastplate: return "middle"; case .sword: return "last" }
        }
    }
    enum Phase: Equatable { case intro, fitting, ready, walking, completed, paused }
    enum Event: Equatable { case docked(Piece), ready, heavyStep, braveStep, completed }
    enum Drop: Equatable { case accepted, wrongStand, unavailable }
    private(set) var phase: Phase = .intro
    private(set) var selected: Piece?
    private(set) var stowed: Set<Piece> = []
    private(set) var settling: [Piece: Double] = [:]
    private(set) var strideRemaining: Double = 0
    private(set) var walkElapsed: Double = 0
    private(set) var tests = 0
    private(set) var elapsed: Double = 0
    private var priorPhase: Phase = .fitting
    var isTrying: Bool { strideRemaining > 0 }
    var strideProgress: Double { isTrying ? 1 - strideRemaining / 1.05 : 0 }
    var walkProgress: Double { min(1, walkElapsed / 2.6) }
    var returnedCount: Int { stowed.count }
    var remainingCount: Int { 3 - stowed.count - settling.count }
    var weight: Double { Double(remainingCount) / 3 }
    func isWorn(_ piece: Piece) -> Bool { !stowed.contains(piece) && settling[piece] == nil }
    mutating func start() { self = Self(); phase = .fitting }
    @discardableResult mutating func select(_ piece: Piece) -> Bool {
        guard phase == .fitting, !isTrying, isWorn(piece) else { return false }
        selected = piece; return true
    }
    mutating func drop(_ piece: Piece, onto stand: Piece?) -> Drop {
        guard phase == .fitting, !isTrying, selected == piece, isWorn(piece) else { return .unavailable }
        selected = nil
        guard stand == piece else { return .wrongStand }
        settling[piece] = 0.65
        return .accepted
    }
    mutating func tryStep() -> [Event] {
        guard !isTrying, settling.isEmpty else { return [] }
        if phase == .fitting {
            selected = nil; strideRemaining = 1.05; tests += 1
            return [.heavyStep]
        }
        if phase == .ready {
            phase = .walking; walkElapsed = 0; return [.braveStep]
        }
        return []
    }
    mutating func pause() {
        guard phase == .fitting || phase == .ready || phase == .walking else { return }
        priorPhase = phase; phase = .paused
    }
    mutating func resume() { if phase == .paused { phase = priorPhase } }
    mutating func advance(_ delta: Double) -> [Event] {
        guard delta.isFinite, delta > 0, phase == .fitting || phase == .ready || phase == .walking else { return [] }
        let dt = min(delta,1)
        elapsed += dt; strideRemaining = max(0,strideRemaining - dt)
        var events: [Event] = []
        for piece in Piece.allCases {
            guard let remaining = settling[piece] else { continue }
            if remaining <= dt {
                settling[piece] = nil; stowed.insert(piece); events.append(.docked(piece))
            } else { settling[piece] = remaining - dt }
        }
        if phase == .fitting, stowed.count == 3 { phase = .ready; events.append(.ready) }
        if phase == .walking {
            walkElapsed = min(2.6,walkElapsed + dt)
            if walkElapsed >= 2.6 - 0.000001 { walkElapsed = 2.6; phase = .completed; events.append(.completed) }
        }
        return events
    }
}
