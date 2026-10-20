import Foundation

struct DovePoint: Equatable {
    var x: Double
    var y: Double
    var finite: Bool { x.isFinite && y.isFinite }
    func distance(_ other: Self) -> Double { hypot(x-other.x,(y-other.y)*1000) }
    func close(_ other: Self) -> Double { hypot(x-other.x,y-other.y) }
}
enum DoveDiscovery: Int,CaseIterable,Identifiable {
    case reflection,waterfall,olive
    var id: Int { rawValue }
    var title: String { ["A silver mirror","Water finding its way","A little green hope"][rawValue] }
    var text: String { ["Calm water can reflect the clouds and the bird above it.","As water moves downhill, it can tumble over rocks in a waterfall.","Olive leaves are narrow and green. A fresh leaf showed Noah that the waters were going down."][rawValue] }
    var symbol: String { ["water.waves","drop","leaf"][rawValue] }
    var point: DovePoint { [.init(x:780,y:0.57),.init(x:1380,y:0.41),.init(x:2370,y:0.38)][rawValue] }
}
struct DoveVoyageRound {
    enum Phase: Equatable { case intro,launching,seeking,returning,leaf,leafTaken,landing,landed,between,waiting,ready,settling,settled,finale,won,exploring,paused }
    enum Event: Equatable { case launched,observed,homeward,grove,leaf,home,landed,week,ready,branch,settled,finished,discovery(DoveDiscovery) }
    private(set) var phase: Phase = .intro
    private var resumePhase: Phase = .seeking
    private(set) var flight = 0
    private(set) var leg = 0
    private(set) var position = DovePoint(x:260,y:0.43)
    private(set) var velocity = 0.0
    private(set) var verticalVelocity = 0.0
    private(set) var facingRight = true
    private(set) var phaseTime = 0.0
    private(set) var time = 0.0
    private(set) var dwell = 0.0
    private(set) var days = 0
    private(set) var hasLeaf = false
    private(set) var deliveredLeaf = false
    private(set) var completedFlights = 0
    private(set) var discoveries: Set<DoveDiscovery> = []
    private var discoveryDwell: [DoveDiscovery:Double] = [:]
    private(set) var guiding = false
    private var breeze = 0.0
    private var altitude = 0.43
    private var holding = false
    private var gust = 0.0
    private var reportedFinish = false
    static let leafHome = DovePoint(x:0.68,y:0.39)
    static let beak = DovePoint(x:0.43,y:0.53)
    static let palm = DovePoint(x:0.49,y:0.61)
    static let perch = DovePoint(x:0.43,y:0.52)
    var flying: Bool { [.seeking,.returning,.exploring].contains(phase) }
    var closeup: Bool { [.leaf,.leafTaken,.landing,.landed,.settling,.settled].contains(phase) }
    var goal: DovePoint {
        if phase == .returning { return .init(x:230,y:0.43) }
        if phase == .exploring { return DoveDiscovery.allCases.first(where:{!discoveries.contains($0)})?.point ?? .init(x:2600,y:0.42) }
        let points: [[DovePoint]] = [[.init(x:860,y:0.47),.init(x:1730,y:0.48)],[.init(x:1240,y:0.49),.init(x:2320,y:0.42)],[.init(x:1260,y:0.46),.init(x:2780,y:0.43)]]
        return points[flight][min(1,leg)]
    }
    var objective: String {
        switch phase {
        case .returning: return "Carry \(hasLeaf ? "the little leaf" : "our dove") home to Noah."
        case .leaf,.leafTaken: return "Gently carry the fresh leaf to the dove’s beak."
        case .landing,.landed: return "Guide the dove into Noah’s welcoming hand."
        case .settling,.settled: return "Bring the dove onto the sunlit branch."
        case .exploring: return "Follow a breeze. Discover a little wonder."
        default:
            return [["Explore the silver water.","Look for somewhere to rest."],["Look at the land appearing.","Find the olive grove."],["Follow the greener coastline.","Find a peaceful place to stay."]][flight][min(1,leg)]
        }
    }
    var progress: Double { min(1,max(0,dwell/1.4)) }
    mutating func start() { self = Self();phase = .launching }
    mutating func launch() { guard phase == .ready else { return };phase = .launching;phaseTime = 0;position = .init(x:260,y:0.43);leg = 0;clearInput() }
    mutating func steer(direction:Double,altitude:Double) {
        guard flying,direction.isFinite,altitude.isFinite else { return }
        guiding = false;breeze = min(1,max(-1,direction));self.altitude = min(0.72,max(0.23,altitude));holding = true;gust = 0
    }
    mutating func release() { holding = false;if abs(breeze)>0.12 { gust = 1.1 } }
    mutating func followBreeze() { guard flying else { return };guiding = true;holding = false;gust = 0 }
    mutating func pluck(from:DovePoint,to:DovePoint) -> [Event] {
        guard phase == .leaf,from.finite,to.finite,from.close(Self.leafHome)<0.19,to.close(Self.beak)<0.22 else { return [] }
        hasLeaf = true;phase = .leafTaken;phaseTime = 0;return [.leaf]
    }
    mutating func land(at:DovePoint) -> [Event] {
        guard phase == .landing,at.finite,at.close(Self.palm)<0.22,flight == 0 || hasLeaf else { return [] }
        phase = .landed;phaseTime = 0;completedFlights = flight+1
        if hasLeaf { deliveredLeaf = true;discoveries.insert(.olive) }
        return [.landed]
    }
    mutating func settle(at:DovePoint) -> [Event] {
        guard phase == .settling,at.finite,at.close(Self.perch)<0.23,flight == 2,deliveredLeaf else { return [] }
        phase = .settled;phaseTime = 0;completedFlights = 3;return [.settled]
    }
    mutating func waitSevenDays() { guard phase == .between,flight<2 else { return };phase = .waiting;phaseTime = 0;days = 0 }
    mutating func explore() { guard phase == .won else { return };phase = .exploring;position = .init(x:1800,y:0.45);phaseTime = 0;hasLeaf = false;clearInput() }
    mutating func pause() {
        guard ![.intro,.paused,.won].contains(phase) else { return };resumePhase = phase;phase = .paused;clearInput()
    }
    mutating func resume() { guard phase == .paused else { return };phase = resumePhase }
    mutating func advance(_ seconds:Double) -> [Event] {
        guard seconds.isFinite,seconds>0,phase != .paused,phase != .intro,phase != .won else { return [] }
        let dt = min(0.05,seconds);time += dt;phaseTime += dt
        switch phase {
        case .launching:
            if phaseTime>=2.8 { phase = .seeking;phaseTime = 0;return [.launched] }
        case .leafTaken:
            if phaseTime>=1.8 { phase = .returning;phaseTime = 0;clearInput();return [.homeward] }
        case .landed:
            if phaseTime>=3 { phase = .between;phaseTime = 0 }
        case .waiting:
            let previous = days;days = min(7,Int(phaseTime/0.95))
            if days == 7 { flight += 1;leg = 0;hasLeaf = false;phase = .ready;phaseTime = 0;return [.ready] }
            if days != previous { return [.week] }
        case .settled:
            if phaseTime>=4 { phase = .finale;phaseTime = 0 }
        case .finale:
            if phaseTime>=15,!reportedFinish { reportedFinish = true;phase = .won;return [.finished] }
        default: break
        }
        guard flying else { return [] }
        var events:[Event] = []
        let destination = goal
        var horizontal = 0.0
        if guiding { horizontal = min(1,max(-1,(destination.x-position.x)/160));altitude = destination.y }
        else if holding || gust>0 { horizontal = breeze;gust = max(0,gust-dt) }
        velocity += (horizontal*170-velocity)*min(1,dt*3.4)
        let oldY = position.y
        position.x = min(3300,max(140,position.x+velocity*dt))
        position.y += (altitude-position.y)*min(1,dt*2.6)
        position.y = min(0.72,max(0.23,position.y));verticalVelocity = (position.y-oldY)/dt
        if abs(velocity)>12 { facingRight = velocity>0 }
        for discovery in DoveDiscovery.allCases where !discoveries.contains(discovery) {
            let visible = discovery == .reflection || flight>0
            if visible && position.distance(discovery.point)<200 {
                discoveryDwell[discovery,default:0] += dt
                if discoveryDwell[discovery,default:0]>=0.8 { discoveries.insert(discovery);events.append(.discovery(discovery)) }
            }
        }
        if position.distance(destination)<190 { dwell += dt } else { dwell = max(0,dwell-dt*0.8) }
        guard dwell>=1.4 else { return events }
        dwell = 0;guiding = false;holding = false;gust = 0
        if phase == .exploring { return events }
        if phase == .returning { phase = .landing;phaseTime = 0;velocity = 0;events.append(.home);return events }
        if leg == 0 { leg = 1;events.append(.observed) }
        else if flight == 0 { phase = .returning;phaseTime = 0;events.append(.homeward) }
        else if flight == 1 { phase = .leaf;phaseTime = 0;velocity = 0;events.append(.grove) }
        else { phase = .settling;phaseTime = 0;velocity = 0;events.append(.branch) }
        return events
    }
    private mutating func clearInput() { guiding = false;holding = false;gust = 0;breeze = 0;velocity = 0;verticalVelocity = 0;dwell = 0;altitude = position.y }
}
