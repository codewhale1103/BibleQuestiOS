import SwiftUI

struct ArkAfloatRoom: View {
    @ObservedObject var controller: ArkAfloatController
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    private enum Touch { case carry(FloodTask), rope, shutter(Bool), apple(Int), stroke, wipe }
    @GestureState private var touching = false
    @State private var touch: Touch?
    @State private var touchAmount = 0.0
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width,h = geo.size.height,r = controller.round
            let t = controller.reduceMotion ? 0 : controller.time
            ZStack {
                Image(r.room.image).resizable().scaledToFill().frame(width: w,height: h).clipped().accessibilityHidden(true)
                window(w,h,t)
                if r.room == .cargo { cargo(w,h,t) }
                if r.room == .loft { loft(w,h,t) }
                if r.room == .shelter { shelter(w,h,t) }
                if controller.time < controller.successUntil { kindness(w,h,t) }
                if controller.time < controller.hintUntil { hint(w,h,t) }
                Color.clear.contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0).updating($touching) { _,state,_ in state = true }.onChanged { value in
                        routeTouch(value,w,h)
                    }.onEnded { value in
                        endTouch(value,w,h)
                    }).accessibilityHidden(true)
                if voiceOver,let task = r.task {
                    Button(action: controller.accessibleAction) { Label(task.instruction,systemImage: "hand.point.up.left.fill").font(.system(size: 12,weight: .bold)).padding(12).background(FloodPalette.ink,in: Capsule()) }
                        .foregroundStyle(FloodPalette.cream).position(x: w*0.5,y: h*0.92).accessibilityLabel("Help with this action")
                }
            }.coordinateSpace(name: "flood-room").clipped()
                .onChange(of: touching) { _,value in if !value { touch = nil; controller.cancelTouch() } }
                .onChange(of: r.room) { _,_ in touch = nil; controller.cancelTouch() }
                .onChange(of: r.phase) { _,_ in touch = nil; controller.cancelTouch() }
                .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(FloodPalette.gold.opacity(0.35)))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .rotationEffect(.degrees(r.phase == .caring && !controller.reduceMotion ? sin(t*0.65)*0.45 : 0))
        }.aspectRatio(2.0/3.0,contentMode: .fit)
    }
    private func windowRect(_ room: FloodRoom) -> CGRect {
        if room == .cargo { return .init(x: 0.31,y: 0.105,width: 0.42,height: 0.25) }
        if room == .shelter { return .init(x: 0.315,y: 0.175,width: 0.37,height: 0.21) }
        return .init(x: 0.335,y: 0.249,width: 0.33,height: 0.17)
    }
    private func routeTouch(_ value: DragGesture.Value,_ w: Double,_ h: Double) {
        let start = FloodPoint(x: value.startLocation.x/w,y: value.startLocation.y/h)
        let p = FloodPoint(x: value.location.x/w,y: value.location.y/h),r = controller.round
        if touch == nil {
            switch r.task {
            case .basket where start.distance(to: ArkAfloatRound.basketHome) < 0.24: touch = .carry(.basket)
            case .lantern where start.distance(to: ArkAfloatRound.lanternHome) < 0.23: touch = .carry(.lantern)
            case .blanket where start.distance(to: ArkAfloatRound.blanketHome) < 0.23: touch = .carry(.blanket)
            case .cargoRope,.stormRope:
                if start.distance(to: .init(x: 0.76,y: 0.47+r.rope*0.29)) < 0.18 { touch = .rope }
            case .shutters,.stormShutters:
                let left = FloodPoint(x: 0.25+0.165*r.shutterLeft,y: 0.334)
                let right = FloodPoint(x: 0.75-0.165*r.shutterRight,y: 0.334)
                if min(start.distance(to: left),start.distance(to: right)) < 0.19 {
                    let isLeft = start.distance(to: left) < start.distance(to: right)
                    touch = .shutter(isLeft); touchAmount = isLeft ? r.shutterLeft : r.shutterRight
                }
            case .apples:
                if let index = (0..<3).filter({ !r.apples.contains($0) }).min(by: { start.distance(to: controller.applePoint($0)) < start.distance(to: controller.applePoint($1)) }),start.distance(to: controller.applePoint(index)) < 0.20 { touch = .apple(index) }
            case .soothe where start.distance(to: ArkAfloatRound.lamb) < 0.31: touch = .stroke; controller.stroke(start)
            default: break
            }
            if touch == nil,windowRect(r.room).contains(CGPoint(x: start.x,y: start.y)) { touch = .wipe }
        }
        switch touch {
        case .carry(let task): controller.drag(task,to: p)
        case .rope: controller.pullRope((p.y-0.47)/0.29)
        case .shutter(let left): controller.shutter(left: left,amount: touchAmount+Double(value.translation.width)/(w*0.165)*(left ? 1.0 : -1.0))
        case .apple(let index): controller.dragApple(index,to: p)
        case .stroke: controller.stroke(p)
        case .wipe:
            let rect = windowRect(r.room)
            controller.wipe(.init(x: (p.x-rect.minX)/rect.width,y: (p.y-rect.minY)/rect.height))
        case nil: break
        }
    }
    private func endTouch(_ value: DragGesture.Value,_ w: Double,_ h: Double) {
        routeTouch(value,w,h)
        let p = FloodPoint(x: value.location.x/w,y: value.location.y/h)
        switch touch {
        case .carry(let task): controller.drop(task,at: p)
        case .apple(let index): controller.dropApple(index,at: p)
        case .stroke: controller.endStroke()
        default: break
        }
        touch = nil
    }
    private func window(_ w: Double,_ h: Double,_ t: Double) -> some View {
        let room = controller.round.room
        let x = room == .cargo ? 0.52 : 0.5,y = room == .cargo ? 0.23 : room == .shelter ? 0.28 : 0.334
        let ww = room == .cargo ? 0.42 : room == .shelter ? 0.37 : 0.33,hh = room == .cargo ? 0.25 : room == .shelter ? 0.21 : 0.17
        return FloodGlass(controller: controller).frame(width: w*ww,height: h*hh).position(x: w*x,y: h*y)
            .accessibilityLabel("Rainy window. Wipe with a finger to see through.")
    }
    @ViewBuilder private func cargo(_ w: Double,_ h: Double,_ t: Double) -> some View {
        let r = controller.round,task = r.task
        let housed = r.completed.contains(.basket)
        let p = controller.draggedTask == .basket ? controller.dragPoint ?? ArkAfloatRound.basketHome : housed ? ArkAfloatRound.basketCradle : ArkAfloatRound.basketHome
        // A wooden cradle is a physical destination, not a floating UI box.
        ZStack {
            FloodWood().frame(width: w*0.29,height: h*0.035).rotationEffect(.degrees(-4))
            FloodWood().frame(width: w*0.035,height: h*0.11).offset(x: -w*0.14,y: -h*0.025)
            FloodWood().frame(width: w*0.035,height: h*0.11).offset(x: w*0.14,y: -h*0.025)
        }.position(x: w*0.70,y: h*0.81).accessibilityHidden(true)
        if task == .basket || task == .apples {
            FloodTarget(symbol: task == .apples ? "basket" : "arrow.down",time: t,label: task == .apples ? "IN THE BASKET" : "BASKET HERE")
                .frame(width: w*0.25,height: w*0.25).position(x: w*0.70,y: h*0.72)
        }
        FloodBasket(apples: r.phase == .caring ? r.apples.count : 3).frame(width: w*0.31,height: w*0.32)
            .scaleEffect(controller.draggedTask == .basket ? 1.08 : 1)
            .shadow(color: .black.opacity(0.22),radius: 5,y: 4)
            .position(x: w*p.x,y: h*p.y)

            .accessibilityElement(children: .ignore).accessibilityLabel("Supply basket. Drag to the cradle.")
            .accessibilityAction(named: "Put basket in cradle",controller.accessibleAction).accessibilityHidden(task != .basket)
        if housed { rope(w,h,t) }
        if task == .apples {
            ForEach(0..<3,id: \.self) { index in
                if !r.apples.contains(index) {
                    let p = controller.applePoint(index)
                    FloodApple().frame(width: max(44,w*0.14),height: max(48,w*0.16)).contentShape(Rectangle())
                        .rotationEffect(.degrees(controller.draggedApple == index ? 0 : sin(t*0.75+Double(index))*18))
                        .scaleEffect(controller.draggedApple == index ? 1.15 : 1)
                        .position(x: w*p.x,y: h*p.y)
                        .accessibilityElement(children: .ignore).accessibilityLabel("Rolling apple \(index+1). Drag into the basket.")
                }
            }
            HStack(spacing: 7) { ForEach(0..<3,id: \.self) { index in Circle().fill(index < r.apples.count ? FloodPalette.gold : .white.opacity(0.25)).frame(width: 7,height: 7) } }.position(x: w*0.30,y: h*0.94).accessibilityLabel("\(r.apples.count) of 3 apples collected")
        }
    }
    @ViewBuilder private func rope(_ w: Double,_ h: Double,_ t: Double) -> some View {
        let r = controller.round,active = r.task == .cargoRope || r.task == .stormRope
        let secured = r.phase == .preparing ? r.completed.contains(.cargoRope) : r.completed.contains(.stormRope)
        let y = ArkAfloatRound.ropeStart.y+r.rope*0.29
        Canvas { c,s in
            let end = CGPoint(x: s.width*0.76,y: s.height*y)
            var p = Path();p.move(to: .init(x: s.width*0.56,y: s.height*0.72));p.addQuadCurve(to: .init(x: s.width*0.84,y: s.height*0.68),control: .init(x: s.width*0.7,y: s.height*0.62));p.addLine(to: end)
            c.stroke(p,with: .color(Color(hex: "#4C3423")),style: .init(lineWidth: 7,lineCap: .round))
            c.stroke(p,with: .color(Color(hex: "#D2AA72")),style: .init(lineWidth: 4,lineCap: .round,dash: [3,1]))
        }.allowsHitTesting(false).accessibilityHidden(true)
        if active {
            FloodTarget(symbol: "arrow.down",time: t,label: "PULL HERE").frame(width: 53,height: 72).position(x: w*0.76,y: h*0.80).opacity(0.7)
            ZStack {
                Circle().fill(LinearGradient(colors: [FloodPalette.gold,Color(hex: "#6E482D")],startPoint: .topLeading,endPoint: .bottomTrailing))
                Circle().fill(FloodPalette.ink.opacity(0.65)).padding(7)
                Image(systemName: "hand.point.down.fill").font(.system(size: 18)).foregroundStyle(FloodPalette.cream)
            }.frame(width: 48,height: 48).shadow(color: .black.opacity(0.3),radius: 4,y: 3)
                .position(x: w*0.76,y: h*y)
                .accessibilityElement(children: .ignore).accessibilityLabel("Rope handle. Pull down to secure the supplies.")
                .accessibilityAction(named: "Tighten rope",controller.accessibleAction)
        } else if secured {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 24)).foregroundStyle(FloodPalette.gold).position(x: w*0.82,y: h*0.70).accessibilityHidden(true)
        }
    }
    @ViewBuilder private func loft(_ w: Double,_ h: Double,_ t: Double) -> some View {
        let r = controller.round,task = r.task,sliding = task == .shutters || task == .stormShutters
        let left = r.shutterLeft,right = r.shutterRight
        shutter(w,h,left: true,amount: left,active: sliding)
        shutter(w,h,left: false,amount: right,active: sliding)
        if sliding {
            HStack { Image(systemName: "arrow.right"); Spacer();Image(systemName: "arrow.left") }.font(.system(size: 17,weight: .bold)).foregroundStyle(FloodPalette.cream)
                .frame(width: w*0.31).position(x: w*0.5,y: h*0.46).allowsHitTesting(false).accessibilityHidden(true)
        }
        let lit = r.completed.contains(.lantern)
        let p = controller.draggedTask == .lantern ? controller.dragPoint ?? ArkAfloatRound.lanternHome : lit ? FloodPoint(x: 0.52,y: 0.28) : ArkAfloatRound.lanternHome
        if task == .lantern { FloodTarget(symbol: "arrow.up",time: t,label: "HANG HERE").frame(width: 52,height: 70).position(x: w*0.52,y: h*0.18) }
        if lit { RadialGradient(colors: [FloodPalette.gold.opacity(0.35),.clear],center: .init(x: 0.52,y: 0.27),startRadius: 0,endRadius: w*0.8).blendMode(.screen).allowsHitTesting(false) }
        FloodLantern(time: t).frame(width: w*0.24,height: h*0.25)
            .rotationEffect(.degrees(lit && !controller.reduceMotion ? sin(t*1.5)*3 : 0),anchor: .top)
            .position(x: w*p.x,y: h*p.y)
            .accessibilityElement(children: .ignore).accessibilityLabel("Glowing lantern. Carry up to the hook.")
            .accessibilityAction(named: "Hang lantern",controller.accessibleAction).accessibilityHidden(task != .lantern)
    }
    private func shutter(_ w: Double,_ h: Double,left: Bool,amount: Double,active: Bool) -> some View {
        let open = left ? 0.25 : 0.75,closed = left ? 0.415 : 0.585
        return FloodWood().frame(width: w*0.165,height: h*0.185).contentShape(Rectangle())
            .overlay(alignment: left ? .trailing : .leading) { Capsule().fill(FloodPalette.gold).frame(width: 5,height: 24).padding(6) }
            .position(x: w*(open+(closed-open)*amount),y: h*0.334)
            .accessibilityElement(children: .ignore).accessibilityLabel("\(left ? "Left" : "Right") shutter. Slide toward the middle.")
            .accessibilityAction(named: "Close shutters",controller.accessibleAction).accessibilityHidden(!active)
    }
    @ViewBuilder private func shelter(_ w: Double,_ h: Double,_ t: Double) -> some View {
        let r = controller.round,covered = r.completed.contains(.blanket),settled = r.completed.contains(.soothe)
        let p = controller.draggedTask == .blanket ? controller.dragPoint ?? ArkAfloatRound.blanketHome : ArkAfloatRound.blanketHome
        Ellipse().fill(.black.opacity(0.23)).frame(width: w*0.40,height: h*0.04).blur(radius: 5).position(x: w*0.65,y: h*0.83).accessibilityHidden(true)
        Image("ParadeSheep").resizable().scaledToFit().frame(width: w*0.59,height: w*0.59)
            .scaleEffect(x: 1,y: 1+sin(t*1.6)*0.008,anchor: .bottom)
            .rotationEffect(.degrees(settled ? -4 : sin(t*1.1)*0.7),anchor: .bottom)
            .position(x: w*0.64,y: h*0.72).accessibilityHidden(true)
        if covered {
            FloodBlanket().frame(width: w*0.31,height: h*0.105).rotationEffect(.degrees(-8)).position(x: w*0.55,y: h*0.735).allowsHitTesting(false)
        } else {
            FloodBlanket(folded: true).frame(width: w*0.29,height: h*0.12).contentShape(Rectangle()).position(x: w*p.x,y: h*p.y)

                .accessibilityElement(children: .ignore).accessibilityLabel("Soft blanket. Carry to the lamb.")
                .accessibilityAction(named: "Cover the lamb",controller.accessibleAction).accessibilityHidden(r.task != .blanket)
        }
        if r.task == .blanket { FloodTarget(symbol: "heart",time: t,label: "FOR OUR FRIEND").frame(width: 58,height: 79).position(x: w*0.70,y: h*0.55) }
        if r.task == .soothe {
            Color.clear.contentShape(Ellipse()).frame(width: w*0.60,height: w*0.55).position(x: w*0.64,y: h*0.72)
                .accessibilityLabel("Gently stroke the lamb's wool")
                .accessibilityAction(named: "Comfort the lamb",controller.accessibleAction)
            HStack(spacing: 8) {
                Image(systemName: "heart.fill").foregroundStyle(FloodPalette.gold)
                GeometryReader { g in Capsule().fill(.white.opacity(0.15));Capsule().fill(FloodPalette.gold).frame(width: g.size.width*r.comfort) }.frame(width: w*0.32,height: 5)
            }.font(.system(size: 15)).position(x: w*0.6,y: h*0.52).allowsHitTesting(false).accessibilityLabel("Lamb comfort \(Int(r.comfort*100)) percent")
        }
        if settled {
            Label("All cozy",systemImage: "moon.stars.fill").font(.system(size: 15,weight: .semibold,design: .rounded)).foregroundStyle(FloodPalette.cream).padding(12).background(FloodPalette.ink.opacity(0.8),in: Capsule()).position(x: w*0.65,y: h*0.52).accessibilityHidden(true)
        }
    }
    private func hint(_ w: Double,_ h: Double,_ t: Double) -> some View {
        Canvas { c,s in
            guard let task = controller.round.task else { return }
            let a: FloodPoint,b: FloodPoint
            switch task {
            case .basket: a = ArkAfloatRound.basketHome;b = ArkAfloatRound.basketCradle
            case .lantern: a = ArkAfloatRound.lanternHome;b = ArkAfloatRound.hook
            case .blanket: a = ArkAfloatRound.blanketHome;b = ArkAfloatRound.lamb
            case .cargoRope,.stormRope: a = ArkAfloatRound.ropeStart;b = ArkAfloatRound.ropeEnd
            default: return
            }
            var p = Path();p.move(to: .init(x: a.x*s.width,y: a.y*s.height));p.addLine(to: .init(x: b.x*s.width,y: b.y*s.height))
            c.stroke(p,with: .color(FloodPalette.cream.opacity(0.8)),style: .init(lineWidth: 2,lineCap: .round,dash: [2,7],dashPhase: -t*12))
            let u = (t*0.6).truncatingRemainder(dividingBy: 1),point = a.mix(b,u)
            c.draw(Image(systemName: "hand.point.up.left.fill"),at: .init(x: point.x*s.width,y: point.y*s.height))
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
    private func kindness(_ w: Double,_ h: Double,_ t: Double) -> some View {
        let age = 1.3-(controller.successUntil-controller.time)
        return ZStack { ForEach(0..<8,id: \.self) { i in
            Image(systemName: i%3 == 0 ? "heart.fill" : "sparkle").font(.system(size: 11+Double(i%3)*3)).foregroundStyle(FloodPalette.gold)
                .opacity(max(0,1-age/1.3)).position(x: w*(0.22+Double(i)*0.08),y: h*(0.58-age*0.12)+sin(Double(i))*20)
        } }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

private struct FloodGlass: View {
    @ObservedObject var controller: ArkAfloatController
    var body: some View {
        Canvas { c,s in
            let t = controller.reduceMotion ? 0 : controller.time
            c.fill(Path(CGRect(origin: .zero,size: s)),with: .color(Color(hex: "#93C2C9").opacity(0.09)))
            for i in 0..<36 {
                let n = Double(i),x = (n*0.271).truncatingRemainder(dividingBy: 1)*s.width
                let y = (n*0.173+t*(0.10+Double(i%3)*0.015)).truncatingRemainder(dividingBy: 1)*s.height
                let p = Path(roundedRect: .init(x: x,y: y,width: i%4 == 0 ? 2.4 : 1,height: 7+Double(i%7)*3),cornerRadius: 2)
                c.fill(p,with: .linearGradient(.init(colors: [.white.opacity(0.05),FloodPalette.aqua.opacity(0.7)]),startPoint: .init(x: x,y: y),endPoint: .init(x: x,y: y+20)))
            }
            c.blendMode = .destinationOut
            for p in controller.wipes { c.fill(Path(ellipseIn: .init(x: p.x*s.width-18,y: p.y*s.height-18,width: 36,height: 36)),with: .color(.white)) }
        }.compositingGroup().contentShape(Rectangle())

            .accessibilityHidden(true)
    }
}
