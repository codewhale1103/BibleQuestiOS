import Testing
import AVFoundation
@testable import BibleQuest

struct DoveVoyageAudioTests {
    @Test func everyOfflineClipAndScoreCanDecode() throws {
        let voices = ["first","water","homeward","land","welcome","wait","second","landscape","grove","leaf","delivered","third","branch","finale","hint","reflection","waterfall","olive"]
        let files = voices.map { ("dove-voice-"+$0,"m4a") }+[("dove-song-wings-of-hope","m4a")]+["air","wing","leaf","glimmer","coo"].map { ("dove-"+$0,"wav") }
        for (name,ext) in files {
            let url = try #require(Bundle.main.url(forResource:name,withExtension:ext),"Missing bundled audio: \(name)")
            let p = try AVAudioPlayer(contentsOf:url)
            #expect(p.duration>0.2);#expect(p.numberOfChannels>0);#expect(p.prepareToPlay())
        }
    }
}
