import Testing
import CoreGraphics
@testable import BibleQuest

struct ArmorCampRoundTests {
    @Test func matchingUsesStageCoordinatesAndRejectsWrongStands() {
        for size in [CGSize(width: 393,height: 852),CGSize(width: 852,height: 393),CGSize(width: 768,height: 1024)] {
            let layout = ArmorCampLayout(size: size)
            for piece in ArmorCampRound.Piece.allCases {
                #expect(layout.stand(at: layout.standPosition(piece)) == piece)
                #expect(layout.stand(at: layout.wornPosition(piece,intro: false)) == nil)
            }
        }
        var round = ArmorCampRound(); round.start()
        #expect(round.drop(.helmet,onto: .helmet) == .unavailable)
        round.select(.helmet)
        #expect(round.drop(.helmet,onto: .sword) == .wrongStand)
        #expect(round.isWorn(.helmet))
        #expect(round.returnedCount == 0)
        round.select(.helmet)
        #expect(round.drop(.helmet,onto: .helmet) == .accepted)
        let repeated = round.select(.helmet)
        #expect(!repeated)
    }

    @Test func allArmorMustSettleAndDavidMustTakeFinalStep() {
        var round = ArmorCampRound(); round.start()
        for piece in ArmorCampRound.Piece.allCases {
            round.select(piece)
            #expect(round.drop(piece,onto: piece) == .accepted)
        }
        #expect(round.phase == .fitting)
        #expect(round.tryStep().isEmpty)
        #expect(round.advance(0.64).isEmpty)
        let events = round.advance(0.02)
        #expect(events.filter { $0 == .ready }.count == 1)
        #expect(round.phase == .ready)
        #expect(round.returnedCount == 3)
        #expect(round.advance(1).isEmpty)
        #expect(round.phase == .ready)
        #expect(round.tryStep() == [.braveStep])
        #expect(round.advance(1).isEmpty)
        #expect(round.advance(1).isEmpty)
        #expect(round.advance(0.6) == [.completed])
        #expect(round.advance(1).isEmpty)
        #expect(round.tryStep().isEmpty)
    }

    @Test func testingTheWeightLocksPiecesUntilFeetSettle() {
        var round = ArmorCampRound(); round.start()
        #expect(round.weight == 1)
        #expect(round.tryStep() == [.heavyStep])
        let duringStep = round.select(.sword)
        #expect(!duringStep)
        #expect(round.tryStep().isEmpty)
        _ = round.advance(1); _ = round.advance(0.1)
        #expect(!round.isTrying)
        let afterStep = round.select(.sword)
        #expect(afterStep)
        _ = round.drop(.sword,onto: .sword); _ = round.advance(0.7)
        #expect(round.weight < 1)
        #expect(round.tryStep() == [.heavyStep])
    }

    @Test func pauseFreezesSettlingAndFinalStride() {
        var round = ArmorCampRound(); round.start(); round.select(.helmet)
        _ = round.drop(.helmet,onto: .helmet); _ = round.advance(0.2)
        round.pause(); let pending = round.settling
        #expect(round.advance(100).isEmpty)
        #expect(round.settling == pending)
        round.resume(); _ = round.advance(0.5)
        for piece in [ArmorCampRound.Piece.breastplate,.sword] {
            round.select(piece); _ = round.drop(piece,onto: piece)
        }
        _ = round.advance(0.7); _ = round.tryStep(); _ = round.advance(0.5)
        round.pause(); _ = round.advance(10)
        #expect(round.walkElapsed == 0.5)
        round.resume(); #expect(round.phase == .walking)
    }

    @Test func restartDiscardsPendingWorkAndInvalidTimeIsInert() {
        var round = ArmorCampRound(); round.start(); round.select(.breastplate)
        _ = round.drop(.breastplate,onto: .breastplate); round.pause(); round.start()
        #expect(round.settling.isEmpty)
        #expect(round.stowed.isEmpty)
        #expect(round.selected == nil)
        #expect(round.weight == 1)
        #expect(round.advance(.nan).isEmpty)
        #expect(round.advance(.infinity).isEmpty)
        #expect(round.advance(-1).isEmpty)
        #expect(round.advance(1).isEmpty)
        #expect(round.returnedCount == 0)
    }
}
