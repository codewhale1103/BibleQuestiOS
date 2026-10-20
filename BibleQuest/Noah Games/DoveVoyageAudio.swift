import AVFoundation

/// Bundled narration and original sampled music. Pausing preserves all playheads.
final class DoveVoyageAudio: NSObject,AVAudioPlayerDelegate {
    private var music: AVAudioPlayer?
    private var air: AVAudioPlayer?
    private var voice: AVAudioPlayer?
    private var effects: [AVAudioPlayer] = []
    private var queue: [String] = []
    private var suspended = false
    private var prepared = false
    private func player(_ name: String,_ ext: String = "wav") -> AVAudioPlayer? {
        if !prepared { try? AVAudioSession.sharedInstance().setCategory(.ambient,mode:.default,options:[.mixWithOthers]);prepared = true }
        guard let url = Bundle.main.url(forResource:name,withExtension:ext) else { return nil }
        let p = try? AVAudioPlayer(contentsOf:url);p?.prepareToPlay();return p
    }
    func begin() {
        suspended = false
        if music == nil { music = player("dove-song-wings-of-hope","m4a");music?.numberOfLoops = -1 }
        if air == nil { air = player("dove-air");air?.numberOfLoops = -1 }
        music?.play();air?.play();balance()
    }
    func narrate(_ id:String,interrupt:Bool = false) {
        if interrupt { voice?.stop();voice = nil;queue = [] }
        if !queue.contains(id) { queue.append(id) };if queue.count>2 { queue.removeFirst() }
        if voice == nil { next() }
    }
    private func next() {
        guard !suspended else { return }
        while !queue.isEmpty {
            let id = queue.removeFirst()
            if let p = player("dove-voice-"+id,"m4a") { voice = p;p.delegate = self;p.volume = 0.9;p.play();balance();return }
        }
        voice = nil;balance()
    }
    private func balance() {
        music?.setVolume(voice?.isPlaying == true ? 0.10 : 0.50,fadeDuration:0.4)
        air?.setVolume(voice?.isPlaying == true ? 0.025 : 0.06,fadeDuration:0.3)
    }
    func cue(_ name:String,volume:Float = 0.3) {
        guard !suspended else { return };effects.removeAll { !$0.isPlaying }
        guard let p = player("dove-"+name) else { return };p.volume = volume;p.play();effects.append(p)
        if effects.count>6 { effects.removeFirst().stop() }
    }
    func suspend() { suspended = true;music?.pause();air?.pause();voice?.pause();effects.forEach {$0.stop()};effects = [] }
    func mute() { suspend();voice?.stop();voice = nil;queue = [] }
    func describe(_ id:String) { suspended = false;narrate(id,interrupt:true) }
    func resume() { suspended = false;begin();if let voice { voice.play() } else { next() };balance() }
    func audioPlayerDidFinishPlaying(_ player:AVAudioPlayer,successfully flag:Bool) { if player === voice { voice = nil;next() } }
    func stop() { music?.stop();air?.stop();voice?.stop();effects.forEach {$0.stop()};music = nil;air = nil;voice = nil;effects = [];queue = [];suspended = false }
}
