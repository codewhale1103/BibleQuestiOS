import Testing
import Foundation
@testable import BibleQuest

struct RainOrchestraRoundTests {
    private func advance(_ r:inout RainOrchestraRound,_ seconds:Double) -> [RainOrchestraRound.Event] {
        var events:[RainOrchestraRound.Event] = []
        for _ in 0..<Int(ceil(seconds/0.05)) { events += r.advance(0.05) };return events
    }
    private func solve(_ r:inout RainOrchestraRound,note:Int = 1) {
        for (cell,tile) in RainOrchestraRound.solution(chapter:r.chapter,note:note) {
            _ = r.place(tile.piece,at:cell)
            for _ in 0..<3 { if r.tiles[cell]?.turn == tile.turn { break };r.rotate(cell) }
        }
    }
    private func chapter(_ r:inout RainOrchestraRound) {
        if r.chapter == 2 {
            for note in RainOrchestraRound.melody { solve(&r,note:note);_ = r.pour();_ = advance(&r,6.2) }
        } else { solve(&r);_ = r.pour();_ = advance(&r,6.2) }
    }
    @Test func anEmptyRingSpillsWithoutCompleting() {
        var r = RainOrchestraRound();r.start();let poured = r.pour();#expect(poured)
        let events = advance(&r,7)
        #expect(r.phase == .playing && r.cycleNotes.isEmpty && events.contains(.spill))
        #expect(r.network().spills[RainCell(0,1)] == 1)
    }
    @Test func waterMustTravelAndFillBeforeTheSongCompletes() {
        var r = RainOrchestraRound();r.start();solve(&r);let poured = r.pour();#expect(poured)
        _ = advance(&r,1);#expect(r.cycleNotes.isEmpty && r.phase == .playing)
        let events = advance(&r,3)
        #expect(events.contains(.note(1)) && r.phase == .celebrating && r.completedChapters == 1 && r.day == 8)
        #expect(!r.pour() && !r.place(.channel,at:RainCell(0,0)))
    }
    @Test func splittersConserveFlowAndBothBowlsNeedTheSamePour() {
        var r = RainOrchestraRound();r.start();chapter(&r);r.next();solve(&r)
        let f = r.network();#expect(abs(f.outputs.reduce(0,+)-1)<0.000001)
        #expect(f.outputs[0] == 0.5 && f.outputs[2] == 0.5 && f.outputs[1] == 0)
        r.remove(RainCell(3,2));_ = r.pour();_ = advance(&r,6.5)
        #expect(r.phase == .playing && r.cycleNotes == [0])
        _ = r.place(.channel,at:RainCell(3,2));r.remove(RainCell(3,0));_ = r.pour();_ = advance(&r,6.5)
        #expect(r.phase == .playing && r.cycleNotes == [2])
        _ = r.place(.channel,at:RainCell(3,0));_ = r.pour();_ = advance(&r,6.5)
        #expect(r.phase == .celebrating)
    }
    @Test func moonlightMelodyRequiresLowHighMiddleInOrder() {
        var r = RainOrchestraRound();r.start();chapter(&r);r.next();chapter(&r);r.next()
        solve(&r,note:2);_ = r.pour();_ = advance(&r,6.5);#expect(r.melodyProgress == 0)
        for (i,note) in RainOrchestraRound.melody.enumerated() {
            solve(&r,note:note);_ = r.pour();_ = advance(&r,6.5);#expect(r.melodyProgress == i+1)
        }
        #expect(r.phase == .celebrating)
    }
    @Test func everyValidNetworkConservesAllInputIncludingSpills() {
        var r = RainOrchestraRound.showcase()
        for seed in 0..<25 {
            for row in 0..<4 { for col in 0..<3 {
                let cell = RainCell(row,col);_ = r.place(RainPiece.allCases[(seed+row+col)%3],at:cell)
                for _ in 0..<((seed+row*3+col)%3) { r.rotate(cell) }
                if (seed+row+col)%7 == 0 { r.remove(cell) }
            } }
            let f = r.network();#expect(abs(f.outputs.reduce(0,+)+f.spills.values.reduce(0,+)-1)<0.000001)
            #expect(f.outputs.allSatisfy {$0>=0 && $0<=1})
        }
    }
    @Test func wheelAndDrumNeedToWorkTogether() {
        var r = RainOrchestraRound();r.start()
        for _ in 0..<3 { chapter(&r);r.next() };solve(&r)
        #expect(r.network().wheel == 1)
        _ = r.pour();_ = advance(&r,2);#expect(r.phase == .playing)
        _ = advance(&r,4.5);#expect(r.phase == .celebrating && r.wheelTurns>=0.8)
    }
    @Test func allFiveSongsProduceOnlyOneCompletionAndUnlockFreePlay() {
        var r = RainOrchestraRound();r.start()
        for i in 0..<5 { #expect(r.chapter == i);chapter(&r);#expect(r.phase == .celebrating);r.next() }
        #expect(r.phase == .finale && r.day == 40 && r.completedChapters == 5)
        let events = advance(&r,15);#expect(events.filter {$0 == .finished}.count == 1 && r.phase == .won)
        #expect(advance(&r,15).isEmpty);r.freeplay();#expect(r.phase == .freeplay)
        _ = r.pour();#expect(!advance(&r,7).contains(.finished))
    }
    @Test func pauseFreezesWaterAndReplayClearsTheMachine() {
        var r = RainOrchestraRound();r.start();solve(&r);_ = r.pour();_ = advance(&r,0.5)
        let age = r.pourAge;r.pause();_ = advance(&r,20)
        #expect(r.pourAge == age && !r.pour() && !r.place(.channel,at:RainCell(0,0)))
        r.resume();_ = advance(&r,4);#expect(r.phase == .celebrating)
        r.start();#expect(r.chapter == 0 && r.phase == .playing && r.completedChapters == 0 && r.tiles.count == 3 && r.played.isEmpty)
    }
    @Test func hintsRepairOneConnectionWithoutSkippingTheInteraction() {
        var r = RainOrchestraRound();r.start()
        #expect(r.hint() == RainCell(0,1));#expect(r.hint() == nil && r.phase == .playing)
        _ = r.pour();_ = advance(&r,6.5);#expect(r.phase == .celebrating)
        r.next();let before = r.tiles.count;#expect(r.hint() != nil && r.tiles.count == before+1)
        #expect(r.completedChapters == 1)
    }
    @Test func draggingSwapsPiecesAndInvalidCellsCannotChangeState() {
        var r = RainOrchestraRound.showcase();let a = RainCell(1,1),b = RainCell(2,0),oldA = r.tiles[a],oldB = r.tiles[b]
        let moved = r.move(from:a,to:b);#expect(moved);#expect(r.tiles[a] == oldB && r.tiles[b] == oldA)
        let tiles = r.tiles;let placed = r.place(.channel,at:RainCell(-1,0));let invalidMove = r.move(from:a,to:RainCell(0,99));#expect(!placed && !invalidMove)
        _ = r.advance(.nan);_ = r.advance(.infinity);_ = r.advance(-1);#expect(r.tiles == tiles && r.elapsed == 0)
    }
}
