import SwiftUI

enum ElahPalette {
    static let ink = Color(red: 0.065,green: 0.15,blue: 0.17)
    static let cream = Color(red: 0.99,green: 0.96,blue: 0.86)
    static let gold = Color(red: 0.96,green: 0.79,blue: 0.47)
    static let mint = Color(red: 0.64,green: 0.85,blue: 0.78)
    static let amber = Color(red: 1,green: 0.62,blue: 0.34)
}

struct ElahIntro: View {
    @ObservedObject var controller: ElahBalanceController
    let exit: () -> Void
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height * 1.3
            ZStack(alignment: .bottomLeading) {
                LinearGradient(stops: [.init(color: .clear,location: 0),.init(color: ElahPalette.ink.opacity(0.8),location: 0.5),.init(color: ElahPalette.ink,location: 1)],startPoint: wide ? .trailing : .top,endPoint: wide ? .leading : .bottom).ignoresSafeArea()
                VStack(alignment: .leading,spacing: wide ? 10 : 15) {
                    Text("VALLEY OF ELAH").font(.system(size: 10,weight: .bold)).tracking(4).foregroundStyle(ElahPalette.gold)
                    Text("Steady faith.").font(.system(size: wide ? 47 : 53,design: .serif)).lineLimit(1).minimumScaleFactor(0.7)
                    Text("A narrow crossing. A quiet heart.").font(.system(size: 17,design: .serif))
                    Text("Lean against the wind. Keep David centered, and carry your courage to the other side.")
                        .font(.system(size: 14)).lineSpacing(3).foregroundStyle(ElahPalette.cream.opacity(0.75)).fixedSize(horizontal: false,vertical: true)
                    HStack(spacing: 25) {
                        introDetail("36","SECONDS")
                        introDetail("3","MARKERS")
                        introDetail("1","STEADY HEART")
                    }.padding(.vertical,3)
                    ElahControlChoice(controller: controller)
                    Button { controller.start() } label: {
                        HStack { Text("Find your balance"); Spacer(); Image(systemName: "arrow.right") }
                    }.buttonStyle(ElahPrimaryStyle())
                }
                .frame(maxWidth: wide ? 380 : 500,alignment: .leading).padding(.leading,wide ? 84 : 26).padding(.trailing,wide ? 28 : 26).padding(.bottom,wide ? 12 : 18)
                VStack { HStack { ElahIcon(symbol: "chevron.left",label: "Back to adventure",action: exit); Spacer() }; Spacer() }.padding(.horizontal,20).padding(.top,8)
            }.foregroundStyle(ElahPalette.cream)
        }
    }
    private func introDetail(_ value: String,_ label: String) -> some View {
        VStack(alignment: .leading,spacing: 3) {
            Text(value).font(.system(size: 27,design: .serif))
            Text(label).font(.system(size: 7,weight: .bold)).tracking(1.4).foregroundStyle(ElahPalette.cream.opacity(0.55))
        }
    }
}

struct ElahControlChoice: View {
    @ObservedObject var controller: ElahBalanceController
    var body: some View {
        HStack(spacing: 6) {
            ForEach(ElahBalanceController.Control.allCases,id: \.self) { mode in
                if mode == .touch || controller.motionAvailable {
                    Button { controller.setControl(mode) } label: {
                        HStack(spacing: 6) {
                            Image(systemName: mode == .touch ? "hand.draw" : "iphone.gen3.radiowaves.left.and.right")
                            Text(mode.rawValue)
                        }.font(.system(size: 11,weight: .semibold)).frame(maxWidth: .infinity,minHeight: 44)
                            .background(controller.control == mode ? ElahPalette.mint.opacity(0.18) : .clear,in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(controller.control == mode ? ElahPalette.mint.opacity(0.6) : ElahPalette.cream.opacity(0.12)))
                    }.buttonStyle(.plain).accessibilityLabel("\(mode.rawValue) controls").accessibilityAddTraits(controller.control == mode ? .isSelected : [])
                }
            }
            if !controller.motionAvailable {
                Text("SLIDE TO COUNTER THE WIND").font(.system(size: 7,weight: .bold)).tracking(1).foregroundStyle(ElahPalette.cream.opacity(0.6)).frame(maxWidth: .infinity)
            }
        }
    }
}

struct ElahHUD: View {
    @ObservedObject var controller: ElahBalanceController
    let exit: () -> Void
    var body: some View {
        let hud = controller.hud
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ElahIcon(symbol: "chevron.left",label: "Back to adventure",action: exit)
                VStack(alignment: .leading,spacing: 4) {
                    Text("STEADY FAITH").font(.system(size: 10,weight: .bold)).tracking(2.4)
                    Text(hud.chapter).font(.system(size: 8,weight: .medium)).tracking(1.3).foregroundStyle(ElahPalette.gold)
                }
                Spacer(minLength: 0)
                ElahIcon(symbol: controller.soundOn ? "speaker.wave.2" : "speaker.slash",label: controller.soundOn ? "Mute sound" : "Enable sound",action: controller.toggleSound)
                ElahIcon(symbol: "pause",label: "Pause game",action: controller.pause)
            }
            HStack(spacing: 13) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(ElahPalette.cream.opacity(0.15)).frame(height: 2)
                        Capsule().fill(ElahPalette.gold).frame(width: max(0,geo.size.width * hud.progress),height: 2)
                        ForEach(1...3,id: \.self) { marker in
                            Circle().fill(marker <= hud.checkpoint ? ElahPalette.gold : ElahPalette.ink).frame(width: 8,height: 8)
                                .overlay(Circle().strokeBorder(ElahPalette.gold.opacity(0.8),lineWidth: 1))
                                .position(x: geo.size.width * CGFloat(marker)/3,y: 6)
                        }
                    }.frame(maxHeight: .infinity)
                }.frame(height: 12).accessibilityHidden(true)
                Text("\(hud.meters) / 58 m").font(.system(size: 10,weight: .medium,design: .monospaced)).monospacedDigit().foregroundStyle(ElahPalette.gold)
            }
            .accessibilityElement(children: .ignore).accessibilityLabel("Crossing progress, \(Int(hud.progress*100)) percent. \(hud.checkpoint) of 3 markers reached.")
            Text(hud.message).font(.system(size: 12,weight: .medium)).multilineTextAlignment(.center)
                .frame(maxWidth: .infinity,minHeight: 34).padding(.horizontal,10).padding(.vertical,4)
                .background(ElahPalette.ink.opacity(0.72),in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder((hud.danger > 0.12 ? ElahPalette.amber : ElahPalette.mint).opacity(0.2)))
        }.foregroundStyle(ElahPalette.cream)
    }
}

struct ElahBalanceControls: View {
    @ObservedObject var controller: ElahBalanceController
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("DAVID’S BALANCE").font(.system(size: 8,weight: .bold)).tracking(1.8)
                Spacer()
                Text(controller.hud.calm ? "CALM" : abs(controller.hud.offset) < 0.3 ? "STEADY" : "COUNTER THE WIND")
                    .font(.system(size: 8,weight: .bold)).tracking(1).foregroundStyle(controller.hud.danger > 0.12 ? ElahPalette.amber : ElahPalette.mint)
            }
            GeometryReader { geo in
                ZStack {
                    Capsule().fill(ElahPalette.cream.opacity(0.12))
                    Capsule().fill(ElahPalette.mint.opacity(0.4)).frame(width: geo.size.width * 0.30)
                    Rectangle().fill(ElahPalette.cream.opacity(0.55)).frame(width: 1,height: 10)
                    Circle().fill(controller.hud.danger > 0.12 ? ElahPalette.amber : ElahPalette.gold).frame(width: 10,height: 10)
                        .shadow(color: ElahPalette.gold.opacity(0.6),radius: 5)
                        .offset(x: min(1,max(-1,controller.hud.offset)) * (geo.size.width-14)/2)
                }
            }.frame(height: 6)
                .accessibilityElement(children: .ignore).accessibilityLabel("David’s balance").accessibilityValue(balanceDescription)
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    HStack {
                        Text(controller.control == .touch ? "SLIDE TO LEAN" : "TILT GENTLY").font(.system(size: 7,weight: .bold)).tracking(1.4)
                        Spacer()
                        Button(action: controller.center) { Text(controller.control == .touch ? "CENTER" : "RECENTER").font(.system(size: 7,weight: .bold)).tracking(0.8).frame(minHeight: 25) }
                            .accessibilityLabel(controller.control == .touch ? "Center lean control" : "Recalibrate tilt")
                    }.foregroundStyle(ElahPalette.cream.opacity(0.65))
                    HStack(spacing: 0) {
                        Button { controller.lean(-1) } label: { Image(systemName: "chevron.left").frame(width: 44,height: 44) }.accessibilityLabel("Lean left")
                        GeometryReader { geo in
                            ZStack {
                                Capsule().fill(ElahPalette.cream.opacity(0.08)).frame(height: 36)
                                HStack(spacing: 0) { ForEach(0..<9,id: \.self) { i in
                                    if i > 0 { Spacer(minLength: 0) }
                                    Capsule().fill(ElahPalette.cream.opacity(i == 4 ? 0.6 : 0.18)).frame(width: 1,height: i == 4 ? 12 : 6)
                                }}.padding(.horizontal,15)
                                Capsule().fill(ElahPalette.cream).frame(width: 28,height: 31)
                                    .overlay(Capsule().fill(ElahPalette.ink.opacity(0.35)).frame(width: 2,height: 10))
                                    .offset(x: CGFloat(controller.control == .touch ? controller.touchValue : 0) * max(0,(geo.size.width-30)/2))
                            }.frame(maxHeight: .infinity).contentShape(Rectangle())
                                .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                                    if controller.control != .touch { controller.setControl(.touch) }
                                    controller.setTouch((value.location.x / max(1,geo.size.width) - 0.5)*2)
                                }).accessibilityHidden(true)
                        }.frame(height: 44)
                        Button { controller.lean(1) } label: { Image(systemName: "chevron.right").frame(width: 44,height: 44) }.accessibilityLabel("Lean right")
                    }.buttonStyle(.plain).font(.system(size: 12,weight: .semibold))
                }
                Button(action: controller.breathe) {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle().strokeBorder(ElahPalette.cream.opacity(0.15),lineWidth: 2)
                            Circle().trim(from: 0,to: controller.hud.calm ? 1 : controller.hud.focus).stroke(ElahPalette.gold,style: StrokeStyle(lineWidth: 2,lineCap: .round)).rotationEffect(.degrees(-90))
                            Image(systemName: controller.hud.calm ? "sparkle" : "wind").font(.system(size: 19,weight: .light))
                        }.frame(width: 39,height: 39)
                        Text(controller.hud.calm ? "BREATHE…" : "BREATHE").font(.system(size: 7,weight: .bold)).tracking(1)
                    }.frame(width: 66,height: 66).foregroundStyle(controller.hud.canBreathe || controller.hud.calm ? ElahPalette.gold : ElahPalette.cream.opacity(0.48))
                }.buttonStyle(.plain).disabled(!controller.hud.canBreathe)
                    .accessibilityLabel("Breathe").accessibilityValue(controller.hud.calm ? "Active" : "\(Int(controller.hud.focus*100)) percent charged")
                    .accessibilityHint("Steady steps charge this ability. When ready, calm the wind and return toward the middle.")
            }
        }
        .foregroundStyle(ElahPalette.cream).padding(.horizontal,15).padding(.vertical,12)
        .background(ElahPalette.ink.opacity(0.91),in: RoundedRectangle(cornerRadius: 23))
        .overlay(RoundedRectangle(cornerRadius: 23).strokeBorder(ElahPalette.mint.opacity(0.24)))
        .disabled(controller.hud.phase != .walking)
        .allowsHitTesting(controller.hud.phase == .walking)
        .opacity(controller.hud.phase == .walking ? 1 : 0.65)
    }
    private var balanceDescription: String {
        let value = controller.hud.offset
        if abs(value) < 0.25 { return "Centered" }
        return "Leaning \(value < 0 ? "left" : "right"). \(abs(value) > 0.7 ? "Near the edge." : "")"
    }
}

struct ElahCountdown: View {
    let count: Int
    var body: some View {
        VStack(spacing: 12) {
            Text("Find your center").font(.system(size: 20,design: .serif))
            Text("\(count)").font(.system(size: 50,design: .serif)).frame(width: 88,height: 88)
                .background(ElahPalette.ink.opacity(0.75),in: Circle())
                .overlay(Circle().strokeBorder(ElahPalette.gold.opacity(0.6)))
            Text("THE CROSSING BEGINS").font(.system(size: 8,weight: .bold)).tracking(2.4)
        }.foregroundStyle(ElahPalette.cream).accessibilityElement(children: .combine).allowsHitTesting(false)
    }
}

struct ElahRoundPanel: View {
    enum Kind { case paused,lost,won }
    @ObservedObject var controller: ElahBalanceController
    let kind: Kind
    let exit: () -> Void
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height * 1.3
            ZStack {
                ElahPalette.ink.opacity(0.94).ignoresSafeArea()
                ScrollView {
                    HStack(spacing: 28) {
                        if wide { emblem.frame(width: 90) }
                        VStack(alignment: .leading,spacing: wide ? 8 : 18) {
                            Text(kicker).font(.system(size: 9,weight: .bold)).tracking(3).foregroundStyle(ElahPalette.gold)
                            if !wide { emblem.frame(maxWidth: .infinity).padding(.vertical,10) }
                            Text(title).font(.system(size: wide ? 31 : 43,design: .serif)).fixedSize(horizontal: false,vertical: true)
                            Text(detail).font(.system(size: wide ? 12 : 15)).lineSpacing(4).foregroundStyle(ElahPalette.cream.opacity(0.75))
                            if kind == .paused {
                                ElahControlChoice(controller: controller)
                                Button("Keep crossing",action: controller.resume).buttonStyle(ElahPrimaryStyle())
                                HStack { Button("Start again") { controller.start() }; Spacer(); Button("Back to adventure",action: exit) }.font(.system(size: 12,weight: .semibold)).frame(minHeight: 44)
                            } else if kind == .lost {
                                Button(controller.hud.checkpoint > 0 ? "Return to the last marker" : "Find your balance again") { controller.start(fromCheckpoint: true) }.buttonStyle(ElahPrimaryStyle())
                                HStack { Button("Start fresh") { controller.start() }; Spacer(); Button("Back to adventure",action: exit) }.font(.system(size: 12,weight: .semibold)).frame(minHeight: 44)
                            } else {
                                Text("THE BATTLE IS THE LORD’S · 1 SAMUEL 17:47").font(.system(size: 8,weight: .bold)).tracking(1.2).foregroundStyle(ElahPalette.gold)
                                if wide {
                                    HStack(spacing: 12) {
                                        Button("Continue the adventure",action: exit).buttonStyle(ElahPrimaryStyle())
                                        ElahIcon(symbol: "arrow.clockwise",label: "Cross the valley again") { controller.start() }
                                    }
                                } else {
                                    Button("Continue the adventure",action: exit).buttonStyle(ElahPrimaryStyle())
                                    Button("Cross the valley again") { controller.start() }.font(.system(size: 13,weight: .semibold)).frame(maxWidth: .infinity,minHeight: 44)
                                }
                            }
                        }
                    }.frame(maxWidth: wide ? 650 : 410,alignment: .leading).padding(wide ? 20 : 30).frame(maxWidth: .infinity)
                }.defaultScrollAnchor(.center,for: .alignment)
            }.foregroundStyle(ElahPalette.cream)
        }
    }
    private var kicker: String { kind == .paused ? "A QUIET MOMENT" : kind == .lost ? "COURAGE TAKES PRACTICE" : "THE VALLEY IS BEHIND YOU" }
    private var title: String { kind == .paused ? "Take a breath." : kind == .lost ? "Find your\nfooting." : "Steady steps.\nUnshaken faith." }
    private var detail: String {
        kind == .paused ? "The stream can wait. Settle in, then take your next step." : kind == .lost ? "The wind caught David off balance. Lean against each gust, and use Breathe when it’s ready. Your last marker is saved." : "Across the wind, one faithful step at a time. David is ready to face what lies ahead."
    }
    private var emblem: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle().strokeBorder(ElahPalette.gold.opacity(0.22),lineWidth: 1).frame(width: 80,height: 80)
                Circle().strokeBorder(ElahPalette.gold.opacity(0.55),lineWidth: 1).frame(width: 63,height: 63)
                Image(systemName: kind == .won ? "figure.walk" : kind == .paused ? "wind" : "shoeprints.fill").font(.system(size: 27,weight: .ultraLight)).foregroundStyle(ElahPalette.gold)
            }
            HStack(spacing: 12) { ForEach(1...3,id: \.self) { index in
                Image(systemName: index <= controller.hud.checkpoint ? "checkmark.circle.fill" : "circle").font(.system(size: 12)).foregroundStyle(ElahPalette.gold.opacity(index <= controller.hud.checkpoint ? 1 : 0.4))
            }}
        }.accessibilityHidden(true)
    }
}

struct ElahIcon: View {
    let symbol: String
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) { Image(systemName: symbol).font(.system(size: 13,weight: .semibold)).frame(width: 44,height: 44).background(ElahPalette.ink.opacity(0.65),in: Circle()).overlay(Circle().strokeBorder(ElahPalette.cream.opacity(0.15))) }
            .buttonStyle(.plain).foregroundStyle(ElahPalette.cream).accessibilityLabel(label)
    }
}
struct ElahPrimaryStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 15,weight: .semibold)).frame(maxWidth: .infinity,minHeight: 52).padding(.horizontal,20)
            .foregroundStyle(ElahPalette.ink)
            .background(LinearGradient(colors: [ElahPalette.cream,ElahPalette.gold],startPoint: .topLeading,endPoint: .bottomTrailing),in: RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(ElahPalette.cream.opacity(0.4)))
            .shadow(color: .black.opacity(0.2),radius: 12,y: 5).scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
