import SwiftUI

struct RoaringBeastGame: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onComplete: (() -> Void)? = nil
    @StateObject private var game = RoaringRunController()

    var body: some View {
        ZStack {
            RoaringSceneView(controller: game)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .gesture(swipe)
                .accessibilityHidden(true)

            LinearGradient(stops: [
                .init(color: Color(hex: "#172C28").opacity(0.72), location: 0),
                .init(color: .clear, location: 0.3),
                .init(color: .clear, location: 0.75),
                .init(color: Color(hex: "#172C28").opacity(0.45), location: 1)
            ], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea().allowsHitTesting(false)

            if game.phase == .countdown {
                VStack(spacing: 12) {
                    Text("FIND YOUR COURAGE")
                        .font(.system(size: 10, weight: .heavy, design: .rounded)).tracking(3)
                    Text("\(game.hud.countdown)")
                        .font(.system(size: 100, weight: .medium, design: .serif))
                        .contentTransition(.numericText())
                        .shadow(color: .black.opacity(0.2), radius: 16)
                    Text("Read the path. Trust your feet.")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(BeastPalette.cream)
                .allowsHitTesting(false)
            }

            Color(hex: "#EDB25B").opacity(game.hud.hitFlash * 0.16)
                .ignoresSafeArea().allowsHitTesting(false)
        }
        .overlay(alignment: .top) {
            if game.phase == .running || game.phase == .countdown {
                RoaringHUDView(hud: game.hud, soundOn: game.soundOn,
                               onBack: { dismiss() }, onSound: game.toggleSound, onPause: game.pause)
                    .padding(.horizontal, 20).padding(.top, 8)
            }
        }
        .overlay(alignment: .bottom) {
            if game.phase == .running {
                VStack(spacing: 14) {
                    Text(game.hud.warning.isEmpty ? "SWIPE TO DODGE · SWIPE UP TO JUMP" : game.hud.warning)
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(game.hud.warning.isEmpty ? BeastPalette.cream.opacity(0.7) : BeastPalette.gold)
                        .padding(.horizontal, 13).padding(.vertical, 8)
                        .background(BeastPalette.ink.opacity(0.68), in: Capsule())
                        .accessibilityAddTraits(.updatesFrequently)
                    HStack(spacing: 16) {
                        RoaringControl(icon: "arrow.left", label: "Dodge left") { game.move(-1) }
                        Button(action: game.jump) {
                            Label("Jump", systemImage: "arrow.up")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(BeastPalette.cream)
                                .frame(width: 124, height: 50)
                                .background(BeastPalette.ink.opacity(0.78), in: Capsule())
                                .overlay(Capsule().stroke(BeastPalette.gold.opacity(0.5), lineWidth: 1))
                        }
                        .buttonStyle(RoaringPressStyle())
                        RoaringControl(icon: "arrow.right", label: "Dodge right") { game.move(1) }
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .overlay {
            switch game.phase {
            case .ready:
                RoaringIntro(onStart: game.start, onBack: { dismiss() })
            case .paused:
                RoaringEndPanel(mode: .paused, hud: game.hud, best: game.bestMeters,
                                onPrimary: game.resume, onReplay: game.start, onBack: { dismiss() })
            case .caught:
                RoaringEndPanel(mode: .caught, hud: game.hud, best: game.bestMeters,
                                onPrimary: game.start, onReplay: game.start, onBack: { dismiss() })
            case .finished:
                RoaringEndPanel(mode: .won, hud: game.hud, best: game.bestMeters,
                                onPrimary: { dismiss() }, onReplay: game.start, onBack: { dismiss() })
            default: EmptyView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar, .tabBar)
        .onAppear {
            game.onComplete = onComplete
            game.reduceMotion = reduceMotion
            game.attach()
        }
        .onDisappear { game.detach() }
        .onChange(of: scenePhase) { _, value in if value != .active { game.pause() } }
        .onChange(of: reduceMotion) { _, value in game.reduceMotion = value }
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 22).onEnded { value in
            let dx = value.translation.width; let dy = value.translation.height
            if abs(dx) > abs(dy), abs(dx) > 28 { game.move(dx > 0 ? 1 : -1) }
            else if dy < -30 { game.jump() }
        }
    }
}

#Preview {
    NavigationStack { RoaringBeastGame() }
}
