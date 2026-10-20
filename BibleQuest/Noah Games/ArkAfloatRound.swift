import Foundation

struct FloodPoint: Equatable, Codable {
    var x: Double
    var y: Double
    var finite: Bool { x.isFinite && y.isFinite }
    func distance(to other: Self) -> Double { hypot(x-other.x,y-other.y) }
    func mix(_ other: Self,_ t: Double) -> Self { .init(x: x+(other.x-x)*t,y: y+(other.y-y)*t) }
}

enum FloodRoom: Int, CaseIterable, Identifiable {
    case cargo, shelter, loft
    var id: Int { rawValue }
    var name: String { ["Supplies","Animal cabin","Lantern loft"][rawValue] }
    var shortName: String { ["Supplies","Animals","Lanterns"][rawValue] }
    var symbol: String { ["shippingbox.fill","pawprint.fill","lamp.desk.fill"][rawValue] }
    var image: String { ["FloodCargoRoom","FloodAnimalRoom","FloodLanternRoom"][rawValue] }
}

enum FloodTask: Int, CaseIterable, Identifiable {
    case basket, cargoRope, shutters, lantern, apples, stormRope, blanket, soothe, stormShutters
    var id: Int { rawValue }
    var room: FloodRoom {
        switch self { case .basket,.cargoRope,.apples,.stormRope: return .cargo; case .blanket,.soothe: return .shelter; case .shutters,.lantern,.stormShutters: return .loft }
    }
    var title: String {
        switch self {
        case .basket: return "A place for every basket."
        case .cargoRope: return "Pull it snug."
        case .shutters,.stormShutters: return "Slide the shutters closed."
        case .lantern: return "A little light goes a long way."
        case .apples: return "Three little runaways!"
        case .stormRope: return "One more gentle pull."
        case .blanket: return "Something soft for our friend."
        case .soothe: return "A gentle hand. A happy lamb."
        }
    }
    var instruction: String {
        switch self {
        case .basket: return "Drag the basket onto the glowing cradle."
        case .cargoRope,.stormRope: return "Pull the round rope handle down to the knot."
        case .shutters,.stormShutters: return "Slide each wooden panel toward the middle."
        case .lantern: return "Carry the lantern up to the glowing hook."
        case .apples: return "Catch each rolling apple. Put it in the basket."
        case .blanket: return "Drag the blanket over to the little lamb."
        case .soothe: return "Gently stroke the lamb’s wool until it settles."
        }
    }
    var voice: String {
        switch self {
        case .cargoRope,.stormRope: return "rope"
        case .shutters,.stormShutters: return "shutters"
        default: return ["basket","rope","shutters","lantern","apples","rope","blanket","soothe","shutters"][rawValue]
        }
    }
    var symbol: String {
        switch self { case .basket: return "basket.fill"; case .cargoRope,.stormRope: return "hand.draw.fill"; case .shutters,.stormShutters: return "arrow.right.and.line.vertical.and.arrow.left"; case .lantern: return "sun.max.fill"; case .apples: return "3.circle.fill"; case .blanket: return "square.stack.fill"; case .soothe: return "heart.fill" }
    }
}

/// All interaction points are normalized inside the room, so layout never changes the rules.
struct ArkAfloatRound {
    enum Phase: Equatable { case intro, rain, preparing, launching, caring, finale, won, paused }
    enum Event: Equatable { case prepared, lifted, task(FloodTask), apple, splash, won }
    private(set) var phase: Phase = .intro
    private(set) var phaseTime = 0.0
    private(set) var room: FloodRoom = .cargo
    private(set) var completed: Set<FloodTask> = []
    private(set) var shutterLeft = 0.0
    private(set) var shutterRight = 0.0
    private(set) var rope = 0.0
    private(set) var apples: Set<Int> = []
    private(set) var comfort = 0.0
    private(set) var rainTouches = 0
    private var storedPhase: Phase = .preparing
    static let basketHome = FloodPoint(x: 0.27,y: 0.80)
    static let basketCradle = FloodPoint(x: 0.70,y: 0.74)
    static let lanternHome = FloodPoint(x: 0.28,y: 0.80)
    static let hook = FloodPoint(x: 0.52,y: 0.20)
    static let blanketHome = FloodPoint(x: 0.24,y: 0.83)
    static let lamb = FloodPoint(x: 0.64,y: 0.72)
    static let ropeStart = FloodPoint(x: 0.76,y: 0.47)
    static let ropeEnd = FloodPoint(x: 0.76,y: 0.76)
    static let preparation: Set<FloodTask> = [.basket,.cargoRope,.shutters,.lantern]
    static let care: Set<FloodTask> = [.apples,.stormRope,.blanket,.soothe,.stormShutters]
    var active: Bool { phase == .preparing || phase == .caring }
    var ready: Bool { Self.preparation.isSubset(of: completed) }
    var caredFor: Bool { Self.care.isSubset(of: completed) }
    var count: Int { completed.count }
    var task: FloodTask? {
        guard active else { return nil }
        let tasks: [FloodTask]
        if phase == .preparing { tasks = room == .cargo ? [.basket,.cargoRope] : room == .loft ? [.shutters,.lantern] : [] }
        else { tasks = room == .cargo ? [.apples,.stormRope] : room == .shelter ? [.blanket,.soothe] : [.stormShutters] }
        return tasks.first { !completed.contains($0) }
    }
    func roomFinished(_ value: FloodRoom) -> Bool {
        let tasks = (phase == .caring ? Self.care : Self.preparation).filter { $0.room == value }
        return tasks.allSatisfy { completed.contains($0) }
    }
    mutating func start() { self = Self(); change(.rain) }
    mutating func comeInside() { guard phase == .rain else { return }; room = .cargo; change(.preparing) }
    mutating func select(_ room: FloodRoom) { guard active else { return }; self.room = room }
    mutating func launch() -> [Event] { guard phase == .preparing,ready else { return [] }; change(.launching); return [.prepared] }
    mutating func finish() { guard phase == .caring,caredFor else { return }; change(.finale) }
    mutating func touchRain() -> [Event] { guard phase != .paused,phase != .intro,phase != .won else { return [] }; rainTouches += 1; return [.splash] }
    mutating func drop(_ item: FloodTask,at p: FloodPoint) -> [Event] {
        guard p.finite,task == item else { return [] }
        let target: FloodPoint
        switch item { case .basket: target = Self.basketCradle; case .lantern: target = Self.hook; case .blanket: target = Self.lamb; default: return [] }
        guard p.distance(to: target) <= (item == .blanket ? 0.24 : 0.19) else { return [] }
        return complete(item)
    }
    mutating func pullRope(_ amount: Double) -> [Event] {
        guard amount.isFinite,let task,task == .cargoRope || task == .stormRope else { return [] }
        rope = max(rope,min(1,max(0,amount)))
        return rope >= 0.92 ? complete(task) : []
    }
    mutating func slideShutter(left: Bool,amount: Double) -> [Event] {
        guard amount.isFinite,let task,task == .shutters || task == .stormShutters else { return [] }
        if left { shutterLeft = max(shutterLeft,min(1,max(0,amount))) } else { shutterRight = max(shutterRight,min(1,max(0,amount))) }
        if shutterLeft >= 0.9 && shutterRight >= 0.9 { shutterLeft = 1; shutterRight = 1; return complete(task) }
        return []
    }
    mutating func catchApple(_ index: Int,at p: FloodPoint) -> [Event] {
        guard task == .apples,(0..<3).contains(index),!apples.contains(index),p.finite,p.distance(to: Self.basketCradle) < 0.23 else { return [] }
        apples.insert(index)
        return apples.count == 3 ? [.apple]+complete(.apples) : [.apple]
    }
    mutating func stroke(_ distance: Double) -> [Event] {
        guard task == .soothe,distance.isFinite,distance > 0 else { return [] }
        comfort = min(1,comfort+min(0.05,distance)*0.65)
        return comfort >= 1 ? complete(.soothe) : []
    }
    /// VoiceOver actions provide the same outcomes without requiring precise dragging.
    mutating func accessibleAction() -> [Event] {
        guard let task else { return [] }
        switch task {
        case .basket: return drop(task,at: Self.basketCradle)
        case .lantern: return drop(task,at: Self.hook)
        case .blanket: return drop(task,at: Self.lamb)
        case .cargoRope,.stormRope: return pullRope(1)
        case .shutters,.stormShutters: _ = slideShutter(left: true,amount: 1); return slideShutter(left: false,amount: 1)
        case .apples: return (0..<3).flatMap { catchApple($0,at: Self.basketCradle) }
        case .soothe: comfort = 1; return complete(task)
        }
    }
    mutating func advance(_ dt: Double) -> [Event] {
        guard dt.isFinite,dt > 0,![.paused,.intro,.won].contains(phase) else { return [] }
        phaseTime += min(0.1,dt)
        if phase == .launching,phaseTime >= 12 {
            shutterLeft = 0; shutterRight = 0; rope = 0; room = .cargo; change(.caring); return [.lifted]
        }
        if phase == .finale,phaseTime >= 9 { change(.won); return [.won] }
        return []
    }
    mutating func pause() { guard ![.intro,.won,.paused].contains(phase) else { return }; storedPhase = phase; phase = .paused }
    mutating func resume() { guard phase == .paused else { return }; phase = storedPhase }
    private mutating func complete(_ task: FloodTask) -> [Event] {
        guard !completed.contains(task) else { return [] }; completed.insert(task)
        if task == .apples { rope = 0 }
        return [.task(task)]
    }
    private mutating func change(_ phase: Phase) { self.phase = phase; phaseTime = 0 }
}
