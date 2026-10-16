import SwiftUI

struct ParadeAction: View {
    let title: String
    var symbol = "arrow.right"
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack { Text(title);Spacer();Image(systemName: symbol) }.font(.system(size: 14,weight: .bold)).foregroundStyle(ParadePalette.ink)
                .padding(.horizontal,20).frame(minHeight: 55).background(LinearGradient(colors: [ParadePalette.cream,ParadePalette.gold],startPoint: .topLeading,endPoint: .bottomTrailing),in: RoundedRectangle(cornerRadius: 17))
        }.buttonStyle(.plain)
    }
}

struct ParadeHeader: View {
    @ObservedObject var controller: ArkParadeController
    let exit: () -> Void
    let journal: () -> Void
    var body: some View {
        HStack(spacing: 3) {
            icon("chevron.left","Back to Noah's voyage",exit)
            VStack(alignment: .leading,spacing: 4) {
                Text("GATHER ANIMALS").font(.system(size: 6,weight: .bold)).tracking(2).foregroundStyle(ParadePalette.gold)
                Text("Ark Parade").font(.system(size: 21,design: .serif)).foregroundStyle(ParadePalette.cream)
            }.frame(maxWidth: .infinity,alignment: .leading)
            icon("book.closed","Animal journal",journal)
            icon(controller.soundOn ? "speaker.wave.2" : "speaker.slash",controller.soundOn ? "Mute animal sounds and narration" : "Turn animal sounds and narration on",controller.toggleSound)
            if controller.round.phase != .intro { icon("pause","Pause Ark Parade",controller.pause) }
        }.frame(minHeight: 50)
    }
    private func icon(_ symbol: String,_ label: String,_ action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: symbol).font(.system(size: 16,weight: .light)).foregroundStyle(ParadePalette.cream).frame(width: 40,height: 44) }.buttonStyle(.plain).accessibilityLabel(label)
    }
}

struct ParadeIntro: View {
    @ObservedObject var controller: ArkParadeController
    let wide: Bool
    let exit: () -> Void
    let journal: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            ParadeHeader(controller: controller,exit: exit,journal: journal).padding(.horizontal,20)
            if wide {
                HStack(spacing: 24) {
                    ArkParadeScene(controller: controller).frame(maxWidth: .infinity,maxHeight: .infinity)
                    copy.frame(width: 330)
                }.padding(.horizontal,30)
            } else {
                ArkParadeScene(controller: controller).padding(.horizontal,6).frame(maxWidth: 490,maxHeight: .infinity)
                copy.padding(.horizontal,26).padding(.bottom,14)
            }
        }
    }
    private var copy: some View {
        VStack(alignment: .leading,spacing: 13) {
            Text("A LITTLE CALL. A GREAT BIG ADVENTURE.").font(.system(size: 7,weight: .bold)).tracking(1.8).foregroundStyle(ParadePalette.gold)
            Text("Every friend\nbelongs aboard.").font(.system(size: wide ? 35 : 39,design: .serif)).lineSpacing(-1).foregroundStyle(ParadePalette.cream).fixedSize(horizontal: false,vertical: true)
            Text("Listen for a call. Find its partner. Draw their very own trail into Noah’s ark.").font(.system(size: 14)).lineSpacing(4).foregroundStyle(ParadePalette.cream.opacity(0.85))
            HStack(spacing: 18) {
                label("waveform","Real animal calls")
                label("hand.draw","Trails you draw")
            }.padding(.vertical,2)
            ParadeAction(title: "Let's gather the animals",symbol: "pawprint.fill",action: controller.start)
            Text("8 PAIRS TO DISCOVER · PLAY AT YOUR OWN PACE").font(.system(size: 6,weight: .semibold)).tracking(1.1).foregroundStyle(ParadePalette.mint.opacity(0.75)).frame(maxWidth: .infinity)
        }.frame(maxWidth: 460)
    }
    private func label(_ symbol: String,_ text: String) -> some View {
        HStack(spacing: 6) { Image(systemName: symbol).font(.system(size: 15,weight: .light));Text(text).font(.system(size: 10,weight: .semibold)) }.foregroundStyle(ParadePalette.gold)
    }
}

struct ParadeDiscovery: View {
    @ObservedObject var controller: ArkParadeController
    var body: some View {
        let animal = controller.round.animal
        VStack(alignment: .leading,spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(ParadePalette.gold.opacity(0.12)).overlay(Circle().strokeBorder(ParadePalette.gold.opacity(0.65)))
                    Image(animal.image).resizable().scaledToFit().padding(8)
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 23)).foregroundStyle(ParadePalette.gold).offset(x: 31,y: 26)
                }.frame(width: 81,height: 81)
                VStack(alignment: .leading,spacing: 6) {
                    Text("A NEW ANIMAL STAMP").font(.system(size: 7,weight: .bold)).tracking(1.7).foregroundStyle(ParadePalette.gold)
                    Text("\(animal.plural) aboard!").font(.system(size: 28,design: .serif)).foregroundStyle(ParadePalette.cream)
                    Text("\(controller.round.boarded.count) \(controller.round.boarded.count == 1 ? "pair" : "pairs") × 2 = \(controller.round.animalsAboard) animals").font(.system(size: 12,weight: .semibold,design: .rounded)).foregroundStyle(ParadePalette.mint)
                }
            }
            Text(animal.fact).font(.system(size: 14)).lineSpacing(5).foregroundStyle(ParadePalette.cream.opacity(0.87)).fixedSize(horizontal: false,vertical: true)
            ParadeAction(title: controller.round.boarded.count == ArkParadeRound.pairCount ? "Everyone's here. Let's celebrate!" : "Find the next pair",action: controller.next)
        }.padding(23).background(LinearGradient(colors: [ParadePalette.forest,ParadePalette.ink],startPoint: .topLeading,endPoint: .bottomTrailing),in: RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(ParadePalette.mint.opacity(0.35)))
            .shadow(color: .black.opacity(0.3),radius: 24,y: 10)
    }
}

struct ParadeFinishPanel: View {
    @ObservedObject var controller: ArkParadeController
    let exit: () -> Void
    let journal: () -> Void
    var body: some View {
        let won = controller.round.phase == .won
        ZStack {
            ParadePalette.ink.opacity(0.75).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 17) {
                    Image(systemName: won ? "leaf.circle" : "pause.circle").font(.system(size: 46,weight: .ultraLight)).foregroundStyle(ParadePalette.gold)
                    Text(won ? "THE GATHERING IS COMPLETE" : "A QUIET LITTLE BREAK").font(.system(size: 7,weight: .bold)).tracking(2.2).foregroundStyle(ParadePalette.gold)
                    Text(won ? "Small acts.\nGreat big kindness." : "Your friends\nare right here.").font(.system(size: 38,design: .serif)).multilineTextAlignment(.center).foregroundStyle(ParadePalette.cream)
                    if won {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()),count: 4),spacing: 3) { ForEach(ParadeAnimal.allCases) { animal in Image(animal.image).resizable().scaledToFit().frame(height: 59) } }.accessibilityHidden(true)
                        Text("8 pairs · 16 animals · all safely aboard").font(.system(size: 13,weight: .semibold)).foregroundStyle(ParadePalette.mint)
                        Text("Noah listened to God and cared for the animals. You helped make the ark a welcoming place.").font(.system(size: 14)).lineSpacing(5).multilineTextAlignment(.center).foregroundStyle(ParadePalette.cream.opacity(0.8))
                    }
                    ParadeAction(title: won ? "Back to Noah's voyage" : "Keep exploring",symbol: won ? "sailboat" : "play.fill",action: won ? exit : controller.resume)
                    if won { Button("Play with new hiding places",action: controller.start).font(.system(size: 13,weight: .semibold)).foregroundStyle(ParadePalette.gold).frame(minHeight: 44) }
                    HStack {
                        Button("Animal journal",action: journal)
                        if !won { Spacer();Button("Leave the clearing",action: exit) }
                    }.font(.system(size: 12)).foregroundStyle(ParadePalette.mint).frame(minHeight: 44)
                }.padding(26).frame(maxWidth: 400).background(ParadePalette.ink.opacity(0.95),in: RoundedRectangle(cornerRadius: 30)).overlay(RoundedRectangle(cornerRadius: 30).strokeBorder(ParadePalette.mint.opacity(0.25))).padding(22).frame(maxWidth: .infinity)
            }.defaultScrollAnchor(.center)
        }
    }
}
