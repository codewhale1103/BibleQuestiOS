import SwiftUI

struct RainbowPromiseGame: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var controller = RainbowPromiseController()
    @State private var showLearning = false
    var onComplete: (() -> Void)? = nil
    var onExit: (() -> Void)? = nil
    private func exit() {
        if let onExit { onExit() } else { dismiss() }
    }
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height*1.3
            let phase = controller.round.phase
            let modal = [.question,.lesson,.paused,.won].contains(phase)
            let chromeOpacity = modal || phase == .reveal ? 0.0 : 1.0
            let life = Double(controller.round.completedBands)/7
            ZStack {
                GeometryReader { bg in Image("RainbowPromiseValley").resizable().scaledToFill().frame(width: bg.size.width,height: bg.size.height).clipped() }.ignoresSafeArea().accessibilityHidden(true)
                PromisePalette.ink.opacity((1-life)*0.38).ignoresSafeArea().allowsHitTesting(false)
                LinearGradient(colors: [PromisePalette.ink.opacity(0.76),.clear,PromisePalette.ink.opacity(0.30)],startPoint: .top,endPoint: .bottom).ignoresSafeArea().allowsHitTesting(false)
                PromiseLivingValley(controller: controller).ignoresSafeArea()
                if phase == .intro {
                    PromiseIntro(controller: controller,exit: exit,info: { showLearning = true })
                } else {
                    Group {
                        if wide {
                            HStack(spacing: 18) {
                                VStack(spacing: 14) {
                                    PromiseHeader(controller: controller,exit: exit).opacity(chromeOpacity)
                                    Spacer(minLength: 0)
                                    instruction.opacity(chromeOpacity)
                                    footer.opacity(chromeOpacity)
                                }.frame(width: 300)
                                RainbowPromiseBoard(controller: controller)
                            }.padding(.horizontal,20).padding(.vertical,6)
                        } else {
                            VStack(spacing: 5) {
                                PromiseHeader(controller: controller,exit: exit).padding(.horizontal,20).padding(.top,5).opacity(chromeOpacity)
                                instruction.frame(height: 70).opacity(chromeOpacity)
                                RainbowPromiseBoard(controller: controller)
                                footer.padding(.horizontal,20).padding(.bottom,7).opacity(chromeOpacity)
                            }
                        }
                    }.accessibilityHidden(modal || phase == .reveal).allowsHitTesting(!modal && phase != .reveal)
                    if phase == .reveal {
                        ZStack {
                            PromisePalette.ink.opacity(0.35)
                            Image("RainbowPromiseDove").resizable().scaledToFit().frame(width: wide ? 160 : 180)
                                .position(x: geo.size.width*(controller.reduceMotion ? 0.76 : -0.2+controller.round.phaseTime/4.2*1.4),y: geo.size.height*(wide ? 0.25 : 0.30)+(controller.reduceMotion ? 0 : sin(controller.round.phaseTime*1.8)*15))
                            VStack(spacing: 12) {
                                Text("A SIGN FOR GENERATIONS").font(.system(size: 8,weight: .bold)).tracking(3).foregroundStyle(PromisePalette.gold)
                                Text("Let the promise\nshine.").font(.system(size: wide ? 36 : 45,design: .serif)).multilineTextAlignment(.center).foregroundStyle(PromisePalette.cream)
                            }
                        }.ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
                    }
                }
                if phase == .question || phase == .lesson { PromiseDiscoveryPanel(controller: controller).transition(.opacity) }
                if phase == .paused || phase == .won { PromiseRoundPanel(controller: controller,exit: exit,info: { showLearning = true }).transition(.opacity) }
            }.onChange(of: wide) { _,_ in controller.pause() }
        }.background(PromisePalette.ink).preferredColorScheme(.dark).toolbar(.hidden,for: .navigationBar,.tabBar)
            .onAppear { controller.onComplete = onComplete; controller.reduceMotion = reduceMotion; controller.attach() }
            .onDisappear { controller.detach() }
            .onChange(of: scenePhase) { _,phase in if phase != .active { controller.pause() } }
            .onChange(of: reduceMotion) { _,value in controller.reduceMotion = value }
            .sheet(isPresented: $showLearning) { PromiseLearningSheet() }
            .animation(.easeOut(duration: reduceMotion ? 0.1 : 0.45),value: controller.round.phase == .won)
    }
    private var instruction: some View {
        VStack(spacing: 5) {
            Text(controller.round.phase == .bloom ? "A RIBBON OF LIGHT" : controller.round.phase == .choose ? "FIND THE NEXT COLOR" : "FOLLOW THE GLOW")
                .font(.system(size: 7,weight: .bold)).tracking(2.4).foregroundStyle(PromisePalette.gold)
            Text(controller.round.phase == .bloom ? "Beautifully woven." : controller.round.phase == .choose ? controller.round.color.name : "Weave \(controller.round.color.name.lowercased()).")
                .font(.system(size: 28,design: .serif)).foregroundStyle(PromisePalette.cream)
            if controller.round.phase == .choose && controller.round.completedBands == 3 {
                Text("Sunlight and raindrops reveal a world of color.").font(.system(size: 10)).foregroundStyle(PromisePalette.cream.opacity(0.7))
            }
        }.frame(maxWidth: .infinity)
    }
    private var footer: some View {
        VStack(spacing: 9) {
            if controller.round.phase == .choose { PromiseColorChoices(controller: controller) }
            else {
                HStack(spacing: 7) {
                    ForEach(0..<5,id: \.self) { index in Circle().fill(index < controller.round.checkpoint ? PromisePalette.gold : .white.opacity(0.22)).frame(width: 5,height: 5) }
                }.frame(height: 16).accessibilityLabel("\(controller.round.checkpoint) of 5 guiding stars")
            }
            Text(controller.visualTime < controller.messageUntil ? controller.message : controller.round.phase == .choose ? "Choose a color to begin its ribbon." : "Trace the curve, or tap the stars in order.")
                .font(.system(size: 11,weight: .medium)).lineSpacing(3).foregroundStyle(PromisePalette.cream.opacity(0.88)).multilineTextAlignment(.center).frame(maxWidth: .infinity,minHeight: 32)
                .padding(.horizontal,12).padding(.vertical,7).background(PromisePalette.ink.opacity(0.76),in: RoundedRectangle(cornerRadius: 14))
        }.frame(height: 145,alignment: .bottom)
    }
}
#Preview { NavigationStack { RainbowPromiseGame() } }
