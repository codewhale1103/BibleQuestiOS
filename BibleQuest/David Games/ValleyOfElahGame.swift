import SwiftUI

struct ValleyOfElahGame: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var controller = ElahBalanceController()
    var onComplete: (() -> Void)? = nil

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height * 1.3
            let phase = controller.hud.phase
            let modal = phase == .paused || phase == .lost || phase == .won
            ZStack {
                GeometryReader { background in
                    Image("ElahValleySky").resizable().scaledToFill()
                        .frame(width: background.size.width,height: background.size.height).clipped()
                }.ignoresSafeArea().accessibilityHidden(true)
                ElahSceneView(controller: controller).ignoresSafeArea().accessibilityHidden(true)
                if phase == .intro {
                    Image("ArmorCampDavid").resizable().scaledToFit()
                        .frame(height: geo.size.height * (wide ? 0.95 : 0.57))
                        .shadow(color: ElahPalette.ink.opacity(0.35),radius: 18,y: 8)
                        .position(x: geo.size.width * (wide ? 0.76 : 0.53),y: geo.size.height * (wide ? 0.49 : 0.31))
                        .allowsHitTesting(false).accessibilityHidden(true)
                    ElahIntro(controller: controller,exit: { dismiss() })
                } else {
                    LinearGradient(colors: [ElahPalette.ink.opacity(0.88),.clear],startPoint: .top,endPoint: .bottom)
                        .frame(height: wide ? 190 : 250).frame(maxHeight: .infinity,alignment: .top).ignoresSafeArea().allowsHitTesting(false)
                    LinearGradient(colors: [.clear,ElahPalette.ink.opacity(0.8)],startPoint: .top,endPoint: .bottom)
                        .frame(height: 260).frame(maxHeight: .infinity,alignment: .bottom).ignoresSafeArea().allowsHitTesting(false)
                    RadialGradient(colors: [.clear,ElahPalette.amber.opacity(controller.hud.danger*0.42)],center: .center,startRadius: geo.size.width*0.35,endRadius: geo.size.height*0.75).ignoresSafeArea().allowsHitTesting(false)
                    VStack {
                        ElahHUD(controller: controller,exit: { dismiss() }).frame(maxWidth: wide ? 320 : 600).frame(maxWidth: .infinity,alignment: wide ? .leading : .center)
                        Spacer(minLength: 0)
                        if !controller.hud.markerMessage.isEmpty {
                            Text(controller.hud.markerMessage).font(.system(size: 22,design: .serif)).foregroundStyle(ElahPalette.cream).padding(.horizontal,18).padding(.vertical,12)
                                .background(ElahPalette.ink.opacity(0.75),in: Capsule()).transition(.opacity)
                        }
                        Spacer(minLength: 0)
                        ElahBalanceControls(controller: controller).frame(maxWidth: wide ? 345 : 440).frame(maxWidth: .infinity,alignment: wide ? .leading : .center)
                    }.padding(.horizontal,wide ? 24 : 20).padding(.top,8).padding(.bottom,10).accessibilityHidden(modal).allowsHitTesting(!modal)
                    if phase == .countdown { ElahCountdown(count: controller.hud.countdown).offset(x: wide ? geo.size.width*0.16 : 0,y: -30) }
                }
                if phase == .paused { ElahRoundPanel(controller: controller,kind: .paused,exit: { dismiss() }).transition(.opacity) }
                if phase == .lost { ElahRoundPanel(controller: controller,kind: .lost,exit: { dismiss() }).transition(.opacity) }
                if phase == .won { ElahRoundPanel(controller: controller,kind: .won,exit: { dismiss() }).transition(.opacity) }
            }
        }
        .background(ElahPalette.ink).preferredColorScheme(.dark)
        .toolbar(.hidden,for: .navigationBar,.tabBar)
        .onAppear { controller.onComplete = onComplete; controller.reduceMotion = reduceMotion; controller.attach() }
        .onDisappear { controller.detach() }
        .onChange(of: scenePhase) { _, value in if value != .active { controller.pause() } }
        .onChange(of: reduceMotion) { _, value in controller.reduceMotion = value }
        .animation(.easeOut(duration: reduceMotion ? 0.15 : 0.4),value: controller.hud.phase == .won)
        .animation(.easeOut(duration: 0.25),value: controller.hud.markerMessage)
    }
}
#Preview { NavigationStack { ValleyOfElahGame() } }
