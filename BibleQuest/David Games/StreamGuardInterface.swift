import SwiftUI

enum StreamPalette {
    static let ink = Color(hex: "#092D2D")
    static let cream = Color(hex: "#FFF3D6")
    static let gold = Color(hex: "#EAC783")
    static let aqua = Color(hex: "#A6E4D4")
}

struct StreamIntro: View {
    let onStart: () -> Void
    let onBack: () -> Void
    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.width > geometry.size.height * 1.3
            ZStack(alignment: .bottom) {
                LinearGradient(stops: [.init(color: .clear,location: 0.30),
                                       .init(color: StreamPalette.ink.opacity(0.75),location: 0.66),
                                       .init(color: StreamPalette.ink.opacity(0.99),location: 1)],
                               startPoint: compact ? .trailing : .top,endPoint: compact ? .leading : .bottom)
                    .ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading,spacing: 12) {
                        Text("DAVID’S PREPARATION").font(.system(size: 9,weight: .heavy,design: .rounded)).tracking(3)
                            .foregroundStyle(StreamPalette.gold)
                        Text("Stream of Stones")
                            .font(.system(size: compact ? 35 : 39,weight: .medium,design: .serif))
                            .lineLimit(1).minimumScaleFactor(0.75).foregroundStyle(StreamPalette.cream)
                        Text("Five smooth stones. One steady hand.\nTap swooping birds before they reach the pouch.")
                            .font(.system(size: 13,weight: .medium,design: .rounded))
                            .lineSpacing(4).foregroundStyle(StreamPalette.cream.opacity(0.8))
                        HStack(spacing: 32) {
                            stat("30", "SECONDS")
                            stat("5", "STONES")
                            VStack(alignment: .leading,spacing: 4) {
                                Image(systemName: "hand.tap").font(.system(size: 23,weight: .light))
                                Text("TAP TO GUARD").font(.system(size: 7,weight: .bold,design: .rounded)).tracking(1.2).opacity(0.55)
                            }.foregroundStyle(StreamPalette.cream)
                        }.padding(.vertical,5)
                        StreamPrimaryButton(title: "Guard the stones",icon: "arrow.right",action: onStart)
                        Label("Five taps charge your shepherd’s call.",systemImage: "wind")
                            .font(.system(size: 10,weight: .medium,design: .rounded))
                            .foregroundStyle(StreamPalette.cream.opacity(0.57))
                    }
                    .padding(.horizontal,26).padding(.vertical,22)
                    .padding(.top,compact ? 52 : 0)
                    .frame(maxWidth: compact ? 405 : 510,alignment: .leading)
                    .frame(maxWidth: .infinity,alignment: compact ? .leading : .center)
                }
                .frame(maxHeight: compact ? .infinity : 350)
                .defaultScrollAnchor(.bottom)
            }
            .overlay(alignment: .topLeading) {
                Button(action: onBack) {
                    Label("Adventures",systemImage: "arrow.left")
                        .font(.system(size: 12,weight: .semibold,design: .rounded))
                        .padding(.horizontal,17).frame(height: 44)
                        .background(StreamPalette.ink.opacity(0.7),in: Capsule())
                        .foregroundStyle(StreamPalette.cream)
                }
                .buttonStyle(StreamPressStyle()).padding(.leading,20).padding(.top,10)
            }
        }
    }
    private func stat(_ value: String,_ label: String) -> some View {
        VStack(alignment: .leading,spacing: 4) {
            Text(value).font(.system(size: 25,weight: .medium,design: .serif))
            Text(label).font(.system(size: 7,weight: .bold,design: .rounded)).tracking(1.3).opacity(0.55)
        }.foregroundStyle(StreamPalette.cream)
    }
}

struct StreamHUD: View {
    let hud: StreamGuardHUD
    let soundOn: Bool
    let onBack: () -> Void
    let onSound: () -> Void
    let onPause: () -> Void
    var body: some View {
        VStack(spacing: 13) {
            HStack(spacing: 10) {
                StreamIconButton(icon: "arrow.left",label: "Back to adventure",action: onBack)
                VStack(alignment: .leading,spacing: 4) {
                    Text("STREAM OF STONES").font(.system(size: 9,weight: .heavy,design: .rounded)).tracking(1.7)
                    Text(hud.chapter).font(.system(size: 7,weight: .bold,design: .rounded)).tracking(1.1).opacity(0.6)
                }
                Spacer(minLength: 0)
                StreamIconButton(icon: soundOn ? "speaker.wave.2" : "speaker.slash",label: soundOn ? "Mute sound" : "Enable sound",action: onSound)
                StreamIconButton(icon: "pause",label: "Pause guarding",action: onPause)
            }
            HStack(alignment: .center) {
                VStack(alignment: .leading,spacing: 2) {
                    HStack(spacing: -1) {
                        ForEach(0..<5) { index in
                            Image("StreamRiverStone").resizable().scaledToFit().frame(width: 25,height: 22)
                                .saturation(index < hud.stones ? 1 : 0).opacity(index < hud.stones ? 1 : 0.18)
                        }
                        Text("\(hud.stones) SAFE").font(.system(size: 8,weight: .heavy,design: .rounded)).tracking(1)
                            .padding(.leading,6).foregroundStyle(StreamPalette.aqua)
                    }
                    HStack(spacing: 8) {
                        Text("\(hud.score)").monospacedDigit().contentTransition(.numericText())
                        Text("POINTS").font(.system(size: 7,weight: .bold,design: .rounded)).tracking(1).opacity(0.55)
                        if hud.combo > 1 {
                            Text("×\(hud.combo)").foregroundStyle(StreamPalette.gold).contentTransition(.numericText())
                        }
                    }.font(.system(size: 12,weight: .semibold,design: .rounded))
                }
                Spacer(minLength: 0)
                HStack(alignment: .firstTextBaseline,spacing: 4) {
                    Text("\(hud.seconds)").font(.system(size: 34,weight: .medium,design: .serif)).monospacedDigit().contentTransition(.numericText())
                    Text("SEC").font(.system(size: 8,weight: .bold,design: .rounded)).tracking(1).opacity(0.6)
                }
            }
            GeometryReader { geometry in
                Capsule().fill(.white.opacity(0.16)).overlay(alignment: .leading) {
                    Capsule().fill(LinearGradient(colors: [StreamPalette.aqua,StreamPalette.gold],startPoint: .leading,endPoint: .trailing))
                        .frame(width: max(3,geometry.size.width * hud.progress))
                }
            }.frame(height: 3)
        }
        .foregroundStyle(StreamPalette.cream)
        .frame(maxWidth: 650)
        .padding(.bottom,30)
        .animation(.easeOut(duration: 0.18),value: hud.score)
    }
}

struct StreamCallControl: View {
    let charge: Int
    let onCall: () -> Void
    var body: some View {
        Button(action: onCall) {
            HStack(spacing: 13) {
                Image(systemName: "wind").font(.system(size: 23,weight: .light)).frame(width: 32)
                VStack(alignment: .leading,spacing: 4) {
                    Text("Shepherd’s call").font(.system(size: 14,weight: .bold,design: .rounded))
                    Text(charge == 5 ? "READY · SEND THEM SOARING" : "TAP BIRDS TO CHARGE")
                        .font(.system(size: 7,weight: .heavy,design: .rounded)).tracking(1)
                        .opacity(charge == 5 ? 0.7 : 0.55)
                }
                Spacer(minLength: 6)
                HStack(spacing: 3) {
                    ForEach(0..<5) { index in
                        Capsule().fill((charge == 5 ? StreamPalette.ink : StreamPalette.gold).opacity(index < charge ? 1 : 0.2))
                            .frame(width: 4,height: 19 + CGFloat(index % 3) * 4)
                    }
                }
            }
            .foregroundStyle(charge == 5 ? StreamPalette.ink : StreamPalette.cream)
            .padding(.horizontal,20).frame(height: 65)
            .background {
                Capsule().fill(charge == 5 ? StreamPalette.gold : StreamPalette.ink.opacity(0.93))
            }
            .overlay(Capsule().stroke(charge == 5 ? StreamPalette.cream.opacity(0.8) : StreamPalette.aqua.opacity(0.25),lineWidth: 1))
            .shadow(color: StreamPalette.ink.opacity(0.3),radius: 16,y: 5)
        }
        .frame(maxWidth: 345)
        .disabled(charge < 5)
        .buttonStyle(StreamPressStyle())
        .accessibilityLabel(charge == 5 ? "Use shepherd’s call" : "Shepherd’s call, \(charge) of 5 charges")
        .accessibilityHint("Shoos every approaching bird. Earn a charge by tapping a bird.")
        .animation(.easeInOut(duration: 0.3),value: charge == 5)
    }
}

struct StreamResultPanel: View {
    enum Mode { case paused,won,lost }
    let mode: Mode
    let hud: StreamGuardHUD
    let best: Int
    let onPrimary: () -> Void
    let onReplay: () -> Void
    let onBack: () -> Void
    var body: some View {
        ZStack {
            StreamPalette.ink.opacity(mode == .paused ? 0.86 : 0.94).ignoresSafeArea()
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 19) {
                        Text(mode == .paused ? "A MOMENT OF STILLNESS" : mode == .won ? "READY FOR THE VALLEY" : "A NEW CHANCE TO PREPARE")
                            .font(.system(size: 8,weight: .heavy,design: .rounded)).tracking(2.4).foregroundStyle(StreamPalette.gold)
                        HStack(spacing: -4) {
                            ForEach(0..<5) { index in
                                Image("StreamRiverStone").resizable().scaledToFit().frame(width: 48,height: 44)
                                    .opacity(mode == .paused || index < hud.stones ? 1 : 0.15)
                                    .rotationEffect(.degrees(Double(index - 2) * 8))
                            }
                        }.padding(.vertical,4)
                        Text(title).font(.system(size: 41,weight: .medium,design: .serif))
                            .multilineTextAlignment(.center).foregroundStyle(StreamPalette.cream)
                        Text(mode == .paused ? "The spring will wait until you’re ready." : mode == .won ?
                             "\(hud.stones) of five stones kept safe.\nSmall things. A great purpose." : "Watch the wings. Tap before they land.\nYour next attempt begins with five stones.")
                            .font(.system(size: 13,weight: .medium,design: .rounded)).lineSpacing(5)
                            .multilineTextAlignment(.center).foregroundStyle(StreamPalette.cream.opacity(0.7))
                        if mode != .paused {
                            HStack(spacing: 30) {
                                resultStat("\(hud.score)","SCORE")
                                resultStat("×\(hud.bestCombo)","BEST COMBO")
                                resultStat("\(best)","PERSONAL BEST")
                            }.padding(.vertical,8)
                        }
                        if mode == .won {
                            VStack(spacing: 9) {
                                Text("“He chose five smooth stones\nfrom the stream.”").font(.system(size: 18,design: .serif)).italic()
                                    .multilineTextAlignment(.center).foregroundStyle(StreamPalette.cream.opacity(0.9))
                                Text("1 SAMUEL 17:40").font(.system(size: 8,weight: .bold,design: .rounded)).tracking(2).foregroundStyle(StreamPalette.gold)
                            }.padding(.vertical,6)
                        }
                        StreamPrimaryButton(title: mode == .paused ? "Return to the stream" : mode == .won ? "Guard them again" : "Try again",
                                            icon: mode == .paused ? "play.fill" : "arrow.clockwise",action: onPrimary)
                        if mode == .paused {
                            Button("Restart with five stones",action: onReplay).font(.system(size: 12,weight: .semibold,design: .rounded)).foregroundStyle(StreamPalette.cream.opacity(0.7))
                        }
                        Button("Back to adventure",action: onBack).font(.system(size: 12,weight: .semibold,design: .rounded)).foregroundStyle(StreamPalette.cream.opacity(0.7))
                    }
                    .padding(.horizontal,27).padding(.vertical,30)
                    .frame(maxWidth: 450).frame(maxWidth: .infinity,minHeight: geometry.size.height)
                }
            }
        }
    }
    private var title: String {
        if mode == .paused { return "Hold your\nstillness." }
        if mode == .won { return hud.stones == 5 ? "Every stone.\nSafe and sound." : "A steady hand.\nA brave heart." }
        return "Find your\nsteady hand."
    }
    private func resultStat(_ value: String,_ label: String) -> some View {
        VStack(spacing: 5) {
            Text(value).font(.system(size: 23,weight: .medium,design: .serif)).foregroundStyle(StreamPalette.cream)
            Text(label).font(.system(size: 7,weight: .bold,design: .rounded)).tracking(1).foregroundStyle(StreamPalette.cream.opacity(0.45))
        }
    }
}

struct StreamIconButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 16,weight: .semibold)).foregroundStyle(StreamPalette.cream)
                .frame(width: 43,height: 43)
                .background(StreamPalette.ink.opacity(0.7),in: Circle())
                .overlay(Circle().stroke(StreamPalette.cream.opacity(0.18),lineWidth: 1))
        }.buttonStyle(StreamPressStyle()).accessibilityLabel(label)
    }
}
struct StreamPrimaryButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title).font(.system(size: 15,weight: .bold,design: .rounded))
                Image(systemName: icon).font(.system(size: 12,weight: .bold))
            }
            .foregroundStyle(StreamPalette.ink).frame(maxWidth: .infinity,minHeight: 54)
            .background(LinearGradient(colors: [Color(hex: "#FFE9B7"),StreamPalette.gold],startPoint: .top,endPoint: .bottom),in: Capsule())
            .overlay(Capsule().stroke(StreamPalette.cream.opacity(0.75),lineWidth: 1))
        }.buttonStyle(StreamPressStyle())
    }
}
struct StreamPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.26,dampingFraction: 0.75),value: configuration.isPressed)
    }
}
