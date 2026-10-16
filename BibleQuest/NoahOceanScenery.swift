import SwiftUI

struct NoahOceanPath: Shape {
    var progress: CGFloat = 1
    var animatableData: CGFloat { get { progress } set { progress = newValue } }
    func path(in rect: CGRect) -> Path {
        let route = NoahVoyageRoute(width: rect.width)
        let total = progress.clamped(to: 0...1)*6
        var path = Path(); path.move(to: route.stop(0))
        for index in 0..<6 where CGFloat(index) < total {
            let a = route.stop(index),b = route.stop(index+1),mid = (a.y+b.y)/2
            let c1 = CGPoint(x: a.x,y: mid),c2 = CGPoint(x: b.x,y: mid)
            let t = min(1,total-CGFloat(index))
            if t >= 1 { path.addCurve(to: b,control1: c1,control2: c2) }
            else {
                // de Casteljau subdivision keeps the gold trail exactly on the same parameter as the ship.
                let q1 = mix(a,c1,t),q2 = mix(c1,c2,t),q3 = mix(c2,b,t)
                let r1 = mix(q1,q2,t),r2 = mix(q2,q3,t)
                path.addCurve(to: mix(r1,r2,t),control1: q1,control2: r1)
            }
        }
        return path
    }
    private func mix(_ a: CGPoint,_ b: CGPoint,_ t: CGFloat) -> CGPoint { CGPoint(x: a.x+(b.x-a.x)*t,y: a.y+(b.y-a.y)*t) }
}

struct NoahOceanScenery: View {
    let width: CGFloat
    var body: some View {
        ZStack {
            LinearGradient(stops: [
                .init(color: Color(hex: "#168D95"),location: 0),
                .init(color: Color(hex: "#087786"),location: 0.28),
                .init(color: Color(hex: "#123C58"),location: 0.48),
                .init(color: Color(hex: "#173B58"),location: 0.62),
                .init(color: Color(hex: "#14868E"),location: 0.80),
                .init(color: Color(hex: "#64C8BB"),location: 1)
            ],startPoint: .top,endPoint: .bottom)
            Rectangle().fill(ImagePaint(image: Image("NoahVoyageWater"),scale: 0.48)).blendMode(.softLight).opacity(0.72)
            LinearGradient(colors: [Color(hex: "#B7F3CE").opacity(0.12),.clear,Color(hex: "#061C3A").opacity(0.12)],startPoint: .topLeading,endPoint: .bottomTrailing)
            // Coastlines stay off the navigable channel. Alpha silhouettes make the surf follow the actual rocks.
            island("NoahVoyageShore",width: width*0.88,x: width*1.01,y: 430,mirror: false)
            island("NoahVoyageShore",width: width*0.57,x: -width*0.035,y: 1085,mirror: true)
            island("NoahVoyageReef",width: width*0.43,x: width*1.01,y: 1510,mirror: false)
            island("NoahVoyageReef",width: width*0.47,x: -width*0.035,y: 1980,mirror: true)
            island("NoahVoyageReef",width: width*0.35,x: width*0.99,y: 2390,mirror: false)
            island("NoahVoyageArarat",width: width*0.65,x: -width*0.025,y: 2880,mirror: false)
            // Sun shafts return with the dove, long before the final rainbow comes into view.
            Ellipse().fill(Color(hex: "#FFEDBC").opacity(0.11)).frame(width: width*1.2,height: 700).rotationEffect(.degrees(-25)).blur(radius: 45).position(x: width*0.9,y: 2900)
        }.frame(width: width,height: NoahVoyageRoute.height).clipped().accessibilityHidden(true).allowsHitTesting(false)
    }
    private func island(_ asset: String,width islandWidth: CGFloat,x: CGFloat,y: CGFloat,mirror: Bool) -> some View {
        Image(asset).resizable().scaledToFit().frame(width: min(390,islandWidth),height: min(585,islandWidth*1.5))
            .scaleEffect(x: mirror ? -1 : 1)
            .shadow(color: Color(hex: "#E4FFEB").opacity(0.75),radius: 1.4)
            .shadow(color: Color(hex: "#A4F1E6").opacity(0.28),radius: 5)
            .shadow(color: Color(hex: "#032E3E").opacity(0.5),radius: 16,x: 2,y: 13)
            .position(x: x,y: y)
    }
}

struct NoahSeaMotion: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let visible: ClosedRange<CGFloat>
    let active: Bool
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0/24,paused: reduceMotion || !active)) { timeline in
            Canvas { context,size in
                guard size.width > 0 else { return }
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                waves(&context,width: size.width,time: time)
                weather(&context,width: size.width,time: time)
                rainbow(&context,width: size.width,time: time)
                birds(&context,width: size.width,time: time)
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
    private func waves(_ context: inout GraphicsContext,width: CGFloat,time: Double) {
        let start = max(0,Int(visible.lowerBound/37)-1),end = min(96,Int(visible.upperBound/37)+1)
        guard start <= end else { return }
        for index in start...end {
            let baseY = CGFloat(index)*37
            let storm = exp(-pow((Double(baseY)-1940)/470,2))
            let phase = time*(0.75+storm*0.7)+Double(index)*1.79
            let amplitude = 4+storm*8
            var path = Path()
            for step in 0...28 {
                let x = width*CGFloat(step)/28
                let y = baseY+sin(Double(x)/62+phase)*amplitude+sin(Double(x)/131-phase*0.55)*3
                let point = CGPoint(x: x,y: y)
                if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            context.stroke(path,with: .color(Color(hex: "#A4E5DD").opacity(0.10+storm*0.065)),style: StrokeStyle(lineWidth: 1+storm*1.2,lineCap: .round))
            // Broken crescent crests slide independently of the long swells.
            let drift = (time*10+Double(index)*89).truncatingRemainder(dividingBy: Double(width)+140)-100
            var crest = Path()
            for step in 0...12 {
                let x = CGFloat(drift)+CGFloat(step)*8
                let y = baseY+sin(Double(x)/62+phase)*amplitude+sin(Double(x)/131-phase*0.55)*3-1
                if step == 0 { crest.move(to: CGPoint(x: x,y: y)) } else { crest.addLine(to: CGPoint(x: x,y: y)) }
            }
            context.stroke(crest,with: .linearGradient(Gradient(colors: [.clear,.white.opacity(0.32+storm*0.16),.clear]),startPoint: CGPoint(x: drift,y: baseY),endPoint: CGPoint(x: drift+96,y: baseY)),style: StrokeStyle(lineWidth: 1.4+storm,lineCap: .round))
            if storm < 0.5 {
                for sparkle in 0..<2 {
                    let x = (Double(index*71+sparkle*133)+sin(time*0.3+Double(index))*9).truncatingRemainder(dividingBy: Double(width))
                    let alpha = 0.10+(sin(time*1.8+Double(index+sparkle))+1)*0.12
                    let rect = CGRect(x: x,y: Double(baseY)+12,width: 2.5,height: 1.5)
                    context.fill(Path(ellipseIn: rect),with: .color(.white.opacity(alpha)))
                }
            }
        }
    }
    private func weather(_ context: inout GraphicsContext,width: CGFloat,time: Double) {
        // Storm effects are geographically fixed to the two flood chapters, not to the screen.
        if visible.upperBound > 1400 && visible.lowerBound < 2460 {
            let top = max(1420,visible.lowerBound),bottom = min(2440,visible.upperBound)
            let cloud = Path(ellipseIn: CGRect(x: -width*0.1,y: 1790,width: width*1.2,height: 440))
            context.fill(cloud,with: .radialGradient(Gradient(colors: [Color(hex: "#06182F").opacity(0.2),.clear]),center: CGPoint(x: width*0.5,y: 2010),startRadius: 0,endRadius: width*0.8))
            if !reduceMotion {
                for index in 0..<70 {
                    let seed = Double(index)
                    let y = 1400+(seed*53+time*125).truncatingRemainder(dividingBy: 1060)
                    guard y >= top,y <= bottom else { continue }
                    let period = Double(width)+40
                    let rawX = seed*73-time*20
                    let x = rawX-floor(rawX/period)*period-20
                    var drop = Path(); drop.move(to: CGPoint(x: x,y: y)); drop.addLine(to: CGPoint(x: x-5,y: y+15))
                    context.stroke(drop,with: .color(Color(hex: "#D4EBFF").opacity(0.19)),style: StrokeStyle(lineWidth: 0.8,lineCap: .round))
                }
            }
        }
    }
    private func rainbow(_ context: inout GraphicsContext,width: CGFloat,time: Double) {
        guard visible.upperBound > 2850 else { return }
        let colors: [Color] = [Color(hex: "#EF92A2"),Color(hex: "#F3B58C"),Color(hex: "#F9DE9A"),Color(hex: "#A9E2BF"),Color(hex: "#8AD9DE"),Color(hex: "#B6C3EE"),Color(hex: "#D6B3E9")]
        let radius = min(330,width*0.69)
        for (index,color) in colors.enumerated() {
            let rx = radius-CGFloat(index)*7,ry = rx*0.75
            var arc = Path()
            for step in 0...48 {
                let angle = Double(step)/48 * .pi
                let point = CGPoint(x: width/2+cos(angle)*rx,y: 3170-sin(angle)*ry)
                if step == 0 { arc.move(to: point) } else { arc.addLine(to: point) }
            }
            context.drawLayer { layer in
                layer.addFilter(.shadow(color: color.opacity(0.3),radius: 7))
                layer.stroke(arc,with: .color(color.opacity(0.36)),style: StrokeStyle(lineWidth: 6,lineCap: .round))
            }
        }
    }
    private func birds(_ context: inout GraphicsContext,width: CGFloat,time: Double) {
        for index in 0..<4 {
            let baseY: CGFloat = index < 2 ? 600 : 2670
            guard visible.contains(baseY) || visible.contains(baseY+120) else { continue }
            let phase = time*0.12+Double(index)*1.8
            let x = width*(0.5+sin(phase)*0.32),y = baseY+CGFloat(cos(phase*0.8)*55)
            let wing = reduceMotion ? 3 : sin(time*3.6+Double(index))*5
            var bird = Path(); bird.move(to: CGPoint(x: x-10,y: y+wing)); bird.addQuadCurve(to: CGPoint(x: x,y: y+2),control: CGPoint(x: x-5,y: y-5)); bird.addQuadCurve(to: CGPoint(x: x+10,y: y+wing),control: CGPoint(x: x+5,y: y-5))
            context.stroke(bird,with: .color(.white.opacity(index < 2 ? 0.6 : 0.9)),style: StrokeStyle(lineWidth: 2,lineCap: .round))
        }
    }
}
