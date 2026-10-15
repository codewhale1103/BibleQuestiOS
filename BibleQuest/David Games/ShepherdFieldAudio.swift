import AVFoundation
import Combine

/// Short, locally bundled cues respect the silent switch and other audio playing on the device.
final class ShepherdFieldAudio: ObservableObject {
    enum Cue: String, CaseIterable {
        case found, call, rustle, complete
    }
    private var players: [Cue: AVAudioPlayer] = [:]
    private var sessionPrepared = false

    func play(_ cue: Cue) {
        do {
            if !sessionPrepared {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: .mixWithOthers)
                sessionPrepared = true
            }
            if players[cue] == nil,
               let url = Bundle.main.url(forResource: "shepherd-\(cue.rawValue)", withExtension: "wav") {
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = cue == .rustle ? 0.5 : 0.65
                player.prepareToPlay()
                players[cue] = player
            }
            players[cue]?.currentTime = 0
            players[cue]?.play()
        } catch {
            // Discovery remains fully playable when audio is unavailable.
        }
    }

    func stop() {
        players.values.forEach { $0.stop() }
    }
}
