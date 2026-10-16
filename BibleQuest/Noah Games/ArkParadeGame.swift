import SwiftUI

struct ArkParadeGame: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var controller = ArkParadeController()
    @State private var showJournal = false
    var onComplete: (() -> Void)? = nil
    var onExit: (() -> Void)? = nil
    private func exit() { controller.pause(); if let onExit { onExit() } else { dismiss() } }
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height*1.25
            let phase = controller.round.phase
            let overlay = [.paused,.won].contains(phase)
            ZStack {
                GeometryReader { bg in
                    Image("ParadeClearing").resizable().scaledToFill().frame(width: bg.size.width,height: bg.size.height).clipped()
                }.ignoresSafeArea().accessibilityHidden(true)
                LinearGradient(stops: [.init(color: ParadePalette.ink.opacity(0.92),location: 0),.init(color: ParadePalette.ink.opacity(0.14),location: 0.24),.init(color: .clear,location: 0.52),.init(color: ParadePalette.ink.opacity(0.95),location: 1)],startPoint: .top,endPoint: .bottom).ignoresSafeArea().allowsHitTesting(false)
                if phase == .intro {
                    ParadeIntro(controller: controller,wide: wide,exit: exit,journal: openJournal)
                } else {
                    Group {
                        if wide {
                            HStack(spacing: 12) {
                                VStack(spacing: 10) {
                                    ParadeHeader(controller: controller,exit: exit,journal: openJournal)
                                    Spacer(minLength: 0)
                                    instructions
                                    Spacer(minLength: 0)
                                    footer
                                }.frame(width: min(310,geo.size.width*0.38))
                                ArkParadeScene(controller: controller).frame(maxWidth: .infinity,maxHeight: .infinity)
                            }.padding(.horizontal,16).padding(.vertical,4)
                        } else {
                            VStack(spacing: 4) {
                                ParadeHeader(controller: controller,exit: exit,journal: openJournal).padding(.horizontal,20)
                                instructions.padding(.horizontal,24).frame(height: 80)
                                Spacer(minLength: 0)
                                ArkParadeScene(controller: controller).padding(.horizontal,8).frame(maxWidth: 560)
                                Spacer(minLength: 0)
                                footer.padding(.horizontal,20).padding(.bottom,4)
                            }.padding(.top,4)
                        }
                    }.accessibilityHidden(overlay || phase == .discovery).allowsHitTesting(!overlay && phase != .discovery)
                    if phase == .discovery {
                        VStack { Spacer(); ParadeDiscovery(controller: controller).frame(maxWidth: 460).padding(20) }
                            .background(ParadePalette.ink.opacity(0.2)).transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    if overlay { ParadeFinishPanel(controller: controller,exit: exit,journal: openJournal).transition(.opacity) }
                }
            }.onChange(of: wide) { _,_ in controller.pause() }
        }.background(ParadePalette.ink).preferredColorScheme(.dark).toolbar(.hidden,for: .navigationBar,.tabBar)
            .onAppear { controller.onComplete = onComplete; controller.reduceMotion = reduceMotion; controller.attach() }
            .onDisappear { controller.detach() }
            .onChange(of: scenePhase) { _,phase in if phase != .active { controller.pause() } }
            .onChange(of: reduceMotion) { _,value in controller.reduceMotion = value }
            .sheet(isPresented: $showJournal,onDismiss: { controller.pause() }) { ParadeJournal(controller: controller) }
            .animation(.easeOut(duration: reduceMotion ? 0.1 : 0.35),value: controller.round.phase == .discovery)
    }
    private func openJournal() { controller.pause(); showJournal = true }
    private var instructions: some View {
        let r = controller.round
        return HStack(spacing: 12) {
            VStack(alignment: .leading,spacing: 5) {
                Text(r.phase == .finding ? "LISTEN · LOOK · REUNITE" : r.phase == .tracing ? "MAKE THEIR LITTLE ADVENTURE" : r.phase == .finale ? "EVERY ANIMAL MATTERS" : "TWO BY TWO, TOGETHER").font(.system(size: 7,weight: .bold)).tracking(2).foregroundStyle(ParadePalette.gold)
                Text(r.phase == .finding ? "Find my partner." : r.phase == .tracing ? "Draw a way home." : r.phase == .greeting ? "Hello, friend!" : r.phase == .finale ? "All aboard!" : "Follow your trail.")
                    .font(.system(size: 28,design: .serif)).foregroundStyle(ParadePalette.cream).lineLimit(1).minimumScaleFactor(0.7)
                Text(r.phase == .finding ? "The \(r.animal.name.lowercased()) is calling. Who answers?" : r.phase == .tracing ? "From the pair to the glowing ramp." : r.phase == .finale ? "Eight pairs. Sixteen animals. One safe place." : "Watch their footprints appear.")
                    .font(.system(size: 11,weight: .medium)).foregroundStyle(ParadePalette.cream.opacity(0.8))
            }.frame(maxWidth: .infinity,alignment: .leading)
            if r.phase == .finding || r.phase == .tracing {
                Button(action: r.phase == .finding ? controller.listen : controller.hint) {
                    Image(systemName: r.phase == .finding ? "waveform" : "sparkle.magnifyingglass")
                        .font(.system(size: 22,weight: .light)).foregroundStyle(ParadePalette.gold).frame(width: 48,height: 48)
                        .background(ParadePalette.forest.opacity(0.82),in: Circle()).overlay(Circle().strokeBorder(ParadePalette.gold.opacity(0.5)))
                }.buttonStyle(.plain).accessibilityLabel(r.phase == .finding ? "Hear the animal call" : "Show a trail hint")
            }
        }
    }
    private var footer: some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(),spacing: 6),count: 4),spacing: 7) {
                ForEach(ParadeAnimal.allCases) { animal in
                    let earned = controller.round.boarded.contains(animal)
                    ZStack {
                        Circle().fill(earned ? ParadePalette.gold.opacity(0.16) : .white.opacity(0.05))
                        Circle().strokeBorder(earned ? ParadePalette.gold.opacity(0.85) : .white.opacity(0.15),lineWidth: 1)
                        Image(animal.image).resizable().scaledToFit().padding(4).saturation(earned ? 1 : 0).opacity(earned ? 1 : 0.45)
                        if earned { Image(systemName: "checkmark.seal.fill").font(.system(size: 12)).foregroundStyle(ParadePalette.gold).offset(x: 14,y: 13) }
                    }.frame(width: 35,height: 35).accessibilityElement(children: .ignore).accessibilityLabel("\(animal.plural): \(earned ? "pair aboard" : "waiting")")
                }
                }.frame(maxWidth: 218)
                Spacer(minLength: 0)
                VStack(alignment: .trailing,spacing: 2) {
                    Text("\(controller.round.animalsAboard)").font(.system(size: 25,design: .serif)).contentTransition(.numericText())
                    Text("ABOARD").font(.system(size: 6,weight: .bold)).tracking(1.4).lineLimit(1).fixedSize()
                }.frame(minWidth: 42).foregroundStyle(ParadePalette.cream).accessibilityElement(children: .ignore).accessibilityLabel("\(controller.round.animalsAboard) of \(ArkParadeRound.animalCount) animals aboard")
            }
            HStack(spacing: 9) {
                Image(systemName: controller.round.phase == .tracing ? "hand.draw" : "ear.badge.waveform").font(.system(size: 17,weight: .light)).foregroundStyle(ParadePalette.gold).accessibilityHidden(true)
                Text(controller.time < controller.messageUntil ? controller.message : controller.round.phase == .finding ? "Tap an animal in the clearing. Listen to its call." : controller.round.phase == .tracing ? "Touch the pair, then draw your trail to the ramp." : controller.round.phase == .finale ? "You made room for every little life." : "A little kindness goes a long way.")
                    .font(.system(size: 11,weight: .medium)).lineSpacing(3).foregroundStyle(ParadePalette.cream.opacity(0.95)).frame(maxWidth: .infinity,alignment: .leading)
                if controller.round.phase == .finding {
                    Button(action: controller.hint) { Image(systemName: "sparkles").font(.system(size: 15)).frame(width: 40,height: 44) }.foregroundStyle(ParadePalette.gold).accessibilityLabel("Help me find the partner")
                }
            }.padding(.horizontal,13).frame(minHeight: 61).background(ParadePalette.ink.opacity(0.83),in: RoundedRectangle(cornerRadius: 17))
                .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(ParadePalette.mint.opacity(0.15)))
        }
    }
}

#Preview { ArkParadeGame() }
