import SwiftUI

struct VictorySongGame: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var controller = VictorySongController()
    @State private var gentle = UIAccessibility.isVoiceOverRunning
    var onComplete: (() -> Void)? = nil
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height*1.3
            let phase = controller.round.phase
            let modal = [.paused,.won,.practice].contains(phase)
            ZStack {
                GeometryReader { background in
                    Image("VictoryTwilightCamp").resizable().scaledToFill().frame(width: background.size.width,height: background.size.height).clipped()
                }.ignoresSafeArea().accessibilityHidden(true)
                LinearGradient(colors: [VictoryPalette.ink.opacity(0.45),.clear,VictoryPalette.ink.opacity(0.6)],startPoint: .top,endPoint: .bottom).ignoresSafeArea()
                VictoryCampLights(controller: controller).ignoresSafeArea()
                if phase == .intro { VictorySongIntro(controller: controller,gentle: $gentle,exit: { dismiss() }) }
                else {
                    if wide {
                        HStack(spacing: 10) {
                            VStack(spacing: 14) {
                                VictorySongHeader(controller: controller,exit: { dismiss() })
                                VictorySongPassage(controller: controller)
                                Image("VictoryDavidHarp").resizable().scaledToFit().frame(maxHeight: .infinity).padding(.horizontal,25).accessibilityHidden(true)
                            }.frame(width: min(300,geo.size.width*0.38))
                            VictoryHarpStage(controller: controller)
                        }.padding(.horizontal,18).padding(.top,5).accessibilityHidden(modal)
                    } else {
                        VStack(spacing: 5) {
                            VictorySongHeader(controller: controller,exit: { dismiss() }).padding(.horizontal,20)
                            VictorySongPassage(controller: controller)
                            VictoryHarpStage(controller: controller)
                            Text(controller.visualTime < controller.messageUntil ? controller.message : "PLUCK AT THE JEWELS · HOLD THE LONG RIBBONS")
                                .font(.system(size: 9,weight: .medium)).tracking(0.5).multilineTextAlignment(.center).foregroundStyle(VictoryPalette.cream.opacity(0.8))
                                .frame(minHeight: 26).padding(.horizontal,20).padding(.bottom,3)
                        }.padding(.top,5).accessibilityHidden(modal)
                    }
                    if phase == .countIn {
                        VStack(spacing: 8) {
                            Text("FIND YOUR RHYTHM").font(.system(size: 8,weight: .bold)).tracking(3)
                            Text("\(controller.round.countdown)").font(.system(size: 70,design: .serif)).contentTransition(.numericText())
                        }.foregroundStyle(VictoryPalette.cream).padding(24).background(VictoryPalette.ink.opacity(0.88),in: RoundedRectangle(cornerRadius: 24)).allowsHitTesting(false)
                    }
                    if phase == .finale {
                        VictoryFinaleBloom(controller: controller).allowsHitTesting(false).accessibilityHidden(true)
                        VStack(spacing: 10) {
                            Text("LET THE VALLEY SING").font(.system(size: 9,weight: .bold)).tracking(3).foregroundStyle(VictoryPalette.gold)
                            Text("Courage becomes\ngratitude.").font(.system(size: wide ? 34 : 42,design: .serif)).multilineTextAlignment(.center).foregroundStyle(VictoryPalette.cream)
                        }.frame(maxWidth: .infinity,maxHeight: .infinity).background(VictoryPalette.ink.opacity(0.55)).allowsHitTesting(false)
                    }
                }
                if modal { VictorySongPanel(controller: controller,gentle: controller.round.gentle,exit: { dismiss() }).transition(.opacity) }
            }
            .onChange(of: wide) { _,_ in controller.pause() }
        }.background(VictoryPalette.ink).preferredColorScheme(.dark).toolbar(.hidden,for: .navigationBar,.tabBar)
        .onAppear { controller.onComplete = onComplete; controller.reduceMotion = reduceMotion; controller.attach() }
        .onDisappear { controller.detach() }
        .onChange(of: scenePhase) { _,phase in if phase != .active { controller.pause() } }
        .onChange(of: reduceMotion) { _,value in controller.reduceMotion = value }
        .animation(.easeOut(duration: reduceMotion ? 0.1 : 0.4),value: controller.round.phase == .won)
    }
}
#Preview { NavigationStack { VictorySongGame() } }
