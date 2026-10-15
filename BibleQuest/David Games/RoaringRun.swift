import Foundation

/// World-space rules for the three-lane chase. Rendering never decides whether a hit occurred.
struct RoaringRun {
    enum Phase: Equatable { case ready, countdown, running, paused, caught, finished }
    enum HazardKind: CaseIterable { case rock, bush, gap }
    enum Event: Equatable { case dodged, hit, finished }
    struct Hazard: Identifiable {
        let id: Int
        let kind: HazardKind
        let lane: Int
        let spansTrack: Bool
        var distance: Double
        var evaluated = false
    }

    static let duration: Double = 30
    static let laneWidth: Double = 2.2
    private(set) var phase: Phase = .ready
    private(set) var lane = 1
    private(set) var lanePosition: Double = 1
    private(set) var elapsed: Double = 0
    private(set) var distance: Double = 0
    private(set) var countdown: Double = 3
    private(set) var strikes = 0
    private(set) var dodges = 0
    private(set) var hazards: [Hazard] = []
    private(set) var jumpTime: Double?
    private(set) var hitProtection: Double = 0
    private var savedPhase: Phase = .running
    private var waveIndex = 0
    private var nextWaveAt: Double = 0.6
    private var nextID = 0
    private var seed: UInt64 = 31

    var remaining: Double { max(0, Self.duration - elapsed) }
    var progress: Double { min(1, elapsed / Self.duration) }
    var speed: Double { 11 + progress * 5 }
    var jumpHeight: Double {
        guard let jumpTime else { return 0 }
        return max(0, sin(min(1, jumpTime / 0.88) * .pi)) * 1.85
    }
    var courage: Int { max(0, 3 - strikes) }
    var closestHazard: Hazard? { hazards.filter { !$0.evaluated && $0.distance > 0 }.min { $0.distance < $1.distance } }

    mutating func start(seed: UInt64 = 31) {
        self = RoaringRun()
        self.seed = max(1, seed)
        phase = .countdown
    }
    mutating func move(_ direction: Int) {
        guard phase == .running else { return }
        lane = min(2, max(0, lane + direction))
    }
    @discardableResult mutating func jump() -> Bool {
        guard phase == .running, jumpTime == nil else { return false }
        jumpTime = 0
        return true
    }
    mutating func pause() {
        guard phase == .running || phase == .countdown else { return }
        savedPhase = phase
        phase = .paused
    }
    mutating func resume() {
        guard phase == .paused else { return }
        phase = savedPhase
    }

    mutating func advance(_ delta: Double) -> [Event] {
        guard delta.isFinite, delta > 0 else { return [] }
        var events: [Event] = []
        // Small substeps keep a skipped render frame from tunnelling through an obstacle.
        var left = min(delta, 1)
        while left > 0.000001 {
            let dt = min(left, 1.0 / 120)
            left -= dt
            if phase == .countdown {
                countdown = max(0, countdown - dt)
                if countdown < 0.000001 { phase = .running }
                continue
            }
            guard phase == .running else { break }
            elapsed = min(Self.duration, elapsed + dt)
            distance += speed * dt
            lanePosition += (Double(lane) - lanePosition) * min(1, dt * 17)
            hitProtection = max(0, hitProtection - dt)
            if let time = jumpTime { jumpTime = time + dt >= 0.88 ? nil : time + dt }

            if elapsed >= nextWaveAt, elapsed < 25.5 {
                spawnWave()
            }
            for index in hazards.indices {
                hazards[index].distance -= speed * dt
                guard !hazards[index].evaluated, hazards[index].distance <= 0.65 else { continue }
                hazards[index].evaluated = true
                let hazard = hazards[index]
                let inLane = hazard.spansTrack || abs(Double(hazard.lane) - lanePosition) < 0.47
                let clearance: Double = hazard.kind == .gap ? 0.48 : (hazard.kind == .rock ? 1.0 : 1.2)
                if inLane && jumpHeight < clearance {
                    guard hitProtection <= 0 else { continue }
                    strikes += 1
                    hitProtection = 1.4
                    events.append(.hit)
                    if strikes >= 3 { phase = .caught; break }
                } else {
                    dodges += 1
                    events.append(.dodged)
                }
            }
            hazards.removeAll { $0.distance < -10 }
            if phase == .running, remaining <= 0.000001 {
                elapsed = Self.duration
                phase = .finished
                events.append(.finished)
            }
        }
        return events
    }

    private mutating func random(_ upper: Int) -> Int {
        seed = seed &* 6364136223846793005 &+ 1442695040888963407
        return Int((seed >> 33) % UInt64(upper))
    }
    private mutating func add(_ kind: HazardKind, lane: Int, full: Bool = false) {
        hazards.append(Hazard(id: nextID, kind: kind, lane: lane, spansTrack: full, distance: 48))
        nextID += 1
    }
    private mutating func spawnWave() {
        // Every wave has an escape lane. Wide gaps get extra space before the next wave.
        let wideGap = waveIndex == 6 || waveIndex == 13
        if wideGap {
            add(.gap, lane: 1, full: true)
            nextWaveAt = elapsed + 2.5
        } else {
            let firstLane = random(3)
            let kind: HazardKind = waveIndex < 2 ? .rock : HazardKind.allCases[random(3)]
            add(kind, lane: firstLane)
            if waveIndex > 3, waveIndex % 3 == 1 {
                add(waveIndex % 2 == 0 ? .bush : .rock, lane: (firstLane + 1 + random(2)) % 3)
            }
            nextWaveAt = elapsed + (waveIndex < 3 ? 1.9 : max(1.25, 1.75 - elapsed * 0.015))
        }
        waveIndex += 1
    }
}
