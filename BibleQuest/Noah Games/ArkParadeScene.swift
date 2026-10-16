import SwiftUI

enum ParadePalette {
    static let ink = Color(hex: "#142F2A")
    static let forest = Color(hex: "#244E3F")
    static let mint = Color(hex: "#C2E6BB")
    static let gold = Color(hex: "#F5D58D")
    static let cream = Color(hex: "#FFF6DF")
}

struct ParadeAnimalSprite: View {
    let animal: ParadeAnimal
    var partner = false
    var time: Double = 0
    var walking = false
    var right = true
    var reduceMotion = false
    var body: some View {
        GeometryReader { geo in
            let beat = reduceMotion ? 0 : sin(time*(walking ? animal.stride : 1.7)+Double(animal.rawValue))
            ZStack(alignment: .bottom) {
                Ellipse().fill(.black.opacity(0.22)).frame(width: geo.size.width*0.63,height: geo.size.height*0.085).blur(radius: 3).offset(y: -geo.size.height*0.04)
                Image(partner ? animal.partnerImage : animal.image).resizable().scaledToFit().accessibilityHidden(true)
                    .scaleEffect(x: right ? 1 : -1,y: 1+beat*(walking ? 0.025 : 0.012),anchor: .bottom)
                    .rotationEffect(.degrees(beat*(walking ? (animal == .monkey ? 3 : 2) : 0.5)),anchor: .bottom)
                    .offset(y: walking ? -abs(beat)*(animal == .monkey ? 9 : 4) : 0)
            }
        }.accessibilityHidden(true)
    }
}

struct ParadeArkView: View {
    var boarded: [ParadeAnimal]
    var time: Double
    var celebrating = false
    var reduceMotion = false
    private let windows: [CGPoint] = [.init(x: 0.165,y: 0.351),.init(x: 0.232,y: 0.326),.init(x: 0.314,y: 0.296),.init(x: 0.405,y: 0.269),.init(x: 0.514,y: 0.234),.init(x: 0.623,y: 0.210)]
    var body: some View {
        GeometryReader { geo in
            Image("ParadeArk").resizable().scaledToFit().shadow(color: .black.opacity(0.28),radius: 9,y: 10)
            ForEach(Array(boarded.suffix(windows.count).enumerated()),id: \.offset) { index,animal in
                HStack(spacing: -1) {
                    ParadeWindowFace(animal: animal)
                    ParadeWindowFace(animal: animal).scaleEffect(x: -1,y: 1)
                }.frame(width: geo.size.width*0.056,height: geo.size.height*0.058)
                    .offset(y: reduceMotion ? 0 : sin(time*1.4+Double(index))*1.5)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .position(x: geo.size.width*windows[index].x,y: geo.size.height*windows[index].y)
            }
        }.rotationEffect(.degrees(celebrating && !reduceMotion ? sin(time*1.2)*0.65 : 0),anchor: .bottom)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Noah's ark. \(boarded.count) \(boarded.count == 1 ? "pair" : "pairs") aboard.")
    }
}

private struct ParadeWindowFace: View {
    let animal: ParadeAnimal
    private var face: CGPoint {
        switch animal {
        case .elephant: return .init(x: 0.72,y: 0.36)
        case .cow: return .init(x: 0.80,y: 0.30)
        case .monkey: return .init(x: 0.79,y: 0.28)
        case .sheep: return .init(x: 0.79,y: 0.27)
        case .lion: return .init(x: 0.64,y: 0.42)
        case .wolf: return .init(x: 0.80,y: 0.28)
        case .tiger: return .init(x: 0.80,y: 0.25)
        case .horse: return .init(x: 0.77,y: 0.25)
        }
    }
    var body: some View {
        GeometryReader { geo in
            let native = UIImage(named: animal.image)?.size ?? .init(width: 1,height: 1)
            let width = geo.size.width*3.5,height = width*native.height/max(1,native.width)
            Image(animal.image).resizable().frame(width: width,height: height)
                .position(x: geo.size.width*0.5+(0.5-face.x)*width,y: geo.size.height*0.6+(0.5-face.y)*height)
        }.clipped().accessibilityHidden(true)
    }
}

struct ArkParadeScene: View {
    @ObservedObject var controller: ArkParadeController
    var decorative = false
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width,h = geo.size.height,r = controller.round,t = controller.reduceMotion ? 0 : controller.time
            ZStack {
                ParadeGround(controller: controller)
                ParadeArkView(boarded: r.boarded,time: t,celebrating: r.phase == .finale || r.phase == .won,reduceMotion: controller.reduceMotion)
                    .frame(width: w*0.96,height: w*0.64).position(x: w*0.52,y: h*0.205)
                if r.phase == .intro || decorative {
                    ParadeAnimalSprite(animal: .lion,time: t).frame(width: w*0.37,height: w*0.37).position(x: w*0.28,y: h*0.66)
                    ParadeAnimalSprite(animal: .wolf,time: t,right: false).frame(width: w*0.31,height: w*0.31).position(x: w*0.75,y: h*0.66)
                    ParadeAnimalSprite(animal: .tiger,time: t).frame(width: w*0.31,height: w*0.31).position(x: w*0.35,y: h*0.85)
                    ParadeAnimalSprite(animal: .monkey,time: t,right: false).frame(width: w*0.25,height: w*0.25).position(x: w*0.73,y: h*0.86)
                } else if r.phase == .finding {
                    leader(w,h,t)
                    ForEach(r.choices.indices,id: \.self) { index in
                        let animal = r.choices[index],p = r.positions[index]
                        let reacting = controller.reactionIndex == index && controller.time < controller.reactionUntil
                        Button { controller.choose(index) } label: {
                            ParadeAnimalSprite(animal: animal,partner: animal == .cow,time: t+Double(index),walking: reacting,right: p.x < 0.5,reduceMotion: controller.reduceMotion)
                                .frame(width: w*0.28*animal.scale,height: w*0.28*animal.scale)
                                .frame(minWidth: 64,minHeight: 64).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                            .offset(y: reacting && !controller.reduceMotion ? -sin((controller.reactionUntil-controller.time)*5)*4 : 0)
                            .position(x: w*p.x,y: h*p.y-w*0.045)
                            .accessibilityLabel("\(animal.name) in the clearing")
                            .accessibilityHint("Listen to this animal and choose it as the partner")
                    }
                } else if [.greeting,.tracing,.escorting,.boarding].contains(r.phase) {
                    pair(w,h,t)
                }
                if r.phase == .finale || r.phase == .won {
                    Image("NoahCallGuide").resizable().scaledToFit().frame(width: w*0.20,height: w*0.32)
                        .rotationEffect(.degrees(controller.reduceMotion ? 0 : sin(t*2)*1.5),anchor: .bottom)
                        .position(x: w*0.74,y: h*0.56).accessibilityHidden(true)
                }
                // Layered reeds tuck the animals' feet into the clearing.
                ParadeForeground(controller: controller).allowsHitTesting(false)
                if r.phase == .tracing {
                    Color.clear.contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                            controller.beginTrail(.init(x: value.startLocation.x/w,y: value.startLocation.y/h))
                            controller.trace(.init(x: value.location.x/w,y: value.location.y/h))
                        }.onEnded { value in controller.endTrail(.init(x: value.location.x/w,y: value.location.y/h)) })
                        .accessibilityHidden(true)
                    Button("Guide this pair to the ark",action: controller.guideAccessibly).opacity(0.015)
                        .frame(width: 1,height: 1).position(x: w*0.5,y: h*0.93)
                        .accessibilityHint("An alternative to drawing the trail")
                }
            }
        }.aspectRatio(0.84,contentMode: .fit)
    }
    private func leader(_ w: Double,_ h: Double,_ t: Double) -> some View {
        Button(action: controller.listen) {
            ParadeAnimalSprite(animal: controller.round.animal,time: t,right: false,reduceMotion: controller.reduceMotion)
                .frame(width: w*0.32*controller.round.animal.scale,height: w*0.32*controller.round.animal.scale)
                .contentShape(Rectangle())
        }.buttonStyle(.plain).position(x: w*ArkParadeRound.start.x,y: h*ArkParadeRound.start.y-w*0.045)
            .accessibilityLabel("Hear the \(controller.round.animal.name.lowercased()) looking for its partner")
    }
    private func pair(_ w: Double,_ h: Double,_ t: Double) -> some View {
        let r = controller.round,walking = r.phase == .escorting,boarding = r.phase == .boarding
        let progress = walking ? r.walkProgress : boarding ? 1 : 0.0
        let sample = r.walker(progress)
        let leadShrink = boarding ? max(0,1-r.phaseTime/0.8)*0.76 : 1-progress*0.24
        let arrival = min(1,r.phaseTime/0.8)
        let buddyProgress = boarding ? 0.76+arrival*0.24 : max(0,progress-0.24)
        let following = r.walker(buddyProgress)
        let greet = min(1,r.phaseTime/1.4),ease = greet*greet*(3-2*greet)
        let together = ParadePoint(x: ArkParadeRound.start.x-0.23,y: ArkParadeRound.start.y-0.025)
        let offset = max(0,1-progress/0.35)
        let trailBuddy = ParadeTrail.outside(ParadePoint(x: following.point.x-0.23*offset,y: following.point.y-0.025*offset))
        let buddy = r.phase == .greeting ? r.positions[r.matchedIndex].mix(together,ease) : walking ? trailBuddy : boarding ? following.point : together
        let buddyShrink = boarding ? 0.76*max(0,1-max(0,r.phaseTime-0.8)/0.9) : 1-buddyProgress*0.24
        return ZStack {
            pairSprite(w,h,t+0.5,point: buddy,scale: buddyShrink,walking: walking || boarding || r.phase == .greeting,right: walking || boarding ? following.right : true)
            pairSprite(w,h,t,point: sample.point,scale: leadShrink,walking: walking,right: walking ? sample.right : false)
            if r.phase == .greeting {
                Image(systemName: "heart.fill").font(.system(size: 19)).foregroundStyle(ParadePalette.gold)
                    .offset(y: controller.reduceMotion ? 0 : -r.phaseTime*15)
                    .position(x: w*(together.x+0.06),y: h*together.y-w*0.23).accessibilityHidden(true)
            }
        }.allowsHitTesting(false).accessibilityElement(children: .ignore).accessibilityLabel("Two \(r.animal.plural.lowercased()), traveling together")
    }
    private func pairSprite(_ w: Double,_ h: Double,_ t: Double,point: ParadePoint,scale: Double,walking: Bool,right: Bool) -> some View {
        ParadeAnimalSprite(animal: controller.round.animal,time: t,walking: walking,right: right,reduceMotion: controller.reduceMotion)
            .frame(width: w*0.28*controller.round.animal.scale,height: w*0.28*controller.round.animal.scale)
            .scaleEffect(max(0.001,scale),anchor: .bottom).opacity(min(1,scale*4))
            .position(x: w*point.x,y: h*point.y-w*0.045*scale)
    }

}

private struct ParadeGround: View {
    @ObservedObject var controller: ArkParadeController
    var body: some View {
        Canvas { context,size in
            let r = controller.round,t = controller.reduceMotion ? 0 : controller.time
            func point(_ p: ParadePoint) -> CGPoint { .init(x: p.x*size.width,y: p.y*size.height) }
            if [.tracing,.escorting,.boarding].contains(r.phase) {
                let ramp = point(ArkParadeRound.ramp)
                let pulse = 1+sin(t*3)*0.08
                let halo = CGRect(x: ramp.x-34*pulse,y: ramp.y-13*pulse,width: 68*pulse,height: 26*pulse)
                context.fill(Path(ellipseIn: halo),with: .color(ParadePalette.gold.opacity(0.28)))
                context.stroke(Path(ellipseIn: halo),with: .color(ParadePalette.cream.opacity(0.9)),lineWidth: 1.5)
                context.draw(Text("ARK RAMP").font(.system(size: 8,weight: .black)).tracking(1.8).foregroundColor(ParadePalette.cream),at: .init(x: ramp.x,y: ramp.y+23))
                let route = r.phase == .tracing ? r.trail : r.route
                if route.count > 1 {
                    var path = Path(); path.move(to: point(route[0])); for p in route.dropFirst() { path.addLine(to: point(p)) }
                    context.stroke(path,with: .color(ParadePalette.gold.opacity(0.18)),style: .init(lineWidth: 16,lineCap: .round,lineJoin: .round))
                    context.stroke(path,with: .color(ParadePalette.cream.opacity(0.8)),style: .init(lineWidth: 2.5,lineCap: .round,lineJoin: .round,dash: [2,8],dashPhase: -t*12))
                } else if r.phase == .tracing {
                    let start = point(ArkParadeRound.start)
                    context.stroke(Path(ellipseIn: .init(x: start.x-28,y: start.y-10,width: 56,height: 20)),with: .color(ParadePalette.gold),lineWidth: 2)
                    context.draw(Text("START HERE").font(.system(size: 8,weight: .black)).tracking(1.2).foregroundColor(ParadePalette.cream),at: .init(x: start.x,y: start.y+48))
                    if controller.time < controller.hintUntil {
                        var guide = Path(); guide.move(to: start);guide.addQuadCurve(to: ramp,control: .init(x: size.width*0.82,y: size.height*0.34))
                        context.stroke(guide,with: .color(ParadePalette.gold.opacity(0.8)),style: .init(lineWidth: 2,dash: [3,9],dashPhase: -t*14))
                    }
                }
                if r.phase == .escorting {
                    let steps = Int(r.walkProgress*42)
                    if steps > 0 { for index in 0..<steps {
                        let sample = r.walker(Double(index)/42),p = point(sample.point)
                        let alpha = max(0.12,0.45-(Double(steps-index)*0.012))
                        let side = index%2 == 0 ? -4.0 : 4.0
                        let rect = CGRect(x: p.x+side-2,y: p.y-1,width: r.animal == .elephant ? 5 : 3,height: 5)
                        context.fill(Path(ellipseIn: rect),with: .color(ParadePalette.ink.opacity(alpha)))
                    } }
                }
            }
            // Use the established textured stone artwork, lit to match the clearing.
            if ![.intro,.won,.finale].contains(r.phase) {
                let c = point(ArkParadeRound.rock),rw = size.width*0.18
                context.draw(Image("ShepherdLimestone"),in: .init(x: c.x-rw/2,y: c.y-rw*0.48,width: rw,height: rw*0.65))
            }
            // Drifting pollen and tiny butterflies make the clearing feel alive.
            for index in 0..<18 {
                let n = Double(index),x = (n*0.347+t*0.012).truncatingRemainder(dividingBy: 1)*size.width
                let y = (0.12+(n*0.237).truncatingRemainder(dividingBy: 0.78))*size.height+sin(t*0.7+n)*8
                let alpha = 0.3+sin(t+n)*0.22
                context.fill(Path(ellipseIn: .init(x: x,y: y,width: index%4 == 0 ? 3 : 1.5,height: index%4 == 0 ? 3 : 1.5)),with: .color(ParadePalette.cream.opacity(alpha)))
            }
            if r.phase == .finding && controller.time < controller.hintUntil,let index = r.choices.firstIndex(of: r.animal) {
                let p = point(r.positions[index]);let radius = size.width*0.16
                context.stroke(Path(ellipseIn: .init(x: p.x-radius,y: p.y-radius*0.5,width: radius*2,height: radius*0.7)),with: .color(ParadePalette.gold),style: .init(lineWidth: 2,dash: [3,5],dashPhase: -t*9))
            }
            if controller.time < controller.callUntil,let animal = controller.calling {
                let p = point(controller.callPoint)
                for i in 0..<3 {
                    let phase = (t*0.7+Double(i)/3).truncatingRemainder(dividingBy: 1),radius = 10+phase*36
                    context.stroke(Path(ellipseIn: .init(x: p.x-radius,y: p.y-radius-size.width*0.15,width: radius*2,height: radius*2)),with: .color(ParadePalette.cream.opacity((1-phase)*0.6)),lineWidth: 1.3)
                }
                context.draw(Text(animal.call).font(.system(size: 9,weight: .black,design: .rounded)).tracking(1.8).foregroundColor(ParadePalette.cream),at: .init(x: p.x,y: p.y-size.width*0.29))
            }
            if r.phase == .finale || r.phase == .won {
                for index in 0..<35 {
                    let n = Double(index),x = (n*0.331).truncatingRemainder(dividingBy: 1)*size.width
                    let y = ((n*0.213+t*0.055).truncatingRemainder(dividingBy: 1))*size.height
                    context.fill(Path(ellipseIn: .init(x: x,y: y,width: 3,height: 5)),with: .color((index%2 == 0 ? ParadePalette.gold : ParadePalette.mint).opacity(0.8)))
                }
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

private struct ParadeForeground: View {
    @ObservedObject var controller: ArkParadeController
    var body: some View {
        GeometryReader { geo in
            if controller.round.phase == .finding {
                ForEach(controller.round.positions.indices,id: \.self) { index in
                    let p = controller.round.positions[index]
                    Image("ElahRiverReeds").resizable().scaledToFit().frame(width: geo.size.width*0.16,height: geo.size.width*0.11).accessibilityHidden(true)
                        .rotationEffect(.degrees(controller.reduceMotion ? 0 : sin(controller.time*1.2+Double(index))*2),anchor: .bottom)
                        .position(x: p.x*geo.size.width,y: p.y*geo.size.height+geo.size.width*0.05)
                }
            }
        }.accessibilityHidden(true)
    }
}
