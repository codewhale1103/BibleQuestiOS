import Foundation

/// The crossing advances in fixed physics steps, independently of rendering and sensors.
struct ElahBalanceRound {
    enum Phase: Equatable { case intro, countdown, walking, falling, paused, won, lost }
    enum Event: Equatable { case began, marker(Int), breathe, stumbled, won, lost }
    static let duration = 36.0
    private(set) var phase: Phase = .intro
    private(set) var elapsed = 0.0
    private(set) var countdown = 2.6
    private(set) var offset = 0.0
    private(set) var velocity = 0.0
    private(set) var danger = 0.0
    private(set) var focus = 0.35
    private(set) var calmRemaining = 0.0
    private(set) var steadySeconds = 0.0
    private(set) var checkpoint = 0
    private(set) var fallElapsed = 0.0
    private var attemptStart = 0.0
    private var previousPhase: Phase = .walking
    var progress: Double { elapsed / Self.duration }
    var distance: Double { elapsed * 1.6 }
    var remaining: Double { max(0,Self.duration - elapsed) }
    var canBreathe: Bool { phase == .walking && focus >= 1 && calmRemaining == 0 }
    var steadyPercent: Int { elapsed > attemptStart ? min(100,Int(steadySeconds / (elapsed-attemptStart) * 100)) : 100 }
    var section: Int { min(2,Int(elapsed / 12)) }
    var chapter: String { ["QUIET STEPS","THE CROSSWIND","A STEADY HEART"][section] }
    var gustDirection: Double {
        let pattern: [Double] = [1,-1,-1,1,-1,1,1]
        return pattern[min(pattern.count-1,Int(elapsed / 5.5))]
    }
    var gustWarning: Bool { phase == .walking && elapsed.truncatingRemainder(dividingBy: 5.5) < 1.1 }
    var wind: Double {
        let t = elapsed.truncatingRemainder(dividingBy: 5.5)
        guard t > 1.1, t < 4.6 else { return 0 }
        let strength = 0.62 + min(0.50,elapsed / Self.duration * 0.55)
        return sin((t - 1.1) / 3.5 * .pi) * strength * gustDirection
    }

    mutating func start(from marker: Int = 0) {
        self = Self(); checkpoint = min(2,max(0,marker))
        elapsed = Double(checkpoint) * 12; attemptStart = elapsed
        phase = .countdown
    }
    mutating func pause() {
        guard phase == .countdown || phase == .walking || phase == .falling else { return }
        previousPhase = phase; phase = .paused
    }
    mutating func resume() { if phase == .paused { phase = previousPhase } }
    mutating func breathe() -> [Event] {
        guard canBreathe else { return [] }
        focus = 0; calmRemaining = 3.2; danger *= 0.3; velocity *= 0.3
        return [.breathe]
    }
    mutating func nudge(_ direction: Double) {
        guard phase == .walking, direction.isFinite else { return }
        velocity += min(1,max(-1,direction)) * 0.46
    }
    mutating func advance(_ delta: Double,input: Double) -> [Event] {
        guard delta.isFinite, delta > 0, [.countdown,.walking,.falling].contains(phase) else { return [] }
        let control = input.isFinite ? min(1,max(-1,input)) : 0
        var remainingDelta = min(0.25,delta), events: [Event] = []
        while remainingDelta > 0.0000001 {
            let dt = min(1.0/120,remainingDelta); remainingDelta -= dt
            if phase == .countdown {
                countdown = max(0,countdown-dt)
                if countdown < 0.000001 { countdown = 0; phase = .walking; events.append(.began) }
                continue
            }
            if phase == .falling {
                fallElapsed += dt
                if fallElapsed >= 1.1 { phase = .lost; events.append(.lost); break }
                continue
            }
            guard phase == .walking else { break }
            elapsed = min(Self.duration,elapsed + dt)
            let calm = calmRemaining > 0
            calmRemaining = max(0,calmRemaining-dt)
            let target = control * (calm ? 0.28 : 0.95)
            let acceleration = (target - offset) * (calm ? 5.2 : 3.0) - velocity * (calm ? 4.2 : 2.5) + wind * (calm ? 0.4 : 3.7)
            velocity += acceleration * dt
            offset += velocity * dt
            if abs(offset) < 0.30 {
                steadySeconds += dt
                if !calm { focus = min(1,focus + dt / 7) }
            }
            if abs(offset) > 0.76 { danger = min(1,danger + dt * (0.8 + (abs(offset)-0.76)*2)) }
            else { danger = max(0,danger - dt * 1.25) }
            if danger >= 1 || abs(offset) > 1.36 {
                phase = .falling; fallElapsed = 0; events.append(.stumbled); break
            }
            let marker = min(2,Int(elapsed / 12))
            if marker > checkpoint { checkpoint = marker; events.append(.marker(marker)) }
            if elapsed >= Self.duration - 0.000001 {
                elapsed = Self.duration; phase = .won; events.append(.won); break
            }
        }
        return events
    }
}
