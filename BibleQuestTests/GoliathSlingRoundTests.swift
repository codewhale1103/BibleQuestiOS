import Testing
@testable import BibleQuest

struct GoliathSlingRoundTests {
    // Independently solve the ballistic endpoint for a one-second flight to a guard.
    private func aim(_ round: inout GoliathSlingRound,at id: Int) {
        let duration = round.arena.wide ? 0.8 : 1.0
        let delta = round.arena.target(id,clock: round.clock+duration)-round.arena.anchor
        let divisor = 1-GoliathSlingRound.launchScale*duration
        round.setPull(SlingPoint(x: delta.x/divisor,y: (delta.y+round.arena.gravity*duration*duration/2)/divisor))
    }
    private func settle(_ round: inout GoliathSlingRound,step: Double = 1.0/120) -> [GoliathSlingRound.Event] {
        var events: [GoliathSlingRound.Event] = []
        for _ in 0..<1600 where ![.ready,.won,.lost].contains(round.phase) { events += round.advance(step) }
        return events
    }
    @Test func canceledShortAndInvalidPullsNeverSpendAStone() {
        var round = GoliathSlingRound()
        round.setPull(SlingPoint(x: -180,y: -150))
        #expect(round.launch().isEmpty)
        round.start(); round.setPull(SlingPoint(x: -10,y: -10))
        #expect(round.launch().isEmpty)
        round.setPull(SlingPoint(x: .nan,y: -150))
        round.setPull(SlingPoint(x: -150,y: -.infinity))
        #expect(!round.canLaunch)
        round.setPull(SlingPoint(x: -180,y: -150)); round.cancelAim()
        #expect(round.launch().isEmpty)
        #expect(round.stones == 5)
        #expect(round.shots == 0)
        round.setPull(SlingPoint(x: -9999,y: -9999))
        #expect(abs(round.pull.length-GoliathSlingRound.maxPull) < 0.0001)
    }
    @Test(arguments: [390.0/844,844.0/390,768.0/1024])
    func everyGuardIsReachableAndAThreeShotFinishKeepsTwoStones(aspect: Double) {
        var round = GoliathSlingRound(); round.resize(aspect: aspect); round.start()
        var events: [GoliathSlingRound.Event] = []
        for id in [2,0,1] {
            aim(&round,at: id)
            #expect(round.pull.length <= GoliathSlingRound.maxPull+0.0001)
            #expect(round.launch() == [.launched])
            events += settle(&round)
            #expect(round.broken.contains(id))
        }
        #expect(round.phase == .won)
        #expect(round.stones == 2)
        #expect(round.shots == 3)
        #expect(round.perfects == 3)
        #expect(round.stars == 3)
        #expect(round.score == 3850)
        #expect(events.filter { $0 == .topple }.count == 1)
        #expect(events.filter { $0 == .won }.count == 1)
        #expect(round.advance(0.1).isEmpty)
        #expect(round.launch().isEmpty)
    }
    @Test func fiveMissesResolveTheirFlightsBeforeLosingAndReplayIsFresh() {
        var round = GoliathSlingRound(); round.start()
        var misses = 0,losses = 0
        for number in 1...5 {
            round.setPull(SlingPoint(x: 0,y: -70))
            _ = round.launch()
            #expect(round.phase == .flight)
            #expect(round.stones == 5-number)
            for event in settle(&round) {
                if case .missed = event { misses += 1 }
                if event == .lost { losses += 1 }
            }
        }
        #expect(misses == 5)
        #expect(losses == 1)
        #expect(round.phase == .lost)
        round.start()
        #expect(round.stones == 5)
        #expect(round.broken.isEmpty)
        #expect(round.shots == 0)
        #expect(round.score == 0)
        #expect(round.flight == nil)
    }
    @Test func pauseFreezesFlightAndResolutionWithoutLateEvents() {
        var round = GoliathSlingRound(); round.start(); aim(&round,at: 2); _ = round.launch()
        _ = round.advance(0.1); round.pause()
        let stone = round.flight, clock = round.clock
        #expect(round.advance(0.1).isEmpty)
        #expect(round.flight == stone)
        #expect(round.clock == clock)
        #expect(round.launch().isEmpty)
        round.resume()
        for _ in 0..<300 where round.phase == .flight { _ = round.advance(1.0/120) }
        #expect(round.phase == .impact)
        round.pause(); let time = round.phaseTime
        _ = round.advance(0.1)
        #expect(round.phaseTime == time)
        round.start()
        for _ in 0..<80 { _ = round.advance(0.1) }
        #expect(round.phase == .ready)
        #expect(round.broken.isEmpty)
        #expect(round.stones == 5)
    }
    @Test func previewIsNonDestructiveAndAgreesWithFlightAtDifferentFrameRates() {
        var slow = GoliathSlingRound(); slow.start(); aim(&slow,at: 0)
        let ammo = slow.stones, clock = slow.clock, pull = slow.pull
        let preview = slow.prediction()
        #expect(preview.target == 0)
        #expect(preview.perfect)
        #expect(!preview.points.isEmpty)
        #expect(slow.stones == ammo)
        #expect(slow.clock == clock)
        #expect(slow.pull == pull)
        var fast = slow
        _ = slow.launch(); _ = fast.launch()
        _ = settle(&slow,step: 1.0/30); _ = settle(&fast,step: 1.0/240)
        #expect(slow.broken == fast.broken)
        #expect(slow.perfects == fast.perfects)
        #expect(slow.score == fast.score)
        #expect(GoliathSlingRound.segmentDistance(SlingPoint(x: 50,y: 0),from: .zero,to: SlingPoint(x: 100,y: 0)) == 0)
        #expect(GoliathSlingRound.segmentDistance(SlingPoint(x: 50,y: 20),from: .zero,to: SlingPoint(x: 100,y: 0)) == 20)
    }
    @Test func rotationRefundsOnlyAnUnfinishedFlightAndKeepsBrokenGuards() {
        var round = GoliathSlingRound(); round.start(); aim(&round,at: 2); _ = round.launch(); _ = settle(&round)
        #expect(round.stones == 4)
        aim(&round,at: 0); _ = round.launch(); _ = round.advance(0.1); round.pause()
        round.resize(aspect: 844.0/390)
        #expect(round.phase == .paused)
        #expect(round.stones == 4)
        #expect(round.shots == 1)
        #expect(round.flight == nil)
        #expect(round.broken == [2])
        round.resume(); #expect(round.phase == .ready)
        round.resize(aspect: 844.0/390)
        #expect(round.stones == 4)
        let before = round.arena.height
        round.resize(aspect: .nan); _ = round.advance(.infinity)
        #expect(round.arena.height == before)
    }
}
