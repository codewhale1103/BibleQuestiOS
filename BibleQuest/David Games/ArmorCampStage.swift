import SwiftUI

struct ArmorCampStage: View {
    @ObservedObject var session: ArmorCampSession
    @State private var dragging: ArmorCampRound.Piece?
    @State private var translation: CGSize = .zero
    @State private var dragOrigin: CGPoint = .zero
    @State private var hover: ArmorCampRound.Piece?

    var body: some View {
        GeometryReader { geo in
            let layout = ArmorCampLayout(size: geo.size)
            let intro = session.round.phase == .intro
            let motion = ArmorCampMotion(round: session.round,time: session.clock,layout: layout,reduced: session.reduceMotion)
            ZStack {
                Image("ArmorCampBackdrop").resizable().scaledToFill()
                    .frame(width: geo.size.width,height: geo.size.height).clipped().accessibilityHidden(true)
                LinearGradient(colors: [.black.opacity(0.14),.clear,.black.opacity(0.3)],startPoint: .top,endPoint: .bottom)
                Ellipse().fill(.black.opacity(0.25)).blur(radius: 9)
                    .frame(width: layout.heroHeight(intro: intro) * 0.44,height: 20 * layout.unit)
                    .position(x: layout.heroCenter(intro: intro).x + motion.offset.width,y: layout.heroCenter(intro: intro).y + layout.heroHeight(intro: intro) * 0.455 + motion.offset.height)
                Image("ArmorCampDavid").resizable().scaledToFit()
                    .frame(height: layout.heroHeight(intro: intro))
                    .scaleEffect(motion.scale).rotationEffect(.degrees(motion.angle),anchor: .bottom)
                    .position(layout.heroCenter(intro: intro)).offset(motion.offset)
                    .accessibilityHidden(true)
                if !intro {
                    ForEach(ArmorCampRound.Piece.allCases) { piece in
                        stand(piece,layout: layout)
                    }
                }
                ForEach(ArmorCampRound.Piece.allCases) { piece in
                    equipment(piece,layout: layout,intro: intro,motion: motion)
                        .zIndex(dragging == piece ? 8 : (piece == .helmet ? 3 : 2))
                }
                ArmorCampAtmosphere(time: session.clock,effects: session.effects,layout: layout,reduced: session.reduceMotion)
                    .allowsHitTesting(false).accessibilityHidden(true).zIndex(10)
            }
            .coordinateSpace(name: "ArmorCampStage")
            .animation(session.reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.65,dampingFraction: 0.8),value: session.round.phase == .intro)
            .onChange(of: session.round.phase) { _, phase in
                if phase == .intro || phase == .paused { clearDrag() }
            }
            .onChange(of: session.round.elapsed) { old, new in if new < old { clearDrag() } }
        }
    }

    private func stand(_ piece: ArmorCampRound.Piece,layout: ArmorCampLayout) -> some View {
        let active = session.round.selected == piece || hover == piece
        let returned = session.round.stowed.contains(piece)
        return Button { session.tapStand(piece) } label: {
            ZStack {
                Ellipse().fill(ArmorCampPalette.gold.opacity(active ? 0.55 : 0))
                    .blur(radius: 14).frame(height: layout.standSize.height * 0.6)
                Image("ArmorCampStand").resizable().scaledToFit()
                    .shadow(color: .black.opacity(0.4),radius: 7,y: 5)
                if !returned && session.round.settling[piece] == nil {
                    Image(piece.artwork).resizable().scaledToFit()
                        .frame(width: layout.dockSize(piece).width,height: layout.dockSize(piece).height)
                        .saturation(0).brightness(0.15).opacity(active ? 0.5 : 0.2)
                        .offset(y: -layout.standSize.height * 0.08)
                }
                VStack {
                    Spacer()
                    HStack(spacing: 3) {
                        if returned { Image(systemName: "checkmark").font(.system(size: 8,weight: .bold)) }
                        Text(piece.title.uppercased()).font(.system(size: 8 * layout.unit,weight: .bold,design: .rounded)).tracking(0.7)
                    }
                    .foregroundStyle(returned ? ArmorCampPalette.gold : ArmorCampPalette.cream)
                    .padding(.horizontal,7).padding(.vertical,5)
                    .background(ArmorCampPalette.ink.opacity(0.92),in: Capsule())
                    .offset(y: 10)
                }
            }
            .frame(width: layout.standSize.width,height: layout.standSize.height)
            .scaleEffect(active ? 1.05 : 1)
        }
        .buttonStyle(.plain)
        .position(layout.standPosition(piece))
        .animation(.easeOut(duration: 0.2),value: active)
        .accessibilityLabel("\(piece.title) stand\(returned ? ", returned" : "")")
        .accessibilityHint("Select the \(piece.title.lowercased()), then tap here to return it.")
    }

    private func equipment(_ piece: ArmorCampRound.Piece,layout: ArmorCampLayout,intro: Bool,motion: ArmorCampMotion) -> some View {
        let worn = session.round.isWorn(piece)
        let held = dragging == piece
        let selected = session.round.selected == piece
        let size = worn ? layout.wornSize(piece,intro: intro) : layout.dockSize(piece)
        let base = worn ? layout.wornPosition(piece,intro: intro) : layout.dockPosition(piece)
        let point = held ? CGPoint(x: dragOrigin.x + translation.width,y: dragOrigin.y + translation.height) : base
        let angle = held ? min(12,max(-12,translation.width * 0.06)) : (worn ? motion.angle : 0)
        return Button { session.select(piece) } label: {
            ArmorCampMetal(piece: piece,time: session.clock,reduced: session.reduceMotion)
                .frame(width: size.width,height: size.height)
                .shadow(color: selected ? ArmorCampPalette.gold.opacity(0.85) : .black.opacity(0.35),radius: held ? 15 : (selected ? 8 : 3),y: held ? 14 : 2)
                .contentShape(Rectangle())
                .scaleEffect(held ? 1.06 : 1)
                .rotationEffect(.degrees(angle))
        }
        .buttonStyle(.plain)
        .highPriorityGesture(DragGesture(minimumDistance: 0,coordinateSpace: .named("ArmorCampStage"))
            .onChanged { value in
                guard session.round.phase == .fitting, worn, !session.round.isTrying else { return }
                if dragging == nil {
                    dragging = piece; dragOrigin = CGPoint(x: base.x + motion.offset.width,y: base.y + motion.offset.height)
                    session.select(piece)
                }
                guard dragging == piece else { return }
                translation = value.translation
                hover = layout.stand(at: CGPoint(x: dragOrigin.x + translation.width,y: dragOrigin.y + translation.height))
            }
            .onEnded { value in
                guard dragging == piece else { return }
                if hypot(value.translation.width,value.translation.height) < 8 { clearDrag(); return }
                let destination = layout.stand(at: CGPoint(x: dragOrigin.x + value.translation.width,y: dragOrigin.y + value.translation.height))
                withAnimation(session.reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.62,dampingFraction: 0.76)) {
                    session.drop(piece,onto: destination); clearDrag()
                }
            })
        .position(point)
        .offset(worn && !held ? motion.offset : .zero)
        .offset(y: selected && !held ? -5 : 0)
        .allowsHitTesting(session.round.phase == .fitting && worn && !session.round.isTrying)
        .accessibilityHidden(!worn || intro)
        .accessibilityLabel("Select \(piece.title.lowercased())")
        .accessibilityHint("Then tap its matching stand. You can also drag it there.")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
    private func clearDrag() { dragging = nil; translation = .zero; hover = nil }
}

private struct ArmorCampMetal: View {
    let piece: ArmorCampRound.Piece
    let time: Double
    let reduced: Bool
    var body: some View {
        Image(piece.artwork).resizable().scaledToFit()
            .overlay {
                if !reduced {
                    GeometryReader { geo in
                        LinearGradient(colors: [.clear,.white.opacity(0.24),.clear],startPoint: .leading,endPoint: .trailing)
                            .frame(width: geo.size.width * 0.35,height: geo.size.height * 2)
                            .rotationEffect(.degrees(24))
                            .offset(x: geo.size.width * ((time.truncatingRemainder(dividingBy: 7) / 7) * 3 - 1),y: -geo.size.height * 0.5)
                    }
                    .mask(Image(piece.artwork).resizable().scaledToFit())
                }
            }
    }
}

private struct ArmorCampMotion {
    var offset: CGSize = .zero
    var angle: Double = 0
    var scale: CGFloat = 1
    init(round: ArmorCampRound,time: Double,layout: ArmorCampLayout,reduced: Bool) {
        guard !reduced else { return }
        offset.height = sin(time * 1.7) * 1.2 * layout.unit
        if round.isTrying {
            let t = round.strideProgress
            offset.width = sin(t * .pi * 4) * (4 + 5 * round.weight) * layout.unit
            offset.height = -abs(sin(t * .pi * 2)) * 4 * layout.unit
            angle = sin(t * .pi * 6) * (1 + 2 * round.weight)
        } else if round.phase == .walking || round.phase == .completed {
            let p = round.walkProgress
            offset.width = layout.size.width * 0.10 * p
            offset.height = -layout.size.height * 0.06 * p - abs(sin(p * .pi * 6)) * 7 * layout.unit
            scale = 1 - p * 0.13; angle = sin(p * .pi * 6) * 1.7
        }
    }
}

private struct ArmorCampAtmosphere: View {
    let time: Double
    let effects: [ArmorCampEffect]
    let layout: ArmorCampLayout
    let reduced: Bool
    var body: some View {
        Canvas { context, size in
            if !reduced {
                for i in 0..<28 {
                    let seed = Double(i)
                    let x = (seed * 73.9 + time * (2 + seed.truncatingRemainder(dividingBy: 3))).truncatingRemainder(dividingBy: size.width)
                    let y = (seed * 97.1 - time * 4).truncatingRemainder(dividingBy: size.height)
                    let rect = CGRect(x: x,y: y < 0 ? y + size.height : y,width: i % 3 == 0 ? 2 : 1,height: i % 3 == 0 ? 2 : 1)
                    context.fill(Path(ellipseIn: rect),with: .color(ArmorCampPalette.cream.opacity(0.22 + sin(time + seed) * 0.12)))
                }
            }
            for effect in effects {
                let age = time - effect.born, p = min(1,age / 0.9)
                switch effect.kind {
                case let .dock(piece):
                    let center = layout.dockPosition(piece)
                    let radius = (12 + p * 42) * layout.unit
                    let ring = CGRect(x: center.x - radius,y: center.y - radius,width: radius * 2,height: radius * 2)
                    context.stroke(Path(ellipseIn: ring),with: .color(ArmorCampPalette.gold.opacity((1-p)*0.55)),lineWidth: 1.5)
                    if !reduced {
                        for i in 0..<12 {
                            let a = Double(i) * .pi / 6
                            let x = center.x + cos(a) * radius, y = center.y + sin(a) * radius + p * p * 14
                            context.fill(Path(ellipseIn: CGRect(x: x,y: y,width: 3 * (1-p),height: 3 * (1-p))),with: .color(ArmorCampPalette.gold.opacity(1-p)))
                        }
                    }
                case let .foot(progress):
                    if !reduced {
                        let hero = layout.heroCenter(intro: false)
                        let x = hero.x + layout.size.width * 0.10 * progress
                        let y = hero.y + layout.heroHeight(intro: false) * 0.44 - layout.size.height * 0.06 * progress
                        let r = 8 + p * 20
                        context.fill(Path(ellipseIn: CGRect(x: x-r,y: y-r*0.3,width: r*2,height: r*0.6)),with: .color(ArmorCampPalette.gold.opacity((1-p)*0.13)))
                    }
                }
            }
        }
    }
}
