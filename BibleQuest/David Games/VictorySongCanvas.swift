import SwiftUI

struct VictoryHarpLayout {
    let rect: CGRect
    init(size: CGSize) {
        let height = max(1,min(size.height-12,size.width*1.43))
        let width = height * 2/3
        rect = CGRect(x: (size.width-width)/2,y: (size.height-height)/2,width: width,height: height)
    }
    var top: CGFloat { rect.minY+rect.height*0.13 }
    var bridge: CGFloat { rect.minY+rect.height*0.755 }
    func x(_ lane: Int) -> CGFloat { rect.minX+rect.width*(0.30+CGFloat(lane)*0.20) }
}

enum VictoryPalette {
    static let ink = Color(red: 0.035,green: 0.075,blue: 0.13)
    static let cream = Color(red: 1,green: 0.95,blue: 0.84)
    static let gold = Color(red: 1,green: 0.77,blue: 0.40)
    static let lanes = [Color(red: 1,green: 0.78,blue: 0.40),Color(red: 0.44,green: 0.91,blue: 0.84),Color(red: 0.93,green: 0.63,blue: 0.80)]
}

struct VictoryHarpStage: View {
    @ObservedObject var controller: VictorySongController
    var body: some View {
        GeometryReader { geo in
            let layout = VictoryHarpLayout(size: geo.size)
            ZStack {
                Ellipse().fill(VictoryPalette.gold.opacity(0.12)).blur(radius: 22)
                    .frame(width: layout.rect.width*0.95,height: layout.rect.height*0.13)
                    .position(x: layout.rect.midX,y: layout.rect.maxY-12)
                Image("VictoryLyreFrame").resizable().frame(width: layout.rect.width,height: layout.rect.height)
                    .position(x: layout.rect.midX,y: layout.rect.midY).shadow(color: .black.opacity(0.6),radius: 18,y: 12).accessibilityHidden(true)
                Canvas { context,size in draw(&context,layout: layout) }.allowsHitTesting(false)
                ForEach(0..<3,id: \.self) { lane in
                    let active = controller.round.pressed.contains(lane)
                    VStack(spacing: 5) {
                        Image(systemName: lane == 0 ? "circle.fill" : lane == 1 ? "diamond.fill" : "triangle.fill")
                            .font(.system(size: 9)).foregroundStyle(VictoryPalette.lanes[lane])
                        Text(["LOW","MID","HIGH"][lane]).font(.system(size: 7,weight: .bold)).tracking(1.2).foregroundStyle(VictoryPalette.cream.opacity(0.8))
                    }
                    .scaleEffect(active && !controller.reduceMotion ? 0.94 : 1)
                    .position(x: layout.x(lane),y: layout.rect.minY+layout.rect.height*0.87).accessibilityHidden(true)
                    Color.clear.contentShape(Rectangle())
                        .frame(width: max(44,layout.rect.width*0.20),height: layout.rect.height*0.78)
                        .position(x: layout.x(lane),y: layout.rect.minY+layout.rect.height*0.49)
                        .gesture(DragGesture(minimumDistance: 0).onChanged { _ in controller.press(lane) }.onEnded { _ in controller.release(lane) })
                        .accessibilityElement(children: .ignore).accessibilityLabel("Pluck \(["low","middle","high"][lane]) string")
                        .accessibilityHint("Tap as the light reaches the jewel. Hold for a long ribbon.")
                        .accessibilityAddTraits(.isButton).accessibilityAction { controller.accessiblePluck(lane) }
                }
            }
            .allowsHitTesting(controller.round.phase == .playing)
        }
    }
    private func draw(_ context: inout GraphicsContext,layout: VictoryHarpLayout) {
        let round = controller.round, clock = controller.visualTime
        let length = layout.bridge-layout.top
        let approach = 2.6
        for lane in 0..<3 {
            let x = layout.x(lane),color = VictoryPalette.lanes[lane]
            let age = clock-controller.lastPluck[lane]
            let held = round.pressed.contains(lane)
            let amplitude = controller.reduceMotion ? 0 : exp(-max(0,age)*5)*min(7,layout.rect.width*0.02)
            var string = Path(); string.move(to: CGPoint(x: x,y: layout.top))
            for index in 1...45 {
                let t = Double(index)/45
                let sway = sin(t * .pi)*sin(t * .pi*5+clock*70)*amplitude
                string.addLine(to: CGPoint(x: x+sway,y: layout.top+length*t))
            }
            context.stroke(string,with: .color(color.opacity(held ? 0.85 : 0.24)),lineWidth: held ? 2.6 : 1.1)
            if age < 0.8 || held {
                context.drawLayer { layer in
                    layer.addFilter(.shadow(color: color.opacity(0.8),radius: 7))
                    layer.stroke(string,with: .color(color.opacity(held ? 0.7 : max(0,1-age*1.8))),lineWidth: 1.4)
                }
            }
            // The catch jewel is fixed to the harp's bridge. Its halo provides a readable beat target.
            let center = CGPoint(x: x,y: layout.bridge)
            let radius = max(15,layout.rect.width*0.052)
            let pulse = controller.reduceMotion ? 1 : 1+sin(clock*3+Double(lane))*0.05
            glow(&context,at: center,radius: radius*2.4,color: color.opacity(held ? 0.42 : 0.12))
            let outer = Path(ellipseIn: CGRect(x: x-radius*pulse,y: center.y-radius*pulse,width: radius*2*pulse,height: radius*2*pulse))
            context.fill(outer,with: .radialGradient(Gradient(colors: [VictoryPalette.ink.opacity(0.8),.black.opacity(0.8)]),center: center,startRadius: 0,endRadius: radius))
            context.stroke(outer,with: .color(color.opacity(0.8)),lineWidth: 1.8)
            let r = held ? radius*0.55 : radius*0.34
            var jewel = Path(); jewel.move(to: CGPoint(x: x,y: center.y-r)); jewel.addLine(to: CGPoint(x: x+r,y: center.y)); jewel.addLine(to: CGPoint(x: x,y: center.y+r)); jewel.addLine(to: CGPoint(x: x-r,y: center.y)); jewel.closeSubpath()
            context.fill(jewel,with: .linearGradient(Gradient(colors: [.white,color,color.opacity(0.5)]),startPoint: CGPoint(x: x-r,y: center.y-r),endPoint: CGPoint(x: x+r,y: center.y+r)))
        }
        for note in VictorySongRound.notes {
            let state = round.states[note.id]
            guard state == .waiting || state == .holding else { continue }
            let until = note.time-round.time
            guard until <= approach,until >= -round.window || state == .holding else { continue }
            let x = layout.x(note.lane),color = VictoryPalette.lanes[note.lane]
            let y = state == .holding ? layout.bridge : layout.top+length*(1-until/approach)
            let tail = max(layout.top,layout.top+length*(1-(note.end-round.time)/approach))
            if note.duration > 0 {
                var ribbon = Path(); ribbon.move(to: CGPoint(x: x,y: max(layout.top,tail))); ribbon.addLine(to: CGPoint(x: x,y: min(layout.bridge,y)))
                context.drawLayer { layer in
                    layer.addFilter(.shadow(color: color.opacity(0.7),radius: 7))
                    layer.stroke(ribbon,with: .color(color.opacity(state == .holding ? 0.9 : 0.5)),style: StrokeStyle(lineWidth: state == .holding ? 10 : 7,lineCap: .round))
                    layer.stroke(ribbon,with: .color(.white.opacity(0.8)),style: StrokeStyle(lineWidth: 1.2,lineCap: .round))
                }
            }
            let point = CGPoint(x: x,y: y),r = max(6,layout.rect.width*0.025)
            glow(&context,at: point,radius: r*3.5,color: color.opacity(0.6))
            let orb = Path(ellipseIn: CGRect(x: x-r,y: y-r,width: r*2,height: r*2))
            context.fill(orb,with: .radialGradient(Gradient(colors: [.white,color,color.opacity(0.6)]),center: point,startRadius: 0,endRadius: r))
            context.stroke(orb,with: .color(.white.opacity(0.8)),lineWidth: 1)
            if note.duration > 0 && state == .waiting {
                context.draw(Text("HOLD").font(.system(size: 7,weight: .bold)).foregroundColor(VictoryPalette.cream),at: CGPoint(x: x,y: y+18))
            }
        }
        for spark in controller.sparks {
            let age = clock-spark.born, color = VictoryPalette.lanes[spark.lane]
            let center = CGPoint(x: layout.x(spark.lane),y: layout.bridge)
            let radius = CGFloat(18+age*(controller.reduceMotion ? 12 : 85))
            var ring = Path(); ring.addEllipse(in: CGRect(x: center.x-radius,y: center.y-radius,width: radius*2,height: radius*2))
            context.stroke(ring,with: .color(color.opacity(max(0,0.8-age))),lineWidth: 1)
            if !controller.reduceMotion {
                for index in 0..<12 {
                    let angle = Double(index)*2.39996
                    let travel = age*(30+Double(index%4)*20)
                    let point = CGPoint(x: center.x+cos(angle)*travel,y: center.y+sin(angle)*travel-age*45)
                    glow(&context,at: point,radius: 3,color: color.opacity(max(0,1-age)))
                }
            }
            context.draw(Text(spark.perfect ? "HARMONY" : "LOVELY").font(.system(size: 9,weight: .semibold)).tracking(1.5).foregroundColor(VictoryPalette.cream.opacity(max(0,1-age))),at: CGPoint(x: center.x,y: center.y-30-(controller.reduceMotion ? 0 : age*22)))
        }
    }
}

struct VictoryCampLights: View {
    @ObservedObject var controller: VictorySongController
    var body: some View {
        Canvas { context,size in
            guard size.width > 0,size.height > 0 else { return }
            let time = controller.visualTime
            let finale = [.finale,.won].contains(controller.round.phase)
            let count = finale ? 12 : controller.round.lanterns
            for index in 0..<12 {
                let fraction = Double(index)/11
                let x = size.width*(0.10+fraction*0.80)
                let y = size.height*(0.44+sin(fraction * .pi)*0.09)
                let on = index < count
                if on {
                    let flutter = controller.reduceMotion ? 1 : 0.85+sin(time*3+Double(index))*0.15
                    glow(&context,at: CGPoint(x: x,y: y),radius: size.width*0.09,color: VictoryPalette.gold.opacity(0.30*flutter))
                    glow(&context,at: CGPoint(x: x,y: y),radius: 5,color: .white.opacity(0.9))
                }
            }
            if !controller.reduceMotion {
                for index in 0..<(finale ? 65 : 18) {
                    let i = Double(index)
                    let speed = finale ? 32.0 : 6.0
                    let x = (i*127+sin(time*0.35+i)*28).truncatingRemainder(dividingBy: size.width)
                    let rise = (i*79+time*speed).truncatingRemainder(dividingBy: size.height)
                    let y = size.height-rise
                    glow(&context,at: CGPoint(x: x,y: y),radius: index%4 == 0 ? 3.2 : 1.6,color: VictoryPalette.gold.opacity(0.3+sin(time+i)*0.2))
                }
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

private func glow(_ context: inout GraphicsContext,at center: CGPoint,radius: CGFloat,color: Color) {
    let circle = Path(ellipseIn: CGRect(x: center.x-radius,y: center.y-radius,width: radius*2,height: radius*2))
    context.fill(circle,with: .radialGradient(Gradient(colors: [color,color.opacity(0)]),center: center,startRadius: 0,endRadius: radius))
}

/// Three strings open into ribbons of light as the camp joins the final chord.
struct VictoryFinaleBloom: View {
    @ObservedObject var controller: VictorySongController
    var body: some View {
        Canvas { context,size in
            let age = controller.round.phaseTime
            let progress = controller.reduceMotion ? 1 : min(1,age/2.4)
            for lane in 0..<3 {
                let x = size.width*(0.3+Double(lane)*0.2)
                let color = VictoryPalette.lanes[lane]
                let start = CGPoint(x: x,y: size.height*0.85)
                let end = CGPoint(x: size.width*(0.12+Double(lane)*0.38),y: size.height*0.13)
                let c1 = CGPoint(x: size.width*(lane == 0 ? 0.02 : lane == 2 ? 0.98 : 0.8),y: size.height*0.64)
                let c2 = CGPoint(x: size.width*(lane == 0 ? 0.02 : lane == 2 ? 0.98 : 0.2),y: size.height*0.3)
                var path = Path(); path.move(to: start); path.addCurve(to: end,control1: c1,control2: c2)
                let visible = path.trimmedPath(from: 0,to: progress)
                context.drawLayer { layer in
                    layer.addFilter(.shadow(color: color,radius: 14))
                    layer.stroke(visible,with: .color(color.opacity(0.65)),style: StrokeStyle(lineWidth: 3,lineCap: .round))
                    layer.stroke(visible,with: .color(.white.opacity(0.8)),lineWidth: 0.8)
                }
                let tip = victoryCurvePoint(t: CGFloat(progress),start: start,c1: c1,c2: c2,end: end)
                glow(&context,at: tip,radius: 45,color: color.opacity(0.65))
                glow(&context,at: tip,radius: 9,color: .white)
                if progress >= 1 {
                    for index in 0..<14 {
                        let angle = Double(index)*2.39996
                        let travel = controller.reduceMotion ? 22 : (age-2.4)*(25+Double(index%4)*13)
                        glow(&context,at: CGPoint(x: end.x+cos(angle)*travel,y: end.y+sin(angle)*travel),radius: 3,color: color.opacity(max(0,1-(age-2.4)*0.6)))
                    }
                }
            }
        }
    }
}

private func victoryCurvePoint(t: CGFloat,start: CGPoint,c1: CGPoint,c2: CGPoint,end: CGPoint) -> CGPoint {
    let u = 1-t
    let a = u*u*u, b = 3*u*u*t, c = 3*u*t*t, d = t*t*t
    let x = start.x*a + c1.x*b + c2.x*c + end.x*d
    let y = start.y*a + c1.y*b + c2.y*c + end.y*d
    return CGPoint(x: x,y: y)
}
