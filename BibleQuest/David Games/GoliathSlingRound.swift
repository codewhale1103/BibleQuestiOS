import Foundation

struct SlingPoint: Equatable {
    var x: Double
    var y: Double
    static let zero = Self(x: 0,y: 0)
    var length: Double { hypot(x,y) }
    var finite: Bool { x.isFinite && y.isFinite }
    static func +(a: Self,b: Self) -> Self { Self(x: a.x+b.x,y: a.y+b.y) }
    static func -(a: Self,b: Self) -> Self { Self(x: a.x-b.x,y: a.y-b.y) }
    static func *(a: Self,b: Double) -> Self { Self(x: a.x*b,y: a.y*b) }
}

struct SlingArena {
    var width = 1000.0
    var height = 2150.0
    var wide: Bool { width > height * 1.3 }
    var anchor: SlingPoint { SlingPoint(x: width * (wide ? 0.23 : 0.27),y: height * (wide ? 0.49 : 0.30)) }
    var bossHeight: Double { min(height * (wide ? 0.74 : 0.60),width * 1.05) }
    var bossCenter: SlingPoint { SlingPoint(x: width * (wide ? 0.75 : 0.69),y: height * (wide ? 0.53 : 0.535)) }
    var guardRadius: Double { min(52,height * 0.075) }
    var gravity: Double { min(1000,max(400,height * 1.25)) }
    var ground: Double { height * (wide ? 0.15 : 0.17) }
    func target(_ id: Int,clock: Double) -> SlingPoint {
        let offsets = [SlingPoint(x: -0.07,y: 0.13),SlingPoint(x: 0.19,y: 0.005),SlingPoint(x: -0.025,y: -0.20)]
        let point = offsets[min(2,max(0,id))] * bossHeight
        return bossCenter + point + sway(clock)
    }
    func sway(_ clock: Double) -> SlingPoint { SlingPoint(x: sin(clock * 0.8) * 12,y: sin(clock * 1.6) * 4) }
}

struct GoliathSlingRound {
    enum Phase: Equatable { case intro,ready,flight,impact,toppling,paused,won,lost }
    enum Event: Equatable {
        case launched
        case hit(Int,SlingPoint,perfect: Bool,streak: Int)
        case missed(SlingPoint)
        case reloaded
        case topple
        case won
        case lost
    }
    struct Flight: Equatable { var position: SlingPoint; var velocity: SlingPoint; var age = 0.0 }
    struct Prediction { var points: [SlingPoint] = []; var target: Int?; var perfect = false }
    static let maxPull = 240.0
    static let minPull = 36.0
    static let launchScale = 6.2
    static let gravity = 1000.0
    static let stoneRadius = 11.0
    private(set) var arena = SlingArena()
    private(set) var phase: Phase = .intro
    private(set) var stones = 5
    private(set) var broken: Set<Int> = []
    private(set) var pull = SlingPoint.zero
    private(set) var flight: Flight?
    private(set) var clock = 0.0
    private(set) var phaseTime = 0.0
    private(set) var shots = 0
    private(set) var score = 0
    private(set) var perfects = 0
    private(set) var streak = 0
    private(set) var angle = 57.0
    private(set) var power = 0.76
    private var priorPhase: Phase = .ready
    var aiming: Bool { phase == .ready && pull.length >= Self.minPull }
    var canLaunch: Bool { phase == .ready && stones > 0 && pull.length >= Self.minPull }
    var pouch: SlingPoint { arena.anchor + pull }
    var stars: Int { max(1,3-max(0,shots-3)) }
    mutating func resize(aspect: Double) {
        guard aspect.isFinite, aspect > 0 else { return }
        let next = min(3200,max(350,1000/aspect))
        guard abs(arena.height-next) > 1 else { return }
        arena.height = next; pull = .zero
        if phase == .flight || (phase == .paused && priorPhase == .flight) {
            stones += 1; shots = max(0,shots-1); flight = nil
            if phase == .paused { priorPhase = .ready } else { phase = .ready; phaseTime = 0 }
        }
    }
    mutating func start() {
        let layout = arena
        self = Self(); arena = layout; phase = .ready
        angle = arena.wide ? 38 : 57; power = arena.wide ? 0.56 : 0.76
    }
    mutating func setPull(_ point: SlingPoint) {
        guard phase == .ready, stones > 0, point.finite else { return }
        var next = SlingPoint(x: min(0,point.x),y: min(0,point.y))
        if next.length > Self.maxPull { next = next * (Self.maxPull / next.length) }
        pull = next
        if pull.length >= Self.minPull { angle = atan2(-pull.y,-pull.x) * 180 / .pi; power = pull.length / Self.maxPull }
    }
    mutating func setAim(angle: Double,power: Double) {
        guard angle.isFinite,power.isFinite, phase == .ready else { return }
        let a = min(82,max(12,angle)) * .pi / 180
        let length = min(1,max(0.18,power)) * Self.maxPull
        setPull(SlingPoint(x: -cos(a)*length,y: -sin(a)*length))
    }
    mutating func cancelAim() { pull = .zero }
    mutating func launch() -> [Event] {
        guard canLaunch else { pull = .zero; return [] }
        flight = Flight(position: pouch,velocity: pull * -Self.launchScale)
        stones -= 1; shots += 1; pull = .zero; phase = .flight; phaseTime = 0
        return [.launched]
    }
    mutating func pause() {
        guard [.ready,.flight,.impact,.toppling].contains(phase) else { return }
        pull = .zero; priorPhase = phase; phase = .paused
    }
    mutating func resume() { if phase == .paused { phase = priorPhase } }
    mutating func advance(_ delta: Double) -> [Event] {
        guard delta.isFinite,delta > 0,![.paused,.won,.lost].contains(phase) else { return [] }
        var remaining = min(0.1,delta), events: [Event] = []
        while remaining > 0.0000001 {
            let dt = min(1.0/240,remaining); remaining -= dt
            clock += dt * (aiming ? 0.18 : 1)
            phaseTime += dt
            if phase == .flight, var stone = flight {
                let previous = stone.position
                stone.position = stone.position + stone.velocity * dt + SlingPoint(x: 0,y: -0.5*arena.gravity*dt*dt)
                stone.velocity.y -= arena.gravity*dt; stone.age += dt
                flight = stone
                var hit = false
                for id in 0..<3 where !broken.contains(id) {
                    let target = arena.target(id,clock: clock)
                    if Self.segmentDistance(target,from: previous,to: stone.position) <= arena.guardRadius+Self.stoneRadius {
                        let direction = stone.velocity * (1/max(0.001,stone.velocity.length))
                        let delta = target-previous
                        let accuracy = abs(delta.x*direction.y-delta.y*direction.x)
                        let perfect = accuracy <= arena.guardRadius*0.35
                        broken.insert(id); streak += 1; if perfect { perfects += 1 }
                        score += 700 + (perfect ? 300 : 0) + (streak-1)*150
                        events.append(.hit(id,target,perfect: perfect,streak: streak))
                        flight = nil; phase = .impact; phaseTime = 0; hit = true; break
                    }
                }
                if !hit && ((stone.position.y < arena.ground && stone.velocity.y < 0) || stone.position.x > arena.width+150 || stone.position.x < -150 || stone.age > 4) {
                    streak = 0; flight = nil; phase = .impact; phaseTime = 0
                    events.append(.missed(stone.position))
                }
            } else if phase == .impact, phaseTime >= 0.72 {
                phaseTime = 0
                if broken.count == 3 { phase = .toppling; events.append(.topple) }
                else if stones == 0 { phase = .lost; events.append(.lost) }
                else { phase = .ready; events.append(.reloaded) }
            } else if phase == .toppling, phaseTime >= 2.7 {
                phase = .won; phaseTime = 0; score += stones*200; events.append(.won)
            }
            if phase == .won || phase == .lost { break }
        }
        return events
    }
    func prediction() -> Prediction {
        guard canLaunch else { return Prediction() }
        var sample = self, result = Prediction(points: [pouch])
        _ = sample.launch()
        for index in 0..<160 {
            let events = sample.advance(1.0/60)
            if let stone = sample.flight, index%4 == 0 { result.points.append(stone.position) }
            for event in events {
                if case let .hit(id,point,perfect,_) = event {
                    result.points.append(point); result.target = id; result.perfect = perfect
                }
            }
            if sample.phase != .flight { break }
        }
        return result
    }
    static func segmentDistance(_ point: SlingPoint,from a: SlingPoint,to b: SlingPoint) -> Double {
        let v = b-a, length = v.x*v.x+v.y*v.y
        let t = length > 0 ? min(1,max(0,((point.x-a.x)*v.x+(point.y-a.y)*v.y)/length)) : 0
        return (point-(a+v*t)).length
    }
}
