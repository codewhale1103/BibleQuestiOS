import SwiftUI

enum ArmorCampPalette {
    static let ink = Color(red: 0.11,green: 0.13,blue: 0.10)
    static let cream = Color(red: 1,green: 0.95,blue: 0.83)
    static let gold = Color(red: 0.91,green: 0.73,blue: 0.43)
    static let olive = Color(red: 0.40,green: 0.48,blue: 0.33)
}

struct ArmorCampIntro: View {
    @ObservedObject var session: ArmorCampSession
    let exit: () -> Void
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height * 1.3
            ZStack(alignment: .bottomLeading) {
                LinearGradient(stops: [.init(color: .clear,location: 0),.init(color: ArmorCampPalette.ink.opacity(0.78),location: 0.58),.init(color: ArmorCampPalette.ink,location: 1)],startPoint: wide ? .trailing : .top,endPoint: wide ? .leading : .bottom).ignoresSafeArea()
                VStack(alignment: .leading,spacing: wide ? 12 : 16) {
                    Text("CAMP OF ISRAEL").font(.system(size: 11,weight: .bold)).tracking(4).foregroundStyle(ArmorCampPalette.gold)
                    Text("Set it aside.").font(.system(size: wide ? 44 : 48,weight: .regular,design: .serif)).minimumScaleFactor(0.7).lineLimit(1)
                    Text("A king’s armor. A shepherd’s heart.")
                        .font(.system(size: 17,weight: .medium,design: .serif))
                    Text("Saul’s armor doesn’t fit. Help David return it, then find his own brave stride.")
                        .font(.system(size: 14)).foregroundStyle(ArmorCampPalette.cream.opacity(0.78)).lineSpacing(3).fixedSize(horizontal: false,vertical: true)
                    HStack(spacing: 12) {
                        ForEach(ArmorCampRound.Piece.allCases) { piece in
                            HStack(spacing: 5) {
                                Image(piece.artwork).resizable().scaledToFit().frame(width: 22,height: 30)
                                Text(piece.title).font(.system(size: 10,weight: .medium))
                            }
                        }
                    }.padding(.vertical,2).accessibilityHidden(true)
                    Button(action: session.start) {
                        HStack { Text("Find your stride"); Spacer(); Image(systemName: "arrow.right") }
                    }.buttonStyle(ArmorCampPrimaryStyle())
                    Text("DRAG TO MATCH · OR TAP TO RETURN").font(.system(size: 8,weight: .bold)).tracking(1.5).foregroundStyle(ArmorCampPalette.cream.opacity(0.55)).frame(maxWidth: .infinity)
                }
                .foregroundStyle(ArmorCampPalette.cream)
                .frame(maxWidth: wide ? 380 : 500,alignment: .leading)
                .padding(.horizontal,wide ? 32 : 26).padding(.bottom,wide ? 14 : 20)
                VStack { HStack { ArmorCampIcon(symbol: "chevron.left",label: "Back to adventure",action: exit); Spacer() }; Spacer() }.padding(.horizontal,20).padding(.top,8)
            }
        }
    }
}

struct ArmorCampHUD: View {
    @ObservedObject var session: ArmorCampSession
    let exit: () -> Void
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                ArmorCampIcon(symbol: "chevron.left",label: "Back to adventure",action: exit)
                VStack(alignment: .leading,spacing: 4) {
                    Text("CAMP OF ISRAEL").font(.system(size: 10,weight: .bold)).tracking(2)
                    Text("SAUL’S TENT").font(.system(size: 8,weight: .medium)).tracking(2).foregroundStyle(ArmorCampPalette.gold)
                }
                Spacer(minLength: 0)
                ArmorCampIcon(symbol: session.soundEnabled ? "speaker.wave.2" : "speaker.slash",label: session.soundEnabled ? "Mute sound" : "Enable sound",action: session.toggleSound)
                ArmorCampIcon(symbol: "pause",label: "Pause game",action: session.pause)
            }
            HStack(spacing: 10) {
                HStack(spacing: 4) {
                    ForEach(ArmorCampRound.Piece.allCases) { piece in
                        Capsule().fill(session.round.stowed.contains(piece) ? ArmorCampPalette.gold : ArmorCampPalette.cream.opacity(0.20)).frame(width: 22,height: 3)
                    }
                }.accessibilityHidden(true)
                Text("\(session.round.returnedCount) / 3 RETURNED").font(.system(size: 9,weight: .bold)).tracking(1)
                Spacer()
                Text(session.round.remainingCount == 0 ? "FREE TO MOVE" : session.round.remainingCount == 3 ? "TOO HEAVY" : "GETTING LIGHTER")
                    .font(.system(size: 8,weight: .bold)).tracking(1).foregroundStyle(ArmorCampPalette.gold)
            }
            Text(session.message).font(.system(size: 12,weight: .medium)).multilineTextAlignment(.center)
                .foregroundStyle(ArmorCampPalette.cream.opacity(0.9)).frame(maxWidth: .infinity,minHeight: 32)
                .padding(.horizontal,10).padding(.vertical,6)
                .background(ArmorCampPalette.ink.opacity(0.65),in: RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel(session.message)
        }
        .foregroundStyle(ArmorCampPalette.cream)
    }
}

struct ArmorCampStepButton: View {
    @ObservedObject var session: ArmorCampSession
    var body: some View {
        let ready = session.round.phase == .ready
        Button(action: session.tryStep) {
            HStack(spacing: 10) {
                Image(systemName: ready ? "figure.walk" : "shoeprints.fill")
                Text(ready ? "Take a brave step" : session.round.isTrying ? "Clank, clank…" : "Try a step")
                Spacer(minLength: 10)
                Image(systemName: "arrow.right")
            }
        }
        .buttonStyle(ArmorCampPrimaryStyle(bright: ready))
        .disabled(session.round.isTrying || !session.round.settling.isEmpty || session.round.phase == .walking)
        .opacity(session.round.phase == .walking ? 0 : 1)
        .accessibilityHint(ready ? "Walk freely without Saul’s armor to finish." : "See how David moves with the armor he is wearing.")
    }
}

struct ArmorCampPause: View {
    @ObservedObject var session: ArmorCampSession
    let exit: () -> Void
    var body: some View {
        ArmorCampModal {
            Text("A MOMENT IN THE CAMP").font(.system(size: 10,weight: .bold)).tracking(3).foregroundStyle(ArmorCampPalette.gold)
            Text("Take a breath.").font(.system(size: 42,design: .serif)).minimumScaleFactor(0.7).lineLimit(1)
            Text("David and the armor will be right here.").font(.system(size: 14)).foregroundStyle(ArmorCampPalette.cream.opacity(0.7))
            Button("Keep going",action: session.resume).buttonStyle(ArmorCampPrimaryStyle())
            HStack {
                Button("Start again",action: session.start)
                Spacer()
                Button("Back to adventure",action: exit)
            }.font(.system(size: 12,weight: .semibold)).padding(.vertical,12)
        }
    }
}

struct ArmorCampVictory: View {
    @ObservedObject var session: ArmorCampSession
    let exit: () -> Void
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height * 1.3
            ZStack {
                ArmorCampPalette.ink.opacity(0.94).ignoresSafeArea()
                ScrollView {
                    HStack(alignment: .center,spacing: 32) {
                        if wide { trophyColumn.frame(width: 85) }
                        VStack(alignment: .leading,spacing: wide ? 10 : 18) {
                            Text("READY FOR THE VALLEY").font(.system(size: 10,weight: .bold)).tracking(3).foregroundStyle(ArmorCampPalette.gold)
                            if !wide { trophyRow.padding(.vertical,8) }
                            Text("His own stride.\nGod’s strength.").font(.system(size: wide ? 30 : 42,design: .serif)).fixedSize(horizontal: false,vertical: true)
                            Text("David set aside Saul’s armor. He would face the valley as a shepherd, trusting the Lord.")
                                .font(.system(size: wide ? 13 : 15)).lineSpacing(3).foregroundStyle(ArmorCampPalette.cream.opacity(0.76))
                            Text("1 SAMUEL 17:38–40").font(.system(size: 9,weight: .bold)).tracking(2).foregroundStyle(ArmorCampPalette.gold)
                            Button("Continue the adventure",action: exit).buttonStyle(ArmorCampPrimaryStyle())
                            Button("Try the armor again",action: session.start).font(.system(size: 13,weight: .semibold)).frame(maxWidth: .infinity,minHeight: 44)
                        }
                    }
                    .frame(maxWidth: wide ? 650 : 410,alignment: .leading).padding(wide ? 20 : 30).frame(maxWidth: .infinity)
                }.defaultScrollAnchor(.center,for: .alignment)
            }.foregroundStyle(ArmorCampPalette.cream)
        }
    }
    private var trophyRow: some View {
        HStack(spacing: 22) {
            ForEach(ArmorCampRound.Piece.allCases) { piece in trophy(piece,height: 65) }
        }.frame(maxWidth: .infinity).accessibilityHidden(true)
    }
    private var trophyColumn: some View {
        VStack(spacing: 15) {
            ForEach(ArmorCampRound.Piece.allCases) { piece in trophy(piece,height: 53) }
        }.accessibilityHidden(true)
    }
    private func trophy(_ piece: ArmorCampRound.Piece,height: CGFloat) -> some View {
        VStack(spacing: 6) {
            Image(piece.artwork).resizable().scaledToFit().frame(width: 55,height: height)
            Image(systemName: "checkmark.circle.fill").font(.system(size: 14)).foregroundStyle(ArmorCampPalette.gold)
        }
    }
}

private struct ArmorCampModal<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        ZStack {
            ArmorCampPalette.ink.opacity(0.94).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading,spacing: 18,content: content)
                    .frame(maxWidth: 410,alignment: .leading).padding(30)
                    .frame(maxWidth: .infinity)
            }.defaultScrollAnchor(.center,for: .alignment)
        }.foregroundStyle(ArmorCampPalette.cream)
    }
}

struct ArmorCampIcon: View {
    let symbol: String
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) { Image(systemName: symbol).font(.system(size: 14,weight: .semibold)).frame(width: 44,height: 44).background(ArmorCampPalette.ink.opacity(0.6),in: Circle()).overlay(Circle().strokeBorder(ArmorCampPalette.cream.opacity(0.16))) }
            .buttonStyle(.plain).foregroundStyle(ArmorCampPalette.cream).accessibilityLabel(label)
    }
}

struct ArmorCampPrimaryStyle: ButtonStyle {
    var bright = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 15,weight: .semibold)).frame(maxWidth: .infinity,minHeight: 52).padding(.horizontal,20)
            .foregroundStyle(bright ? ArmorCampPalette.ink : ArmorCampPalette.cream)
            .background(LinearGradient(colors: bright ? [ArmorCampPalette.cream,ArmorCampPalette.gold] : [ArmorCampPalette.olive,ArmorCampPalette.ink],startPoint: .topLeading,endPoint: .bottomTrailing),in: RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(ArmorCampPalette.cream.opacity(0.25)))
            .shadow(color: .black.opacity(0.25),radius: 10,y: 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
