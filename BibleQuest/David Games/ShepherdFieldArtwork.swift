import SwiftUI

struct ShepherdFieldBackdrop: View {
    var body: some View {
        GeometryReader { geometry in
            Image("ShepherdFieldLandscape")
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .overlay {
                    LinearGradient(stops: [
                        .init(color: Color(hex: "#102D23").opacity(0.78), location: 0),
                        .init(color: Color(hex: "#143529").opacity(0.26), location: 0.23),
                        .init(color: .clear, location: 0.4),
                        .init(color: .clear, location: 0.66),
                        .init(color: Color(hex: "#10281F").opacity(0.75), location: 1)
                    ], startPoint: .top, endPoint: .bottom)
                }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

struct ShepherdLambSprite: View {
    let index: Int
    var isMoving = false
    var highlighted = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathing = false

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color(hex: "#25371C").opacity(0.3))
                .frame(width: 45, height: 13)
                .blur(radius: 3)
                .offset(y: 26)
            if highlighted { ShepherdClueGlow() }
            Image("ShepherdLamb")
                .resizable()
                .scaledToFit()
                .scaleEffect(x: index.isMultiple(of: 2) ? 1 : -1, y: 1)
                .scaleEffect(breathing && !isMoving ? 1.035 : 1, anchor: .bottom)
                .rotationEffect(.degrees(isMoving ? -12 : (breathing ? 1.5 : -1.5)))
                .offset(y: breathing && !isMoving ? -3 : 0)
                .shadow(color: Color(hex: "#23351E").opacity(0.22), radius: 3, y: 3)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.6 + Double(index) * 0.08)
                .repeatForever(autoreverses: true)) { breathing = true }
        }
    }
}

struct ShepherdHidingPlace: View {
    let kind: ShepherdCoverKind
    let opened: Bool
    let highlighted: Bool
    let movesLeft: Bool
    let scale: CGFloat
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            ZStack {
                if highlighted { ShepherdClueGlow().frame(width: 110, height: 110) }
                Ellipse()
                    .fill(Color(hex: "#1F321D").opacity(0.34))
                    .frame(width: kind.width * 0.7, height: 21)
                    .blur(radius: 7)
                    .offset(y: kind.width * 0.24)
                Image(kind.asset)
                    .resizable()
                    .scaledToFit()
                    .shadow(color: Color(hex: "#29321B").opacity(0.25), radius: 5, y: 6)
            }
            .frame(width: kind.width, height: kind.width * 0.9)
            .contentShape(Ellipse())
            .rotationEffect(.degrees(opened ? (movesLeft ? -9 : 9) : 0), anchor: .bottom)
            .scaleEffect(opened ? 0.86 : 1)
            .offset(x: opened ? (movesLeft ? -62 : 62) : 0, y: opened ? -18 : 0)
            .opacity(opened ? 0.86 : 1)
            .scaleEffect(scale)
        }
        .buttonStyle(ShepherdPressStyle())
        .disabled(opened)
        .allowsHitTesting(!opened)
        .simultaneousGesture(DragGesture(minimumDistance: 16).onEnded { _ in
            if !opened { action() }
        })
        .animation(reduceMotion ? .easeOut(duration: 0.15) :
            .spring(response: 0.55, dampingFraction: 0.75), value: opened)
        .accessibilityHint("Moves this hiding place aside to look for a lamb")
    }
}

struct ShepherdClueGlow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: "#FFE497").opacity(0.36)).blur(radius: 12)
            Circle().stroke(Color(hex: "#FFF0B1").opacity(expanded ? 0.2 : 0.9), lineWidth: 2)
                .scaleEffect(expanded ? 1.25 : 0.8)
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { expanded = true }
        }
    }
}

struct ShepherdDiscoveryBurst: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "#FFE8A0"), lineWidth: 2)
                .frame(width: 48, height: 48)
                .scaleEffect(expanded ? 2.2 : 0.5)
                .opacity(expanded ? 0 : 0.9)
            ForEach(0..<10) { index in
                Circle()
                    .fill(Color(hex: index.isMultiple(of: 2) ? "#FFF5CF" : "#EFC76D"))
                    .frame(width: 4, height: 4)
                    .offset(x: cos(Double(index) * .pi / 5) * (expanded ? 55 : 8),
                            y: sin(Double(index) * .pi / 5) * (expanded ? 45 : 8))
                    .opacity(expanded ? 0 : 1)
            }
            Text("+1 safe")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#FFF5CF"))
                .shadow(color: Color(hex: "#203B23"), radius: 4)
                .offset(y: expanded ? -70 : -28)
                .opacity(expanded ? 0 : 1)
        }
        .onAppear {
            withAnimation(.easeOut(duration: reduceMotion ? 0.18 : 0.85)) { expanded = true }
        }
        .accessibilityHidden(true)
    }
}

struct ShepherdFieldAtmosphere: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: reduceMotion || scenePhase != .active)) { timeline in
            Canvas { context, size in
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                for index in 0..<24 {
                    let seed = Double(index)
                    let x = (sin(seed * 127.1) + 1) / 2 * size.width
                    let y = (sin(seed * 311.7) + 1) / 2 * size.height
                    let drift = sin(time * 0.22 + seed) * 16
                    let alpha = (sin(time * 0.6 + seed) + 1) * 0.18 + 0.12
                    let rect = CGRect(x: x + drift, y: y + drift * 1.5, width: 2.5, height: 2.5)
                    context.fill(Path(ellipseIn: rect), with: .color(Color(hex: "#FFF2BB").opacity(alpha)))
                }
                // Two tiny butterflies follow soft loops through the meadow.
                if !reduceMotion {
                    for index in 0..<2 {
                        let phase = time * 0.16 + Double(index) * 3.1
                        let point = CGPoint(x: size.width * (0.5 + sin(phase) * 0.29),
                                            y: size.height * (0.46 + cos(phase * 0.7) * 0.17))
                        let wings = abs(sin(time * 6 + Double(index))) * 3 + 1
                        let left = CGRect(x: point.x - wings, y: point.y, width: wings, height: 4)
                        let right = CGRect(x: point.x, y: point.y, width: wings, height: 4)
                        context.fill(Path(ellipseIn: left), with: .color(Color(hex: "#FFF2C3").opacity(0.8)))
                        context.fill(Path(ellipseIn: right), with: .color(Color(hex: "#FFF2C3").opacity(0.8)))
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct ShepherdPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
