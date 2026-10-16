import SwiftUI

struct ParadeRecording: Identifiable {
    let animal: ParadeAnimal
    let title: String
    let author: String
    let source: String
    let license: String
    let licenseURL: String
    var id: Int { animal.rawValue }
    static let all: [Self] = [
        .init(animal: .lion,title: "Lion Roar",author: "Mike Koenig / SoundBible",source: "https://soundbible.com/1282-Lion-Roar.html",license: "CC BY 3.0",licenseURL: "https://creativecommons.org/licenses/by/3.0/"),
        .init(animal: .wolf,title: "Medium Pack of Wolves Howling",author: "fws.gov / SoundBible",source: "https://soundbible.com/277-Medium-Pack-Of-Wolves-Howling.html",license: "Public Domain",licenseURL: "https://creativecommons.org/publicdomain/mark/1.0/"),
        .init(animal: .tiger,title: "Tiger Growling",author: "Mike Koenig / SoundBible",source: "https://soundbible.com/1485-Tiger-Growling.html",license: "CC BY 3.0",licenseURL: "https://creativecommons.org/licenses/by/3.0/"),
        .init(animal: .elephant,title: "Elephant voice – trumpeting",author: "தகவலுழவன் (Info-farmer)",source: "https://commons.wikimedia.org/wiki/File:Elephant_voice_-_trumpeting.ogg",license: "CC0 1.0",licenseURL: "https://creativecommons.org/publicdomain/zero/1.0/"),
        .init(animal: .cow,title: "Cow Moo",author: "Mike Koenig / SoundBible",source: "https://soundbible.com/1778-Cow-Moo.html",license: "CC BY 3.0",licenseURL: "https://creativecommons.org/licenses/by/3.0/"),
        .init(animal: .monkey,title: "Sound of stump-tailed macaque",author: "Rushenb / Wikimedia Commons",source: "https://commons.wikimedia.org/wiki/File:Sound-of-stump-tailed-macaque-(macaca-arctoides).ogg",license: "CC BY-SA 4.0",licenseURL: "https://creativecommons.org/licenses/by-sa/4.0/"),
        .init(animal: .sheep,title: "Sheep Bleating",author: "Mike Koenig / SoundBible",source: "https://soundbible.com/520-Sheep-Bleating.html",license: "CC BY 3.0",licenseURL: "https://creativecommons.org/licenses/by/3.0/"),
        .init(animal: .horse,title: "Horse Neigh",author: "Mike Koenig / SoundBible",source: "https://soundbible.com/1296-Horse-Neigh.html",license: "CC BY 3.0",licenseURL: "https://creativecommons.org/licenses/by/3.0/")
    ]
}

struct ParadeJournal: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var controller: ArkParadeController
    var body: some View {
        ScrollView {
            VStack(alignment: .leading,spacing: 22) {
                HStack {
                    VStack(alignment: .leading,spacing: 7) {
                        Text("NOAH'S FIELD NOTES").font(.system(size: 7,weight: .bold)).tracking(2.2).foregroundStyle(ParadePalette.gold)
                        Text("The animal journal").font(.system(size: 31,design: .serif))
                    }
                    Spacer()
                    Button { dismiss() } label: { Image(systemName: "xmark").frame(width: 44,height: 44) }.accessibilityLabel("Close animal journal")
                }
                Text("Listen, look closely, and discover something wonderful about each animal.").font(.system(size: 14)).lineSpacing(5).foregroundStyle(ParadePalette.mint)
                ForEach(ParadeAnimal.allCases) { animal in
                    VStack(alignment: .leading,spacing: 12) {
                        HStack(spacing: 16) {
                            Image(animal.image).resizable().scaledToFit().frame(width: 82,height: 82).accessibilityHidden(true)
                            VStack(alignment: .leading,spacing: 5) {
                                Text(animal.name).font(.system(size: 24,design: .serif))
                                Text(animal.call).font(.system(size: 7,weight: .bold)).tracking(2).foregroundStyle(ParadePalette.gold)
                                Text(controller.round.boarded.contains(animal) ? "PAIR SAFELY ABOARD" : "WAITING TO BOARD").font(.system(size: 6,weight: .semibold)).tracking(0.9).foregroundStyle(ParadePalette.mint.opacity(0.7))
                            }
                            Spacer(minLength: 0)
                            Button { controller.journalCall(animal) } label: { Image(systemName: "waveform").font(.system(size: 23,weight: .light)).frame(width: 48,height: 48).background(ParadePalette.gold.opacity(0.12),in: Circle()) }
                                .disabled(!controller.soundOn).foregroundStyle(ParadePalette.gold).accessibilityLabel("Listen to the \(animal.name.lowercased()) recording")
                        }
                        Text(animal.fact).font(.system(size: 13)).lineSpacing(5).foregroundStyle(ParadePalette.cream.opacity(0.85))
                        Button { controller.readFact(animal) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 18,weight: .semibold))
                                    .frame(width: 36,height: 36)
                                    .background(ParadePalette.forest.opacity(0.1),in: Circle())
                                Text("Read to me").font(.system(size: 16,weight: .bold,design: .rounded))
                                Spacer(minLength: 8)
                                Image(systemName: "play.fill").font(.system(size: 14,weight: .bold))
                            }.foregroundStyle(ParadePalette.ink).padding(.horizontal,16)
                                .frame(maxWidth: .infinity,minHeight: 58)
                                .background(LinearGradient(colors: [ParadePalette.cream,ParadePalette.gold],startPoint: .topLeading,endPoint: .bottomTrailing),in: RoundedRectangle(cornerRadius: 19,style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 19,style: .continuous).strokeBorder(.white.opacity(0.35)))
                                .contentShape(RoundedRectangle(cornerRadius: 19,style: .continuous))
                        }.buttonStyle(ParadeReadButtonStyle()).disabled(!controller.soundOn)
                            .opacity(controller.soundOn ? 1 : 0.45)
                            .accessibilityLabel("Read to me about the \(animal.name.lowercased())")
                            .accessibilityHint("Anna reads this animal's facts aloud")
                    }.padding(18).background(.white.opacity(0.045),in: RoundedRectangle(cornerRadius: 22)).overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(ParadePalette.mint.opacity(0.14)))
                }
                VStack(alignment: .leading,spacing: 11) {
                    Text("A note for grown-ups").font(.system(size: 23,design: .serif)).foregroundStyle(ParadePalette.gold)
                    Text("This game follows eight selected animal pairs to practice listening, matching, counting, and care. Genesis 7:2–3 describes additional pairs of clean animals and birds; the sixteen animals in this game are not the full number aboard the ark.")
                    Text("The story's focus is Noah listening to God and caring for living creatures. The woodland, animal appearances, and parade are imaginative play.")
                    Text("Sound is optional. Written calls, visible ripples, hints, and spoken guidance support different learners. VoiceOver users can choose an animal and use ‘Guide this pair to the ark’ instead of drawing.")
                }.font(.system(size: 13)).lineSpacing(5).foregroundStyle(ParadePalette.mint)
                DisclosureGroup {
                    VStack(alignment: .leading,spacing: 20) {
                        Text("Animal recordings are bundled for offline play. Clips were converted to mono 22,050 Hz, level adjusted, and gently faded. The wolf excerpt is 1–5 seconds of the original. The macaque excerpt is 5.8–8.9 seconds of the original; this adapted clip is distributed under CC BY-SA 4.0. You may export the clips below under their stated licenses.").font(.system(size: 12)).lineSpacing(4)
                        ForEach(ParadeRecording.all) { recording in
                            VStack(alignment: .leading,spacing: 6) {
                                Text(recording.title).font(.system(size: 14,weight: .semibold))
                                Text(recording.author).font(.system(size: 12))
                                HStack(spacing: 20) {
                                    if let source = URL(string: recording.source) { Link("Original recording",destination: source) }
                                    if let license = URL(string: recording.licenseURL) { Link(recording.license,destination: license) }
                                }.font(.system(size: 11)).foregroundStyle(ParadePalette.gold)
                                if let clip = Bundle.main.url(forResource: "parade-\(recording.animal.name.lowercased())",withExtension: "wav") {
                                    ShareLink(item: clip,subject: Text(recording.title),message: Text("\(recording.title) — \(recording.author). Adapted with level adjustment and fades. \(recording.license): \(recording.licenseURL). Source: \(recording.source)")) { Label("Export licensed clip",systemImage: "square.and.arrow.up").font(.system(size: 11)).frame(minHeight: 44) }.foregroundStyle(ParadePalette.gold)
                                }
                            }
                        }
                        Text("Woodland ambience, footfalls, and musical cues are original designed sounds. Ark, clearing, and animal illustrations were created for BibleQuest using the built-in image-generation tool, except the lion credited below.").font(.system(size: 12)).lineSpacing(4)
                        Text("Narration: Anna – Children’s Book Narrator, generated with ElevenLabs Multilingual v2. Recorded guidance and facts play offline.").font(.system(size: 12)).lineSpacing(4)
                        Text("Lion illustration: cameronschmidt / Pixabay. Used under the Pixabay Content License.").font(.system(size: 12)).lineSpacing(4)
                        Link("Lion artwork source",destination: URL(string: "https://pixabay.com/illustrations/ai-generated-lion-transparent-animal-9287227/")!).font(.system(size: 11)).foregroundStyle(ParadePalette.gold)
                        Link("Pixabay Content License",destination: URL(string: "https://pixabay.com/service/license-summary/")!).font(.system(size: 11)).foregroundStyle(ParadePalette.gold)
                    }.padding(.top,15)
                } label: { Text("Recording credits & licenses").font(.system(size: 13,weight: .semibold)) }.tint(ParadePalette.gold)
            }.padding(24).frame(maxWidth: 600).frame(maxWidth: .infinity)
        }.background(ParadePalette.ink.ignoresSafeArea()).foregroundStyle(ParadePalette.cream).preferredColorScheme(.dark).presentationDragIndicator(.visible)
            .onDisappear { controller.pause() }
    }
}

private struct ParadeReadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .shadow(color: .black.opacity(configuration.isPressed ? 0.08 : 0.18),radius: configuration.isPressed ? 1 : 5,y: configuration.isPressed ? 1 : 4)
            .animation(.easeOut(duration: 0.16),value: configuration.isPressed)
    }
}
