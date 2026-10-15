import Foundation

struct StreamPoint: Equatable {
    var x: Double
    var y: Double
    static func +(lhs: Self, rhs: Self) -> Self { Self(x: lhs.x + rhs.x, y: lhs.y + rhs.y) }
    static func *(lhs: Self, rhs: Double) -> Self { Self(x: lhs.x * rhs, y: lhs.y * rhs) }
}

struct StreamGuardRound {
    enum Phase: Equatable { case ready, countdown, playing, paused, won, lost }
    struct Bird: Identifiable, Equatable {
        let id: Int
        let start: StreamPoint
        let bendA: StreamPoint
        let bendB: StreamPoint
        let duration: Double
        let variant: Int
        var age: Double = 0
        var progress: Double { min(1, age / duration) }
        var position: StreamPoint {
            let t = progress, a = 1 - t
            return start * (a * a * a) + bendA * (3 * a * a * t)
                + bendB * (3 * a * t * t) + StreamGuardRound.pouch * (t * t * t)
        }
        var direction: StreamPoint {
            let t = progress, a = 1 - t
            let first = StreamPoint(x: bendA.x - start.x, y: bendA.y - start.y) * (3 * a * a)
            let middle = StreamPoint(x: bendB.x - bendA.x, y: bendB.y - bendA.y) * (6 * a * t)
            let last = StreamPoint(x: StreamGuardRound.pouch.x - bendB.x, y: StreamGuardRound.pouch.y - bendB.y) * (3 * t * t)
            return first + middle + last
        }
    }
    enum Event: Equatable {
        case shooed(Bird, combo: Int, fromCall: Bool)
        case stolen(Bird, stone: Int)
        case call
        case won
        case lost
    }
    static let duration: Double = 30
    static let pouch = StreamPoint(x: 0.5, y: 0.22)
    private(set) var phase: Phase = .ready
    private(set) var elapsed: Double = 0
    private(set) var countdown: Double = 3
    private(set) var stones = 5
    private(set) var score = 0
    private(set) var shooed = 0
    private(set) var combo = 0
    private(set) var bestCombo = 0
    private(set) var callCharge = 0
    private(set) var birds: [Bird] = []
    private var previousPhase: Phase = .playing
    private var nextBird: Double = 0.35
    private var nextID = 1
    private var lastTap: Double = -10
    private var randomState: UInt64 = 31
    var remaining: Double { max(0, Self.duration - elapsed) }
    var progress: Double { elapsed / Self.duration }
    var callReady: Bool { callCharge == 5 }

    mutating func start(seed: UInt64 = 31) {
        self = Self()
        randomState = max(1, seed)
        phase = .countdown
    }
    mutating func pause() {
        guard phase == .playing || phase == .countdown else { return }
        previousPhase = phase; phase = .paused
    }
    mutating func resume() {
        guard phase == .paused else { return }
        phase = previousPhase
    }
    mutating func shoo(_ id: Int) -> [Event] {
        guard phase == .playing, let index = birds.firstIndex(where: { $0.id == id }) else { return [] }
        let bird = birds.remove(at: index)
        combo = elapsed - lastTap < 1.8 ? combo + 1 : 1
        lastTap = elapsed; bestCombo = max(bestCombo, combo)
        score += 100 + min(combo - 1, 4) * 25
        shooed += 1; callCharge = min(5, callCharge + 1)
        return [.shooed(bird, combo: combo, fromCall: false)]
    }
    mutating func call() -> [Event] {
        guard phase == .playing, callReady else { return [] }
        callCharge = 0
        let flock = birds
        birds.removeAll()
        score += flock.count * 50; shooed += flock.count
        return [.call] + flock.map { .shooed($0, combo: 0, fromCall: true) }
    }
    mutating func advance(_ delta: Double) -> [Event] {
        guard delta.isFinite, delta > 0, phase == .playing || phase == .countdown else { return [] }
        var events: [Event] = []
        var remainingDelta = min(delta, 1)
        while remainingDelta > 0.000001, phase == .playing || phase == .countdown {
            let step = min(remainingDelta, 1.0 / 120)
            remainingDelta -= step
            if phase == .countdown {
                countdown = max(0, countdown - step)
                if countdown < 0.000001 { phase = .playing; countdown = 0 }
                continue
            }
            elapsed = min(Self.duration, elapsed + step)
            if elapsed >= Self.duration - 0.000001 {
                elapsed = Self.duration; phase = .won; events.append(.won)
                break
            }
            if elapsed - lastTap > 1.8 { combo = 0 }
            for index in birds.indices { birds[index].age += step }
            let arrivals = birds.filter { $0.progress >= 1 }
            birds.removeAll { $0.progress >= 1 }
            for bird in arrivals {
                stones -= 1; combo = 0
                events.append(.stolen(bird, stone: stones))
                if stones == 0 { phase = .lost; events.append(.lost); break }
            }
            guard phase == .playing else { break }
            if elapsed >= nextBird, elapsed < 28.2 {
                spawn()
                let interval = 1.28 - progress * 0.60
                nextBird += interval + random() * 0.18
            }
        }
        return events
    }
    private mutating func spawn() {
        let side = nextID % 4
        let start: StreamPoint
        if side == 0 { start = StreamPoint(x: -0.15, y: 0.66 + random() * 0.22) }
        else if side == 2 { start = StreamPoint(x: 1.15, y: 0.67 + random() * 0.22) }
        else { start = StreamPoint(x: 0.12 + random() * 0.76, y: 1.1) }
        let bend = (random() - 0.5) * 0.5
        let a = StreamPoint(x: min(1.12, max(-0.12, start.x + bend)), y: 0.70 + random() * 0.16)
        let b = StreamPoint(x: 0.26 + random() * 0.48, y: 0.34 + random() * 0.16)
        birds.append(Bird(id: nextID, start: start, bendA: a, bendB: b,
                          duration: 4.5 - progress * 1.15, variant: nextID % 3))
        nextID += 1
    }
    private mutating func random() -> Double {
        randomState = randomState &* 6364136223846793005 &+ 1442695040888963407
        return Double(randomState >> 11) / Double(UInt64.max >> 11)
    }
}
