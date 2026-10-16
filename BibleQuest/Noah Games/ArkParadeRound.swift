import Foundation

struct ParadePoint: Equatable, Codable {
    var x: Double
    var y: Double
    var finite: Bool { x.isFinite && y.isFinite }
    func distance(to p: Self) -> Double { hypot(x-p.x,y-p.y) }
    func mix(_ p: Self,_ t: Double) -> Self { .init(x: x+(p.x-x)*t,y: y+(p.y-y)*t) }
}

enum ParadeAnimal: Int, CaseIterable, Identifiable {
    case lion, wolf, tiger, monkey, elephant, sheep, cow, horse
    var id: Int { rawValue }
    var name: String { ["Lion","Wolf","Tiger","Monkey","Elephant","Sheep","Cow","Horse"][rawValue] }
    var plural: String { ["Lions","Wolves","Tigers","Monkeys","Elephants","Sheep","Cows","Horses"][rawValue] }
    var image: String { "Parade"+name }
    var partnerImage: String { image }
    var call: String { ["ROAR","HOWL","GROWL","CHATTER","TRUMPET","BAA","MOO","NEIGH"][rawValue] }
    var fact: String {
        ["Lions greet one another by rubbing their heads. A lion's roar helps other lions find it.",
         "Wolves live in family groups called packs. They howl to stay in touch. Can you make a gentle howl?",
         "A tiger's stripes help it hide in tall grass. Look closely at the beautiful pattern on its coat.",
         "Monkeys use calls to talk to their group. This recording is a macaque monkey. Can you answer its call?",
         "An elephant uses its trunk to smell, drink, and pick things up. Can you curl your arm like a trunk?",
         "Sheep recognize familiar voices. A little lamb can find its mother by listening to her bleat.",
         "Cows use moos to call to one another. A calf learns to recognize its mother's voice.",
         "Horses move their ears toward sounds. Their hooves make a clip-clop rhythm as they walk."][rawValue]
    }
    var hint: String {
        ["Look for golden fur and a fluffy mane.","Look for pointed ears, gray fur, and a bushy tail.","Look for orange fur and black stripes.","Look for a little monkey with a curling tail.","Look for a long trunk and big ears.","Look for a soft, woolly coat.","Look for a brown-and-white coat, little horns, and a soft muzzle.","Look for a flowing mane and four hooves."][rawValue]
    }
    var stride: Double { [6.3,9.0,7.2,12.0,5.4,9.5,7.2,8.5][rawValue] }
    var scale: Double { [1.12,1.06,1.08,0.85,1.13,0.90,1.10,1.11][rawValue] }
}

/// Coordinates belong to the playfield, independent of device size or orientation.
struct ArkParadeRound {
    static var pairCount: Int { ParadeAnimal.allCases.count }
    static var animalCount: Int { pairCount*2 }
    enum Phase: Equatable { case intro, finding, greeting, tracing, escorting, boarding, discovery, finale, won, paused }
    enum Event: Equatable { case wrong(ParadeAnimal), matched, trailHint, walking, boarded(ParadeAnimal), next, won }
    static let start = ParadePoint(x: 0.65,y: 0.77)
    static let ramp = ParadePoint(x: 0.20,y: 0.43)
    static let door = ParadePoint(x: 0.42,y: 0.275)
    static let rock = ParadePoint(x: 0.51,y: 0.605)
    static let rockRadius = 0.085
    private(set) var phase: Phase = .intro
    private(set) var phaseTime = 0.0
    private(set) var pairIndex = 0
    private(set) var boarded: [ParadeAnimal] = []
    private(set) var choices: [ParadeAnimal] = []
    private(set) var positions: [ParadePoint] = []
    private(set) var matchedIndex = 0
    private(set) var trail: [ParadePoint] = []
    private(set) var route: [ParadePoint] = []
    private(set) var routeLength = 0.0
    private(set) var helpedAroundRock = false
    private var storedPhase: Phase = .finding
    private(set) var seed: UInt64 = 1
    var animal: ParadeAnimal { ParadeAnimal.allCases[min(Self.pairCount-1,pairIndex)] }
    var walkDuration: Double { max(3.8,min(9,routeLength/0.15)) }
    var walkProgress: Double { phase == .boarding || phase == .discovery ? 1 : min(1,phaseTime/walkDuration) }
    var animalsAboard: Int { boarded.count*2 }
    mutating func start(seed: UInt64) {
        self = Self(); self.seed = max(1,seed); phase = .finding; arrange()
    }
    private mutating func random() -> Double {
        seed = seed &* 6364136223846793005 &+ 1442695040888963407
        return Double(seed >> 33)/Double(UInt64(1)<<31)
    }
    private mutating func arrange() {
        var other = ParadeAnimal.allCases.filter { $0 != animal }
        let a = Int(random()*Double(other.count)); let first = other.remove(at: min(a,other.count-1))
        let b = Int(random()*Double(other.count)); let second = other.remove(at: min(b,other.count-1))
        choices = [first,second,animal]
        let swap = min(2,Int(random()*3)); choices.swapAt(swap,2)
        let anchors = [ParadePoint(x: 0.18,y: 0.58),.init(x: 0.81,y: 0.49),.init(x: 0.39,y: 0.895)]
        positions = anchors.map { p in .init(x: p.x+(random()-0.5)*0.055,y: p.y+(random()-0.5)*0.04) }
        trail = []; route = []; routeLength = 0; helpedAroundRock = false
    }
    mutating func choose(_ index: Int) -> [Event] {
        guard phase == .finding,choices.indices.contains(index) else { return [] }
        guard choices[index] == animal else { return [.wrong(choices[index])] }
        matchedIndex = index; change(.greeting); return [.matched]
    }
    mutating func trace(_ p: ParadePoint) {
        guard phase == .tracing,p.finite,(0.04...0.96).contains(p.x),(0.36...0.96).contains(p.y) else { return }
        if trail.isEmpty {
            let pairCenter = ParadePoint(x: Self.start.x-0.11,y: Self.start.y-0.025)
            guard p.distance(to: pairCenter) < 0.24 else { return }; trail = [Self.start]
        }
        if let last = trail.last,last.distance(to: p) > 0.012,trail.count < 600 { trail.append(p) }
    }
    mutating func endTrail(_ p: ParadePoint) -> [Event] {
        guard phase == .tracing else { return [] }
        trace(p)
        guard p.finite,p.distance(to: Self.ramp) < 0.135,trail.count >= 2 else { trail = []; return [.trailHint] }
        var requested = trail; requested.append(Self.ramp)
        route = ParadeTrail.route(requested)
        helpedAroundRock = requested.contains { $0.distance(to: Self.rock) < Self.rockRadius+0.025 }
            || zip(requested,requested.dropFirst()).contains { !ParadeTrail.clear($0.0,$0.1) }
        route.append(Self.door)
        routeLength = zip(route,route.dropFirst()).reduce(0) { $0+$1.0.distance(to: $1.1) }
        change(.escorting); return [.walking]
    }
    /// Equivalent controls for children using VoiceOver or who cannot draw a trail.
    mutating func accessibleTrail() -> [Event] {
        guard phase == .tracing else { return [] }
        trail = [Self.start,.init(x: 0.76,y: 0.61),.init(x: 0.63,y: 0.43)]
        return endTrail(Self.ramp)
    }
    func walker(_ progress: Double) -> (point: ParadePoint, right: Bool) {
        guard route.count > 1 else { return (Self.start,true) }
        var distance = max(0,min(1,progress))*routeLength
        for (a,b) in zip(route,route.dropFirst()) {
            let length = a.distance(to: b)
            if distance <= length { return (a.mix(b,length > 0 ? distance/length : 1),b.x >= a.x) }
            distance -= length
        }
        return (route.last!,true)
    }
    mutating func advance(_ elapsed: Double) -> [Event] {
        guard elapsed.isFinite,elapsed > 0,phase != .paused,phase != .intro,phase != .won else { return [] }
        phaseTime += min(0.1,elapsed)
        if phase == .greeting && phaseTime >= 1.6 { change(.tracing) }
        else if phase == .escorting && phaseTime >= walkDuration { change(.boarding) }
        else if phase == .boarding && phaseTime >= 1.8 {
            let saved = animal; boarded.append(saved); change(.discovery); return [.boarded(saved)]
        } else if phase == .finale && phaseTime >= 5.2 { change(.won); return [.won] }
        return []
    }
    mutating func next() -> [Event] {
        guard phase == .discovery else { return [] }
        if boarded.count == Self.pairCount { change(.finale) } else { pairIndex += 1; arrange(); change(.finding) }
        return [.next]
    }
    mutating func pause() {
        guard ![.intro,.won,.paused].contains(phase) else { return }
        storedPhase = phase; phase = .paused; trail = []
    }
    mutating func resume() { guard phase == .paused else { return }; phase = storedPhase }
    private mutating func change(_ phase: Phase) { self.phase = phase; phaseTime = 0 }
}

/// Local detours keep the child's route while safely walking around the central boulder.
enum ParadeTrail {
    static func clear(_ a: ParadePoint,_ b: ParadePoint) -> Bool {
        let c = ArkParadeRound.rock,dx = b.x-a.x,dy = b.y-a.y,l2 = dx*dx+dy*dy
        let t = l2 > 0 ? max(0,min(1,((c.x-a.x)*dx+(c.y-a.y)*dy)/l2)) : 0
        return a.mix(b,t).distance(to: c) >= ArkParadeRound.rockRadius+0.025
    }
    static func outside(_ p: ParadePoint) -> ParadePoint {
        let c = ArkParadeRound.rock,r = ArkParadeRound.rockRadius+0.04,d = p.distance(to: c)
        guard d < r else { return p }
        return .init(x: c.x+(d > 0.0001 ? (p.x-c.x)/d : -1)*r,y: c.y+(d > 0.0001 ? (p.y-c.y)/d : 0)*r)
    }
    static func route(_ input: [ParadePoint]) -> [ParadePoint] {
        let points = input.filter { $0.finite }.map(outside)
        guard let first = points.first else { return [] }
        var result = [first]
        for b in points.dropFirst() {
            let a = result.last!
            if !clear(a,b) {
                let c = ArkParadeRound.rock,r = ArkParadeRound.rockRadius+0.055
                let aa = atan2(a.y-c.y,a.x-c.x),bb = atan2(b.y-c.y,b.x-c.x)
                var delta = bb-aa
                while delta > .pi { delta -= 2 * .pi }; while delta < -.pi { delta += 2 * .pi }
                // Short circular detour, joined by tangents from the child's waypoints.
                for i in 0...12 {
                    let angle = aa+delta*Double(i)/12
                    result.append(.init(x: c.x+cos(angle)*r,y: c.y+sin(angle)*r))
                }
            }
            result.append(b)
        }
        return result
    }
}
