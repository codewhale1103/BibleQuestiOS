import Testing
@testable import BibleQuest

struct RoaringRunTests {
    @Test func countdownPreventsMovementAndPauseFreezesTheWholeRun() {
        var run = RoaringRun()
        run.start()
        run.move(-1)
        let earlyJump = run.jump()
        #expect(run.lane == 1)
        #expect(!earlyJump)
        run.pause()
        let frozenCount = run.countdown
        _ = run.advance(1)
        #expect(run.countdown == frozenCount)
        run.resume()
        for _ in 0..<181 { _ = run.advance(1.0 / 60) }
        #expect(run.phase == .running)
        for _ in 0..<100 { _ = run.advance(1.0 / 60) }
        run.pause()
        let distance = run.distance
        let elapsed = run.elapsed
        let hazards = run.hazards.map(\.distance)
        _ = run.advance(1)
        #expect(run.distance == distance)
        #expect(run.elapsed == elapsed)
        #expect(run.hazards.map(\.distance) == hazards)
    }

    @Test func controlsStayInBoundsAndJumpCannotBeStacked() {
        var run = runningRound()
        for _ in 0..<10 { run.move(-1) }
        #expect(run.lane == 0)
        for _ in 0..<10 { run.move(1) }
        #expect(run.lane == 2)
        let first = run.jump()
        let repeated = run.jump()
        #expect(first)
        #expect(!repeated)
        _ = run.advance(0.44)
        #expect(run.jumpHeight > 1.7)
        _ = run.advance(0.5)
        #expect(run.jumpTime == nil)
        #expect(run.jumpHeight == 0)
    }

    @Test(arguments: [UInt64(1), 31, 578, 9999, 65001])
    func aReadableRouteCanSurviveEveryWaveAndFinishesOnlyOnce(seed: UInt64) {
        var run = runningRound(seed: seed)
        var finishEvents = 0
        for _ in 0..<3700 {
            if run.phase != .running { break }
            steerSafely(&run)
            let events = run.advance(1.0 / 120)
            finishEvents += events.filter { $0 == .finished }.count
        }
        #expect(run.phase == .finished)
        #expect(run.strikes == 0)
        #expect(run.elapsed == 30)
        #expect(run.remaining == 0)
        #expect(finishEvents == 1)
        #expect(run.dodges > 0)
        let afterFinish = run.advance(1)
        #expect(afterFinish.isEmpty)
    }

    @Test func threeUnavoidedHitsEndTheRunAndRestartClearsIt() {
        var run = runningRound()
        for _ in 0..<4000 {
            guard run.phase == .running else { break }
            if let hazard = run.closestHazard, !hazard.spansTrack {
                run.move(hazard.lane - run.lane)
            }
            _ = run.advance(1.0 / 120)
        }
        #expect(run.phase == .caught)
        #expect(run.strikes == 3)
        #expect(run.courage == 0)
        run.start()
        #expect(run.phase == .countdown)
        #expect(run.strikes == 0)
        #expect(run.hazards.isEmpty)
        #expect(run.distance == 0)
        #expect(run.jumpTime == nil)
    }

    @Test func skippedFramesStillEvaluateCollisions() {
        var run = runningRound()
        for _ in 0..<30 {
            guard run.phase == .running else { break }
            if let hazard = run.closestHazard, !hazard.spansTrack { run.move(hazard.lane - run.lane) }
            _ = run.advance(1)
        }
        #expect(run.phase == .caught)
        #expect(run.strikes == 3)
    }

    private func runningRound(seed: UInt64 = 31) -> RoaringRun {
        var run = RoaringRun(); run.start(seed: seed)
        for _ in 0..<3 { _ = run.advance(1) }
        return run
    }
    private func steerSafely(_ run: inout RoaringRun) {
        let near = run.hazards.filter { !$0.evaluated && $0.distance < 15 && !$0.spansTrack }
        let blocked = Set(near.map(\.lane))
        if blocked.contains(run.lane), let safe = (0...2).first(where: { !blocked.contains($0) }) {
            run.move(safe - run.lane)
        }
        if let gap = run.hazards.first(where: { !$0.evaluated && $0.spansTrack && $0.distance / run.speed < 0.45 }) {
            if gap.distance > 0.7 { _ = run.jump() }
        }
    }
}
