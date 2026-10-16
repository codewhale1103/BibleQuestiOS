import SwiftUI

struct ArkWorkshopGame: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @StateObject private var controller = ArkWorkshopController()
    @State private var boardFrame = CGRect.zero
    @State private var basketFrame = CGRect.zero
    @State private var showStory = false
    var onComplete: (() -> Void)? = nil
    var onExit: (() -> Void)? = nil
    private func exit() { if let onExit { onExit() } else { dismiss() } }
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height*1.3
            let phase = controller.round.phase
            let modal = [.listening,.discovery,.paused,.won,.reveal].contains(phase)
            ZStack {
                GeometryReader { bg in Image(controller.round.step == .timber && phase == .playing ? "ArkTimberGrove" : "NoahCallWorkshop").resizable().scaledToFill().frame(width: bg.size.width,height: bg.size.height).clipped() }.ignoresSafeArea().accessibilityHidden(true)
                LinearGradient(colors: [ArkWorkshopPalette.ink.opacity(phase == .intro ? 0.28 : 0.72),ArkWorkshopPalette.ink.opacity(0.08),ArkWorkshopPalette.ink.opacity(0.6)],startPoint: .top,endPoint: .bottom).ignoresSafeArea().allowsHitTesting(false)
                ArkLivingAir(controller: controller).ignoresSafeArea()
                if phase == .intro {
                    ArkWelcome(controller: controller,exit: exit,info: { showStory = true })
                } else {
                    Group {
                        if wide {
                            HStack(spacing: 5) {
                                VStack(spacing: 8) {
                                    ArkHeader(controller: controller,exit: exit)
                                    Spacer(minLength: 0)
                                    taskHeading
                                    ArkTaskTray(controller: controller,boardFrame: boardFrame,basketFrame: $basketFrame).opacity(phase == .playing ? 1 : 0)
                                }.frame(width: 310).opacity(modal ? 0 : 1)
                                ArkSceneBoard(controller: controller,boardFrame: $boardFrame,basketFrame: basketFrame)
                            }.padding(.horizontal,14).padding(.vertical,4)
                        } else {
                            VStack(spacing: 7) {
                                ArkHeader(controller: controller,exit: exit).padding(.horizontal,18).padding(.top,5).opacity(modal ? 0 : 1)
                                taskHeading.frame(height: 68).opacity(modal ? 0 : 1)
                                ArkSceneBoard(controller: controller,boardFrame: $boardFrame,basketFrame: basketFrame)
                                ArkTaskTray(controller: controller,boardFrame: boardFrame,basketFrame: $basketFrame).padding(.horizontal,18).padding(.bottom,7).opacity(phase == .playing ? 1 : 0)
                            }
                        }
                    }.accessibilityHidden(modal || phase == .listening).allowsHitTesting(!modal && phase != .listening)
                    if phase == .listening || phase == .discovery {
                        if !wide { Image("NoahCallGuide").resizable().scaledToFit().frame(height: min(240,geo.size.height*0.32)).position(x: geo.size.width*0.77,y: geo.size.height*0.20).allowsHitTesting(false).accessibilityHidden(true) }
                        ArkStoryCard(controller: controller,wide: wide,exit: exit)
                    }
                    if phase == .reveal {
                        VStack(spacing: 12) {
                            Text("YOUR ONE-OF-A-KIND CREATION").font(.system(size: 9,weight: .bold)).tracking(3).foregroundStyle(ArkWorkshopPalette.gold)
                            Text("Ready for\nadventure.").font(.system(size: wide ? 36 : 43,design: .serif)).multilineTextAlignment(.center).foregroundStyle(ArkWorkshopPalette.cream)
                        }.frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .top).padding(.top,wide ? 5 : 35).allowsHitTesting(false)
                    }
                }
                if let brush = controller.brushLocation { ArkBrushArt(color: controller.round.selectedColor).frame(width: 90,height: 110).position(x: brush.x+28,y: brush.y-45).allowsHitTesting(false).accessibilityHidden(true) }
                if phase == .paused || phase == .won { ArkEndPanel(controller: controller,exit: exit,info: { showStory = true }) }
            }.coordinateSpace(name: "ArkGame")
                .onChange(of: wide) { _,_ in controller.pause() }
        }.background(ArkWorkshopPalette.ink).preferredColorScheme(.dark).toolbar(.hidden,for: .navigationBar,.tabBar)
            .onAppear { controller.onComplete = onComplete; controller.reduceMotion = reduceMotion; controller.attach() }
            .onDisappear { controller.detach() }
            .onChange(of: scenePhase) { _,phase in if phase != .active { controller.pause() } }
            .onChange(of: reduceMotion) { _,value in controller.reduceMotion = value }
            .sheet(isPresented: $showStory) { ArkLearningSheet() }
    }
    private var taskHeading: some View {
        VStack(spacing: 5) {
            Text("HUNT · BUILD · CREATE").font(.system(size: 7,weight: .bold)).tracking(2.1).foregroundStyle(ArkWorkshopPalette.gold)
            Text(controller.round.step.title).font(.system(size: 27,design: .serif)).foregroundStyle(ArkWorkshopPalette.cream).lineLimit(1).minimumScaleFactor(0.7)
        }.frame(maxWidth: .infinity).shadow(color: .black.opacity(0.4),radius: 8,y: 2)
    }
}
struct ArkWelcome: View {
    @ObservedObject var controller: ArkWorkshopController
    let exit: () -> Void
    let info: () -> Void
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height*1.3
            ZStack(alignment: .bottomLeading) {
                ArkWorkshopView(controller: controller).frame(width: geo.size.width*(wide ? 0.65 : 0.92),height: geo.size.height*(wide ? 0.7 : 0.36))
                    .position(x: geo.size.width*(wide ? 0.71 : 0.4),y: geo.size.height*(wide ? 0.65 : 0.39))
                Image("NoahCallGuide").resizable().scaledToFit().frame(height: geo.size.height*(wide ? 0.77 : 0.43))
                    .offset(y: controller.reduceMotion ? 0 : sin(controller.time*1.1)*2)
                    .position(x: geo.size.width*(wide ? 0.84 : 0.76),y: geo.size.height*(wide ? 0.41 : 0.24)).accessibilityHidden(true)
                LinearGradient(stops: [.init(color: .clear,location: 0),.init(color: .clear,location: wide ? 0.2 : 0.33),.init(color: ArkWorkshopPalette.ink.opacity(0.85),location: wide ? 0.5 : 0.59),.init(color: ArkWorkshopPalette.ink,location: 0.86)],startPoint: wide ? .trailing : .top,endPoint: wide ? .leading : .bottom).ignoresSafeArea().allowsHitTesting(false)
                VStack(alignment: .leading,spacing: wide ? 9 : 14) {
                    Text("NOAH’S ADVENTURE · CHAPTER TWO").font(.system(size: 8,weight: .bold)).tracking(1.8).foregroundStyle(ArkWorkshopPalette.gold)
                    Text("Build the Ark.").font(.system(size: wide ? 48 : 53,design: .serif)).fixedSize(horizontal: false,vertical: true)
                    Text("A big adventure. Built by you.").font(.system(size: 22,design: .serif)).foregroundStyle(ArkWorkshopPalette.gold)
                    Text("Find hidden timber. Fit the decks. Pick your colors and paint an ark that is truly yours.").font(.system(size: wide ? 13 : 15,design: .rounded)).lineSpacing(4).foregroundStyle(ArkWorkshopPalette.cream.opacity(0.85)).fixedSize(horizontal: false,vertical: true)
                    HStack(spacing: 22) { feature("leaf.fill","HUNT"); feature("hand.draw.fill","BUILD"); feature("paintpalette.fill","PAINT") }.padding(.vertical,5)
                    Button(action: controller.start) { HStack { Text("Enter the workshop"); Spacer(); Image(systemName: "arrow.right") } }.buttonStyle(ArkPrimaryStyle())
                    HStack {
                        Button("Hear the story",action: controller.readAgain)
                        Spacer()
                        Button("For grown-ups",action: info)
                    }.font(.system(size: 11,weight: .semibold,design: .rounded)).foregroundStyle(ArkWorkshopPalette.cream.opacity(0.8)).frame(minHeight: 32)
                }.frame(maxWidth: wide ? 340 : 470,alignment: .leading).padding(.leading,wide ? 65 : 25).padding(.trailing,25).padding(.bottom,wide ? 5 : 12)
                VStack { HStack { ArkIcon(symbol: "chevron.left",label: "Back to Noah’s voyage",action: exit); Spacer() }; Spacer() }.padding(.horizontal,18).padding(.top,5)
            }.foregroundStyle(ArkWorkshopPalette.cream)
        }
    }
    private func feature(_ symbol: String,_ title: String) -> some View {
        HStack(spacing: 5) { Image(systemName: symbol).font(.system(size: 14,weight: .light)); Text(title).font(.system(size: 7,weight: .bold)).tracking(1) }.foregroundStyle(ArkWorkshopPalette.mint)
    }
}
struct ArkStoryCard: View {
    @ObservedObject var controller: ArkWorkshopController
    let wide: Bool
    let exit: () -> Void
    var body: some View {
        let learning = controller.round.phase == .discovery
        ZStack(alignment: wide ? .trailing : .bottom) {
            if learning { ArkWorkshopPalette.ink.opacity(0.22).ignoresSafeArea() }
            HStack(alignment: .bottom,spacing: wide ? 16 : 0) {
                if wide { Image("NoahCallGuide").resizable().scaledToFit().frame(width: 120,height: 240).accessibilityHidden(true) }
                ScrollView {
                    VStack(alignment: .leading,spacing: 12) {
                        HStack {
                            Text(learning ? "YOU REMEMBERED!" : "WORKSHOP CHALLENGE · \(controller.round.step.rawValue+1) / 3").font(.system(size: 7,weight: .bold)).tracking(1.1).foregroundStyle(ArkWorkshopPalette.gold)
                            Spacer(minLength: 0)
                            Button(action: controller.readAgain) { Image(systemName: "speaker.wave.2").frame(width: 44,height: 44) }.buttonStyle(.plain).accessibilityLabel("Read this story card aloud")
                        }
                        Text(learning ? controller.round.step.discoveryTitle : controller.round.step.title).font(.system(size: wide ? 26 : 27,design: .serif)).fixedSize(horizontal: false,vertical: true)
                        Text(learning ? controller.round.step.discovery : controller.round.step.instruction).font(.system(size: 14,weight: .medium,design: .rounded)).lineSpacing(4).foregroundStyle(ArkWorkshopPalette.cream.opacity(0.85)).fixedSize(horizontal: false,vertical: true)
                        Text(controller.round.step.reference).font(.system(size: 7,weight: .bold)).tracking(1).foregroundStyle(ArkWorkshopPalette.gold)
                        Button(action: { if learning { controller.next() } else { controller.begin() } }) {
                            HStack { Text(learning ? (controller.round.step == .pitch ? "See my finished ark" : "Next little step") : ["Explore the grove","Fit the decks","Open the paint studio"][controller.round.step.rawValue]); Spacer(); Image(systemName: "arrow.right") }
                        }.buttonStyle(ArkPrimaryStyle())
                    }.padding(18)
                }.frame(height: wide ? 310 : 300).background(ArkWorkshopPalette.ink.opacity(0.97),in: RoundedRectangle(cornerRadius: 24))
                    .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(ArkWorkshopPalette.gold.opacity(0.4)))
            }.frame(maxWidth: wide ? 610 : 520).padding(wide ? 12 : 15)
            VStack { HStack { ArkIcon(symbol: "pause.fill",label: "Pause Build the Ark",action: controller.pause); Spacer() }; Spacer() }.padding(18)
        }.frame(maxWidth: .infinity,maxHeight: .infinity).foregroundStyle(ArkWorkshopPalette.cream)
    }
}
struct ArkEndPanel: View {
    @ObservedObject var controller: ArkWorkshopController
    let exit: () -> Void
    let info: () -> Void
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height*1.3
            let won = controller.round.phase == .won
            ZStack {
                ArkWorkshopPalette.ink.opacity(0.95).ignoresSafeArea()
                ScrollView {
                    HStack(spacing: wide ? 25 : 0) {
                        if wide { Image("NoahCallGuide").resizable().scaledToFit().frame(width: 135,height: 265).accessibilityHidden(true) }
                        VStack(alignment: .leading,spacing: wide ? 12 : 20) {
                            Text(won ? "LOOK WHAT YOU CREATED" : "A QUIET MOMENT").font(.system(size: 8,weight: .bold)).tracking(2.4).foregroundStyle(ArkWorkshopPalette.gold)
                            if won {
                                HStack(spacing: 12) { ForEach(ArkWorkshopStep.allCases) { step in VStack(spacing: 7) { Image(systemName: "checkmark.seal.fill").font(.system(size: 27,weight: .light)); Text(step.shortTitle).font(.system(size: 6,weight: .bold)).tracking(0.5) }.foregroundStyle(ArkWorkshopPalette.gold).frame(maxWidth: .infinity) } }.padding(.vertical,8).accessibilityElement(children: .ignore).accessibilityLabel("All three instructions remembered")
                            }
                            Text(won ? "Built by you.\nMade with care." : "Little hands\ncan rest.").font(.system(size: wide ? 33 : 42,design: .serif)).fixedSize(horizontal: false,vertical: true)
                            Text(won ? "You found the timber, fitted every deck, and made your ark one of a kind. Your adventure is ready to continue." : "Your beams, decks, and brushwork are safe in this round.").font(.system(size: 15,design: .rounded)).lineSpacing(4).foregroundStyle(ArkWorkshopPalette.cream.opacity(0.85))
                            if won { Text("3 WORKSHOP CHALLENGES · \(controller.round.score) POINTS · GENESIS 6:22").font(.system(size: 7,weight: .semibold)).tracking(0.6).foregroundStyle(ArkWorkshopPalette.gold).fixedSize(horizontal: false,vertical: true) }
                            Button(won ? "Back to Noah’s voyage" : "Keep helping Noah",action: won ? exit : controller.resume).buttonStyle(ArkPrimaryStyle())
                            HStack {
                                Button(won ? "Play again" : "Start again",action: controller.start)
                                Spacer()
                                Button(won ? "For grown-ups" : "Back to Noah’s voyage",action: won ? info : exit)
                            }.font(.system(size: 12,weight: .semibold,design: .rounded)).frame(minHeight: 44)
                        }.frame(maxWidth: wide ? 450 : 430,alignment: .leading)
                    }.padding(26).frame(maxWidth: .infinity)
                }.defaultScrollAnchor(.center,for: .alignment)
            }.foregroundStyle(ArkWorkshopPalette.cream)
        }
    }
}
struct ArkLearningSheet: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment: .leading,spacing: 19) {
                HStack { Text("A NOTE FOR GROWN-UPS").font(.system(size: 8,weight: .bold)).tracking(2).foregroundStyle(ArkWorkshopPalette.gold); Spacer(); Button { dismiss() } label: { Image(systemName: "xmark").frame(width: 44,height: 44) }.accessibilityLabel("Close grown-up notes") }
                Text("Play, build,\nand make it yours.").font(.system(size: 36,design: .serif))
                Text("Build the Ark explores wood, three decks, and protective pitch inside and outside. Children search, sweep, carry, match shapes, and paint directly on a 3D model.").font(.system(size: 16,design: .rounded)).lineSpacing(5)
                Text("The miniature, timber hunt, and colorful paint are imaginative play. Genesis describes pitch as a protective coating, not this color palette. The cutaway helps children see the decks; this is not an exact reconstruction.").font(.system(size: 14,design: .rounded)).lineSpacing(5).foregroundStyle(ArkWorkshopPalette.cream.opacity(0.8))
                Text("Spoken guidance can be replayed. There is no timer or penalty. VoiceOver actions provide alternatives for collecting timber and painting. Cover most of each side, then keep decorating or reveal the finished ark.").font(.system(size: 14,design: .rounded)).lineSpacing(5).foregroundStyle(ArkWorkshopPalette.cream.opacity(0.8))
                Link("Read Genesis 6:14–22",destination: URL(string: "https://www.biblegateway.com/passage/?search=Genesis+6%3A14-22&version=KJV")!).foregroundStyle(ArkWorkshopPalette.gold).font(.system(size: 15,weight: .semibold)).frame(minHeight: 44)
                Button("Back to Noah",action: { dismiss() }).buttonStyle(ArkPrimaryStyle())
            }.padding(26).frame(maxWidth: 560).frame(maxWidth: .infinity)
        }.background(ArkWorkshopPalette.ink.ignoresSafeArea()).foregroundStyle(ArkWorkshopPalette.cream).preferredColorScheme(.dark).presentationDragIndicator(.visible)
    }
}
struct ArkLivingAir: View {
    @ObservedObject var controller: ArkWorkshopController
    @State private var burstTime = -10.0
    var body: some View {
        Canvas { context,size in
            guard size.width > 0,size.height > 0,!controller.reduceMotion else { return }
            for index in 0..<30 {
                let i = Double(index),t = controller.time
                let x = (i*73+sin(t*0.3+i)*22+size.width).truncatingRemainder(dividingBy: size.width)
                let y = (i*51-t*(3+i.truncatingRemainder(dividingBy: 4))+size.height*10).truncatingRemainder(dividingBy: size.height)
                let p = CGPoint(x: x,y: y),r: CGFloat = index%5 == 0 ? 3 : 1.3
                context.fill(Path(ellipseIn: CGRect(x: p.x-r,y: p.y-r,width: r*2,height: r*2)),with: .radialGradient(Gradient(colors: [ArkWorkshopPalette.gold.opacity(0.55),.clear]),center: p,startRadius: 0,endRadius: r))
            }
            let age = controller.time-burstTime
            if age >= 0 && age < 1.3 {
                for index in 0..<32 {
                    let angle = Double(index)*2.39996,travel = age*(50+Double(index%7)*14)
                    let p = CGPoint(x: size.width*0.5+cos(angle)*travel,y: size.height*0.46+sin(angle)*travel+age*age*40)
                    let r = CGFloat(2+index%3)
                    context.fill(Path(roundedRect: CGRect(x: p.x-r,y: p.y-r,width: r*2,height: r*2),cornerRadius: 1),with: .color((index%2 == 0 ? ArkWorkshopPalette.gold : ArkWorkshopPalette.mint).opacity(max(0,1-age/1.3))))
                }
            }
        }.allowsHitTesting(false).accessibilityHidden(true).onChange(of: controller.burst) { _,_ in burstTime = controller.time }
    }
}
#Preview { ArkWorkshopGame() }
