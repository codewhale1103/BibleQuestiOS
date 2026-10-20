import SwiftUI

enum FloodPalette {
    static let ink = Color(hex: "#092C39")
    static let teal = Color(hex: "#1B5B69")
    static let cream = Color(hex: "#FFF1D3")
    static let gold = Color(hex: "#EBC586")
    static let aqua = Color(hex: "#A9DCD7")
}

struct FloodBasket: View {
    var apples = 0
    var body: some View {
        GeometryReader { g in
            let w = g.size.width,h = g.size.height
            ZStack {
                Ellipse().fill(.black.opacity(0.24)).frame(width: w*0.85,height: h*0.12).blur(radius: 3).offset(y: h*0.35)
                Ellipse().trim(from: 0.5,to: 1).stroke(LinearGradient(colors: [Color(hex: "#5D341E"),Color(hex: "#DFA567"),Color(hex: "#654128")],startPoint: .leading,endPoint: .trailing),lineWidth: w*0.06).frame(width: w*0.7,height: h*0.75).offset(y: -h*0.08)
                if apples > 0 { ForEach(0..<apples,id: \.self) { i in FloodApple().frame(width: w*0.31,height: h*0.4).offset(x: Double(i-1)*w*0.19,y: -h*0.02-Double(i%2)*h*0.1) } }
                Canvas { c,s in
                    var p = Path();p.move(to: .init(x: s.width*0.05,y: s.height*0.35));p.addQuadCurve(to: .init(x: s.width*0.95,y: s.height*0.35),control: .init(x: s.width*0.5,y: s.height*0.50));p.addLine(to: .init(x: s.width*0.84,y: s.height*0.89));p.addQuadCurve(to: .init(x: s.width*0.16,y: s.height*0.89),control: .init(x: s.width*0.5,y: s.height*1.03));p.closeSubpath()
                    c.fill(p,with: .linearGradient(.init(colors: [Color(hex: "#E0B477"),Color(hex: "#996638"),Color(hex: "#5B3822")]),startPoint: .zero,endPoint: .init(x: s.width,y: s.height)))
                    c.clip(to: p)
                    for i in 0..<15 {
                        let x = Double(i)/14*s.width
                        var strand = Path();strand.move(to: .init(x: x,y: 0));strand.addQuadCurve(to: .init(x: s.width*0.5+(x-s.width*0.5)*0.72,y: s.height),control: .init(x: x,y: s.height*0.5))
                        c.stroke(strand,with: .color(.black.opacity(0.24)),lineWidth: 2)
                        c.stroke(strand,with: .color(Color(hex: "#F4CE93").opacity(0.45)),style: .init(lineWidth: 1,dash: [3,3]))
                    }
                    for i in 0..<12 {
                        let y = s.height*0.38+Double(i)*s.height*0.052
                        var strand = Path();strand.move(to: .init(x: 0,y: y));strand.addQuadCurve(to: .init(x: s.width,y: y),control: .init(x: s.width*0.5,y: y+s.height*0.1))
                        c.stroke(strand,with: .color(Color(hex: "#EBC18C").opacity(0.7)),lineWidth: 1.7)
                    }
                }
                Ellipse().stroke(LinearGradient(colors: [Color(hex: "#F3D2A2"),Color(hex: "#664027")],startPoint: .top,endPoint: .bottom),lineWidth: 4).frame(width: w*0.9,height: h*0.17).offset(y: -h*0.12)
            }
        }.accessibilityHidden(true)
    }
}
struct FloodApple: View {
    var body: some View {
        GeometryReader { g in
            ZStack {
                Ellipse().fill(.black.opacity(0.22)).frame(width: g.size.width*0.75,height: g.size.height*0.13).offset(y: g.size.height*0.36).blur(radius: 2)
                RoundedRectangle(cornerRadius: g.size.width*0.39).fill(RadialGradient(colors: [Color(hex: "#FFB276"),Color(hex: "#D85A35"),Color(hex: "#942D2C"),Color(hex: "#57251E")],center: .topLeading,startRadius: 1,endRadius: g.size.width)).frame(width: g.size.width*0.83,height: g.size.height*0.74).rotationEffect(.degrees(-6))
                Capsule().fill(Color(hex: "#54331D")).frame(width: 3,height: g.size.height*0.22).rotationEffect(.degrees(18)).offset(y: -g.size.height*0.38)
                Ellipse().fill(LinearGradient(colors: [Color(hex: "#C1C97F"),Color(hex: "#496846")],startPoint: .topLeading,endPoint: .bottomTrailing)).frame(width: g.size.width*0.34,height: g.size.height*0.15).rotationEffect(.degrees(-25)).offset(x: g.size.width*0.17,y: -g.size.height*0.34)
                Ellipse().fill(.white.opacity(0.30)).frame(width: g.size.width*0.12,height: g.size.height*0.22).rotationEffect(.degrees(25)).offset(x: -g.size.width*0.22,y: -g.size.height*0.15).blur(radius: 2)
            }.frame(width: g.size.width,height: g.size.height)
        }.accessibilityHidden(true)
    }
}
struct FloodLantern: View {
    let time: Double
    var lit = true
    var body: some View {
        GeometryReader { g in
            let w = g.size.width,h = g.size.height
            ZStack {
                if lit { Circle().fill(RadialGradient(colors: [FloodPalette.gold.opacity(0.65),.orange.opacity(0.16),.clear],center: .center,startRadius: 0,endRadius: w*0.8)).frame(width: w*2,height: w*2).blendMode(.screen) }
                Ellipse().stroke(LinearGradient(colors: [FloodPalette.gold,Color(hex: "#543B25")],startPoint: .topLeading,endPoint: .bottomTrailing),lineWidth: 4).frame(width: w*0.48,height: h*0.50).offset(y: -h*0.18)
                Capsule().fill(Color(hex: "#5A442C")).frame(width: 3,height: h*0.53).offset(x: -w*0.29,y: h*0.02)
                Capsule().fill(Color(hex: "#C99D54")).frame(width: 3,height: h*0.53).offset(x: w*0.29,y: h*0.02)
                if lit {
                    Ellipse().fill(Color(hex: "#FFB742")).frame(width: w*0.23,height: h*0.40).blur(radius: 4).offset(y: h*0.06)
                    Ellipse().fill(LinearGradient(colors: [.white,FloodPalette.cream,.orange],startPoint: .bottom,endPoint: .top)).frame(width: w*0.13,height: h*0.28).rotationEffect(.degrees(sin(time*7)*5),anchor: .bottom).offset(y: h*0.08)
                }
                Ellipse().fill(LinearGradient(colors: [FloodPalette.gold,Color(hex: "#8D6433"),Color(hex: "#3D2D22")],startPoint: .top,endPoint: .bottom)).frame(width: w*0.80,height: h*0.19).offset(y: h*0.28)
                Capsule().fill(Color(hex: "#B88A48")).frame(width: w*0.50,height: 4).offset(y: -h*0.23)
            }.frame(width: g.size.width,height: g.size.height)
        }.accessibilityHidden(true)
    }
}
struct FloodBlanket: View {
    var folded = false
    var body: some View {
        GeometryReader { g in
            let cloth = FloodClothShape(folded: folded)
            ZStack {
                cloth.fill(LinearGradient(colors: [Color(hex: "#B8CBC9"),Color(hex: "#618C90"),Color(hex: "#285D6A")],startPoint: .topLeading,endPoint: .bottomTrailing))
                Canvas { c,s in
                    for i in 0..<30 {
                        let y = Double(i)/30*s.height
                        var p = Path();p.move(to: .init(x: 0,y: y));p.addQuadCurve(to: .init(x: s.width,y: y+sin(Double(i))*2),control: .init(x: s.width*0.4,y: y+4))
                        c.stroke(p,with: .color(.white.opacity(i%5 == 0 ? 0.38 : 0.1)),lineWidth: i%5 == 0 ? 2 : 0.5)
                    }
                    for i in 0..<6 { let x = Double(i)/5*s.width;c.fill(Path(CGRect(x: x,y: 0,width: 1,height: s.height)),with: .color(.black.opacity(0.12))) }
                }.clipShape(cloth)
                cloth.stroke(FloodPalette.gold.opacity(0.65),lineWidth: 1.4).padding(5)
            }.shadow(color: .black.opacity(0.3),radius: 4,y: 4)
                .rotationEffect(.degrees(folded ? -7 : 7))
        }.accessibilityHidden(true)
    }
}
private struct FloodClothShape: Shape {
    let folded: Bool
    func path(in rect: CGRect) -> Path {
        if folded { return Path(roundedRect: rect,cornerRadius: 10) }
        let w = rect.width,h = rect.height
        var p = Path();p.move(to: .init(x: w*0.08,y: h*0.08))
        p.addQuadCurve(to: .init(x: w*0.88,y: h*0.04),control: .init(x: w*0.46,y: -h*0.04))
        p.addQuadCurve(to: .init(x: w*0.98,y: h*0.78),control: .init(x: w*0.90,y: h*0.46))
        p.addCurve(to: .init(x: w*0.06,y: h*0.84),control1: .init(x: w*0.70,y: h*1.12),control2: .init(x: w*0.32,y: h*0.72))
        p.addQuadCurve(to: .init(x: w*0.08,y: h*0.08),control: .init(x: -w*0.02,y: h*0.40));p.closeSubpath();return p
    }
}
struct FloodWood: View {
    var body: some View {
        GeometryReader { g in
            RoundedRectangle(cornerRadius: 4).fill(LinearGradient(colors: [Color(hex: "#AC713B"),Color(hex: "#704623"),Color(hex: "#C89355")],startPoint: .leading,endPoint: .trailing))
            Canvas { c,s in
                for i in 0..<8 {
                    let x = Double(i)/8*s.width
                    var p = Path();p.move(to: .init(x: x,y: 0));p.addCurve(to: .init(x: x+2,y: s.height),control1: .init(x: x+sin(Double(i))*6,y: s.height*0.35),control2: .init(x: x-4,y: s.height*0.6))
                    c.stroke(p,with: .color(.black.opacity(0.25)),lineWidth: i%2 == 0 ? 2 : 0.7)
                }
                for y in [CGFloat(0.13),0.82] {
                    c.fill(Path(CGRect(x: 0,y: s.height*y,width: s.width,height: s.height*0.06)),with: .color(Color(hex: "#492F21")))
                    for x in [CGFloat(0.15),0.85] { c.fill(Path(ellipseIn: CGRect(x: s.width*x-2,y: s.height*(y+0.03)-2,width: 4,height: 4)),with: .color(FloodPalette.gold)) }
                }
            }.clipShape(RoundedRectangle(cornerRadius: 4))
        }.shadow(color: .black.opacity(0.4),radius: 3,x: 2,y: 3).accessibilityHidden(true)
    }
}
struct FloodTarget: View {
    let symbol: String
    let time: Double
    var label: String? = nil
    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle().fill(FloodPalette.gold.opacity(0.10)).blur(radius: 3)
                Circle().strokeBorder(FloodPalette.cream.opacity(0.85),style: .init(lineWidth: 1.5,dash: [3,5],dashPhase: -time*8))
                Image(systemName: symbol).font(.system(size: 22,weight: .light)).foregroundStyle(FloodPalette.cream)
            }
            if let label { Text(label).font(.system(size: 7,weight: .bold,design: .rounded)).tracking(1.2).foregroundStyle(FloodPalette.cream).fixedSize() }
        }.shadow(color: FloodPalette.gold.opacity(0.7),radius: 8).allowsHitTesting(false).accessibilityHidden(true)
    }
}
