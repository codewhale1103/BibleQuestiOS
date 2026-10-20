import SwiftUI
import Combine
import AVFoundation

final class RainOrchestraController: NSObject,ObservableObject {
    private(set) var round = RainOrchestraRound()
    @Published private(set) var time = 0.0
    @Published private(set) var soundOn = true
    @Published var selected: RainPiece = .channel
    @Published private(set) var song = RainSong(rawValue:UserDefaults.standard.string(forKey:"RainOrchestra.song") ?? "") ?? .afterTheRain
    private var musicWanted = true
    private var patternFocusUntil = 0.0
    var musicPlaying: Bool { audio.musicPlaying }
    var musicProgress: Double { audio.musicProgress }
    private(set) var highlight: RainCell?
    private(set) var hintUntil = 0.0
    private(set) var noteTimes = [-100.0,-100,-100]
    private(set) var boatStart = -100.0
    private(set) var caption = ""
    private(set) var captionUntil = 0.0
    var reduceMotion = false
    var onComplete: (() -> Void)?
    private let audio = RainOrchestraAudio()
    private var display: CADisplayLink?
    private var proxy: RainDisplayTarget?
    private var lastFrame: Double?
    private var melodyQueue: [(Double,Int)] = []
    private var delivered = false
    private var lastSpill = -100.0
    func attach() {
        guard display == nil else { return }
        let proxy = RainDisplayTarget();proxy.owner = self;self.proxy = proxy
        let display = CADisplayLink(target: proxy,selector: #selector(RainDisplayTarget.frame(_:)))
        display.preferredFrameRateRange = .init(minimum: 30,maximum: 60,preferred: 60)
        display.add(to: .main,forMode: .common);self.display = display
    }
    func detach() { display?.invalidate();display = nil;proxy = nil;audio.stop();onComplete = nil }
    func start() {
        round.start();time = 0;lastFrame = nil;delivered = false;selected = .channel;highlight = RainCell(0,1);hintUntil = 8
        noteTimes = [-100,-100,-100];boatStart = -100;caption = "";captionUntil = 0;lastSpill = -100;melodyQueue = []
        audio.stop();patternFocusUntil = 0;if soundOn { audio.ambience();if musicWanted { audio.playMusic(song) };audio.speak(["welcome","first"]) };objectWillChange.send()
    }
    func select(_ piece: RainPiece) { selected = piece;UISelectionFeedbackGenerator().selectionChanged() }
    func place(_ piece: RainPiece,at cell: RainCell) {
        guard round.place(piece,at: cell) else { return };highlight = nil
        click();objectWillChange.send()
    }
    func tap(_ cell: RainCell) {
        guard round.interactive else { return }
        if round.tiles[cell] == nil { place(selected,at: cell) }
        else { round.rotate(cell);click();objectWillChange.send() }
    }
    func move(_ from: RainCell,to: RainCell) { if round.move(from: from,to: to) { click();objectWillChange.send() } }
    func remove(_ cell: RainCell) { round.remove(cell);click();objectWillChange.send() }
    func pour() {
        guard round.pour() else { return };if soundOn { audio.cue("rain-gate",volume: 0.30);if musicWanted { audio.playMusic(song) } }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred();caption = "Follow the little stream…";captionUntil = time+3;objectWillChange.send()
    }
    func help() {
        highlight = round.hint();hintUntil = time+8
        if soundOn { audio.speak(["help"]) }
        caption = highlight == nil ? "Your route is ready. Pull the gold gate!" : "One little clue. Try the next connection!";captionUntil = time+6
        announce(caption);objectWillChange.send()
    }
    func read() { if soundOn { audio.speak([round.voice]) };announce(round.instruction) }
    func melody() {
        guard round.interactive else { return };patternFocusUntil = time+4;audio.focusOnPattern(true);melodyQueue = RainOrchestraRound.melody.enumerated().map { (time+Double($0.offset)*0.85,$0.element) }
        caption = "Listen: low · high · middle";captionUntil = time+3;objectWillChange.send()
    }
    func playBowl(_ note: Int) {
        guard (0..<3).contains(note),round.interactive else { return }
        strike(note);announce(["Low note","Middle note","High note"][note])
    }
    func next() {
        guard round.phase == .celebrating else { return };round.next();highlight = nil;hintUntil = 0;captionUntil = 0;melodyQueue = []
        if soundOn { audio.speak([round.phase == .finale ? "finale" : round.voice]) }
        if round.phase == .finale { audio.stopAmbience() }
        announce(round.phase == .finale ? "Forty days and nights. The rain is growing quiet." : round.title+". "+round.instruction);objectWillChange.send()
    }
    func freeplay() { round.freeplay();if soundOn { audio.ambience();if musicWanted { audio.playMusic(song) };audio.speak(["free"]) };objectWillChange.send() }
    func boat() {
        guard round.phase == .freeplay else { return }
        if !round.waterMoving { pour() };boatStart = time;objectWillChange.send()
    }
    func reset() { round.resetBoard();highlight = nil;captionUntil = 0;melodyQueue = [];objectWillChange.send() }
    func pause() { round.pause();lastFrame = nil;melodyQueue = [];patternFocusUntil = 0;audio.focusOnPattern(false);audio.suspend();objectWillChange.send() }
    func resume() { round.resume();lastFrame = nil;if soundOn { audio.resume(song:song,musicWanted:musicWanted,rainWanted:round.phase != .finale) };objectWillChange.send() }
    func toggleSound() {
        soundOn.toggle()
        if soundOn && round.phase != .paused { audio.resume(song:song,musicWanted:musicWanted,rainWanted:round.phase != .finale && round.phase != .intro) }
        else { audio.suspend() }
    }
    func toggleMusic() {
        if audio.musicPlaying { musicWanted = false;audio.pauseMusic() }
        else {
            musicWanted = true;melodyQueue = [];patternFocusUntil = 0;audio.focusOnPattern(false)
            soundOn = true;audio.resume(song:song,musicWanted:true,rainWanted:round.interactive)
        }
        objectWillChange.send()
    }
    func chooseSong(_ selection:RainSong) {
        song = selection;musicWanted = true;melodyQueue = [];patternFocusUntil = 0;audio.focusOnPattern(false)
        UserDefaults.standard.set(selection.rawValue,forKey:"RainOrchestra.song")
        soundOn = true;audio.resume(song:song,musicWanted:true,rainWanted:round.interactive)
        objectWillChange.send()
    }
    private func click() { UISelectionFeedbackGenerator().selectionChanged();if soundOn { audio.cue("rain-wood",volume: 0.22) } }
    private func strike(_ note: Int) { noteTimes[note] = time;if soundOn { audio.note(note) };UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.35) }
    private func announce(_ text: String) { UIAccessibility.post(notification: .announcement,argument: text) }
    fileprivate func frame(_ link: CADisplayLink) {
        let dt = min(0.1,max(0,lastFrame.map {link.timestamp-$0} ?? 1.0/60));lastFrame = link.timestamp
        guard round.phase != .paused else { return };time += dt
        let previousMelody = round.melodyProgress
        for event in round.advance(dt) {
            switch event {
            case .note(let note):
                strike(note)
                if round.chapter == 2 && round.phase == .playing {
                    caption = round.melodyProgress>previousMelody ? "Lovely! Next: "+["LOW","HIGH","MIDDLE"][min(2,round.melodyProgress)]+"." : "Try the melody: LOW, HIGH, MIDDLE."
                    captionUntil = time+5;announce(caption)
                }
            case .chapter:
                caption = "Beautiful! Your water machine sings.";captionUntil = time+5
                if soundOn && musicWanted { audio.playMusic(song) };announce("Song complete. "+round.title)
            case .finished:
                if !delivered { delivered = true;onComplete?() };audio.stopAmbience();announce("Forty days and nights complete. Keep making music or return to Noah's voyage.")
            case .spill:
                if time-lastSpill > 15 { lastSpill = time;caption = "Splish, splash! Try turning a channel.";captionUntil = time+4 }
            }
        }
        if patternFocusUntil>0 && time>=patternFocusUntil { patternFocusUntil = 0;audio.focusOnPattern(false) }
        while let item = melodyQueue.first,item.0 <= time { melodyQueue.removeFirst();strike(item.1) }
    }
    deinit { display?.invalidate() }
}
private final class RainDisplayTarget: NSObject {
    weak var owner: RainOrchestraController?
    @objc func frame(_ link: CADisplayLink) { owner?.frame(link) }
}
