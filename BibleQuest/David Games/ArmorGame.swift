import SwiftUI

struct ArmorGame: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var session = ArmorCampSession()
    var onComplete: (() -> Void)? = nil

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height * 1.3
            let modal = session.round.phase == .paused || session.round.phase == .completed
            ZStack {
                ArmorCampStage(session: session).ignoresSafeArea()
                    .accessibilityElement(children: .contain)
                    .accessibilityHidden(modal || session.round.phase == .intro)
                    .allowsHitTesting(!modal)
                if session.round.phase == .intro {
                    ArmorCampIntro(session: session,exit: { dismiss() })
                } else {
                    LinearGradient(colors: [ArmorCampPalette.ink.opacity(0.9),.clear],startPoint: .top,endPoint: .bottom)
                        .frame(height: wide ? 160 : 240).frame(maxHeight: .infinity,alignment: .top).ignoresSafeArea().allowsHitTesting(false)
                    VStack {
                        ArmorCampHUD(session: session,exit: { dismiss() })
                            .frame(maxWidth: wide ? 300 : 600).frame(maxWidth: .infinity,alignment: wide ? .leading : .center)
                        Spacer(minLength: 0)
                        ArmorCampStepButton(session: session)
                            .frame(maxWidth: wide ? 260 : 350).frame(maxWidth: .infinity,alignment: wide ? .leading : .center)
                    }
                    .padding(.horizontal,wide ? 24 : 20).padding(.top,8).padding(.bottom,10)
                    .accessibilityHidden(modal).allowsHitTesting(!modal)
                }
                if session.round.phase == .paused {
                    ArmorCampPause(session: session,exit: { dismiss() }).transition(.opacity)
                }
                if session.round.phase == .completed {
                    ArmorCampVictory(session: session,exit: { dismiss() }).transition(.opacity)
                }
            }
        }
        .background(ArmorCampPalette.ink)
        .toolbar(.hidden,for: .navigationBar,.tabBar)
        .preferredColorScheme(.dark)
        .onAppear { session.onComplete = onComplete; session.reduceMotion = reduceMotion; session.attach() }
        .onDisappear { session.detach() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { session.pause() } }
        .onChange(of: reduceMotion) { _, value in session.reduceMotion = value }
        .animation(.easeOut(duration: reduceMotion ? 0.15 : 0.45),value: session.round.phase == .completed)
    }
}

#Preview { NavigationStack { ArmorGame() } }
