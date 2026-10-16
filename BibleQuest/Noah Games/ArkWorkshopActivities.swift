import SwiftUI

struct ArkSceneBoard: View {
    @ObservedObject var controller: ArkWorkshopController
    @Binding var boardFrame: CGRect
    let basketFrame: CGRect
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if controller.round.step == .timber && controller.round.phase == .playing {
                    ArkTimberHunt(controller: controller,basketFrame: basketFrame)
                } else {
                    ArkWorkshopView(controller: controller)
                    if controller.round.phase == .playing && controller.round.step == .decks {
                        ForEach(controller.targets.indices,id: \.self) { index in
                            let done = controller.round.decks.contains(index),point = controller.targets[index]
                            Button { controller.placeDeck(index) } label: {
                                ZStack {
                                    Circle().fill(ArkWorkshopPalette.ink.opacity(done ? 0.1 : 0.85))
                                    Circle().strokeBorder(ArkWorkshopPalette.deckColors[index],lineWidth: 2)
                                    Text(done ? "✓" : "\(index+1)").font(.system(size: 20,weight: .bold,design: .rounded)).foregroundStyle(ArkWorkshopPalette.deckColors[index])
                                }.frame(width: done ? 22 : 36,height: done ? 22 : 36).frame(width: 46,height: 46).contentShape(Circle())
                            }.buttonStyle(.plain).disabled(done).position(x: point.x*geo.size.width,y: point.y*geo.size.height)
                                .accessibilityLabel("Place deck \(index+1)").accessibilityValue(done ? "Complete" : "Ready")
                        }
                    }
                    if controller.round.phase == .playing && controller.round.step == .pitch {
                        Color.clear.accessibilityElement().accessibilityLabel("Ark painting canvas").accessibilityHint("Choose a color, then drag the brush here. VoiceOver users can use the paint next section action.")
                            .accessibilityAction(named: Text("Paint next section")) { controller.accessiblePaint() }
                        if !controller.round.brushEquipped {
                            VStack { Spacer(); Label("Drag your brush here",systemImage: "hand.draw").font(.system(size: 12,weight: .semibold,design: .rounded)).padding(12).background(ArkWorkshopPalette.ink.opacity(0.92),in: Capsule()).foregroundStyle(ArkWorkshopPalette.cream) }.padding(.bottom,8).allowsHitTesting(false)
                        }
                    }
                }
            }.contentShape(Rectangle()).coordinateSpace(name: "ArkPaintBoard")
                .simultaneousGesture(DragGesture(minimumDistance: 2,coordinateSpace: .named("ArkPaintBoard"))
                    .onChanged { value in paint(value,in: geo,ended: false) }
                    .onEnded { value in paint(value,in: geo,ended: true) })
                .onAppear { boardFrame = geo.frame(in: .named("ArkGame")) }
                .onChange(of: geo.frame(in: .named("ArkGame"))) { _,frame in boardFrame = frame }
        }
    }
    private func paint(_ value: DragGesture.Value,in geo: GeometryProxy,ended: Bool) {
        guard controller.round.step == .pitch,geo.size.width > 0,geo.size.height > 0 else { return }
        controller.paintStroke(from: .init(x: value.startLocation.x/geo.size.width,y: value.startLocation.y/geo.size.height),to: .init(x: value.location.x/geo.size.width,y: value.location.y/geo.size.height),ended: ended,boardFrame: boardFrame)
    }
}
struct ArkTaskTray: View {
    @ObservedObject var controller: ArkWorkshopController
    let boardFrame: CGRect
    @Binding var basketFrame: CGRect
    @State private var dragging: Int?
    @State private var dragOffset = CGSize.zero
    var body: some View {
        VStack(spacing: 9) {
            if controller.round.step == .timber {
                HStack(spacing: 16) {
                    ArkTimberBasket(count: controller.round.wood.count).frame(width: 132,height: 88)
                        .background(GeometryReader { geo in Color.clear.onAppear { basketFrame = geo.frame(in: .named("ArkGame")) }.onChange(of: geo.frame(in: .named("ArkGame"))) { _,value in basketFrame = value } })
                        .accessibilityLabel("Timber basket, \(controller.round.wood.count) of 5 beams")
                    VStack(alignment: .leading,spacing: 10) {
                        Text("\(controller.round.wood.count) / 5 FOUND").font(.system(size: 11,weight: .bold,design: .rounded)).tracking(1.5)
                        HStack(spacing: 6) { ForEach(0..<5,id: \.self) { index in Capsule().fill(index < controller.round.wood.count ? ArkWorkshopPalette.gold : .white.opacity(0.2)).frame(width: 17,height: 6) } }
                        Button(action: controller.timberClue) { Label("A little clue",systemImage: "sparkles").font(.system(size: 12,weight: .semibold,design: .rounded)).frame(minHeight: 44) }.buttonStyle(.plain).foregroundStyle(ArkWorkshopPalette.gold)
                    }.foregroundStyle(ArkWorkshopPalette.cream)
                }.frame(maxWidth: .infinity).padding(.vertical,5).background(ArkWorkshopPalette.ink.opacity(0.94),in: RoundedRectangle(cornerRadius: 23))
            } else if controller.round.step == .decks {
                HStack(spacing: 8) {
                    ForEach(0..<3,id: \.self) { index in
                        let done = controller.round.decks.contains(index)
                        Button { controller.selectDeck(index) } label: {
                            VStack(spacing: 5) {
                                ZStack { ArkMaterialArt(index: index).frame(width: 72,height: 45); Text(done ? "✓" : "\(index+1)").font(.system(size: 17,weight: .bold,design: .rounded)).foregroundStyle(ArkWorkshopPalette.ink).frame(width: 27,height: 27).background(ArkWorkshopPalette.deckColors[index],in: Circle()) }
                                Text(["Lower","Middle","Upper"][index]).font(.system(size: 12,weight: .bold,design: .rounded))
                            }.foregroundStyle(ArkWorkshopPalette.cream).frame(maxWidth: .infinity,minHeight: 96)
                                .background(ArkWorkshopPalette.ink.opacity(done ? 0.45 : 0.94),in: RoundedRectangle(cornerRadius: 18))
                                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(ArkWorkshopPalette.deckColors[index].opacity(0.65)))
                        }.buttonStyle(.plain).disabled(done).accessibilityLabel("Choose \(["lower","middle","upper"][index]) deck").accessibilityValue(done ? "Placed" : "Drag to its matching shadow")
                            .offset(dragging == index ? dragOffset : .zero).zIndex(dragging == index ? 10 : 0)
                            .simultaneousGesture(DragGesture(minimumDistance: 6,coordinateSpace: .named("ArkGame"))
                                .onChanged { value in if !done { if dragging != index { dragging = index; controller.selectDeck(index) }; dragOffset = value.translation } }
                                .onEnded { value in
                                    defer { dragging = nil; dragOffset = .zero }
                                    guard !done,boardFrame.width > 0,boardFrame.height > 0 else { return }
                                    controller.dropDeck(index,point: .init(x: (value.location.x-boardFrame.minX)/boardFrame.width,y: (value.location.y-boardFrame.minY)/boardFrame.height))
                                })
                    }
                }
                Text("Lift a deck. Slide it into its glowing shadow.").font(.system(size: 11,weight: .medium,design: .rounded)).foregroundStyle(ArkWorkshopPalette.cream)
            } else {
                HStack(spacing: 3) {
                    ForEach(ArkPaintColor.allCases) { color in
                        Button { controller.chooseColor(color) } label: {
                            Circle().fill(Color(hex: color.hex).gradient).frame(width: 30,height: 30)
                                .overlay(Circle().strokeBorder(.white.opacity(controller.round.selectedColor == color ? 1 : 0.25),lineWidth: controller.round.selectedColor == color ? 3 : 1))
                                .shadow(color: Color(hex: color.hex).opacity(0.35),radius: controller.round.selectedColor == color ? 7 : 0)
                                .frame(width: 44,height: 48).contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityLabel("Choose \(color.name)").accessibilityValue(controller.round.selectedColor == color ? "Selected" : "Paint color")
                    }
                    Spacer(minLength: 0)
                    Button { _ = controller.pickUpBrush() } label: { ArkBrushArt(color: controller.round.selectedColor).frame(width: 53,height: 64).background(.white.opacity(0.07),in: RoundedRectangle(cornerRadius: 14)) }
                        .buttonStyle(.plain).accessibilityLabel("Pick up paintbrush").accessibilityHint("Drag this brush onto the ark")
                        .simultaneousGesture(DragGesture(minimumDistance: 3,coordinateSpace: .named("ArkGame"))
                            .onChanged { value in controller.dragBrush(from: value.startLocation,to: value.location,ended: false,bounds: boardFrame) }
                            .onEnded { value in controller.dragBrush(from: value.startLocation,to: value.location,ended: true,bounds: boardFrame) })
                }.padding(.horizontal,4).background(ArkWorkshopPalette.ink.opacity(0.95),in: RoundedRectangle(cornerRadius: 20))
                HStack(spacing: 8) { sideButton("Outside",inside: false); sideButton("Inside",inside: true) }
            }
            if controller.round.step == .pitch && controller.round.paintReady {
                Button(action: controller.finishPainting) { HStack { Text("Reveal my ark"); Spacer(); Image(systemName: "sparkles") } }.buttonStyle(ArkPrimaryStyle())
            } else {
                HStack(spacing: 7) {
                    Button(action: controller.readAgain) { Image(systemName: "ear.badge.waveform").font(.system(size: 19)).frame(width: 44,height: 44) }.buttonStyle(.plain).accessibilityLabel("Hear the instruction again")
                    Text(controller.message.isEmpty ? controller.round.step.prompt : controller.message).font(.system(size: 12,weight: .medium,design: .rounded)).lineSpacing(2).frame(maxWidth: .infinity,alignment: .leading)
                }.foregroundStyle(ArkWorkshopPalette.cream).padding(.horizontal,8).frame(minHeight: 55).background(ArkWorkshopPalette.ink.opacity(0.95),in: RoundedRectangle(cornerRadius: 16))
            }
        }.frame(height: 205,alignment: .bottom)
    }
    private func sideButton(_ title: String,inside: Bool) -> some View {
        let active = controller.round.inside == inside,percent = controller.round.percent(inside: inside)
        return Button { if controller.round.inside != inside { controller.flipSide() } } label: {
            HStack(spacing: 6) {
                Image(systemName: percent >= 75 ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath").font(.system(size: 12))
                Text(title).font(.system(size: 12,weight: .bold,design: .rounded)); Spacer(minLength: 0)
                Text("\(percent)%").font(.system(size: 10,weight: .semibold,design: .monospaced)).fixedSize()
            }.foregroundStyle(active ? ArkWorkshopPalette.ink : ArkWorkshopPalette.cream).padding(.horizontal,12).frame(minHeight: 42).background(active ? ArkWorkshopPalette.gold : ArkWorkshopPalette.ink.opacity(0.96),in: Capsule())
        }.buttonStyle(.plain).accessibilityLabel("Paint \(title.lowercased())").accessibilityValue("\(percent) percent painted\(active ? ", selected" : "")")
    }
}
struct ArkBrushArt: View {
    let color: ArkPaintColor?
    var body: some View {
        Canvas { context,size in
            context.scaleBy(x: size.width/90,y: size.height/110)
            var handle = Path(); handle.move(to: CGPoint(x: 63,y: 8)); handle.addLine(to: CGPoint(x: 36,y: 65))
            context.stroke(handle,with: .linearGradient(Gradient(colors: [Color(hex: "#E6BD82"),Color(hex: "#875135")]),startPoint: .zero,endPoint: CGPoint(x: 70,y: 70)),style: StrokeStyle(lineWidth: 14,lineCap: .round))
            var ferrule = Path(); ferrule.move(to: CGPoint(x: 29,y: 60)); ferrule.addLine(to: CGPoint(x: 46,y: 68)); ferrule.addLine(to: CGPoint(x: 38,y: 84)); ferrule.addLine(to: CGPoint(x: 21,y: 76)); ferrule.closeSubpath()
            context.fill(ferrule,with: .linearGradient(Gradient(colors: [Color(hex: "#F5DEAD"),Color(hex: "#8D7550")]),startPoint: CGPoint(x: 23,y: 60),endPoint: CGPoint(x: 45,y: 80)))
            var tip = Path(); tip.move(to: CGPoint(x: 20,y: 75)); tip.addLine(to: CGPoint(x: 39,y: 84)); tip.addQuadCurve(to: CGPoint(x: 29,y: 108),control: CGPoint(x: 37,y: 102)); tip.addLine(to: CGPoint(x: 5,y: 96)); tip.addQuadCurve(to: CGPoint(x: 20,y: 75),control: CGPoint(x: 14,y: 88)); tip.closeSubpath()
            context.fill(tip,with: .color(color.map { Color(hex: $0.hex) } ?? ArkWorkshopPalette.cream))
            for index in 0..<5 { var bristle = Path();bristle.move(to: CGPoint(x: CGFloat(21+index*3),y: CGFloat(81+index)));bristle.addLine(to: CGPoint(x: CGFloat(10+index*4),y: CGFloat(98+index))); context.stroke(bristle,with: .color(.white.opacity(0.25)),lineWidth: 1) }
        }.shadow(color: .black.opacity(0.3),radius: 4,y: 3).accessibilityHidden(true)
    }
}
