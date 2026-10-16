import SwiftUI

enum SlingPalette {
    static let ink = Color(red: 0.15,green: 0.12,blue: 0.115)
    static let cream = Color(red: 1,green: 0.95,blue: 0.83)
    static let gold = Color(red: 0.98,green: 0.76,blue: 0.39)
    static let wine = Color(red: 0.37,green: 0.17,blue: 0.19)
}
struct SlingIntro: View {
    @ObservedObject var controller: GoliathSlingController
    let exit: () -> Void
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height*1.3
            ZStack(alignment: .bottomLeading) {
                LinearGradient(stops: [.init(color: .clear,location: 0),.init(color: SlingPalette.ink.opacity(0.8),location: 0.52),.init(color: SlingPalette.ink,location: 1)],startPoint: wide ? .trailing : .top,endPoint: wide ? .leading : .bottom).ignoresSafeArea()
                VStack(alignment: .leading,spacing: wide ? 12 : 16) {
                    Text("THE VALLEY SHOWDOWN").font(.system(size: 10,weight: .bold)).tracking(3.4).foregroundStyle(SlingPalette.gold)
                    Text("Face Goliath.").font(.system(size: wide ? 46 : 48,design: .serif)).lineLimit(1).minimumScaleFactor(0.7)
                    Text("One sling. Five stones. Unshaken faith.").font(.system(size: 16,design: .serif))
                    Text("Pull back, find your arc, and let courage fly. Break all three bronze guards before your stones run out.")
                        .font(.system(size: 14)).lineSpacing(3).foregroundStyle(SlingPalette.cream.opacity(0.75)).fixedSize(horizontal: false,vertical: true)
                    HStack(spacing: 26) {
                        detail("5","SMOOTH STONES"); detail("3","BRONZE GUARDS"); detail("3","STARS TO EARN")
                    }.padding(.vertical,4)
                    Button { controller.start() } label: { HStack { Text("Step into the valley"); Spacer(); Image(systemName: "arrow.right") } }.buttonStyle(SlingPrimaryStyle())
                    Text("PULL THE GLOWING STONE · RELEASE TO FIRE").font(.system(size: 8,weight: .bold)).tracking(1.3).foregroundStyle(SlingPalette.cream.opacity(0.5)).frame(maxWidth: .infinity)
                }
                .frame(maxWidth: wide ? 370 : 500,alignment: .leading).padding(.leading,wide ? 80 : 26).padding(.trailing,26).padding(.bottom,wide ? 12 : 18)
                VStack { HStack { SlingIcon(symbol: "chevron.left",label: "Back to adventure",action: exit); Spacer() }; Spacer() }.padding(.horizontal,20).padding(.top,8)
            }.foregroundStyle(SlingPalette.cream)
        }
    }
    private func detail(_ value: String,_ label: String) -> some View {
        VStack(alignment: .leading,spacing: 3) {
            Text(value).font(.system(size: 29,design: .serif))
            Text(label).font(.system(size: 7,weight: .bold)).tracking(1.1).foregroundStyle(SlingPalette.cream.opacity(0.55))
        }
    }
}
struct SlingHUD: View {
    @ObservedObject var controller: GoliathSlingController
    let exit: () -> Void
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                SlingIcon(symbol: "chevron.left",label: "Back to adventure",action: exit)
                VStack(alignment: .leading,spacing: 4) {
                    Text("FACE GOLIATH").font(.system(size: 10,weight: .bold)).tracking(2.5)
                    Text(controller.hud.broken == 3 ? "COURAGE PREVAILS" : "BREAK HIS GUARD").font(.system(size: 8,weight: .medium)).tracking(1.6).foregroundStyle(SlingPalette.gold)
                }
                Spacer(minLength: 0)
                SlingIcon(symbol: controller.soundOn ? "speaker.wave.2" : "speaker.slash",label: controller.soundOn ? "Mute sound" : "Enable sound",action: controller.toggleSound)
                SlingIcon(symbol: "pause",label: "Pause game",action: controller.pause)
            }
            HStack(spacing: 12) {
                HStack(spacing: 4) { ForEach(0..<5,id: \.self) { index in
                    Image("StreamRiverStone").resizable().scaledToFit().frame(width: 17,height: 17).opacity(index < controller.hud.stones ? 1 : 0.18)
                }}.accessibilityElement(children: .ignore).accessibilityLabel("\(controller.hud.stones) stones remaining")
                Spacer(minLength: 0)
                HStack(spacing: 5) { ForEach(0..<3,id: \.self) { index in
                    Image(systemName: index < controller.hud.broken ? "checkmark.shield.fill" : "shield").font(.system(size: 13,weight: .medium)).foregroundStyle(index < controller.hud.broken ? SlingPalette.gold : SlingPalette.cream.opacity(0.45))
                }}.accessibilityElement(children: .ignore).accessibilityLabel("\(controller.hud.broken) of 3 guards broken")
                Spacer(minLength: 0)
                Text(String(format: "%04d",controller.hud.score)).font(.system(size: 12,weight: .semibold,design: .monospaced)).monospacedDigit().foregroundStyle(SlingPalette.gold).accessibilityLabel("Score \(controller.hud.score)")
            }
            Text(controller.hud.message).font(.system(size: 12,weight: .medium)).multilineTextAlignment(.center)
                .frame(maxWidth: .infinity,minHeight: 35).padding(.horizontal,9).padding(.vertical,4)
                .background(SlingPalette.ink.opacity(0.73),in: RoundedRectangle(cornerRadius: 12))
        }.foregroundStyle(SlingPalette.cream)
    }
}
struct SlingAimControls: View {
    @ObservedObject var controller: GoliathSlingController
    @Binding var expanded: Bool
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(expanded ? "FINE AIM" : "PULL BACK & LET GO").font(.system(size: 8,weight: .bold)).tracking(1.8)
                Spacer()
                Button { expanded.toggle() } label: {
                    HStack(spacing: 5) { Text(expanded ? "Close" : "Fine aim"); Image(systemName: expanded ? "chevron.down" : "scope") }
                        .font(.system(size: 11,weight: .semibold)).frame(minHeight: 32)
                }.accessibilityLabel(expanded ? "Close fine aim controls" : "Open fine aim controls")
            }.foregroundStyle(SlingPalette.cream.opacity(0.8))
            if expanded {
                HStack(spacing: 14) {
                    VStack(spacing: 9) {
                        HStack {
                            Image(systemName: "angle").frame(width: 18)
                            Slider(value: Binding(get: { controller.hud.angle },set: controller.setAngle),in: 12...82,step: 1).tint(SlingPalette.gold).accessibilityLabel("Launch angle").accessibilityValue("\(Int(controller.hud.angle.rounded())) degrees")
                            Text("\(Int(controller.hud.angle.rounded()))°").frame(width: 33,alignment: .trailing).monospacedDigit()
                        }
                        HStack {
                            Image(systemName: "arrow.up.right").frame(width: 18)
                            Slider(value: Binding(get: { controller.hud.power },set: controller.setPower),in: 0.18...1,step: 0.01).tint(SlingPalette.gold).accessibilityLabel("Pull strength").accessibilityValue("\(Int((controller.hud.power*100).rounded())) percent")
                            Text("\(Int((controller.hud.power*100).rounded()))%").frame(width: 33,alignment: .trailing).monospacedDigit()
                        }
                    }.font(.system(size: 10,weight: .medium))
                    Button(action: controller.firePreset) {
                        VStack(spacing: 6) { Image(systemName: "arrow.up.right").font(.system(size: 20,weight: .light)); Text("RELEASE").font(.system(size: 7,weight: .bold)).tracking(1) }
                            .frame(width: 62,height: 70).background(SlingPalette.gold,in: RoundedRectangle(cornerRadius: 16)).foregroundStyle(SlingPalette.ink)
                    }.buttonStyle(.plain).accessibilityLabel("Release stone")
                }.disabled(controller.hud.phase != .ready).opacity(controller.hud.phase == .ready ? 1 : 0.4)
            }
        }.foregroundStyle(SlingPalette.cream).padding(.horizontal,15).padding(.vertical,9)
            .background(SlingPalette.ink.opacity(0.90),in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(SlingPalette.gold.opacity(0.22)))
    }
}
struct SlingRoundPanel: View {
    enum Kind { case paused,lost,won }
    @ObservedObject var controller: GoliathSlingController
    let kind: Kind
    let exit: () -> Void
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height*1.3
            ZStack {
                SlingPalette.ink.opacity(0.95).ignoresSafeArea()
                ScrollView {
                    HStack(spacing: 30) {
                        if wide { emblem.frame(width: 90) }
                        VStack(alignment: .leading,spacing: wide ? 9 : 18) {
                            Text(kind == .won ? "THE GIANT’S GUARD HAS FALLEN" : kind == .paused ? "A MOMENT BEFORE THE SHOT" : "COURAGE TAKES PRACTICE")
                                .font(.system(size: 9,weight: .bold)).tracking(2.5).foregroundStyle(SlingPalette.gold)
                            if !wide { emblem.frame(maxWidth: .infinity).padding(.vertical,8) }
                            Text(kind == .won ? "Small stone.\nGreat courage." : kind == .paused ? "Steady your aim." : "A steadier\nshot awaits.")
                                .font(.system(size: wide ? 32 : 43,design: .serif)).fixedSize(horizontal: false,vertical: true)
                            if kind == .won {
                                HStack(spacing: 28) { stat("\(controller.hud.score)","SCORE"); stat("\(controller.hud.perfects)","PERFECT SHOTS"); stat("\(controller.hud.stones)","STONES LEFT") }
                                Text("David stood in faith. With a sling and a stone, the impossible became possible.")
                                    .font(.system(size: wide ? 12 : 15)).lineSpacing(3).foregroundStyle(SlingPalette.cream.opacity(0.75))
                                Text("1 SAMUEL 17:49–50 · BEST \(controller.bestScore)").font(.system(size: 8,weight: .bold)).tracking(1.3).foregroundStyle(SlingPalette.gold)
                                HStack(spacing: 10) {
                                    Button("Continue the adventure",action: exit).buttonStyle(SlingPrimaryStyle())
                                    if wide { SlingIcon(symbol: "arrow.clockwise",label: "Play the challenge again",action: controller.start) }
                                }
                                if !wide { Button("Play the challenge again",action: controller.start).font(.system(size: 13,weight: .semibold)).frame(maxWidth: .infinity,minHeight: 44) }
                            } else if kind == .paused {
                                Text("Take your time. Your stones and broken guards are saved for this round.").font(.system(size: wide ? 12 : 15)).lineSpacing(3).foregroundStyle(SlingPalette.cream.opacity(0.75))
                                Button("Keep aiming",action: controller.resume).buttonStyle(SlingPrimaryStyle())
                                HStack { Button("Start again",action: controller.start); Spacer(); Button("Back to adventure",action: exit) }.font(.system(size: 12,weight: .semibold)).frame(minHeight: 44)
                            } else {
                                Text("Five stones spent. Every shot teaches something. Follow the arc, adjust your pull, and try for the glowing centers.").font(.system(size: wide ? 12 : 15)).lineSpacing(3).foregroundStyle(SlingPalette.cream.opacity(0.75))
                                Button("Five stones. A fresh start.",action: controller.start).buttonStyle(SlingPrimaryStyle())
                                Button("Back to adventure",action: exit).font(.system(size: 13,weight: .semibold)).frame(maxWidth: .infinity,minHeight: 44)
                            }
                        }
                    }.frame(maxWidth: wide ? 650 : 410,alignment: .leading).padding(wide ? 20 : 30).frame(maxWidth: .infinity)
                }.defaultScrollAnchor(.center,for: .alignment)
            }.foregroundStyle(SlingPalette.cream)
        }
    }
    private var emblem: some View {
        VStack(spacing: 12) {
            Image("GoliathGuardShield").resizable().scaledToFit().frame(width: 80,height: 80)
            HStack(spacing: 6) { ForEach(0..<3,id: \.self) { index in
                Image(systemName: kind == .won ? (index < controller.hud.stars ? "star.fill" : "star") : (index < controller.hud.broken ? "checkmark.circle.fill" : "circle")).font(.system(size: 13)).foregroundStyle(SlingPalette.gold)
            }}
        }.accessibilityElement(children: .ignore).accessibilityLabel(kind == .won ? "\(controller.hud.stars) stars earned" : "\(controller.hud.broken) guards broken")
    }
    private func stat(_ value: String,_ label: String) -> some View {
        VStack(alignment: .leading,spacing: 4) { Text(value).font(.system(size: 27,design: .serif)); Text(label).font(.system(size: 7,weight: .bold)).tracking(1).foregroundStyle(SlingPalette.cream.opacity(0.6)) }
    }
}
struct SlingIcon: View {
    let symbol: String
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) { Image(systemName: symbol).font(.system(size: 13,weight: .semibold)).frame(width: 44,height: 44).background(SlingPalette.ink.opacity(0.65),in: Circle()).overlay(Circle().strokeBorder(SlingPalette.cream.opacity(0.15))) }
            .buttonStyle(.plain).foregroundStyle(SlingPalette.cream).accessibilityLabel(label)
    }
}
struct SlingPrimaryStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 15,weight: .semibold)).frame(maxWidth: .infinity,minHeight: 52).padding(.horizontal,20)
            .foregroundStyle(SlingPalette.ink).background(LinearGradient(colors: [SlingPalette.cream,SlingPalette.gold],startPoint: .topLeading,endPoint: .bottomTrailing),in: RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(SlingPalette.cream.opacity(0.35)))
            .shadow(color: .black.opacity(0.24),radius: 12,y: 5).scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
