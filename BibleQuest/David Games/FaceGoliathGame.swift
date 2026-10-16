import SwiftUI

struct FaceGoliathGame: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var controller = GoliathSlingController()
    @State private var fineAim = UIAccessibility.isVoiceOverRunning
    @State private var dragStarted = false
    @State private var dragActive = false
    @State private var initialPull = SlingPoint.zero
    var onComplete: (() -> Void)? = nil
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height*1.3
            let phase = controller.hud.phase
            let modal = [.paused,.won,.lost].contains(phase)
            ZStack {
                GoliathArenaView(controller: controller).ignoresSafeArea().accessibilityHidden(true)
                if phase == .intro { SlingIntro(controller: controller,exit: { dismiss() }) }
                else {
                    LinearGradient(colors: [SlingPalette.ink.opacity(0.9),.clear],startPoint: .top,endPoint: .bottom)
                        .frame(height: wide ? 185 : 245).frame(maxHeight: .infinity,alignment: .top).ignoresSafeArea().allowsHitTesting(false)
                    LinearGradient(colors: [.clear,SlingPalette.ink.opacity(0.65)],startPoint: .top,endPoint: .bottom)
                        .frame(height: 200).frame(maxHeight: .infinity,alignment: .bottom).ignoresSafeArea().allowsHitTesting(false)
                    VStack {
                        SlingHUD(controller: controller,exit: { dismiss() }).frame(maxWidth: wide ? 310 : 600).frame(maxWidth: .infinity,alignment: wide ? .leading : .center)
                        Spacer(minLength: 0)
                        SlingAimControls(controller: controller,expanded: $fineAim).frame(maxWidth: wide ? 340 : 440)
                    }.padding(.horizontal,wide ? 24 : 20).padding(.top,8).padding(.bottom,10).accessibilityHidden(modal).allowsHitTesting(!modal)
                }
                if phase == .paused { SlingRoundPanel(controller: controller,kind: .paused,exit: { dismiss() }).transition(.opacity) }
                if phase == .lost { SlingRoundPanel(controller: controller,kind: .lost,exit: { dismiss() }).transition(.opacity) }
                if phase == .won { SlingRoundPanel(controller: controller,kind: .won,exit: { dismiss() }).transition(.opacity) }
            }
            .coordinateSpace(name: "SlingInput")
            .simultaneousGesture(DragGesture(minimumDistance: 0,coordinateSpace: .named("SlingInput"))
                .onChanged { value in
                    guard controller.hud.phase == .ready else { return }
                    let scale = max(0.001,controller.scene.size.width/1000)
                    if !dragStarted {
                        dragStarted = true
                        let point = SlingPoint(x: (value.startLocation.x+geo.safeAreaInsets.leading)/scale,y: (controller.scene.size.height-value.startLocation.y-geo.safeAreaInsets.top)/scale)
                        let arena = controller.round.arena
                        dragActive = (point-arena.anchor).length < 150 || (point-controller.round.pouch).length < 120
                        initialPull = controller.round.pull
                    }
                    if dragActive { controller.pull(initialPull+SlingPoint(x: value.translation.width/scale,y: -value.translation.height/scale)) }
                }
                .onEnded { value in
                    if dragActive {
                        let scale = max(0.001,controller.scene.size.width/1000)
                        controller.pull(initialPull+SlingPoint(x: value.translation.width/scale,y: -value.translation.height/scale))
                        controller.release()
                    }
                    dragStarted = false; dragActive = false
                })
            .onChange(of: controller.hud.phase) { _, phase in if phase == .paused || phase == .intro { dragStarted = false; dragActive = false } }
        }
        .background(SlingPalette.ink).preferredColorScheme(.dark).toolbar(.hidden,for: .navigationBar,.tabBar)
        .onAppear { controller.onComplete = onComplete; controller.reduceMotion = reduceMotion; controller.attach() }
        .onDisappear { controller.detach() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { controller.pause() } }
        .onChange(of: reduceMotion) { _, value in controller.reduceMotion = value }
        .animation(.easeOut(duration: reduceMotion ? 0.15 : 0.4),value: controller.hud.phase == .won)
        .animation(.easeOut(duration: 0.2),value: fineAim)
    }
}
#Preview { NavigationStack { FaceGoliathGame() } }
