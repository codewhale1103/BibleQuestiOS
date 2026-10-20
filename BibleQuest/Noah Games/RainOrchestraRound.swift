import Foundation

struct RainCell: Hashable, Identifiable {
    let row: Int
    let column: Int
    var id: Int { row*3+column }
    var valid: Bool { (0..<4).contains(row) && (0..<3).contains(column) }
    init(_ row: Int,_ column: Int) { self.row = row; self.column = column }
}
enum RainPiece: String,CaseIterable,Identifiable {
    case channel,fork,wheel
    var id: String { rawValue }
    var name: String { switch self { case .channel: "Channel";case .fork: "Splitter";case .wheel: "Waterwheel" } }
    var symbol: String { switch self { case .channel: "arrow.down";case .fork: "arrow.triangle.branch";case .wheel: "gearshape" } }
}
struct RainTile: Equatable {
    var piece: RainPiece = .channel
    var turn = 0
    func destinations(from column: Int) -> [Int] {
        if piece == .fork {
            let pairs = turn == 0 ? [column-1,column+1] : turn == 1 ? [column,column+1] : [column-1,column]
            return Array(Set(pairs.map { min(2,max(0,$0)) })).sorted()
        }
        return [min(2,max(0,column+turn))]
    }
    mutating func rotate(at column: Int) {
        if piece == .fork { turn = turn == 0 ? 1 : turn == 1 ? -1 : 0;return }
        let allowed = [0,1,-1].filter { (0..<3).contains(column+$0) }
        turn = allowed[((allowed.firstIndex(of: turn) ?? 0)+1)%allowed.count]
    }
}
struct RainFlow {
    var inputs: [RainCell: Double] = [:]
    var outputs = [0.0,0,0]
    var wheel = 0.0
    var spills: [RainCell:Double] = [:]
}
struct RainOrchestraRound {
    enum Phase: Equatable { case intro,playing,celebrating,finale,won,freeplay,paused }
    enum Event: Equatable { case note(Int),chapter,finished,spill }
    private(set) var phase: Phase = .intro
    private var resumePhase: Phase = .playing
    private(set) var chapter = 0
    private(set) var tiles: [RainCell:RainTile] = [:]
    private(set) var gateRemaining = 0.0
    private(set) var pourAge = 100.0
    private(set) var phaseTime = 0.0
    private(set) var elapsed = 0.0
    private(set) var fills = [0.0,0,0]
    private(set) var played: Set<Int> = []
    private(set) var cycleNotes: Set<Int> = []
    private(set) var melodyProgress = 0
    private(set) var wheelTurns = 0.0
    private var wheelThisPour = 0.0
    private(set) var completedChapters = 0
    private var reportedSpill = false
    private var reportedFinish = false
    static let melody = [0,2,1]
    static let pourDuration = 4.4
    var interactive: Bool { phase == .playing || phase == .freeplay }
    var pouring: Bool { gateRemaining > 0 }
    var waterMoving: Bool { pourAge < Self.pourDuration+1.65 }
    var day: Int {
        if [.finale,.won,.freeplay].contains(phase) { return 40 }
        if phase == .celebrating { return (chapter+1)*8 }
        return min(40,chapter*8+1+Int(min(7,elapsed/9)))
    }
    var tools: [RainPiece] { chapter == 0 ? [.channel] : chapter < 3 ? [.channel,.fork] : [.channel,.fork,.wheel] }
    var targets: [Int] { switch chapter { case 0,3: [1]; case 1: [0,2];default: [0,1,2] } }
    var title: String { ["The first little song","One stream becomes two","A moonlight melody","The waterwheel parade","The whole ark sings"][chapter] }
    var instruction: String {
        switch chapter {
        case 0: "Drag a channel onto the empty ring. Pull the gold gate to pour."
        case 1: "Split the stream. Make both outer bowls sing in one pour."
        case 2: "Make the bowls sing: LOW → HIGH → MIDDLE. One note per pour."
        case 3: "Guide water through a wheel and into the middle drum."
        default: "Use splitters to make all three instruments sing in one pour."
        }
    }
    var voice: String { ["first","split","moon","wheel","together"][chapter] }
    mutating func start() {
        self = Self();phase = .playing;loadChapter()
    }
    mutating func place(_ piece: RainPiece,at cell: RainCell) -> Bool {
        guard interactive,cell.valid,tools.contains(piece) else { return false }
        tiles[cell] = RainTile(piece: piece);return true
    }
    mutating func move(from: RainCell,to: RainCell) -> Bool {
        guard interactive,from.valid,to.valid,let tile = tiles[from] else { return false }
        if from == to { return true }
        let replacement = tiles[to];tiles[to] = tile;tiles[from] = replacement;return true
    }
    mutating func remove(_ cell: RainCell) { guard interactive else { return };tiles[cell] = nil }
    mutating func rotate(_ cell: RainCell) { guard interactive,cell.valid,var tile = tiles[cell] else { return };tile.rotate(at: cell.column);tiles[cell] = tile }
    @discardableResult mutating func pour() -> Bool {
        guard interactive,!waterMoving else { return false }
        gateRemaining = Self.pourDuration;pourAge = 0;fills = [0,0,0];cycleNotes = [];wheelThisPour = 0;reportedSpill = false
        return true
    }
    /// Acyclic, conservative flow: streams only descend; every fork divides its incoming volume.
    func network() -> RainFlow {
        var flow = RainFlow();flow.inputs[RainCell(0,1)] = 1
        for row in 0..<4 {
            for col in 0..<3 {
                let cell = RainCell(row,col),volume = flow.inputs[cell,default: 0]
                guard volume > 0 else { continue }
                guard let tile = tiles[cell] else { flow.spills[cell] = volume;continue }
                if tile.piece == .wheel { flow.wheel += volume }
                let next = tile.destinations(from: col),part = volume/Double(next.count)
                for target in next {
                    if row == 3 { flow.outputs[target] += part }
                    else { flow.inputs[RainCell(row+1,target),default: 0] += part }
                }
            }
        }
        return flow
    }
    func liveInput(_ cell: RainCell) -> Double {
        guard phase != .intro else { return 0 }
        let delay = Double(cell.row)*0.32
        return pourAge >= delay && pourAge < Self.pourDuration+delay && (pouring || pourAge < Self.pourDuration+delay) ? network().inputs[cell,default: 0] : 0
    }
    mutating func advance(_ seconds: Double) -> [Event] {
        guard seconds.isFinite,seconds > 0,phase != .paused,phase != .intro,phase != .won else { return [] }
        let dt = min(seconds,0.1);phaseTime += dt
        if phase == .celebrating {
            pourAge += dt;gateRemaining = max(0,gateRemaining-dt)
            if waterMoving { wheelTurns += network().wheel*dt*0.65 }
            return []
        }
        if phase == .finale {
            if phaseTime >= 14 && !reportedFinish { reportedFinish = true;phase = .won;return [.finished] }
            return []
        }
        guard interactive else { return [] };elapsed += dt
        let wasMoving = waterMoving
        pourAge += dt;gateRemaining = max(0,gateRemaining-dt)
        guard wasMoving else { return [] }
        let flow = network();var events: [Event] = []
        let arrived = pourAge >= 1.28 && pourAge < Self.pourDuration+1.28
        if arrived {
            wheelTurns += flow.wheel*dt*0.65;wheelThisPour += flow.wheel*dt*0.65
            for col in 0..<3 {
                guard !cycleNotes.contains(col) else { continue }
                fills[col] = min(1,fills[col]+flow.outputs[col]*dt*1.15)
                if fills[col] >= 0.68 {
                    cycleNotes.insert(col);played.insert(col);events.append(.note(col))
                    if chapter == 2 && phase == .playing && cycleNotes.count == 1 && melodyProgress<3 {
                        if col == Self.melody[melodyProgress] { melodyProgress += 1 }
                        else { melodyProgress = col == Self.melody[0] ? 1 : 0 }
                    }
                }
            }
        }
        if pourAge > 1.4,!reportedSpill,!flow.spills.isEmpty { reportedSpill = true;events.append(.spill) }
        if phase == .playing {
            let complete: Bool
            switch chapter {
            case 0: complete = cycleNotes.contains(1)
            case 1: complete = cycleNotes.isSuperset(of: [0,2])
            case 2: complete = melodyProgress == 3
            case 3: complete = cycleNotes.contains(1) && wheelThisPour >= 0.8
            default: complete = cycleNotes.count == 3
            }
            if complete { phase = .celebrating;phaseTime = 0;completedChapters = chapter+1;events.append(.chapter) }
        }
        return events
    }
    mutating func next() {
        guard phase == .celebrating else { return }
        if chapter == 4 { phase = .finale;phaseTime = 0;return }
        chapter += 1;phase = .playing;loadChapter()
    }
    mutating func freeplay() {
        guard phase == .won else { return };phase = .freeplay;chapter = 4;gateRemaining = 0;pourAge = 100;fills = [0,0,0];cycleNotes = []
    }
    mutating func resetBoard() { guard interactive else { return };loadChapter() }
    mutating func pause() { guard [.playing,.celebrating,.finale,.freeplay].contains(phase) else { return };resumePhase = phase;phase = .paused }
    mutating func resume() { guard phase == .paused else { return };phase = resumePhase }
    /// One reversible hint at a time; children still open the gate themselves.
    mutating func hint() -> RainCell? {
        guard interactive else { return nil }
        let solution = Self.solution(chapter: chapter,note: chapter == 2 ? Self.melody[min(2,melodyProgress)] : 1)
        if let cell = solution.keys.sorted(by: {$0.id<$1.id}).first(where: {tiles[$0] != solution[$0]}) { tiles[cell] = solution[cell];return cell }
        return nil
    }
    static func solution(chapter: Int,note: Int = 1) -> [RainCell:RainTile] {
        var result: [RainCell:RainTile] = [:]
        if chapter == 1 || chapter == 4 {
            result[RainCell(0,1)] = .init();result[RainCell(1,1)] = .init(piece: .fork)
            for r in 2...3 { result[RainCell(r,0)] = .init();result[RainCell(r,2)] = .init() }
            if chapter == 4 { result[RainCell(2,0)] = .init(piece: .fork,turn: 1);result[RainCell(3,1)] = .init();result[RainCell(2,2)] = .init(piece:.wheel) }
        } else {
            let target = chapter == 2 ? note : 1
            result[RainCell(0,1)] = .init(turn: target-1)
            for r in 1...3 { result[RainCell(r,target)] = .init(piece: chapter == 3 && r == 2 ? .wheel : .channel) }
        }
        return result
    }
    static func showcase() -> Self {
        var r = Self();r.chapter = 4;r.phase = .freeplay;r.loadChapter();r.tiles = Self.solution(chapter:4);return r
    }
    private mutating func loadChapter() {
        phaseTime = 0;elapsed = 0;gateRemaining = 0;pourAge = 100;fills = [0,0,0];played = [];cycleNotes = [];melodyProgress = 0;wheelTurns = 0;wheelThisPour = 0;reportedSpill = false
        switch chapter {
        case 0: tiles = [RainCell(1,1):.init(),RainCell(2,1):.init(),RainCell(3,1):.init()]
        case 1: tiles = Self.solution(chapter: 1);tiles[RainCell(3,0)] = nil;tiles[RainCell(3,2)] = nil
        case 2: tiles = Self.solution(chapter: 2,note: 1);for r in 1...3 { tiles[RainCell(r,0)] = .init();tiles[RainCell(r,2)] = .init() }
        case 3: tiles = Self.solution(chapter: 3);tiles[RainCell(2,1)] = nil;tiles[RainCell(0,1)] = .init(turn: -1)
        default: tiles = Self.solution(chapter: 4);tiles[RainCell(1,1)] = nil;tiles[RainCell(2,0)] = .init();tiles[RainCell(3,1)] = nil
        }
    }
}
