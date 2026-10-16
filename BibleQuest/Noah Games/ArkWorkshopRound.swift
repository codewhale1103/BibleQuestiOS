import Foundation

enum ArkWorkshopStep: Int, CaseIterable, Identifiable {
    case timber, decks, pitch
    var id: Int { rawValue }
    var title: String { ["The hidden timber trail", "Fit the three decks", "Your ark. Your colors."][rawValue] }
    var shortTitle: String { ["TIMBER HUNT", "THREE DECKS", "PAINT STUDIO"][rawValue] }
    var symbol: String { ["leaf.fill", "square.3.layers.3d", "paintpalette.fill"][rawValue] }
    var instruction: String {
        ["Find five hidden beams. Sweep the leaves away, then drag each beam into the timber basket.",
         "God told Noah to make three decks. Lift each deck and drag it to the matching shadow.",
         "Pick a color. Drag the brush onto the ark and paint! Decorate the outside and the inside."][rawValue]
    }
    var prompt: String { ["Sweep the leaves. Carry the timber to the basket.", "Drag each deck onto its matching shadow.", "Choose a color. Pick up the brush. Make your mark!"][rawValue] }
    var discoveryTitle: String { ["A good beginning!", "One, two, three decks!", "Made with care."][rawValue] }
    var discovery: String {
        ["God told Noah to build an ark of wood. You searched carefully and gathered the timber for our model.",
         "A deck is a floor inside a boat. The ark had a lower, middle, and upper deck.",
         "Noah coated the ark with pitch inside and outside to help keep water out. Our colors are a playful way to decorate the model."][rawValue]
    }
    var reference: String { ["GENESIS 6:14", "GENESIS 6:16", "GENESIS 6:14, 22"][rawValue] }
}
enum ArkPaintColor: Int, CaseIterable, Identifiable {
    case honey, lagoon, coral, sky, lavender
    var id: Int { rawValue }
    var name: String { ["Honey gold", "Lagoon teal", "Sunset coral", "Ocean blue", "Lilac"][rawValue] }
    var hex: String { ["#E7AD49", "#41B5A1", "#E78571", "#659FCF", "#AC8EC2"][rawValue] }
}
struct ArkWorkshopPoint: Equatable {
    let x: Double
    let y: Double
    var finite: Bool { x.isFinite && y.isFinite }
    func distance(to other: Self) -> Double { hypot(x-other.x,y-other.y) }
}
struct ArkWorkshopRound {
    enum Phase: Equatable { case intro, listening, playing, discovery, reveal, won, paused }
    enum Event: Equatable { case uncovered(Int), timber(Int), deck(Int), painted(Int), hint, discovery, won }
    static let timberCount = 5
    static let paintColumns = 12
    static let paintRows = 4
    static let paintCellCount = paintColumns*paintRows
    static let requiredPaintCells = 36
    private(set) var phase: Phase = .intro
    private(set) var step: ArkWorkshopStep = .timber
    private(set) var uncovered: Set<Int> = []
    private(set) var wood: Set<Int> = []
    private(set) var decks: Set<Int> = []
    private(set) var coverage: [Set<Int>] = [[],[]]
    private(set) var selectedDeck: Int?
    private(set) var selectedColor: ArkPaintColor?
    private(set) var brushEquipped = false
    private(set) var inside = false
    private(set) var discoveries = 0
    private(set) var score = 0
    private(set) var revealTime = 0.0
    private var previousPhase: Phase?
    var side: Int { inside ? 1 : 0 }
    var coveragePercent: Int { Int(Double(coverage[side].count)/Double(Self.paintCellCount)*100) }
    var paintReady: Bool { coverage.allSatisfy { $0.count >= Self.requiredPaintCells } }
    func percent(inside: Bool) -> Int { Int(Double(coverage[inside ? 1 : 0].count)/Double(Self.paintCellCount)*100) }
    mutating func start() { self = Self(); phase = .listening }
    mutating func beginTask() { guard phase == .listening else { return }; phase = .playing }
    mutating func uncover(_ id: Int) -> [Event] {
        guard phase == .playing,step == .timber,(0..<Self.timberCount).contains(id),!uncovered.contains(id) else { return [] }
        uncovered.insert(id); return [.uncovered(id)]
    }
    mutating func storeTimber(_ id: Int,inBasket: Bool) -> [Event] {
        guard phase == .playing,step == .timber,(0..<Self.timberCount).contains(id),uncovered.contains(id),!wood.contains(id) else { return [] }
        guard inBasket else { return [.hint] }
        wood.insert(id); score += 100
        if wood.count == Self.timberCount { phase = .discovery; score += 100; return [.timber(id),.discovery] }
        return [.timber(id)]
    }
    mutating func selectDeck(_ index: Int) {
        guard phase == .playing,step == .decks,(0..<3).contains(index),!decks.contains(index) else { return }; selectedDeck = index
    }
    mutating func placeDeck(at target: Int) -> [Event] {
        guard phase == .playing,step == .decks,(0..<3).contains(target),!decks.contains(target),let selectedDeck else { return [] }
        guard selectedDeck == target else { return [.hint] }
        decks.insert(target); self.selectedDeck = nil; score += 150
        if decks.count == 3 { phase = .discovery; score += 100; return [.deck(target),.discovery] }
        return [.deck(target)]
    }
    mutating func chooseColor(_ color: ArkPaintColor) {
        guard phase == .playing,step == .pitch else { return }; selectedColor = color
    }
    mutating func pickUpBrush() -> Bool {
        guard phase == .playing,step == .pitch,selectedColor != nil else { return false }; brushEquipped = true; return true
    }
    mutating func flipSide() { guard phase == .playing,step == .pitch else { return }; inside.toggle() }
    /// Coverage uses the same UV coordinates and brush footprint as the rendered paint texture.
    mutating func paint(at uv: ArkWorkshopPoint) -> [Event] {
        guard phase == .playing,step == .pitch,selectedColor != nil,brushEquipped,uv.finite,(0...1).contains(uv.x),(0...1).contains(uv.y) else { return [] }
        let before = coverage[side].count
        for row in 0..<Self.paintRows {
            for column in 0..<Self.paintColumns {
                let center = ArkWorkshopPoint(x: (Double(column)+0.5)/Double(Self.paintColumns),y: (Double(row)+0.5)/Double(Self.paintRows))
                let dx = (center.x-uv.x)/0.095,dy = (center.y-uv.y)/0.18
                if dx*dx+dy*dy <= 1 { coverage[side].insert(row*Self.paintColumns+column) }
            }
        }
        let added = coverage[side].count-before
        guard added > 0 else { return [] }; score += added*5; return [.painted(added)]
    }
    mutating func finishPainting() -> [Event] {
        guard phase == .playing,step == .pitch,paintReady else { return [] }
        phase = .discovery; score += 100; return [.discovery]
    }
    mutating func continueDiscovery() {
        guard phase == .discovery else { return }; discoveries += 1
        if let next = ArkWorkshopStep(rawValue: step.rawValue+1) { step = next; phase = .listening }
        else { phase = .reveal; revealTime = 0 }
    }
    mutating func advance(_ dt: Double) -> [Event] {
        guard phase == .reveal,dt.isFinite,dt > 0 else { return [] }; revealTime += min(0.1,dt)
        if revealTime >= 3.8 { phase = .won; return [.won] }; return []
    }
    mutating func pause() { guard ![.intro,.paused,.won].contains(phase) else { return }; previousPhase = phase; phase = .paused }
    mutating func resume() { guard phase == .paused,let previousPhase else { return }; phase = previousPhase; self.previousPhase = nil }
}
