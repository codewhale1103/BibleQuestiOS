import Testing
@testable import BibleQuest

struct StreamGuardRoundTests {
    @Test func countdownBlocksActionsAndPauseFreezesTheRound() {
        var round = StreamGuardRound(); round.start()
        #expect(round.stones == 5)
        #expect(round.shoo(1).isEmpty)
        #expect(round.call().isEmpty)
        _ = round.advance(0.7); round.pause()
        let countdown = round.countdown
        _ = round.advance(1)
        #expect(round.countdown == countdown)
        #expect(round.elapsed == 0)
        round.resume()
        for _ in 0..<3 { _ = round.advance(1) }
        #expect(round.phase == .playing)
        let elapsed = round.elapsed, birds = round.birds
        round.pause(); _ = round.advance(1)
        #expect(round.elapsed == elapsed)
        #expect(round.birds == birds)
        let firstID = birds.first?.id ?? 1
        let pausedTap = round.shoo(firstID)
        #expect(pausedTap.isEmpty)
    }

    @Test(arguments: [UInt64(1), 31, 17040, 65001])
    func protectingTheFlockKeepsAllFiveStonesAndFinishesOnlyOnce(seed: UInt64) {
        var round = playing(seed: seed)
        var completions = 0
        for _ in 0..<3700 {
            for id in round.birds.map(\.id) { _ = round.shoo(id) }
            for event in round.advance(1.0 / 120) { if event == .won { completions += 1 } }
        }
        #expect(round.phase == .won)
        #expect(round.stones == 5)
        #expect(round.remaining == 0)
        #expect(round.shooed > 20)
        #expect(round.score > 2000)
        #expect(completions == 1)
        #expect(round.advance(1).isEmpty)
    }

    @Test func fiveMissesLoseExactlyFiveStonesAndReplayStartsFresh() {
        var round = playing()
        var steals = 0, losses = 0
        for _ in 0..<30 {
            for event in round.advance(1) {
                if case .stolen = event { steals += 1 }
                if case .lost = event { losses += 1 }
            }
        }
        #expect(round.phase == .lost)
        #expect(round.stones == 0)
        #expect(steals == 5)
        #expect(losses == 1)
        #expect(round.advance(1).isEmpty)
        round.start(seed: 72)
        #expect(round.phase == .countdown)
        #expect(round.stones == 5)
        #expect(round.birds.isEmpty)
        #expect(round.elapsed == 0)
        #expect(round.score == 0)
        #expect(round.callCharge == 0)
    }

    @Test func earnedCallScattersTheWholeFlockWithoutRechargingItself() {
        var round = playing()
        while round.shooed < 5 {
            _ = round.advance(1.0 / 60)
            for id in round.birds.map(\.id) { _ = round.shoo(id) }
        }
        #expect(round.callReady)
        while round.birds.count < 2 { _ = round.advance(1.0 / 60) }
        let count = round.birds.count, score = round.score
        let events = round.call()
        #expect(events.first == .call)
        #expect(events.count == count + 1)
        #expect(round.birds.isEmpty)
        #expect(round.score == score + count * 50)
        #expect(round.callCharge == 0)
        #expect(round.call().isEmpty)
    }

    @Test func duplicateTapsCannotScoreTwiceAndSeededFlightsStayFinite() {
        var a = playing(seed: 17040), b = playing(seed: 17040)
        _ = a.advance(1); _ = b.advance(1)
        #expect(a.birds == b.birds)
        let bird = a.birds[0]
        #expect(bird.position.x.isFinite && bird.position.y.isFinite)
        #expect(!a.shoo(bird.id).isEmpty)
        let score = a.score
        #expect(a.shoo(bird.id).isEmpty)
        #expect(a.score == score)
        #expect(a.callCharge == 1)
    }

    private func playing(seed: UInt64 = 31) -> StreamGuardRound {
        var round = StreamGuardRound(); round.start(seed: seed)
        for _ in 0..<3 { _ = round.advance(1) }
        return round
    }
}
