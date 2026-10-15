import SwiftUI

enum BeastPalette {
    static let cream = Color(hex: "#FFF3D5")
    static let gold = Color(hex: "#E8C27A")
    static let ink = Color(hex: "#162F29")
}

struct RoaringHUDView: View {
    let hud: RoaringRunHUD
    let soundOn: Bool
    let onBack: () -> Void
    let onSound: () -> Void
    let onPause: () -> Void
    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                RoaringControl(icon: "arrow.left", label: "Back to adventure", small: true, action: onBack)
                VStack(alignment: .leading, spacing: 4) {
                    Text("ROARING BEAST")
                        .font(.system(size: 9, weight: .heavy, design: .rounded)).tracking(2)
                    Text(hud.chapter)
                        .font(.system(size: 8, weight: .medium, design: .rounded)).tracking(1.2)
                        .opacity(0.62)
                }
                Spacer(minLength: 2)
                RoaringControl(icon: soundOn ? "speaker.wave.2" : "speaker.slash",
                               label: soundOn ? "Mute sound" : "Enable sound", small: true, action: onSound)
                RoaringControl(icon: "pause", label: "Pause run", small: true, action: onPause)
            }
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 5) {
                        ForEach(0..<3) { index in
                            Image(systemName: "shield.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(index < hud.courage ? BeastPalette.gold : BeastPalette.cream.opacity(0.2))
                        }
                        Text("COURAGE")
                            .font(.system(size: 7, weight: .bold, design: .rounded)).tracking(1.3)
                            .opacity(0.65).padding(.leading, 4)
                    }
                    Text("\(hud.meters) m  ·  \(hud.dodges) clean passes")
                        .font(.system(size: 10, weight: .medium, design: .rounded)).opacity(0.7)
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(hud.seconds)")
                        .font(.system(size: 30, weight: .medium, design: .serif))
                        .monospacedDigit().contentTransition(.numericText())
                    Text("SEC")
                        .font(.system(size: 8, weight: .bold, design: .rounded)).tracking(1)
                        .opacity(0.65)
                }
            }
            GeometryReader { geo in
                Capsule().fill(.white.opacity(0.15))
                    .overlay(alignment: .leading) {
                        Capsule().fill(BeastPalette.gold).frame(width: max(3, geo.size.width * hud.progress))
                    }
            }
            .frame(height: 3)
        }
        .foregroundStyle(BeastPalette.cream)
        .frame(maxWidth: 650)
    }
}

struct RoaringIntro: View {
    let onStart: () -> Void
    let onBack: () -> Void
    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 500
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: [.clear, BeastPalette.ink.opacity(0.3), BeastPalette.ink.opacity(0.97)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: compact ? 10 : 12) {
                        Text("THE COURAGE TRIAL")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .tracking(3).foregroundStyle(BeastPalette.gold)
                        Text("Roaring Beast")
                            .font(.system(size: compact ? 43 : 46, weight: .medium, design: .serif))
                            .lineLimit(1).minimumScaleFactor(0.75)
                            .lineSpacing(-5).foregroundStyle(BeastPalette.cream)
                        Text("A narrow path. A fearless heart.\nOutrun the lion through the canyon.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(BeastPalette.cream.opacity(0.78))
                            .lineSpacing(4)
                        HStack(spacing: 30) {
                            introStat("30", "SECONDS")
                            introStat("3", "LANES")
                            introStat("3", "CHANCES")
                        }
                        .padding(.vertical, 4)
                        HStack(spacing: 22) {
                            Label("Dodge", systemImage: "arrow.left.and.right")
                            Label("Jump", systemImage: "arrow.up")
                        }
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(BeastPalette.cream.opacity(0.8))
                        RoaringPrimaryButton(title: "Run the canyon", icon: "arrow.right", action: onStart)
                        Text("Swipe, or use the on-screen controls.")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(BeastPalette.cream.opacity(0.48))
                    }
                    .padding(26)
                    .frame(maxWidth: compact ? 460 : 500, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: compact ? .leading : .center)
                }
                .frame(maxHeight: compact ? .infinity : 390)
                .defaultScrollAnchor(.bottom)
            }
            .overlay(alignment: .topLeading) {
                Button(action: onBack) {
                    Label("Adventures", systemImage: "arrow.left")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(BeastPalette.cream)
                        .padding(.horizontal, 16).frame(height: 44)
                        .background(BeastPalette.ink.opacity(0.5), in: Capsule())
                }
                .buttonStyle(RoaringPressStyle())
                .padding(.leading, 20).padding(.top, 6)
            }
        }
    }
    private func introStat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.system(size: 23, weight: .medium, design: .serif)).foregroundStyle(BeastPalette.cream)
            Text(label).font(.system(size: 8, weight: .bold, design: .rounded)).tracking(1.4)
                .foregroundStyle(BeastPalette.cream.opacity(0.48))
        }
    }
}

struct RoaringEndPanel: View {
    enum Mode { case paused, caught, won }
    let mode: Mode
    let hud: RoaringRunHUD
    let best: Int
    let onPrimary: () -> Void
    let onReplay: () -> Void
    let onBack: () -> Void
    var body: some View {
        ZStack {
            BeastPalette.ink.opacity(mode == .paused ? 0.86 : 0.94).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Text(mode == .won ? "THE CANYON IS BEHIND YOU" : mode == .paused ? "A MOMENT TO BREATHE" : "COURAGE GROWS WITH PRACTICE")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .tracking(2).foregroundStyle(BeastPalette.gold)
                    Image(systemName: mode == .won ? "sun.horizon.fill" : mode == .paused ? "pause.circle" : "shield.lefthalf.filled")
                        .font(.system(size: 48, weight: .ultraLight))
                        .foregroundStyle(BeastPalette.gold)
                        .padding(.vertical, 10)
                    Text(mode == .won ? "Courage carried\nyou home." : mode == .paused ? "Hold your\nground." : "Keep your\ncourage.")
                        .font(.system(size: 43, weight: .medium, design: .serif))
                        .multilineTextAlignment(.center).foregroundStyle(BeastPalette.cream)
                    Text(mode == .won ? "Thirty seconds. One brave shepherd." : mode == .paused ?
                         "The chase will wait until you’re ready." : "Watch the path ahead. Dodge the thorns.\nJump the broken ground.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center).lineSpacing(4)
                        .foregroundStyle(BeastPalette.cream.opacity(0.68))
                    if mode != .paused {
                        HStack(spacing: 32) {
                            resultStat("\(hud.meters)m", "DISTANCE")
                            resultStat("\(hud.dodges)", "CLEAN PASSES")
                            resultStat("\(best)m", "BEST RUN")
                        }
                        .padding(.vertical, 12)
                    }
                    if mode == .won {
                        VStack(spacing: 10) {
                            Text("“I struck it and rescued the sheep\nfrom its mouth.”")
                                .font(.system(size: 18, design: .serif)).italic()
                                .multilineTextAlignment(.center).foregroundStyle(BeastPalette.cream.opacity(0.9))
                            Text("1 SAMUEL 17:35")
                                .font(.system(size: 8, weight: .bold, design: .rounded)).tracking(2)
                                .foregroundStyle(BeastPalette.cream.opacity(0.45))
                        }
                        .padding(.vertical, 16)
                    }
                    RoaringPrimaryButton(title: mode == .won ? "Continue the adventure" : mode == .paused ? "Back to the chase" : "Run again",
                                         icon: mode == .paused ? "play.fill" : "arrow.right", action: onPrimary)
                    if mode == .won || mode == .paused {
                        Button(mode == .won ? "Run again" : "Restart the run", action: onReplay)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(BeastPalette.cream.opacity(0.7)).frame(minHeight: 44)
                    }
                    if mode != .won {
                        Button("Back to adventure", action: onBack)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(BeastPalette.cream.opacity(0.5)).frame(minHeight: 44)
                    }
                }
                .padding(28).frame(maxWidth: 440).frame(maxWidth: .infinity)
            }
            .defaultScrollAnchor(.center)
        }
        .accessibilityAddTraits(.isModal)
    }
    private func resultStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 7) {
            Text(value).font(.system(size: 23, weight: .medium, design: .serif)).foregroundStyle(BeastPalette.gold)
            Text(label).font(.system(size: 7, weight: .bold, design: .rounded)).tracking(1)
                .foregroundStyle(BeastPalette.cream.opacity(0.45))
        }
    }
}

struct RoaringControl: View {
    let icon: String
    let label: String
    var small = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: small ? 14 : 18, weight: .semibold))
                .foregroundStyle(BeastPalette.cream)
                .frame(width: small ? 42 : 52, height: small ? 42 : 52)
                .background(BeastPalette.ink.opacity(0.65), in: Circle())
                .overlay(Circle().stroke(BeastPalette.cream.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(RoaringPressStyle()).accessibilityLabel(label)
    }
}
struct RoaringPrimaryButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title).font(.system(size: 16, weight: .bold, design: .rounded))
                Image(systemName: icon).font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(BeastPalette.ink).frame(maxWidth: .infinity, minHeight: 54)
            .background(LinearGradient(colors: [Color(hex: "#F7E2AF"), Color(hex: "#D9B36A")], startPoint: .top, endPoint: .bottom), in: Capsule())
            .overlay(Capsule().stroke(Color(hex: "#FFF1CD").opacity(0.7), lineWidth: 1))
        }
        .buttonStyle(RoaringPressStyle())
    }
}
struct RoaringPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
