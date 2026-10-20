import Testing
@testable import BibleQuest

struct DoveVoyageRoundTests {
    private func tick(_ r:inout DoveVoyageRound,_ seconds:Double)->[DoveVoyageRound.Event] {
        var events:[DoveVoyageRound.Event] = []
        for _ in 0..<Int((seconds/0.05).rounded(.up)) { events += r.advance(0.05) };return events
    }
    private func launched()->DoveVoyageRound { var r = DoveVoyageRound();r.start();_ = tick(&r,3);return r }
    private func guide(_ r:inout DoveVoyageRound)->[DoveVoyageRound.Event] {
        r.followBreeze();let phase = r.phase,leg = r.leg;var events:[DoveVoyageRound.Event] = []
        for _ in 0..<1400 { events += r.advance(0.05);if r.phase != phase || r.leg != leg { break } };return events
    }
    private func firstHome()->DoveVoyageRound {
        var r = launched();_ = guide(&r);_ = guide(&r);_ = guide(&r);return r
    }
    private func nextFlight(_ r:inout DoveVoyageRound) {
        _ = tick(&r,3.1);r.waitSevenDays();_ = tick(&r,6.7);r.launch();_ = tick(&r,3)
    }
    private func secondLeaf()->DoveVoyageRound {
        var r = firstHome();_ = r.land(at:DoveVoyageRound.palm);nextFlight(&r);_ = guide(&r);_ = guide(&r);return r
    }
    private func thirdBranch()->DoveVoyageRound {
        var r = secondLeaf();_ = r.pluck(from:DoveVoyageRound.leafHome,to:DoveVoyageRound.beak);_ = tick(&r,2);_ = guide(&r);_ = r.land(at:DoveVoyageRound.palm);nextFlight(&r);_ = guide(&r);_ = guide(&r);return r
    }
    @Test func idleDoesNotCompleteAFlight() {
        var r = launched();_ = tick(&r,90)
        #expect(r.phase == .seeking);#expect(r.leg == 0);#expect(r.completedFlights == 0)
    }
    @Test func breezeAssistsOnlyOneDestination() {
        var r = launched();let events = guide(&r),x = r.position.x
        #expect(events.contains(.observed));#expect(r.leg == 1);#expect(!r.guiding)
        _ = tick(&r,20);#expect(r.phase == .seeking);#expect(r.position.x-x<60)
    }
    @Test func firstFlightReturnsWithoutLeafAndNeedsPalm() {
        var r = firstHome();#expect(r.phase == .landing);#expect(!r.hasLeaf)
        #expect(r.land(at:.init(x:0,y:0)).isEmpty);#expect(r.phase == .landing)
        #expect(r.land(at:DoveVoyageRound.palm) == [.landed]);#expect(r.completedFlights == 1);#expect(!r.deliveredLeaf)
    }
    @Test func sevenDaysBeforeEachLaunch() {
        var r = firstHome();_ = r.land(at:DoveVoyageRound.palm);_ = tick(&r,3.1);#expect(r.phase == .between)
        r.launch();#expect(r.phase == .between);r.waitSevenDays();_ = tick(&r,6.1)
        #expect(r.phase == .waiting);#expect(r.days == 6);#expect(r.flight == 0)
        _ = tick(&r,0.6);#expect(r.days == 7);#expect(r.flight == 1);#expect(r.phase == .ready)
        r.launch();#expect(r.phase == .launching);#expect(r.leg == 0)
    }
    @Test func oliveLeafIsARealDragWithSourceAndDestination() {
        var r = secondLeaf();#expect(r.phase == .leaf);#expect(r.flight == 1)
        #expect(r.pluck(from:.init(x:0,y:0),to:DoveVoyageRound.beak).isEmpty)
        #expect(r.pluck(from:DoveVoyageRound.leafHome,to:.init(x:1,y:0)).isEmpty)
        #expect(!r.hasLeaf);#expect(r.pluck(from:DoveVoyageRound.leafHome,to:DoveVoyageRound.beak) == [.leaf]);#expect(r.hasLeaf)
        _ = tick(&r,2);#expect(r.phase == .returning);_ = guide(&r);_ = r.land(at:DoveVoyageRound.palm)
        #expect(r.completedFlights == 2);#expect(r.deliveredLeaf);#expect(r.discoveries.contains(.olive))
    }
    @Test func thirdFlightStaysAwayAndFinishesOnce() {
        var r = thirdBranch();#expect(r.phase == .settling);#expect(r.flight == 2);#expect(r.deliveredLeaf)
        #expect(r.settle(at:.init(x:1,y:1)).isEmpty);#expect(r.settle(at:DoveVoyageRound.perch) == [.settled]);#expect(r.completedFlights == 3)
        let events = tick(&r,20);#expect(events.filter {$0 == .finished}.count == 1);#expect(r.phase == .won)
        #expect(tick(&r,50).isEmpty)
    }
    @Test func pauseFreezesFlightAndReleasesFinger() {
        var r = launched();r.steer(direction:1,altitude:0.3);_ = tick(&r,1);r.pause();let position = r.position,time = r.time
        #expect(tick(&r,20).isEmpty);#expect(r.position == position);#expect(r.time == time)
        r.resume();_ = tick(&r,2);#expect(r.position.x == position.x)
    }
    @Test func pauseFreezesWaitingAndCloseups() {
        var r = firstHome();_ = r.land(at:DoveVoyageRound.palm);_ = tick(&r,3.1);r.waitSevenDays();_ = tick(&r,2);r.pause();_ = tick(&r,20);#expect(r.days == 2)
        r.resume();_ = tick(&r,4.7);#expect(r.phase == .ready)
        r = secondLeaf();r.pause();#expect(r.pluck(from:DoveVoyageRound.leafHome,to:DoveVoyageRound.beak).isEmpty);r.resume();#expect(r.phase == .leaf)
    }
    @Test func inputsStayFiniteAndWithinTheWorld() {
        var r = launched();r.steer(direction:.nan,altitude:.infinity);_ = r.advance(.infinity);_ = r.advance(-4)
        #expect(r.position.finite);r.steer(direction:90,altitude:-500);_ = tick(&r,100)
        #expect(r.position.x<=3300);#expect(r.position.y>=0.23);#expect(r.position.finite)
    }
    @Test func quickGestureGlidesThenComesToRest() {
        var r = launched();r.steer(direction:1,altitude:0.3);r.release();let x = r.position.x
        _ = tick(&r,2);#expect(r.position.x>x+80);_ = tick(&r,3);#expect(abs(r.velocity)<0.1)
    }
    @Test func replayResetsAndExplorationNeverRecompletes() {
        var r = thirdBranch();_ = r.settle(at:DoveVoyageRound.perch);_ = tick(&r,20);r.explore();#expect(r.phase == .exploring)
        var events:[DoveVoyageRound.Event] = [];for _ in 0..<8 { events += guide(&r) }
        #expect(!events.contains(.finished));#expect(r.completedFlights == 3)
        r.start();#expect(r.flight == 0);#expect(r.completedFlights == 0);#expect(!r.hasLeaf);#expect(!r.deliveredLeaf);#expect(r.discoveries.isEmpty)
    }
    @Test func discoveriesOnlyAwardOnce() {
        var r = launched();r.steer(direction:1,altitude:0.57);var events = tick(&r,3.2);r.release();events += tick(&r,4)
        #expect(events.filter {$0 == .discovery(.reflection)}.count == 1);#expect(r.discoveries.contains(.reflection))
        events = tick(&r,10);#expect(!events.contains(.discovery(.reflection)))
    }
}
