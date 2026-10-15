import Testing
import Foundation
@testable import BibleQuest

struct ShepherdRoundTests {
    @Test func hiddenLambCannotBeCollectedBeforeItsHidingPlaceIsOpened() {
        var round = ShepherdRound()
        let hiddenAttempt = round.rescue(1)
        #expect(!hiddenAttempt)
        #expect(round.rescued.isEmpty)
        let revealed = round.reveal(1)
        let rescued = round.rescue(1)
        #expect(revealed)
        #expect(rescued)
        #expect(round.rescued == [1])
    }

    @Test func repeatedTapsAndInvalidTargetsCannotAddProgress() {
        var round = ShepherdRound()
        let first = round.rescue(0)
        let repeated = round.rescue(0)
        let invalid = round.rescue(100)
        let visibleCover = round.reveal(0)
        let invalidCover = round.reveal(100)
        #expect(first)
        #expect(!repeated)
        #expect(!invalid)
        #expect(!visibleCover)
        #expect(!invalidCover)
        #expect(round.rescued.count == 1)
        #expect(!round.isComplete)
    }

    @Test func everyLambIsReachableAndCompletionRequiresAllSeven() {
        var round = ShepherdRound()
        for (index, lamb) in ShepherdLambSpot.flock.enumerated() {
            if lamb.cover != nil {
                let revealed = round.reveal(lamb.id)
                let repeated = round.reveal(lamb.id)
                #expect(revealed)
                #expect(!repeated)
            }
            let rescued = round.rescue(lamb.id)
            #expect(rescued)
            #expect(round.isComplete == (index == 6))
        }
        #expect(round.rescued.count == 7)
        #expect(round.nextClue == nil)
    }

    @Test func hintsPreferVisibleLambsAndNeverPointAtRescuedLambs() {
        var round = ShepherdRound()
        #expect(round.nextClue?.id == 0)
        round.rescue(0)
        #expect(round.nextClue?.id == 3)
        round.rescue(3)
        #expect(round.nextClue?.id == 1)
        round.reveal(1)
        round.rescue(1)
        #expect(round.nextClue?.id == 2)
    }

    @Test func freshRoundRestoresEveryHidingPlaceAndLamb() {
        var round = ShepherdRound()
        round.reveal(1)
        round.rescue(1)
        round = ShepherdRound()
        #expect(round.revealed.isEmpty)
        #expect(round.rescued.isEmpty)
        #expect(!round.isComplete)
        #expect(round.nextClue?.id == 0)
    }

    @Test(arguments: [CGSize(width: 320, height: 568), CGSize(width: 402, height: 778),
                      CGSize(width: 750, height: 369), CGSize(width: 1024, height: 1300)])
    func lambsRemainReachableClearOfTheControls(size: CGSize) {
        let layout = ShepherdFieldLayout(size: size)
        for lamb in ShepherdLambSpot.flock {
            let point = layout.position(lamb)
            let halfSize = 40 * layout.scale
            #expect(point.x - halfSize > 0)
            #expect(point.x + halfSize < size.width)
            #expect(point.y - halfSize > 0)
            #expect(point.y + halfSize < size.height)
            if layout.isLandscape {
                #expect(point.x - halfSize > layout.hudWidth + 12)
            } else {
                #expect(point.y - halfSize > 165)
                #expect(point.y + halfSize < size.height - 155)
            }
        }
    }
}
