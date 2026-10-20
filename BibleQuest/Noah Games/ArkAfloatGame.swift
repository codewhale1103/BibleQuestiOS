import SwiftUI

struct ArkAfloatGame: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var controller = ArkAfloatController()
    @State private var notes = false
    var onComplete: (() -> Void)? = nil
    var onExit: (() -> Void)? = nil
    private func exit() { controller.pause(); if let onExit { onExit() } else { dismiss() } }
    var body: some View {
        GeometryReader { g in
            let wide = g.size.width > g.size.height*1.25,r = controller.round
            ZStack {
                Image("FloodStorm").resizable().scaledToFill().frame(width: g.size.width,height: g.size.height).clipped().opacity(0.30).ignoresSafeArea().accessibilityHidden(true)
                LinearGradient(colors: [FloodPalette.ink.opacity(0.86),FloodPalette.ink.opacity(0.35),FloodPalette.ink.opacity(0.97)],startPoint: .top,endPoint: .bottom).ignoresSafeArea().allowsHitTesting(false)
                if r.phase == .intro {
                    intro(wide: wide)
                } else {
                    Group {
                        if wide {
                            HStack(spacing: 18) {
                                VStack(spacing: 10) { header;instructions;Spacer(minLength: 0);roomPicker;viewHandle;footer }.frame(width: min(305,g.size.width*0.38))
                                stage.frame(maxWidth: .infinity,maxHeight: .infinity)
                            }.padding(.horizontal,20).padding(.vertical,6)
                        } else {
                            VStack(spacing: 8) {
                                header
                                instructions.frame(minHeight: 70)
                                stage.frame(maxHeight: .infinity)
                                roomPicker
                                viewHandle
                                footer
                            }.padding(.horizontal,18).padding(.vertical,4)
                        }
                    }.accessibilityHidden(r.phase == .paused || r.phase == .won).allowsHitTesting(r.phase != .paused && r.phase != .won)
                    if r.phase == .paused || r.phase == .won { finishPanel(won: r.phase == .won) }
                }
            }.onChange(of: wide) { _,_ in controller.pause() }
        }.background(FloodPalette.ink).preferredColorScheme(.dark).toolbar(.hidden,for: .navigationBar,.tabBar)
            .onAppear { controller.onComplete = onComplete; controller.reduceMotion = reduceMotion; controller.attach() }
            .onDisappear { controller.detach() }
            .onChange(of: scenePhase) { _,phase in if phase != .active { controller.pause() } }
            .onChange(of: reduceMotion) { _,value in controller.reduceMotion = value }
            .sheet(isPresented: $notes) { FloodNotes() }
            .animation(.easeOut(duration: reduceMotion ? 0.1 : 0.35),value: controller.round.room)
    }
    private var header: some View {
        HStack(spacing: 4) {
            icon("chevron.left","Back to Noah's voyage",exit)
            VStack(alignment: .leading,spacing: 3) {
                Text("FLOOD BEGINS").font(.system(size: 6,weight: .bold)).tracking(2).foregroundStyle(FloodPalette.gold)
                Text("Ark Afloat").font(.system(size: 23,design: .serif)).foregroundStyle(FloodPalette.cream)
            }.frame(maxWidth: .infinity,alignment: .leading)
            icon(controller.soundOn ? "speaker.wave.2" : "speaker.slash",controller.soundOn ? "Mute Ark Afloat sounds" : "Turn Ark Afloat sounds on",controller.toggleSound)
            if controller.round.phase != .intro { icon("pause","Pause Ark Afloat",controller.pause) }
        }.frame(minHeight: 46)
    }
    private func icon(_ symbol: String,_ label: String,_ action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: symbol).font(.system(size: 17,weight: .light)).foregroundStyle(FloodPalette.cream).frame(width: 40,height: 44) }.buttonStyle(.plain).accessibilityLabel(label)
    }
    private var instructions: some View {
        let r = controller.round
        let title = r.phase == .rain ? "Here comes the rain." : r.phase == .launching ? "A breathtaking beginning." : r.phase == .finale ? "Safe through the storm." : controller.outside > 0.5 ? "A whole world of water." : r.task?.title ?? (r.phase == .preparing ? "A warm welcome awaits." : "A cozy little corner.")
        return HStack(spacing: 8) {
            VStack(alignment: .leading,spacing: 5) {
                Text(r.phase == .rain ? "THE FIRST RAINDROPS" : r.phase == .launching ? "THE FIRST FLOAT" : r.phase == .caring ? "SMALL HANDS. GREAT BIG KINDNESS." : r.phase == .finale ? "SAFE IN GOD’S CARE" : "A PLACE OF SHELTER")
                    .font(.system(size: 6,weight: .bold)).tracking(1.7).foregroundStyle(FloodPalette.gold)
                Text(title).font(.system(size: 26,design: .serif)).lineLimit(2).minimumScaleFactor(0.72).foregroundStyle(FloodPalette.cream)
            }.frame(maxWidth: .infinity,alignment: .leading)
            if r.active {
                Button(action: controller.help) { Image(systemName: "hand.point.up.left.and.text").font(.system(size: 19,weight: .light)).foregroundStyle(FloodPalette.gold).frame(width: 44,height: 44).background(.white.opacity(0.06),in: Circle()) }.buttonStyle(.plain).accessibilityLabel("Show me how")
            }
        }
    }
    private var stage: some View {
        ZStack {
            if controller.outside < 0.999 { ArkAfloatRoom(controller: controller).opacity(1-controller.outside).allowsHitTesting(controller.outside < 0.2).accessibilityHidden(controller.outside > 0.5).transition(.opacity) }
            if controller.outside > 0.001 { ArkAfloatExterior(controller: controller).opacity(controller.outside).allowsHitTesting(controller.outside > 0.8).accessibilityHidden(controller.outside < 0.5).transition(.opacity) }
        }.aspectRatio(2.0/3.0,contentMode: .fit).frame(maxWidth: 460)
            .shadow(color: .black.opacity(0.23),radius: 16,y: 8)
    }
    @ViewBuilder private var roomPicker: some View {
        if controller.round.active {
            HStack(spacing: 7) {
                ForEach(FloodRoom.allCases) { room in
                    let selected = room == controller.round.room && controller.outside < 0.5,done = controller.round.roomFinished(room)
                    Button { controller.select(room) } label: {
                        HStack(spacing: 5) {
                            Image(systemName: done ? "checkmark.circle.fill" : room.symbol).font(.system(size: 12,weight: .light))
                            Text(room.shortName).font(.system(size: 10,weight: .semibold,design: .rounded)).lineLimit(1).minimumScaleFactor(0.8)
                        }.foregroundStyle(selected ? FloodPalette.ink : FloodPalette.cream.opacity(0.8)).frame(maxWidth: .infinity,minHeight: 43)
                            .background(selected ? FloodPalette.gold : .white.opacity(0.06),in: RoundedRectangle(cornerRadius: 13))
                            .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(selected ? FloodPalette.cream.opacity(0.5) : .white.opacity(0.1)))
                    }.buttonStyle(FloodPressStyle()).accessibilityLabel("Explore \(room.name)\(done ? ", room ready" : "")")
                }
            }
        }
    }
    @ViewBuilder private var viewHandle: some View {
        if controller.round.phase != .rain && controller.round.phase != .finale {
            HStack(spacing: 8) {
                Button { controller.peek(false) } label: { VStack(spacing: 3) { Image(systemName: "house.fill");Text("Inside").font(.system(size: 8,weight: .bold)) }.frame(width: 49,height: 42) }.accessibilityLabel("Look inside the ark")
                GeometryReader { g in
                    FloodWood().clipShape(Capsule()).overlay(Capsule().strokeBorder(FloodPalette.gold.opacity(0.4))).frame(height: 13).position(x: g.size.width/2,y: g.size.height/2)
                    ZStack {
                        Circle().fill(LinearGradient(colors: [FloodPalette.cream,FloodPalette.gold],startPoint: .topLeading,endPoint: .bottomTrailing))
                        Image(systemName: "eye").font(.system(size: 18,weight: .light)).foregroundStyle(FloodPalette.ink)
                    }.frame(width: 37,height: 37).shadow(color: .black.opacity(0.3),radius: 4,y: 3)
                        .position(x: 20+max(1,g.size.width-40)*controller.outside,y: g.size.height/2)
                        .gesture(DragGesture(minimumDistance: 0,coordinateSpace: .named("view-track")).onChanged { controller.setOutside(($0.location.x-20)/max(1,g.size.width-40)) }.onEnded { _ in controller.settleView() })
                        .accessibilityHidden(true)
                }.coordinateSpace(name: "view-track").frame(height: 42)
                Button { controller.peek(true) } label: { VStack(spacing: 3) { Image(systemName: "water.waves");Text("Outside").font(.system(size: 8,weight: .bold)) }.frame(width: 49,height: 42) }.accessibilityLabel("Look outside at the waves")
            }.buttonStyle(.plain).foregroundStyle(FloodPalette.aqua)
        }
    }
    private var footer: some View {
        let r = controller.round
        return VStack(spacing: 8) {
            if r.phase == .rain {
                FloodAction(title: "Come inside",symbol: "door.left.hand.open",action: controller.comeInside)
            } else if r.phase == .preparing && r.ready {
                FloodAction(title: "Watch the ark float",symbol: "water.waves",action: controller.launch)
            } else if r.phase == .caring && r.caredFor {
                FloodAction(title: "Everyone is cozy!",symbol: "heart.fill",action: controller.finish)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: controller.outside > 0.5 ? "water.waves" : r.task?.symbol ?? "sparkles").font(.system(size: 20,weight: .light)).foregroundStyle(FloodPalette.gold).frame(width: 27)
                    Text(controller.time < controller.messageUntil ? controller.message : r.phase == .rain ? "Touch the water to make little ripples." : r.phase == .launching ? "Watch the waterline climb. The ark begins to lift." : r.phase == .finale ? "Every little life, safe and cared for." : controller.outside > 0.5 ? "Drag the viewing handle to peek inside again." : r.task?.instruction ?? "This room is ready. Explore another little corner.")
                        .font(.system(size: 12,weight: .medium,design: .rounded)).lineSpacing(3).foregroundStyle(FloodPalette.cream).frame(maxWidth: .infinity,alignment: .leading)
                }.padding(12).frame(minHeight: 63).background(.white.opacity(0.05),in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(FloodPalette.aqua.opacity(0.15)))
            }
            HStack(spacing: 6) {
                ForEach(0..<3,id: \.self) { index in
                    Capsule().fill((index == 0 && r.ready || index == 1 && [.caring,.finale,.won].contains(r.phase) || index == 2 && r.caredFor) ? FloodPalette.gold : .white.opacity(0.16)).frame(width: 25,height: 2)
                }
                Text(r.phase == .preparing ? "GET READY" : r.phase == .launching ? "FIRST FLOAT" : "CARE & KINDNESS").font(.system(size: 6,weight: .bold)).tracking(1.3).foregroundStyle(FloodPalette.aqua.opacity(0.8)).padding(.leading,5)
            }.accessibilityLabel("\(r.count) of 9 caring actions complete")
        }
    }
    private func intro(wide: Bool) -> some View {
        VStack(spacing: 4) {
            header.padding(.horizontal,18)
            if wide {
                HStack(spacing: 24) { ArkAfloatExterior(controller: controller,cutaway: true).frame(maxWidth: .infinity,maxHeight: .infinity);introCopy.frame(width: 310) }.padding(.horizontal,22)
            } else {
                ArkAfloatExterior(controller: controller,cutaway: true).frame(maxHeight: .infinity).padding(.horizontal,12)
                introCopy.padding(.horizontal,25).padding(.bottom,12)
            }
        }
    }
    private var introCopy: some View {
        VStack(alignment: .leading,spacing: 12) {
            Text("A GREAT STORM. A GREATER SHELTER.").font(.system(size: 7,weight: .bold)).tracking(1.8).foregroundStyle(FloodPalette.gold)
            Text("A little care.\nAn ocean of courage.").font(.system(size: 36,design: .serif)).foregroundStyle(FloodPalette.cream).fixedSize(horizontal: false,vertical: true)
            Text("Step inside a living ark. Get ready for the rain, feel the first float, and keep your animal friends cozy.").font(.system(size: 13)).lineSpacing(4).foregroundStyle(FloodPalette.aqua)
            HStack(spacing: 16) {
                Label("Hands-on play",systemImage: "hand.draw");Label("A world to explore",systemImage: "sparkles")
            }.font(.system(size: 9,weight: .semibold)).foregroundStyle(FloodPalette.gold).padding(.vertical,3)
            FloodAction(title: "Come aboard",symbol: "arrow.right",action: controller.start)
            Text("EXPLORE · PREPARE · CARE").font(.system(size: 6,weight: .semibold)).tracking(2).foregroundStyle(FloodPalette.aqua.opacity(0.65)).frame(maxWidth: .infinity)
        }
    }
    private func finishPanel(won: Bool) -> some View {
        ZStack {
            FloodPalette.ink.opacity(0.82).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 17) {
                    Image(systemName: won ? "heart.circle" : "pause.circle").font(.system(size: 48,weight: .ultraLight)).foregroundStyle(FloodPalette.gold)
                    Text(won ? "SAFE THROUGH THE STORM" : "A QUIET LITTLE BREAK").font(.system(size: 7,weight: .bold)).tracking(2).foregroundStyle(FloodPalette.gold)
                    Text(won ? "Great big waves.\nLittle acts of love." : "The ark is\nright here.").font(.system(size: 37,design: .serif)).multilineTextAlignment(.center).foregroundStyle(FloodPalette.cream)
                    if won {
                        HStack(spacing: 18) { Image("ParadeSheep").resizable().scaledToFit().frame(width: 85,height: 85);Image("NoahCallGuide").resizable().scaledToFit().frame(width: 62,height: 105);Image("ParadeMonkey").resizable().scaledToFit().frame(width: 73,height: 85) }.accessibilityHidden(true)
                        Text("You made the ark a warm, caring place. The waters rose, and God kept Noah and everyone in the ark safe.").font(.system(size: 14)).lineSpacing(5).multilineTextAlignment(.center).foregroundStyle(FloodPalette.aqua)
                        Text("GENESIS 7:10–24").font(.system(size: 7,weight: .bold)).tracking(1.6).foregroundStyle(FloodPalette.gold)
                    }
                    FloodAction(title: won ? "Back to Noah’s voyage" : "Keep exploring",symbol: won ? "sailboat" : "play.fill",action: won ? exit : controller.resume)
                    if won { Button("Play the first voyage again",action: controller.start).font(.system(size: 13,weight: .semibold)).frame(minHeight: 44).foregroundStyle(FloodPalette.gold) }
                    HStack {
                        Button("Story & sounds") { controller.pause(); notes = true }
                        if !won { Spacer();Button("Leave the ark",action: exit) }
                    }.font(.system(size: 12)).foregroundStyle(FloodPalette.aqua).frame(minHeight: 44)
                }.padding(25).frame(maxWidth: 410).background(FloodPalette.ink,in: RoundedRectangle(cornerRadius: 29)).overlay(RoundedRectangle(cornerRadius: 29).strokeBorder(FloodPalette.gold.opacity(0.3))).padding(22).frame(maxWidth: .infinity)
            }.defaultScrollAnchor(.center)
        }
    }
}
struct FloodAction: View {
    let title: String
    var symbol = "arrow.right"
    let action: () -> Void
    var body: some View {
        Button(action: action) { HStack { Text(title);Spacer();Image(systemName: symbol) }.font(.system(size: 15,weight: .bold,design: .rounded)).foregroundStyle(FloodPalette.ink).padding(.horizontal,20).frame(minHeight: 55).background(LinearGradient(colors: [FloodPalette.cream,FloodPalette.gold],startPoint: .topLeading,endPoint: .bottomTrailing),in: RoundedRectangle(cornerRadius: 18)) }.buttonStyle(FloodPressStyle())
    }
}
struct FloodPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { configuration.label.scaleEffect(configuration.isPressed ? 0.97 : 1).animation(.easeOut(duration: 0.15),value: configuration.isPressed) }
}
private struct FloodNotes: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView { VStack(alignment: .leading,spacing: 18) {
            HStack { Text("A voyage of care").font(.system(size: 30,design: .serif));Spacer();Button { dismiss() } label: { Image(systemName: "xmark").frame(width: 44,height: 44) }.accessibilityLabel("Close story notes") }
            Text("Genesis 7:10–24 tells how the rain came, the waters rose, and the ark lifted above the land. This game ends at the beginning of the voyage; the long wait, dove, and rainbow come later.")
            Text("The rooms, cargo tasks, lanterns, and animal-care moments are imaginative play. Children practice sequencing, coordination, observation, and kindness. The ark stays a place of shelter as they explore.")
            Text("All actions are available with VoiceOver. Sound is optional, hints are repeatable, and there is no timer. Reduced Motion keeps the essential rising-water sequence while removing ambient rocking and drifting.")
            Text("Artwork was made for BibleQuest with the built-in image-generation tool. Rain, water, wood, and musical cues are original designed sounds. Narration: Anna – Children’s Book Narrator, ElevenLabs Multilingual v2. All recordings play offline.")
            Text("Animal artwork is reused from Ark Parade. This game does not unlock Noah’s final album reward.")
            FloodAction(title: "Back to the ark",symbol: "arrow.left") { dismiss() }
        }.font(.system(size: 14)).lineSpacing(5).padding(25).frame(maxWidth: 580).frame(maxWidth: .infinity) }.foregroundStyle(FloodPalette.cream).background(FloodPalette.ink.ignoresSafeArea()).preferredColorScheme(.dark).presentationDragIndicator(.visible)
    }
}
#Preview { ArkAfloatGame() }
