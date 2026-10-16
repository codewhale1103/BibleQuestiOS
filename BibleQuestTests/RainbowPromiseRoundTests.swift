import Testing
@testable import BibleQuest

struct RainbowPromiseRoundTests {
    private func settle(_ round: inout RainbowPromiseRound) -> [RainbowPromiseRound.Event] {
        var events: [RainbowPromiseRound.Event] = []
        for _ in 0..<60 where round.phase == .bloom || round.phase == .reveal { events += round.advance(0.1) }
        return events
    }
    private func weaveByTaps(_ round: inout RainbowPromiseRound) {
        _ = round.choose(round.color)
        for index in 0..<5 { _ = round.tapStar(index) }
        _ = settle(&round)
    }
    @Test func sevenBandsAndThreeDiscoveriesAreRequiredForOneCompletion() {
        var round = RainbowPromiseRound(); round.start()
        var completions = 0
        for color in PromiseColor.allCases {
            #expect(round.color == color)
            #expect(round.choices.count == 3 && Set(round.choices.map(\.rawValue)).count == 3)
            #expect(round.choices.contains(color))
            weaveByTaps(&round)
            if round.phase == .question {
                #expect(round.answer(round.question.correct) == [.learned(round.discoveries)])
                #expect(round.phase == .lesson)
                #expect(round.advance(0.1).isEmpty)
                round.continueLesson()
            }
            for event in settle(&round) where event == .won { completions += 1 }
        }
        #expect(round.phase == .won)
        #expect(round.completedBands == 7 && round.discoveries == 3)
        #expect(round.score == 6000 && round.stars == 3 && round.firstTries == 10)
        #expect(completions == 1)
        #expect(round.advance(0.1).isEmpty && round.choose(.red).isEmpty && round.answer(0).isEmpty)
    }
    @Test func drawingAndAccessibleTapsWeaveTheSameOrderedStars() {
        var drawn = RainbowPromiseRound(),tapped = RainbowPromiseRound()
        drawn.start(); tapped.start(); _ = drawn.choose(.red); _ = tapped.choose(.red)
        for step in 0...100 { _ = drawn.trace(PromiseArc(band: 0).point(Double(step)/100)) }
        for index in 0..<5 { _ = tapped.tapStar(index) }
        #expect(drawn.phase == .bloom && tapped.phase == .bloom)
        #expect(drawn.completedBands == tapped.completedBands)
        #expect(drawn.score == tapped.score)
        #expect(drawn.checkpoint == 5)
    }
    @Test func skippingStarsOffPathTouchesAndRepeatedTapsCannotCompleteABand() {
        var round = RainbowPromiseRound(); round.start(); _ = round.choose(.red)
        #expect(round.tapStar(4).isEmpty)
        #expect(round.trace(round.arc.point(0.5)).isEmpty)
        #expect(round.trace(.init(x: .nan,y: 0)).isEmpty)
        #expect(round.trace(.init(x: 0.5,y: 0.8)).isEmpty)
        _ = round.tapStar(0)
        let score = round.score
        #expect(round.tapStar(0).isEmpty)
        #expect(round.trace(round.arc.point(0.9)).isEmpty)
        #expect(round.score == score && round.completedBands == 0)
        #expect(round.phase == .weaving)
    }
    @Test func mistakesTeachWithoutBlockingAndCannotFarmExtraPoints() {
        var round = RainbowPromiseRound(); round.start()
        #expect(round.choose(.blue) == [.tryColor])
        #expect(round.choose(.blue).isEmpty)
        _ = round.choose(.red)
        #expect(round.firstTries == 0 && round.score == 70)
        for index in 0..<5 { _ = round.tapStar(index) }
        _ = settle(&round); weaveByTaps(&round)
        #expect(round.phase == .question)
        let wrong = (round.question.correct+1)%3
        #expect(round.answer(wrong) == [.tryAnswer])
        #expect(round.answer(wrong).isEmpty)
        #expect(round.phase == .question)
        let score = round.score
        _ = round.answer(round.question.correct)
        #expect(round.score == score+180 && round.phase == .lesson)
        round.continueLesson()
        #expect(round.phase == .choose && round.discoveries == 1)
    }
    @Test func pauseFreezesWeavingBloomAndDiscoveryWithoutLosingProgress() {
        var round = RainbowPromiseRound(); round.start(); _ = round.choose(.red); _ = round.tapStar(0); _ = round.tapStar(1)
        round.pause(); let score = round.score,progress = round.progress
        #expect(round.tapStar(2).isEmpty)
        #expect(round.advance(0.1).isEmpty)
        round.resume(); #expect(round.phase == .weaving && round.progress == progress && round.score == score)
        for index in 2..<5 { _ = round.tapStar(index) }
        _ = round.advance(0.1); let time = round.phaseTime
        round.pause(); _ = round.advance(0.1); #expect(round.phaseTime == time)
        round.resume(); _ = settle(&round); weaveByTaps(&round)
        round.pause(); #expect(round.answer(round.question.correct).isEmpty)
        round.resume(); #expect(round.phase == .question)
    }
    @Test func resetClearsEveryChoiceLessonAndPendingCelebration() {
        var round = RainbowPromiseRound(); round.start()
        for _ in 0..<7 {
            weaveByTaps(&round)
            if round.phase == .question { _ = round.answer(round.question.correct); round.continueLesson() }
        }
        #expect(round.phase == .reveal)
        round.start()
        #expect(round.score == 0 && round.completedBands == 0 && round.discoveries == 0)
        #expect(round.wrongColors.isEmpty && round.wrongAnswers.isEmpty && round.pointer == nil)
        for _ in 0..<100 { #expect(round.advance(0.1).isEmpty) }
        #expect(round.phase == .choose)
    }
    @Test func rainbowGeometryKeepsRedOutsideVioletAndRejectsInvalidTime() {
        let outer = PromiseArc(band: 0),inner = PromiseArc(band: 6)
        #expect(outer.point(0.5).y < inner.point(0.5).y)
        #expect(outer.point(0).x < inner.point(0).x)
        for band in 0..<7 {
            let arc = PromiseArc(band: band)
            for step in 0...20 {
                let t = Double(step)/20,p = arc.point(t)
                #expect(p.x >= 0 && p.x <= 1 && p.y >= 0 && p.y <= 1)
                #expect(abs(arc.projection(p)-t) < 0.00001)
            }
        }
        var round = RainbowPromiseRound(); round.start(); _ = round.choose(.red)
        for index in 0..<5 { _ = round.tapStar(index) }
        #expect(round.advance(.nan).isEmpty && round.advance(.infinity).isEmpty && round.advance(-1).isEmpty)
        #expect(round.phaseTime == 0)
    }
}
