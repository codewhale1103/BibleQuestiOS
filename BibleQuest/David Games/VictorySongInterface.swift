import SwiftUI

struct VictorySongIntro: View {
    @ObservedObject var controller: VictorySongController
    @Binding var gentle: Bool
    let exit: () -> Void
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height*1.3
            ZStack(alignment: .bottomLeading) {
                Image("VictoryDavidHarp").resizable().scaledToFit()
                    .frame(width: wide ? geo.size.width*0.44 : geo.size.width*0.72,height: wide ? geo.size.height*0.97 : geo.size.height*0.58)
                    .rotationEffect(.degrees(controller.reduceMotion ? 0 : sin(controller.visualTime*0.7)*0.5))
                    .position(x: geo.size.width*(wide ? 0.78 : 0.66),y: geo.size.height*(wide ? 0.52 : 0.30))
                    .shadow(color: VictoryPalette.gold.opacity(0.13),radius: 25).accessibilityHidden(true)
                LinearGradient(stops: [.init(color: .clear,location: 0),.init(color: VictoryPalette.ink.opacity(0.80),location: 0.35),.init(color: VictoryPalette.ink,location: 1)],startPoint: wide ? .trailing : .top,endPoint: wide ? .leading : .bottom).allowsHitTesting(false)
                VStack(alignment: .leading,spacing: wide ? 9 : 14) {
                    Text("DAVID’S ADVENTURE · THE FINALE").font(.system(size: 8,weight: .bold)).tracking(2.6).foregroundStyle(VictoryPalette.gold)
                    Text("Song of\nCourage.").font(.system(size: wide ? 46 : 54,design: .serif)).lineSpacing(-3).fixedSize(horizontal: false,vertical: true)
                    Text("The battle is over. Let the valley sing.").font(.system(size: 15,design: .serif)).foregroundStyle(VictoryPalette.gold)
                    Text("Pluck each string as its light reaches the jewel. Hold the long ribbons. Fill the camp with music and light.")
                        .font(.system(size: wide ? 12 : 14)).lineSpacing(3).foregroundStyle(VictoryPalette.cream.opacity(0.74)).fixedSize(horizontal: false,vertical: true)
                    HStack(spacing: 20) {
                        instruction("hand.tap","PLUCK THE LIGHT")
                        instruction("waveform","HOLD THE RIBBON")
                        instruction("sparkle","LIGHT THE VALLEY")
                    }.padding(.vertical,3)
                    Toggle(isOn: $gentle) {
                        VStack(alignment: .leading,spacing: 3) { Text("Gentle timing").font(.system(size: 12,weight: .semibold)); Text("A little more time to catch each note.").font(.system(size: 10)).foregroundStyle(VictoryPalette.cream.opacity(0.55)) }
                    }.tint(VictoryPalette.gold).scaleEffect(wide ? 0.95 : 1,anchor: .leading)
                    Button { controller.start(gentle: gentle) } label: { HStack { Text("Let the song begin"); Spacer(); Image(systemName: "music.note") } }.buttonStyle(VictoryPrimaryStyle())
                    Text("A MUSICAL CELEBRATION INSPIRED BY DAVID THE HARPIST").font(.system(size: 6,weight: .bold)).tracking(1).foregroundStyle(VictoryPalette.cream.opacity(0.40)).frame(maxWidth: .infinity)
                }.frame(maxWidth: wide ? 350 : 450,alignment: .leading).padding(.leading,wide ? 70 : 25).padding(.trailing,25).padding(.bottom,wide ? 8 : 14)
                VStack { HStack { VictoryIcon(symbol: "chevron.left",label: "Back to adventure",action: exit); Spacer() }; Spacer() }.padding(.horizontal,18).padding(.top,6)
            }.foregroundStyle(VictoryPalette.cream)
        }
    }
    private func instruction(_ symbol: String,_ title: String) -> some View {
        VStack(alignment: .leading,spacing: 7) { Image(systemName: symbol).font(.system(size: 17,weight: .light)).foregroundStyle(VictoryPalette.gold); Text(title).font(.system(size: 6,weight: .bold)).tracking(0.8).foregroundStyle(VictoryPalette.cream.opacity(0.65)) }
    }
}
struct VictorySongHeader: View {
    @ObservedObject var controller: VictorySongController
    let exit: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                VictoryIcon(symbol: "chevron.left",label: "Back to adventure",action: exit)
                VStack(alignment: .leading,spacing: 3) {
                    Text("SONG OF COURAGE").font(.system(size: 9,weight: .bold)).tracking(2)
                    Text("THE VICTORY FINALE").font(.system(size: 7,weight: .medium)).tracking(1.8).foregroundStyle(VictoryPalette.gold)
                }
                Spacer(minLength: 0)
                VictoryIcon(symbol: controller.soundOn ? "speaker.wave.2" : "speaker.slash",label: controller.soundOn ? "Mute music" : "Enable music",action: controller.toggleSound)
                VictoryIcon(symbol: "pause",label: "Pause song",action: controller.pause)
            }
            HStack(spacing: 8) {
                Image(systemName: "sparkle").foregroundStyle(VictoryPalette.gold)
                Text("\(controller.round.lanterns)/12").monospacedDigit().accessibilityLabel("\(controller.round.lanterns) of 12 camp lights")
                Spacer()
                if controller.round.streak > 1 { Text("\(controller.round.streak) IN HARMONY").font(.system(size: 8,weight: .bold)).tracking(1).foregroundStyle(VictoryPalette.lanes[1]) }
                Spacer()
                Text(String(format: "%04d",controller.round.score)).monospacedDigit().foregroundStyle(VictoryPalette.gold).accessibilityLabel("Score \(controller.round.score)")
            }.font(.system(size: 11,weight: .semibold))
            GeometryReader { geo in
                Capsule().fill(.white.opacity(0.13))
                Capsule().fill(LinearGradient(colors: [VictoryPalette.gold,VictoryPalette.lanes[2]],startPoint: .leading,endPoint: .trailing))
                    .frame(width: geo.size.width*min(1,controller.round.time/VictorySongRound.duration))
            }.frame(height: 3).accessibilityLabel("Song progress").accessibilityValue("\(Int(min(1,controller.round.time/VictorySongRound.duration)*100)) percent")
        }.foregroundStyle(VictoryPalette.cream)
    }
}
struct VictorySongPassage: View {
    @ObservedObject var controller: VictorySongController
    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 7) { ForEach(0..<3,id: \.self) { index in Capsule().fill(index <= controller.round.passage ? VictoryPalette.gold : VictoryPalette.cream.opacity(0.2)).frame(width: 15,height: 2) } }.accessibilityHidden(true)
            Text(VictorySongRound.passages[controller.round.passage]).font(.system(size: 20,design: .serif)).foregroundStyle(VictoryPalette.cream)
        }.padding(.top,8)
    }
}
struct VictorySongPanel: View {
    @ObservedObject var controller: VictorySongController
    let gentle: Bool
    let exit: () -> Void
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height*1.3
            let won = controller.round.phase == .won, paused = controller.round.phase == .paused
            ZStack {
                VictoryPalette.ink.opacity(0.94).ignoresSafeArea()
                ScrollView {
                    HStack(spacing: wide ? 25 : 0) {
                        if wide && won { portrait.frame(width: 150,height: 230) }
                        VStack(alignment: .leading,spacing: wide ? 11 : 18) {
                            Text(won ? "THE VALLEY IS ALIVE WITH THANKS" : paused ? "LET THE LAST NOTE LINGER" : "EVERY MELODY BEGINS WITH PRACTICE")
                                .font(.system(size: 8,weight: .bold)).tracking(2.1).foregroundStyle(VictoryPalette.gold)
                            if won && !wide { portrait.frame(height: 190).frame(maxWidth: .infinity) }
                            if won { HStack(spacing: 9) { ForEach(0..<3,id: \.self) { i in Image(systemName: i < controller.round.stars ? "star.fill" : "star").foregroundStyle(VictoryPalette.gold) } }.accessibilityElement(children: .ignore).accessibilityLabel("\(controller.round.stars) stars earned") }
                            Text(won ? "A brave heart.\nA grateful song." : paused ? "A breath\nbetween notes." : "Your song\nis still unfolding.")
                                .font(.system(size: wide ? 34 : 39,design: .serif)).fixedSize(horizontal: false,vertical: true)
                            if won {
                                HStack(spacing: 23) { stat("\(controller.round.score)","SCORE"); stat("\(controller.round.hits)/36","NOTES CAUGHT"); stat("\(controller.round.bestStreak)","BEST HARMONY") }
                                Text("From the shepherd’s field to the valley, David’s courage began with faith. Now the camp shares a song of thanks.").font(.system(size: wide ? 12 : 14)).lineSpacing(3).foregroundStyle(VictoryPalette.cream.opacity(0.7))
                                Text("\(controller.round.sustained) RIBBONS SUSTAINED · BEST \(controller.bestScore)").font(.system(size: 7,weight: .semibold)).tracking(1).foregroundStyle(VictoryPalette.cream.opacity(0.5))
                                Text("DAVID PLAYED THE HARP · 1 SAMUEL 16:23").font(.system(size: 7,weight: .bold)).tracking(1.2).foregroundStyle(VictoryPalette.gold)
                                Button("Complete the adventure",action: exit).buttonStyle(VictoryPrimaryStyle())
                                Button("Play the song again") { controller.start(gentle: gentle) }.font(.system(size: 12,weight: .semibold)).frame(maxWidth: .infinity,minHeight: 35)
                            } else if paused {
                                Text("Your melody is saved. A three-count lead-in will bring you back to the same moment.").font(.system(size: 14)).lineSpacing(3).foregroundStyle(VictoryPalette.cream.opacity(0.7))
                                Button("Return to the melody",action: controller.resume).buttonStyle(VictoryPrimaryStyle())
                                HStack { Button("Begin again") { controller.start(gentle: gentle) }; Spacer(); Button("Back to adventure",action: exit) }.font(.system(size: 12,weight: .semibold)).frame(minHeight: 44)
                            } else {
                                Text("You caught \(controller.round.hits) of 36 notes. Catch at least 20 to complete the song. Watch the jewels, and hold a string until its ribbon runs out.").font(.system(size: 14)).lineSpacing(3).foregroundStyle(VictoryPalette.cream.opacity(0.7))
                                Button("Play with gentle timing") { controller.start(gentle: true) }.buttonStyle(VictoryPrimaryStyle())
                                HStack { Button("Try the original timing") { controller.start(gentle: false) }; Spacer(); Button("Back",action: exit) }.font(.system(size: 12,weight: .semibold)).frame(minHeight: 44)
                            }
                        }.frame(maxWidth: wide ? 450 : 400,alignment: .leading)
                    }.padding(wide ? 20 : 27).frame(maxWidth: .infinity)
                }.defaultScrollAnchor(.center,for: .alignment)
            }.foregroundStyle(VictoryPalette.cream)
        }
    }
    private var portrait: some View { Image("VictoryDavidHarp").resizable().scaledToFit().shadow(color: VictoryPalette.gold.opacity(0.2),radius: 20).accessibilityHidden(true) }
    private func stat(_ value: String,_ label: String) -> some View {
        VStack(alignment: .leading,spacing: 4) { Text(value).font(.system(size: 24,design: .serif)); Text(label).font(.system(size: 6,weight: .bold)).tracking(1).foregroundStyle(VictoryPalette.cream.opacity(0.5)) }
    }
}
struct VictoryIcon: View {
    let symbol: String
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) { Image(systemName: symbol).font(.system(size: 12,weight: .semibold)).frame(width: 42,height: 42).background(VictoryPalette.ink.opacity(0.65),in: Circle()).overlay(Circle().strokeBorder(VictoryPalette.cream.opacity(0.15))) }
            .buttonStyle(.plain).foregroundStyle(VictoryPalette.cream).accessibilityLabel(label)
    }
}
struct VictoryPrimaryStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 14,weight: .semibold)).frame(maxWidth: .infinity,minHeight: 50).padding(.horizontal,18)
            .foregroundStyle(VictoryPalette.ink).background(LinearGradient(colors: [VictoryPalette.cream,VictoryPalette.gold],startPoint: .topLeading,endPoint: .bottomTrailing),in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(VictoryPalette.cream.opacity(0.4)))
            .shadow(color: .black.opacity(0.25),radius: 10,y: 6).scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
