import SwiftUI

struct ArkAfloatExterior: View {
    @ObservedObject var controller: ArkAfloatController
    var cutaway = false
    var body: some View {
        GeometryReader { g in
            let w = g.size.width,h = g.size.height,r = controller.round
            let t = controller.reduceMotion ? 0 : controller.time
            let lifting = r.phase == .launching
            let afloat = [.caring,.finale,.won].contains(r.phase)
            let u = lifting ? min(1,r.phaseTime/10) : afloat || cutaway ? 1.0 : 0
            let lift = u*u*(3-2*u)
            ZStack {
                Image("FloodStorm").resizable().scaledToFill().frame(width: w,height: h).clipped()
                    .overlay(LinearGradient(colors: [FloodPalette.ink.opacity(0.35),.clear,FloodPalette.ink.opacity(0.08)],startPoint: .top,endPoint: .bottom))
                    .accessibilityHidden(true)
                if !afloat && !cutaway {
                    Image("NoahVoyageShore").resizable().scaledToFit().frame(width: w*0.42,height: h*0.42)
                        .position(x: w*0.10,y: h*0.58).opacity(max(0,0.85-lift)).accessibilityHidden(true)
                }
                FloodSea(time: t,surface: cutaway ? 0.70 : 0.80-0.17*lift,foreground: false).accessibilityHidden(true)
                ship(w,h,t,lift)
                FloodSea(time: t,surface: cutaway ? 0.70 : 0.80-0.17*lift,foreground: true).accessibilityHidden(true)
                FloodRain(time: t,density: cutaway ? 0.6 : 1).allowsHitTesting(false).accessibilityHidden(true)
                if lifting {
                    VStack(spacing: 7) {
                        Image(systemName: "arrow.up.and.down.and.sparkles").font(.system(size: 21,weight: .ultraLight))
                        Text(r.phaseTime < 4 ? "THE WATERS ARE RISING" : r.phaseTime < 9 ? "LOOK. WE’RE FLOATING." : "A NEW JOURNEY BEGINS")
                            .font(.system(size: 8,weight: .bold)).tracking(2)
                    }.foregroundStyle(FloodPalette.cream).padding(15).background(FloodPalette.ink.opacity(0.65),in: Capsule()).position(x: w*0.5,y: h*0.19).allowsHitTesting(false)
                }
                Canvas { c,s in
                    for ripple in controller.ripples {
                        let age = controller.time-ripple.born,radius = 5+age*30
                        for i in 0..<2 {
                            let size = radius+Double(i)*9
                            let rect = CGRect(x: ripple.point.x*s.width-size,y: ripple.point.y*s.height-size*0.35,width: size*2,height: size*0.7)
                            c.stroke(Path(ellipseIn: rect),with: .color(FloodPalette.cream.opacity(max(0,0.7-age/1.6))),lineWidth: 1)
                        }
                    }
                }.allowsHitTesting(false).accessibilityHidden(true)
                Color.clear.contentShape(Rectangle()).gesture(DragGesture(minimumDistance: 0).onChanged { value in controller.splash(.init(x: value.location.x/w,y: value.location.y/h)) }).accessibilityLabel("Rain and waves. Touch to make ripples.")
            }.clipped()
        }.clipShape(RoundedRectangle(cornerRadius: 24)).overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(FloodPalette.aqua.opacity(0.25)))
    }
    private func ship(_ w: Double,_ h: Double,_ t: Double,_ lift: Double) -> some View {
        let phase = controller.round.phase
        let bob = controller.reduceMotion || lift < 0.01 ? 0 : sin(t*0.85)*4
        let end = phase == .finale || phase == .won
        let zoom = phase == .won ? 0.775 : end ? max(0.775,1-controller.round.phaseTime*0.025) : 1.0
        let bw = w*0.98
        return ZStack {
            Image(cutaway ? "FloodCutaway" : "FloodExterior").resizable().scaledToFit()
            if cutaway {
                Image("ParadeSheep").resizable().scaledToFit().frame(width: bw*0.12,height: bw*0.12).position(x: bw*0.53,y: bw*0.315)
                Image("ParadeMonkey").resizable().scaledToFit().frame(width: bw*0.095,height: bw*0.11).position(x: bw*0.61,y: bw*0.32)
                Image("ParadeElephant").resizable().scaledToFit().frame(width: bw*0.15,height: bw*0.15).position(x: bw*0.27,y: bw*0.30)
                Image("ParadeTiger").resizable().scaledToFit().frame(width: bw*0.13,height: bw*0.13).position(x: bw*0.79,y: bw*0.315)
            }
        }.frame(width: bw,height: bw*2/3).scaleEffect(zoom)
            .rotationEffect(.degrees(controller.reduceMotion ? 0 : sin(t*0.65)*1.3*lift))
            .shadow(color: .black.opacity(0.3),radius: 8,y: 10)
            .position(x: w*0.5,y: h*(cutaway ? 0.58 : 0.57-0.055*lift)+bob)
            .accessibilityElement(children: .ignore).accessibilityLabel(cutaway ? "A living cutaway of Noah's ark, with warm rooms and animals inside." : "Noah's ark floating safely on the rising water.")
    }

}

struct FloodSea: View {
    let time: Double
    var surface = 0.64
    var foreground = false
    var body: some View {
        Canvas { context,size in paint(&context,size: size) }.allowsHitTesting(false)
    }
    private func paint(_ c: inout GraphicsContext,size: CGSize) {
        let width = Double(size.width),height = Double(size.height)
        let horizon = height*surface,layers = foreground ? 3 : 4
        for layer in 0..<layers {
            let n = Double(layer)
            let offset: Double = foreground ? 0.10 : -0.035
            let base = horizon+n*height*offset
            let amplitude = (foreground ? 5.0 : 3.0)+n*2
            var crest = Path();crest.move(to: CGPoint(x: -5,y: base))
            for i in 0...90 {
                let x = Double(i)/90*width
                let first = sin(x/width*9+time*(0.70+n*0.13)+n*2.7)*amplitude
                let second = sin(x/width*18-time*0.53)*amplitude*0.38
                crest.addLine(to: CGPoint(x: x,y: base+first+second))
            }
            var water = crest;water.addLine(to: CGPoint(x: width,y: height));water.addLine(to: CGPoint(x: 0,y: height));water.closeSubpath()
            if foreground && layer == 0 {
                var texture = c;texture.clip(to: water)
                texture.draw(Image("FloodStorm"),in: CGRect(origin: .zero,size: size))
                texture.fill(water,with: .color(Color(hex: "#17637A").opacity(0.12)))
            }
            c.stroke(crest,with: .color(FloodPalette.aqua.opacity(foreground ? 0.32 : 0.12)),lineWidth: foreground ? 1.2 : 0.7)
            for i in 0..<16 {
                let x = (Double(i)*0.173+time*0.018).truncatingRemainder(dividingBy: 1)*width
                let y = base+12+Double(i%5)*12
                var foam = Path();foam.move(to: CGPoint(x: x,y: y))
                foam.addQuadCurve(to: CGPoint(x: x+12+Double(i%3)*8,y: y-2),control: CGPoint(x: x+6,y: y-5))
                c.stroke(foam,with: .color(.white.opacity(foreground ? 0.22 : 0.1)),lineWidth: 0.8)
            }
        }
    }
}
struct FloodRain: View {
    let time: Double
    var density = 1.0
    var body: some View {
        Canvas { c,s in
            for i in 0..<Int(80*density) {
                let n = Double(i),speed = 0.65+Double(i%5)*0.06
                let x = ((n*0.618-time*0.035).truncatingRemainder(dividingBy: 1)+1).truncatingRemainder(dividingBy: 1)*s.width
                let y = (n*0.371+time*speed).truncatingRemainder(dividingBy: 1)*s.height
                var p = Path();p.move(to: .init(x: x,y: y));p.addLine(to: .init(x: x-3,y: y+9+Double(i%4)*4))
                c.stroke(p,with: .color(.white.opacity(0.10+Double(i%3)*0.06)),lineWidth: i%4 == 0 ? 1 : 0.5)
            }
        }
    }
}
