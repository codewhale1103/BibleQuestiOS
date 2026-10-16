import Testing
@testable import BibleQuest

struct VictorySongRoundTests {
    private func move(_ round: inout VictorySongRound,to target: Double,step: Double = 1.0/120) -> [VictorySongRound.Event] {
        var events: [VictorySongRound.Event] = []
        while round.phase == .playing && round.time < target-0.000001 { events += round.advance(min(step,target-round.time)) }
        return events
    }
    private func begin(_ round: inout VictorySongRound,gentle: Bool = false) {
        round.start(gentle: gentle)
        for _ in 0..<31 where round.phase == .countIn { _ = round.advance(0.1) }
    }
    private func finish(_ round: inout VictorySongRound) -> [VictorySongRound.Event] {
        var events: [VictorySongRound.Event] = []
        for _ in 0..<600 where round.active { events += round.advance(0.1) }
        return events
    }
    @Test func melodyIsPlayableWithOneFingerAndHasThreeDistinctPassages() {
        let notes = VictorySongRound.notes
        #expect(notes.count == 36)
        #expect(Set(notes.map(\.passage)) == [0,1,2])
        #expect(notes.filter { $0.duration > 0 }.count == 6)
        for (note,next) in zip(notes,notes.dropFirst()) { #expect(note.end+0.5 < next.time) }
        #expect(VictorySongRound.duration < 50)
    }
    @Test(arguments: [1.0/30,1.0/60,1.0/240])
    func perfectSongScoresAllNotesAndDeliversOneCompletion(step: Double) {
        var round = VictorySongRound(); begin(&round)
        var events: [VictorySongRound.Event] = []
        for note in VictorySongRound.notes {
            events += move(&round,to: note.time,step: step)
            events += round.press(note.lane)
            #expect(round.press(note.lane).isEmpty)
            if note.duration > 0 { events += move(&round,to: note.end,step: step) }
            events += round.release(note.lane)
        }
        events += finish(&round)
        #expect(round.phase == .won)
        #expect(round.hits == 36)
        #expect(round.perfects == 36)
        #expect(round.sustained == 6)
        #expect(round.bestStreak == 36)
        #expect(round.lanterns == 12)
        #expect(round.stars == 3)
        #expect(round.score == 4860)
        #expect(events.filter { $0 == .finale }.count == 1)
        #expect(events.filter { $0 == .finished(true) }.count == 1)
        #expect(round.advance(0.1).isEmpty)
    }
    @Test func missesNeverAwardVictoryAndReplayClearsEveryNoteAndHold() {
        var round = VictorySongRound(); begin(&round)
        let events = finish(&round)
        #expect(round.phase == .practice)
        #expect(round.hits == 0 && round.score == 0)
        #expect(events.filter { if case .missed = $0 { return true }; return false }.count == 36)
        #expect(!events.contains(.finished(true)))
        begin(&round,gentle: true)
        #expect(round.states.allSatisfy { $0 == .waiting })
        #expect(round.judgments.isEmpty)
        #expect(round.pressed.isEmpty)
        #expect(round.window == 0.42)
    }
    @Test func catchWindowWrongLaneAndRepeatedPressesCannotFarmPoints() {
        var round = VictorySongRound(); begin(&round)
        #expect(round.press(-1).isEmpty && round.press(3).isEmpty)
        #expect(round.press(0).isEmpty); _ = round.release(0)
        let note = VictorySongRound.notes[0]
        _ = move(&round,to: note.time-0.2)
        #expect(round.press(2).isEmpty); _ = round.release(2)
        #expect(round.press(note.lane) == [.plucked(note.id,.good)])
        let score = round.score
        _ = round.release(note.lane)
        #expect(round.press(note.lane).isEmpty)
        #expect(round.score == score && round.hits == 1)
        #expect(round.perfects == 0)
    }
    @Test func heldRibbonsRewardTheirTailOnlyOnceAndEarlyReleaseKeepsTheOnset() {
        var round = VictorySongRound(); begin(&round)
        let note = VictorySongRound.notes[5]
        _ = move(&round,to: note.time); _ = round.press(note.lane)
        _ = move(&round,to: note.time+0.3); _ = round.release(note.lane)
        #expect(round.hits == 1 && round.sustained == 0)
        #expect(round.streak == 0)
        #expect(round.states[note.id] == .caught)
        let next = VictorySongRound.notes[11]
        _ = move(&round,to: next.time); _ = round.press(next.lane)
        let score = round.score
        _ = move(&round,to: next.end-0.1)
        #expect(round.release(next.lane) == [.sustained(next.id)])
        #expect(round.sustained == 1 && round.score == score+70)
        #expect(round.release(next.lane).isEmpty)
    }
    @Test func pauseFreezesTimeAndResumeCountsInWithoutLosingAHeldRibbon() {
        var round = VictorySongRound(); begin(&round)
        let note = VictorySongRound.notes[5]
        _ = move(&round,to: note.time); _ = round.press(note.lane)
        _ = move(&round,to: note.time+0.3)
        round.pause(); let time = round.time,score = round.score
        #expect(round.pressed.isEmpty)
        for _ in 0..<40 { #expect(round.advance(0.1).isEmpty) }
        #expect(round.time == time && round.score == score)
        round.resume(); #expect(round.phase == .countIn)
        for _ in 0..<10 { _ = round.advance(0.1) }
        #expect(round.time == time)
        round.pause(); round.resume()
        for _ in 0..<31 where round.phase == .countIn { _ = round.advance(0.1) }
        #expect(round.phase == .playing && round.time == time)
        #expect(round.press(note.lane).isEmpty)
        _ = move(&round,to: note.end)
        #expect(round.sustained == 1 && round.hits == 1)
    }
    @Test func twentyNotesAreEnoughToFinishAndInvalidTimeCannotMoveTheSong() {
        var round = VictorySongRound(); begin(&round)
        let time = round.time
        #expect(round.advance(.nan).isEmpty && round.advance(.infinity).isEmpty && round.advance(-2).isEmpty)
        #expect(round.time == time)
        for note in VictorySongRound.notes.prefix(20) {
            _ = move(&round,to: note.time); _ = round.press(note.lane); _ = round.release(note.lane)
        }
        _ = finish(&round)
        #expect(round.phase == .won)
        #expect(round.stars == 1)
        #expect(round.hits == 20)
    }
}
