import AVFoundation

enum RainSong: String,CaseIterable,Identifiable {
    case afterTheRain,jesusLovesMe
    var id: String { rawValue }
    var title: String { self == .afterTheRain ? "After the Rain" : "Jesus Loves Me" }
    var detail: String { self == .afterTheRain ? "A happy little adventure" : "A song about Jesus’ love" }
    var file: String { self == .afterTheRain ? "rain-song-after-the-rain" : "rain-song-jesus-loves-me" }
}

/// Offline music and narration share one mixer. Music ducks for instructions;
/// scene pauses preserve its playhead, while replay and exit clear every player.
final class RainOrchestraAudio: NSObject,AVAudioPlayerDelegate {
    private var effects: [AVAudioPlayer] = []
    private var voice: AVAudioPlayer?
    private var rain: AVAudioPlayer?
    private var music: AVAudioPlayer?
    private var musicSong: RainSong?
    private var queue: [String] = []
    private var prepared = false
    private var melodyFocus = false
    private var suspended = false
    var musicPlaying: Bool { music?.isPlaying == true }
    var musicProgress: Double {
        guard let music,music.duration>0 else { return 0 }
        return min(1,max(0,music.currentTime/music.duration))
    }
    private func player(_ name:String,ext:String = "wav") -> AVAudioPlayer? {
        if !prepared { try? AVAudioSession.sharedInstance().setCategory(.ambient,mode:.default,options:[.mixWithOthers]);prepared = true }
        guard let url = Bundle.main.url(forResource:name,withExtension:ext) else { return nil }
        let p = try? AVAudioPlayer(contentsOf:url);p?.prepareToPlay();return p
    }
    func playMusic(_ song:RainSong) {
        guard !suspended else { return }
        if musicSong != song || music == nil {
            music?.stop();music = player(song.file,ext:"m4a");musicSong = song;music?.delegate = self
        }
        guard let music else { return }
        if music.currentTime>=music.duration-0.08 { music.currentTime = 0 }
        if !music.isPlaying { music.volume = 0;music.play() };balance()
    }
    func pauseMusic() { music?.pause();balance() }
    func focusOnPattern(_ active:Bool) { guard melodyFocus != active else { return };melodyFocus = active;balance() }
    private func balance() {
        let speaking = voice?.isPlaying == true
        music?.setVolume(speaking ? 0.12 : melodyFocus ? 0.07 : 0.65,fadeDuration:speaking || melodyFocus ? 0.18 : 0.65)
        rain?.setVolume(speaking ? 0.025 : musicPlaying ? 0.035 : 0.07,fadeDuration:0.3)
    }
    func ambience() {
        guard !suspended else { return }
        if rain == nil { rain = player("flood-rain");rain?.numberOfLoops = -1 }
        rain?.play();balance()
    }
    func stopAmbience() { rain?.pause() }
    func cue(_ name:String,volume:Float) {
        guard !suspended else { return }
        effects.removeAll { !$0.isPlaying };guard let p = player(name) else { return };p.volume = volume;p.play();effects.append(p)
        if effects.count>12 { effects.removeFirst().stop() }
    }
    func note(_ value:Int) { cue("rain-note-\(value)",volume:0.42) }
    func speak(_ clips:[String]) { voice?.stop();voice = nil;queue = clips;nextVoice() }
    private func nextVoice() {
        guard !suspended else { return }
        while !queue.isEmpty {
            let id = queue.removeFirst()
            if let p = player("rain-voice-"+id,ext:"m4a") { voice = p;p.delegate = self;p.volume = 0.85;p.play();balance();return }
        }
        voice = nil;balance()
    }
    func suspend() {
        suspended = true;voice?.pause();music?.pause();rain?.pause();effects.forEach {$0.stop()};effects = []
    }
    func resume(song:RainSong,musicWanted:Bool,rainWanted:Bool) {
        suspended = false
        if let voice { voice.play() } else if !queue.isEmpty { nextVoice() }
        if rainWanted { ambience() }
        if musicWanted { playMusic(song) };balance()
    }
    func audioPlayerDidFinishPlaying(_ player:AVAudioPlayer,successfully flag:Bool) {
        if player === voice { voice = nil;nextVoice() }
        else if player === music { player.currentTime = player.duration;balance() }
    }
    func stop() {
        queue = [];voice?.stop();voice = nil;rain?.pause();music?.stop();music = nil;musicSong = nil
        effects.forEach {$0.stop()};effects = [];suspended = false;melodyFocus = false
    }
}
