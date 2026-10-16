import Testing
@testable import BibleQuest

struct ArkWorkshopRoundTests {
    private func finishTimber(_ r: inout ArkWorkshopRound) {
        r.beginTask()
        for id in 0..<5 { _ = r.uncover(id); _ = r.storeTimber(id,inBasket: true) }
    }
    private func finishDecks(_ r: inout ArkWorkshopRound) {
        r.beginTask()
        for id in [2,0,1] { r.selectDeck(id); _ = r.placeDeck(at: id) }
    }
    private func paintSide(_ r: inout ArkWorkshopRound) {
        for row in 0..<4 { for col in 0..<12 { _ = r.paint(at: .init(x: (Double(col)+0.5)/12,y: (Double(row)+0.5)/4)) } }
    }
    private func paintRound() -> ArkWorkshopRound {
        var r = ArkWorkshopRound();r.start();finishTimber(&r);r.continueDiscovery();finishDecks(&r);r.continueDiscovery();r.beginTask();return r
    }
    @Test func hiddenTimberMustBeUncoveredAndDeliveredToTheBasket() {
        var r = ArkWorkshopRound();r.start();r.beginTask()
        #expect(r.storeTimber(0,inBasket: true).isEmpty)
        #expect(r.uncover(-1).isEmpty && r.uncover(5).isEmpty)
        #expect(r.uncover(0) == [.uncovered(0)])
        #expect(r.uncover(0).isEmpty)
        #expect(r.storeTimber(0,inBasket: false) == [.hint])
        #expect(r.wood.isEmpty && r.score == 0)
        _ = r.storeTimber(0,inBasket: true)
        #expect(r.storeTimber(0,inBasket: true).isEmpty && r.score == 100)
        for id in 1..<5 { _ = r.uncover(id); _ = r.storeTimber(id,inBasket: true) }
        #expect(r.phase == .discovery && r.wood.count == 5 && r.score == 600)
    }
    @Test func matchingDecksCanBePlacedInAnyOrderAndErrorsKeepTheSelectedPiece() {
        var r = ArkWorkshopRound();r.start();finishTimber(&r);r.continueDiscovery();r.beginTask()
        r.selectDeck(2);#expect(r.placeDeck(at: 0) == [.hint])
        #expect(r.selectedDeck == 2 && r.decks.isEmpty)
        _ = r.placeDeck(at: 2);#expect(r.placeDeck(at: 2).isEmpty)
        for id in [1,0] { r.selectDeck(id); _ = r.placeDeck(at: id) }
        #expect(r.phase == .discovery && r.decks.count == 3 && r.score == 1150)
    }
    @Test func colorAndBrushAreRequiredAndPaintMustTouchTheSurface() {
        var r = paintRound()
        let emptyBrush = r.pickUpBrush(); #expect(!emptyBrush)
        #expect(r.paint(at: .init(x: 0.5,y: 0.5)).isEmpty)
        r.chooseColor(.lagoon);#expect(r.paint(at: .init(x: 0.5,y: 0.5)).isEmpty)
        let loadedBrush = r.pickUpBrush(); #expect(loadedBrush)
        for p in [ArkWorkshopPoint(x: .nan,y: 0.5),.init(x: 0.5,y: .infinity),.init(x: -0.1,y: 0.5),.init(x: 1.1,y: 0.5)] { #expect(r.paint(at: p).isEmpty) }
        #expect(r.coverage == [[],[]])
        #expect(!r.paint(at: .init(x: 0.5,y: 0.5)).isEmpty)
    }
    @Test func colorsAndInsideOutsideCoveragePersistWithoutScoreFarming() {
        var r = paintRound();r.chooseColor(.lagoon);_ = r.pickUpBrush()
        paintSide(&r);let score = r.score
        #expect(r.coveragePercent == 100 && !r.paintReady)
        r.chooseColor(.coral);paintSide(&r)
        #expect(r.score == score && r.selectedColor == .coral)
        r.flipSide();#expect(r.coveragePercent == 0 && r.percent(inside: false) == 100)
        paintSide(&r);#expect(r.paintReady && r.coveragePercent == 100)
        #expect(r.phase == .playing) // Children can keep decorating before choosing the reveal.
        r.flipSide();#expect(r.coveragePercent == 100 && r.selectedColor == .coral)
    }
    @Test func bothSidesAndAnExplicitRevealAreRequiredForOneCompletion() {
        var r = paintRound();r.chooseColor(.honey);_ = r.pickUpBrush();paintSide(&r)
        #expect(r.finishPainting().isEmpty)
        r.flipSide();paintSide(&r);#expect(r.finishPainting() == [.discovery])
        #expect(r.finishPainting().isEmpty && r.discoveries == 2)
        r.continueDiscovery();#expect(r.phase == .reveal && r.discoveries == 3 && r.score == 1730)
        var wins = 0
        for _ in 0..<80 { wins += r.advance(0.1).filter { $0 == .won }.count }
        #expect(r.phase == .won && wins == 1)
    }
    @Test func pauseAndReplayPreserveOrResetAllInteractionState() {
        var r = paintRound();r.chooseColor(.sky);_ = r.pickUpBrush();_ = r.paint(at: .init(x: 0.5,y: 0.5));r.flipSide()
        let coverage = r.coverage;r.pause()
        r.chooseColor(.coral);r.flipSide();#expect(r.paint(at: .init(x: 0.7,y: 0.5)).isEmpty)
        #expect(r.inside && r.selectedColor == .sky && r.coverage == coverage)
        r.resume();#expect(r.phase == .playing && r.brushEquipped)
        r.start();#expect(r.uncovered.isEmpty && r.wood.isEmpty && r.decks.isEmpty && r.coverage == [[],[]] && r.selectedColor == nil && !r.brushEquipped && !r.inside && r.score == 0)
        #expect(r.advance(.nan).isEmpty && r.advance(.infinity).isEmpty && r.advance(-1).isEmpty)
        #expect(r.phase == .listening && r.step == .timber)
    }
}
