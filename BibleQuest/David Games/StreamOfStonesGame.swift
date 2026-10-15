import SwiftUI
import SpriteKit

struct StreamOfStonesGame: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var game = StreamGuardController()
    var onComplete: (() -> Void)? = nil

    var body: some View {
        GeometryReader { geometry in
            let fullWidth = geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing
            let fullHeight = geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom
            let compact = geometry.size.width > geometry.size.height * 1.3
            ZStack {
                SpriteView(scene: game.scene,preferredFramesPerSecond: 60,options: [.allowsTransparency])
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                // Native buttons provide generous touch targets and VoiceOver activation.
                if game.phase == .playing {
                    ForEach(game.targets) { target in
                        Button { game.shoo(target.id) } label: {
                            Color.clear.frame(width: max(68,94 * target.scale),height: max(68,94 * target.scale))
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .position(x: fullWidth * target.x - geometry.safeAreaInsets.leading,
                                  y: fullHeight * (1 - target.y) - geometry.safeAreaInsets.top)
                        .accessibilityLabel("Shoo approaching bird \(target.id)")
                        .accessibilityHint("Protect the stones in David’s pouch")
                    }
                }
                if game.phase == .ready {
                    StreamIntro(onStart: game.start,onBack: { dismiss() })
                } else {
                    VStack(spacing: 0) {
                        LinearGradient(colors: [StreamPalette.ink.opacity(0.91),StreamPalette.ink.opacity(0.58),.clear],
                                       startPoint: .top,endPoint: .bottom)
                            .frame(height: compact ? 155 : 205)
                        Spacer(minLength: 0)
                    }
                    .ignoresSafeArea().allowsHitTesting(false)
                    VStack {
                        StreamHUD(hud: game.hud,soundOn: game.soundOn,onBack: { dismiss() },
                                  onSound: game.toggleSound,onPause: game.pause)
                        Spacer(minLength: 0)
                        if game.phase == .playing {
                            StreamCallControl(charge: game.hud.charge,onCall: game.call)
                                .frame(maxWidth: compact ? 270 : 345)
                                .frame(maxWidth: .infinity,alignment: compact ? .trailing : .center)
                                .padding(.bottom,10)
                        }
                    }
                    .padding(.horizontal,20).padding(.top,10)
                    .accessibilityHidden(game.phase == .paused || game.resultVisible)
                    .allowsHitTesting(game.phase != .paused && !game.resultVisible)
                    .opacity(game.resultVisible ? 0 : 1)
                    if game.phase == .countdown {
                        VStack(spacing: 12) {
                            Text("FIND YOUR STILLNESS").font(.system(size: 10,weight: .heavy,design: .rounded)).tracking(3)
                            Text("\(game.hud.countdown)").font(.system(size: 91,weight: .regular,design: .serif)).monospacedDigit()
                            Text("Watch the wings. Guard the stones.").font(.system(size: 12,weight: .medium,design: .rounded))
                        }
                        .foregroundStyle(StreamPalette.cream)
                        .shadow(color: StreamPalette.ink.opacity(0.5),radius: 15)
                        .allowsHitTesting(false)
                    }
                    if game.phase == .paused {
                        StreamResultPanel(mode: .paused,hud: game.hud,best: game.best,
                                          onPrimary: game.resume,onReplay: game.start,onBack: { dismiss() })
                    } else if game.resultVisible {
                        StreamResultPanel(mode: game.phase == .won ? .won : .lost,hud: game.hud,best: game.best,
                                          onPrimary: game.start,onReplay: game.start,onBack: { dismiss() })
                            .transition(.opacity)
                    }
                }
            }
        }
        .background(StreamPalette.ink.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden,for: .navigationBar,.tabBar)
        .onAppear { game.onComplete = onComplete; game.reduceMotion = reduceMotion; game.attach() }
        .onDisappear { game.detach() }
        .onChange(of: reduceMotion) { _, value in game.reduceMotion = value }
        .onChange(of: scenePhase) { _, value in if value != .active { game.pause() } }
        .animation(.easeInOut(duration: 0.24),value: game.resultVisible)
    }
}
