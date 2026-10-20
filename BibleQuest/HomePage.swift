import SwiftUI

private enum WelcomePalette {
    static let paper = Color(hex: "#FFF9EF")
    static let ink = Color(hex: "#243E3B")
    static let muted = Color(hex: "#71817B")
    static let teal = Color(hex: "#24786C")
    static let gold = Color(hex: "#FFDC83")
}

private enum WelcomeDestination: Hashable {
    case adventures, album, verse, david
}

struct HomePage: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dynamicTypeSize) private var typeSize
    var onProfile: (() -> Void)? = nil
    @State private var destination: WelcomeDestination?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                masthead
                greeting
                adventureCard
                toolkit
                courageCard
                HStack(spacing: 7) {
                    Image(systemName: "heart.fill").foregroundStyle(Color(hex: "#D77E65"))
                    Text("Little steps. Big faith.")
                        .foregroundStyle(WelcomePalette.muted)
                }
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.top, 1)
                .padding(.bottom, 10)
            }
            .frame(maxWidth: 640)
            .padding(.horizontal, 22)
            .padding(.top, 14)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity)
        }
        .background(WelcomePalette.paper.ignoresSafeArea())
        .scrollIndicators(.hidden)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $destination) { page in
            switch page {
            case .adventures: SelectQuestView()
            case .album: HeroAlbumView()
            case .verse: VerseView()
            case .david: DavidAdventureView()
            }
        }
    }

    private var avatarName: String {
        let hero = appState.profile?.hero ?? ""
        return hero.isEmpty ? "david" : hero
    }

    private var masthead: some View {
        HStack(spacing: 8) {
            Image(systemName: "safari.fill")
                .accessibilityHidden(true)
                .font(.system(size: 23))
                .foregroundStyle(WelcomePalette.teal)
                .rotationEffect(.degrees(-15))
            Text("BIBLEQUEST")
                .font(.system(.caption, design: .rounded, weight: .heavy))
                .tracking(2.1)
                .foregroundStyle(WelcomePalette.ink)
            Spacer(minLength: 8)
            Button { onProfile?() } label: {
                Image(avatarName)
                    .resizable().scaledToFill()
                    .frame(width: 42, height: 42)
                    .background(Color(hex: "#F8DEAE"))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 3))
                    .shadow(color: WelcomePalette.ink.opacity(0.10), radius: 6, y: 3)
            }
            .buttonStyle(WelcomePressStyle())
            .accessibilityLabel("Open your profile")
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Welcome, \(appState.profile?.displayName ?? "Explorer")!")
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundStyle(WelcomePalette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("There’s a little wonder waiting for you.")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(WelcomePalette.muted)
        }
    }

    private var adventureCard: some View {
        Button { destination = .adventures } label: {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 30)
                    .fill(LinearGradient(colors: [Color(hex: "#286F66"), Color(hex: "#164D49")], startPoint: .topLeading, endPoint: .bottomTrailing))
                WelcomeTrail()
                    .stroke(WelcomePalette.gold.opacity(0.23), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 7]))
                    .padding(20)
                    .accessibilityHidden(true)
                Circle()
                    .fill(Color(hex: "#8CC0A0").opacity(0.19))
                    .frame(width: 205, height: 205)
                    .offset(x: 40, y: 32)
                if !typeSize.isAccessibilitySize {
                    Image("davidFullBody")
                        .resizable().scaledToFit()
                        .frame(width: 160, height: 246)
                        .rotationEffect(.degrees(5))
                        .padding(.trailing, 2)
                        .padding(.bottom, 8)
                        .shadow(color: .black.opacity(0.16), radius: 9, y: 7)
                        .accessibilityHidden(true)
                    Image(systemName: "sparkle")
                        .font(.system(size: 23, weight: .medium))
                        .foregroundStyle(WelcomePalette.gold)
                        .offset(x: -17, y: -211)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 13) {
                    Label("LET’S EXPLORE", systemImage: "sparkles")
                        .font(.system(.caption2, design: .rounded, weight: .heavy))
                        .tracking(1)
                        .foregroundStyle(WelcomePalette.gold)
                    Text("Big stories.\nBrave you.")
                        .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                        .tracking(-0.8)
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Step into a Bible\nstory. Be part of it.")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(Color(hex: "#D8EADF"))
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        Text("Adventures")
                        Image(systemName: "arrow.right").fontWeight(.heavy)
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(WelcomePalette.ink)
                    .padding(.horizontal, 15).padding(.vertical, 11)
                    .background(WelcomePalette.gold, in: Capsule())
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(23)
                .padding(.trailing, typeSize.isAccessibilitySize ? 0 : 115)
            }
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white.opacity(0.5), lineWidth: 1))
            .shadow(color: WelcomePalette.teal.opacity(0.18), radius: 14, y: 8)
        }
        .buttonStyle(WelcomePressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Adventures. Choose a Bible story to explore.")
        .accessibilityAddTraits(.isButton)
    }

    private var toolkit: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .firstTextBaseline) {
                Text("Your adventure kit")
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(WelcomePalette.ink)
                Spacer()
                Image(systemName: "sparkle")
                    .foregroundStyle(Color(hex: "#BC9660"))
                    .accessibilityHidden(true)
            }
            if typeSize.isAccessibilitySize {
                VStack(spacing: 13) { albumTile; verseTile }
            } else {
                HStack(alignment: .top, spacing: 13) { albumTile; verseTile }
            }
        }
    }

    private var albumTile: some View {
        kitTile(title: "Hero Album", subtitle: "Meet your heroes", symbol: "person.2.fill", color: Color(hex: "#7053AC"), background: Color(hex: "#EDE5FB"), image: "album") { destination = .album }
    }

    private var verseTile: some View {
        kitTile(title: "Verse Power-Up", subtitle: "Words to grow by", symbol: "bolt.fill", color: Color(hex: "#A25D27"), background: Color(hex: "#FBE6CC"), image: "scroll") { destination = .verse }
    }

    private func kitTile(title: String, subtitle: String, symbol: String, color: Color, background: Color, image: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Image(systemName: symbol)
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13, weight: .heavy))
                }
                .foregroundStyle(color)
                Image(image)
                    .resizable().scaledToFill()
                    .frame(height: 92)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .accessibilityHidden(true)
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(WelcomePalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(color)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(15)
            .background(background, in: RoundedRectangle(cornerRadius: 25))
            .overlay(RoundedRectangle(cornerRadius: 25).stroke(.white.opacity(0.9), lineWidth: 1.5))
        }
        .buttonStyle(WelcomePressStyle())
        .accessibilityElement(children: .combine)
    }

    private var courageCard: some View {
        Button { destination = .david } label: {
            HStack(spacing: 13) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 29, weight: .semibold))
                    .foregroundStyle(Color(hex: "#C0832A"))
                    .frame(width: 53, height: 60)
                    .background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 18))
                    .rotationEffect(.degrees(-7))
                VStack(alignment: .leading, spacing: 5) {
                    Text("A LITTLE COURAGE")
                        .font(.system(.caption2, design: .rounded, weight: .heavy))
                        .tracking(1.3)
                        .foregroundStyle(Color(hex: "#9D7132"))
                    Text("Small shepherd. Big heart.")
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(WelcomePalette.ink)
                    Text("Discover David’s adventure")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(Color(hex: "#856F4E"))
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Color(hex: "#9D7132"))
            }
            .padding(17)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "#FFF0CD"), in: RoundedRectangle(cornerRadius: 25))
        }
        .buttonStyle(WelcomePressStyle())
        .accessibilityElement(children: .combine)
    }
}

private struct WelcomePressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

private struct WelcomeTrail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.42, y: rect.height * 1.08))
        path.addCurve(to: CGPoint(x: rect.width * 0.90, y: rect.height * 0.06),
                      control1: CGPoint(x: rect.width * 1.04, y: rect.height * 0.85),
                      control2: CGPoint(x: rect.width * 0.38, y: rect.height * 0.12))
        return path
    }
}
