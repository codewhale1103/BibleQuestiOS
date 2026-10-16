import Testing
@testable import BibleQuest

struct ElahBalanceRoundTests {
    private func enter(_ round: inout ElahBalanceRound) {
        for _ in 0..<320 where round.phase == .countdown { _ = round.advance(1.0/120,input: 0) }
    }
    @Test func countdownDoesNotMoveDavidAndInvalidTimeIsInert() {
        var round = ElahBalanceRound(); round.start()
        _ = round.advance(0.25,input: 1)
        #expect(round.elapsed == 0)
        #expect(round.offset == 0)
        let before = round.countdown
        _ = round.advance(.nan,input: 0); _ = round.advance(-3,input: 0); _ = round.advance(.infinity,input: 0)
        #expect(round.countdown == before)
        enter(&round)
        #expect(round.phase == .walking)
        _ = round.advance(0.1,input: .nan)
        #expect(round.offset.isFinite)
    }
    @Test func readableGustsCanBeCounteredAndCompletionIsDeliveredOnce() {
        var round = ElahBalanceRound(); round.start(); enter(&round)
        #expect(round.gustWarning)
        #expect(round.wind == 0)
        var events: [ElahBalanceRound.Event] = []
        for _ in 0..<4500 where round.phase == .walking {
            let control = min(1,max(-1,-round.wind * 1.3))
            events += round.advance(1.0/120,input: control)
        }
        #expect(round.phase == .won)
        #expect(round.progress == 1)
        #expect(events.filter { $0 == .won }.count == 1)
        #expect(events.contains(.marker(1)))
        #expect(events.contains(.marker(2)))
        #expect(round.steadyPercent > 90)
        let afterward = round.advance(0.25,input: 1)
        #expect(afterward.isEmpty)
    }
    @Test func ignoringWindCausesAStumbleAndRetryKeepsLastMarker() {
        var round = ElahBalanceRound(); round.start(); enter(&round)
        var events: [ElahBalanceRound.Event] = []
        for _ in 0..<5000 where round.phase != .lost { events += round.advance(1.0/120,input: 0) }
        #expect(round.phase == .lost)
        #expect(events.filter { $0 == .stumbled }.count == 1)
        #expect(events.filter { $0 == .lost }.count == 1)
        #expect(round.checkpoint == 1)
        let marker = round.checkpoint
        round.start(from: marker)
        #expect(round.elapsed == 12)
        #expect(round.phase == .countdown)
        #expect(round.offset == 0)
        #expect(round.danger == 0)
        #expect(round.fallElapsed == 0)
        #expect(round.steadySeconds == 0)
    }
    @Test func steadyStepsChargeBreatheAndItCannotBeReusedEarly() {
        var round = ElahBalanceRound(); round.start(); enter(&round)
        #expect(round.breathe().isEmpty)
        for _ in 0..<1400 where !round.canBreathe { _ = round.advance(1.0/120,input: min(1,max(-1,-round.wind * 1.3))) }
        #expect(round.canBreathe)
        let before = abs(round.offset)
        #expect(round.breathe() == [.breathe])
        #expect(round.focus == 0)
        #expect(round.calmRemaining == 3.2)
        #expect(round.breathe().isEmpty)
        for _ in 0..<300 { _ = round.advance(1.0/120,input: 0) }
        #expect(round.calmRemaining > 0)
        #expect(abs(round.offset) < max(0.3,before))
        #expect(round.danger == 0)
    }
    @Test func pauseFreezesCrossingAbilityAndStumbleAnimation() {
        var round = ElahBalanceRound(); round.start()
        round.pause(); let countdown = round.countdown
        _ = round.advance(0.25,input: 1)
        #expect(round.countdown == countdown)
        round.resume(); enter(&round)
        for _ in 0..<1400 where !round.canBreathe { _ = round.advance(1.0/120,input: min(1,max(-1,-round.wind * 1.3))) }
        _ = round.breathe(); round.pause()
        let calm = round.calmRemaining, elapsed = round.elapsed, offset = round.offset
        _ = round.advance(0.25,input: 1)
        #expect(round.calmRemaining == calm)
        #expect(round.elapsed == elapsed)
        #expect(round.offset == offset)
        round.resume()
        for _ in 0..<5000 where round.phase == .walking { _ = round.advance(1.0/120,input: 1) }
        #expect(round.phase == .falling)
        round.pause(); _ = round.advance(0.25,input: 0)
        #expect(round.fallElapsed == 0)
        round.resume()
        #expect(round.phase == .falling)
    }
    @Test func physicsIsConsistentAcrossFrameRatesAndRestartResetsAttempt() {
        var slow = ElahBalanceRound(), fast = ElahBalanceRound()
        slow.start(); fast.start(); enter(&slow); enter(&fast)
        for _ in 0..<180 { _ = slow.advance(1.0/30,input: -0.15) }
        for _ in 0..<720 { _ = fast.advance(1.0/120,input: -0.15) }
        #expect(abs(slow.offset-fast.offset) < 0.00001)
        #expect(abs(slow.elapsed-fast.elapsed) < 0.00001)
        slow.start()
        #expect(slow.checkpoint == 0)
        #expect(slow.elapsed == 0)
        #expect(slow.focus == 0.35)
        #expect(slow.velocity == 0)
        #expect(slow.breathe().isEmpty)
    }
}
