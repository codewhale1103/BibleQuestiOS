import Testing
import Foundation
@testable import BibleQuest

struct ArkParadeRoundTests {
    private func advance(_ r: inout ArkParadeRound,seconds: Double) {
        for _ in 0..<Int(ceil(seconds/0.05)) { _ = r.advance(0.05) }
    }
    private func match(_ r: inout ArkParadeRound) {
        _ = r.choose(r.choices.firstIndex(of: r.animal)!);advance(&r,seconds: 1.7)
    }
    private func board(_ r: inout ArkParadeRound) {
        match(&r);_ = r.accessibleTrail();advance(&r,seconds: 11)
    }
    @Test func eachHuntHasOnePartnerAndReplayChangesTheClearing() {
        var a = ArkParadeRound();a.start(seed: 123)
        var b = ArkParadeRound();b.start(seed: 999)
        #expect(a.choices.count == 3 && Set(a.choices.map(\.rawValue)).count == 3)
        #expect(a.choices.filter { $0 == a.animal }.count == 1)
        #expect(a.positions != b.positions)
        #expect(a.positions.allSatisfy { $0.finite && (0...1).contains($0.x) && (0...1).contains($0.y) })
    }
    @Test func onlyTheMatchingPartnerAdvancesAndWrongChoicesHaveNoPenalty() {
        var r = ArkParadeRound();r.start(seed: 12)
        #expect(r.choose(-1).isEmpty && r.choose(3).isEmpty)
        let wrong = r.choices.firstIndex { $0 != r.animal }!
        #expect(r.choose(wrong) == [.wrong(r.choices[wrong])]);#expect(r.boarded.isEmpty && r.phase == .finding)
        match(&r);#expect(r.phase == .tracing && r.boarded.isEmpty)
        #expect(r.choose(0).isEmpty)
    }
    @Test func aRealTrailMustStartAtThePairAndEndAtTheRamp() {
        var r = ArkParadeRound();r.start(seed: 4);match(&r)
        r.trace(.init(x: 0.1,y: 0.9));#expect(r.trail.isEmpty)
        r.trace(ArkParadeRound.start);r.trace(.init(x: 0.75,y: 0.6))
        #expect(r.endTrail(.init(x: 0.9,y: 0.4)) == [.trailHint]);#expect(r.trail.isEmpty && r.phase == .tracing)
        #expect(r.endTrail(.init(x: .nan,y: 0.5)) == [.trailHint])
        r.trace(ArkParadeRound.start);r.trace(.init(x: 0.77,y: 0.58));r.trace(.init(x: 0.70,y: 0.42))
        #expect(r.endTrail(ArkParadeRound.ramp) == [.walking])
        #expect(r.route.contains(.init(x: 0.77,y: 0.58))) // The child's route survives.
        #expect(r.route.last == ArkParadeRound.door && r.phase == .escorting)
    }
    @Test func trailsDetourAroundTheRockWithoutRestartingOrEnteringIt() {
        var r = ArkParadeRound();r.start(seed: 88);match(&r)
        r.trace(ArkParadeRound.start);r.trace(ArkParadeRound.rock)
        #expect(r.endTrail(ArkParadeRound.ramp) == [.walking]);#expect(r.helpedAroundRock)
        #expect(r.route.allSatisfy { $0.finite && $0.distance(to: ArkParadeRound.rock) > ArkParadeRound.rockRadius })
        for progress in stride(from: 0.0,through: 1.0,by: 0.01) {
            let p = r.walker(progress).point
            #expect(p.finite && p.distance(to: ArkParadeRound.rock) > ArkParadeRound.rockRadius)
        }
    }
    @Test func fastTwoPointStrokesStillMakeAValidTrail() {
        var r = ArkParadeRound();r.start(seed: 1);match(&r)
        r.trace(ArkParadeRound.start)
        #expect(r.endTrail(ArkParadeRound.ramp) == [.walking])
        #expect(r.route.first == ArkParadeRound.start && r.route.last == ArkParadeRound.door)
    }
    @Test func allEightPairsMustPhysicallyBoardBeforeOneCompletion() {
        var r = ArkParadeRound();r.start(seed: 18)
        #expect(r.next().isEmpty)
        for index in 0..<ArkParadeRound.pairCount {
            board(&r);#expect(r.phase == .discovery && r.animalsAboard == (index+1)*2)
            #expect(r.advance(.nan).isEmpty && r.advance(.infinity).isEmpty && r.advance(-1).isEmpty)
            #expect(r.next() == [.next])
            if index == 5 { #expect(r.phase == .finding) }
        }
        #expect(r.phase == .finale && Set(r.boarded.map(\.rawValue)).count == ArkParadeRound.pairCount)
        var wins = 0
        for _ in 0..<120 { wins += r.advance(0.05).filter { $0 == .won }.count }
        #expect(wins == 1 && r.phase == .won && r.animalsAboard == ArkParadeRound.animalCount)
        #expect(r.next().isEmpty && r.choose(0).isEmpty && r.accessibleTrail().isEmpty)
    }
    @Test func requestedAnimalsHaveEightDistinctPairs() {
        #expect(ParadeAnimal.allCases.count == 8)
        #expect([ParadeAnimal.lion,.wolf,.tiger,.monkey].allSatisfy { ParadeAnimal.allCases.contains($0) })
        #expect(!ParadeAnimal.allCases.contains { $0.name == "Duck" })
        #expect(ParadeAnimal.wolf.plural == "Wolves")
    }
    @Test func pauseFreezesMovementAndReplayClearsTheTrip() {
        var r = ArkParadeRound();r.start(seed: 55);match(&r);_ = r.accessibleTrail();advance(&r,seconds: 0.5)
        let time = r.phaseTime,route = r.route
        r.pause();#expect(r.phase == .paused);advance(&r,seconds: 5)
        #expect(r.phaseTime == time && r.route == route && r.accessibleTrail().isEmpty)
        r.resume();#expect(r.phase == .escorting);advance(&r,seconds: 11)
        #expect(r.animalsAboard == 2)
        r.start(seed: 22);#expect(r.phase == .finding && r.animalsAboard == 0 && r.route.isEmpty && r.trail.isEmpty && r.pairIndex == 0)
    }
}
