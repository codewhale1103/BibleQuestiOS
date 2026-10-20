import Testing
import Foundation
@testable import BibleQuest

struct ArkAfloatRoundTests {
    private func advance(_ r: inout ArkAfloatRound,_ seconds: Double) { for _ in 0..<Int(ceil(seconds/0.05)) { _ = r.advance(0.05) } }
    private func prepare(_ r: inout ArkAfloatRound) {
        r.start();r.comeInside()
        _ = r.drop(.basket,at: ArkAfloatRound.basketCradle);_ = r.pullRope(1)
        r.select(.loft);_ = r.slideShutter(left: true,amount: 1);_ = r.slideShutter(left: false,amount: 1)
        _ = r.drop(.lantern,at: ArkAfloatRound.hook)
    }
    private func float(_ r: inout ArkAfloatRound) { prepare(&r);_ = r.launch();advance(&r,12.2) }
    @Test func preparationRequiresTheRightObjectsInTheRightRooms() {
        var r = ArkAfloatRound();r.start()
        #expect(r.drop(.basket,at: ArkAfloatRound.basketCradle).isEmpty)
        r.comeInside()
        #expect(r.drop(.lantern,at: ArkAfloatRound.hook).isEmpty)
        #expect(r.drop(.basket,at: .init(x: 0.05,y: 0.05)).isEmpty)
        #expect(r.drop(.basket,at: .init(x: .nan,y: 0.7)).isEmpty)
        #expect(r.task == .basket && r.count == 0 && r.launch().isEmpty)
        #expect(r.drop(.basket,at: ArkAfloatRound.basketCradle) == [.task(.basket)])
        #expect(r.task == .cargoRope && !r.ready)
    }
    @Test func ropesAndBothShuttersNeedRealProgress() {
        var r = ArkAfloatRound();r.start();r.comeInside();_ = r.accessibleAction()
        #expect(r.pullRope(.infinity).isEmpty && r.rope == 0)
        #expect(r.pullRope(0.6).isEmpty && r.task == .cargoRope)
        _ = r.pullRope(0.2);#expect(r.rope == 0.6)
        _ = r.pullRope(1);r.select(.loft)
        #expect(r.slideShutter(left: true,amount: .nan).isEmpty)
        #expect(r.slideShutter(left: true,amount: 1).isEmpty)
        #expect(r.task == .shutters)
        _ = r.slideShutter(left: false,amount: 0.5);#expect(r.task == .shutters)
        #expect(r.slideShutter(left: false,amount: 1) == [.task(.shutters)])
        #expect(r.task == .lantern)
    }
    @Test func theWholePreparationPrecedesTheLiftAndCare() {
        var r = ArkAfloatRound();prepare(&r)
        #expect(r.ready && !r.caredFor && r.count == 4)
        #expect(r.launch() == [.prepared] && r.phase == .launching)
        #expect(r.accessibleAction().isEmpty)
        advance(&r,11);#expect(r.phase == .launching)
        advance(&r,1.2);#expect(r.phase == .caring && r.task == .apples)
        #expect(r.shutterLeft == 0 && r.shutterRight == 0 && r.rope == 0)
    }
    @Test func applesAreThreeUniquePhysicalDeliveries() {
        var r = ArkAfloatRound();float(&r)
        #expect(r.catchApple(-1,at: ArkAfloatRound.basketCradle).isEmpty)
        #expect(r.catchApple(0,at: .init(x: 0.1,y: 0.1)).isEmpty)
        #expect(r.catchApple(0,at: ArkAfloatRound.basketCradle) == [.apple])
        #expect(r.catchApple(0,at: ArkAfloatRound.basketCradle).isEmpty)
        _ = r.catchApple(1,at: ArkAfloatRound.basketCradle);#expect(r.task == .apples)
        #expect(r.catchApple(2,at: ArkAfloatRound.basketCradle) == [.apple,.task(.apples)])
        #expect(r.apples.count == 3 && r.task == .stormRope)
    }
    @Test func aBlanketAndGentleStrokesAreSeparateActsOfCare() {
        var r = ArkAfloatRound();float(&r);r.select(.shelter)
        #expect(r.stroke(1).isEmpty && r.comfort == 0)
        #expect(r.drop(.blanket,at: ArkAfloatRound.lamb) == [.task(.blanket)])
        #expect(r.stroke(0).isEmpty && r.stroke(.nan).isEmpty)
        _ = r.stroke(1);#expect(r.comfort < 0.04 && r.task == .soothe)
        for _ in 0..<40 { _ = r.stroke(0.05) }
        #expect(r.completed.contains(.soothe) && r.comfort == 1)
        #expect(r.stroke(0.05).isEmpty)
    }
    @Test func allNineActsLeadToExactlyOneEnding() {
        var r = ArkAfloatRound();float(&r);r.finish();#expect(r.phase == .caring)
        for room in FloodRoom.allCases { r.select(room);while r.task != nil { _ = r.accessibleAction() } }
        #expect(r.caredFor && r.count == 9)
        r.finish();#expect(r.phase == .finale)
        var wins = 0
        for _ in 0..<220 { wins += r.advance(0.05).filter { $0 == .won }.count }
        #expect(wins == 1 && r.phase == .won && r.count == 9)
        #expect(r.accessibleAction().isEmpty && r.launch().isEmpty)
    }
    @Test func roomsCanBeExploredInAnyOrderWithoutSkippingTasks() {
        var r = ArkAfloatRound();r.start();r.comeInside();r.select(.shelter)
        #expect(r.task == nil && r.count == 0)
        r.select(.loft);_ = r.accessibleAction();_ = r.accessibleAction()
        #expect(r.roomFinished(.loft) && !r.ready)
        r.select(.cargo);_ = r.accessibleAction();_ = r.accessibleAction()
        #expect(r.ready && r.count == 4)
    }
    @Test func pauseFreezesTheCinematicAndReplayResetsEverything() {
        var r = ArkAfloatRound();prepare(&r);_ = r.launch();advance(&r,3)
        let time = r.phaseTime;r.pause();advance(&r,30)
        #expect(r.phase == .paused && r.phaseTime == time)
        #expect(r.accessibleAction().isEmpty && r.drop(.basket,at: ArkAfloatRound.basketCradle).isEmpty)
        r.resume();advance(&r,9.2);#expect(r.phase == .caring)
        r.start();#expect(r.phase == .rain && r.count == 0 && r.comfort == 0 && r.apples.isEmpty)
    }
    @Test func rainPlayAndInvalidTimeCannotAdvanceTheStory() {
        var r = ArkAfloatRound();r.start()
        for _ in 0..<50 { _ = r.touchRain() }
        #expect(r.rainTouches == 50 && r.count == 0 && r.phase == .rain)
        #expect(r.advance(.nan).isEmpty && r.advance(.infinity).isEmpty && r.advance(-1).isEmpty)
        #expect(r.phaseTime == 0)
    }
}
