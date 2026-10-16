import SwiftUI

struct NoahQuestMap: View {
    let progress: CGFloat
    let furthest: CGFloat
    let sailing: Bool
    let reverse: Bool
    var compact = false
    let visible: ClosedRange<CGFloat>
    let active: Bool
    let onSelect: (Int) -> Void
    var body: some View {
        GeometryReader { geo in
            let route = NoahVoyageRoute(width: geo.size.width)
            ZStack {
                NoahOceanScenery(width: geo.size.width)
                NoahSeaMotion(visible: visible,active: active)
                NoahOceanPath().stroke(Color(hex: "#032E46").opacity(0.18),style: StrokeStyle(lineWidth: 19,lineCap: .round)).blur(radius: 4).offset(y: 3)
                NoahOceanPath().stroke(Color(hex: "#B8EDE3").opacity(0.22),style: StrokeStyle(lineWidth: 2,lineCap: .round,dash: [2,11]))
                NoahOceanPath(progress: progress).stroke(Color(hex: "#F8DA98").opacity(0.70),style: StrokeStyle(lineWidth: 2,lineCap: .round,dash: [3,8])).shadow(color: Color(hex: "#F9E2A4").opacity(0.35),radius: 5)
                ForEach(NoahVoyageChapter.allCases) { chapter in
                    NoahHarborMarker(chapter: chapter,compact: compact,current: chapter.rawValue == route.index(at: progress),visited: NoahVoyageRoute.progress(for: chapter.rawValue) <= furthest+0.001) { onSelect(chapter.rawValue) }
                        .position(x: route.stop(chapter.rawValue).x,y: route.stop(chapter.rawValue).y+29)
                }
                NoahArkMotion(progress: progress,sailing: sailing,reverse: reverse,width: geo.size.width,visible: visible,active: active)
            }.frame(width: geo.size.width,height: NoahVoyageRoute.height).clipped()
        }.frame(height: NoahVoyageRoute.height)
    }
}

private struct NoahHarborMarker: View {
    let chapter: NoahVoyageChapter
    var compact = false
    let current: Bool
    let visited: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle().fill(Color(hex: "#B2F0DF").opacity(current ? 0.16 : 0.05)).frame(width: 88,height: 88)
                    Circle().stroke(Color(hex: "#D2F2E4").opacity(current ? 0.5 : 0.13),lineWidth: 1).frame(width: 78,height: 78)
                    Circle().fill(LinearGradient(colors: [Color(hex: "#EED298"),Color(hex: "#9D7540"),Color(hex: "#D9B06E")],startPoint: .topLeading,endPoint: .bottomTrailing)).frame(width: 62,height: 62)
                    Circle().fill(LinearGradient(colors: [Color(hex: current ? "#225D67" : "#1D4657"),Color(hex: "#102D40")],startPoint: .topLeading,endPoint: .bottomTrailing)).frame(width: 53,height: 53)
                        .overlay(Circle().stroke(Color(hex: "#FFF0C6").opacity(0.5),lineWidth: 0.7))
                    if chapter == .promise {
                        NoahRainbowSymbol().frame(width: 29,height: 22)
                    } else {
                        Image(systemName: chapter.symbol).font(.system(size: 23,weight: .light)).foregroundStyle(Color(hex: "#F3E2BD"))
                    }
                    ForEach(0..<8,id: \.self) { index in
                        Circle().fill(Color(hex: "#FFF0C4").opacity(0.8)).frame(width: 2,height: 2)
                            .offset(x: cos(Double(index)*Double.pi/4)*28.5,y: sin(Double(index)*Double.pi/4)*28.5)
                    }
                    Text(String(format: "%02d",chapter.rawValue+1)).font(.system(size: 8,weight: .bold,design: .monospaced)).foregroundStyle(Color(hex: "#17384A"))
                        .frame(width: 22,height: 18).background(Color(hex: "#EDD39E"),in: Capsule()).overlay(Capsule().stroke(Color(hex: "#FFF0CF"),lineWidth: 1)).offset(x: -29,y: -27)
                }.frame(height: 66)
                VStack(spacing: 3) {
                    Text(chapter.title).font(.system(size: 14,weight: .semibold,design: .serif)).foregroundStyle(Color(hex: "#FFF5DE"))
                    Text(chapter.subtitle.uppercased()).font(.system(size: 6,weight: .semibold)).tracking(1.4).foregroundStyle(Color(hex: "#B5D9D6"))
                }.padding(.horizontal,15).padding(.vertical,10)
                    .background(Color(hex: "#0D3346").opacity(0.9),in: RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Color(hex: current ? "#EAD099" : "#749B9C").opacity(0.6),lineWidth: 0.8)).frame(height: 50).offset(x: compact ? -55 : 0)
            }.frame(width: 178,height: 124).shadow(color: .black.opacity(0.23),radius: 9,y: 6).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityElement(children: .ignore).accessibilityAddTraits(.isButton)
            .accessibilityLabel("Chapter \(chapter.rawValue+1), \(chapter.title)\(current ? ", current stop" : "")\(visited ? ", visited" : "")")
            .accessibilityHint("Sail the ark to this chapter")
    }
}

private struct NoahRainbowSymbol: View {
    var body: some View {
        Canvas { context,size in
            let colors = [Color(hex: "#EFACAE"),Color(hex: "#EBD491"),Color(hex: "#9AD8B9"),Color(hex: "#A7D2E3")]
            for index in 0..<4 {
                var arc = Path()
                let r = size.width/2-CGFloat(index)*3
                arc.addArc(center: CGPoint(x: size.width/2,y: size.height*0.84),radius: r,startAngle: .degrees(180),endAngle: .degrees(0),clockwise: false)
                context.stroke(arc,with: .color(colors[index]),style: StrokeStyle(lineWidth: 2,lineCap: .round))
            }
        }
    }
}

private struct NoahArkMotion: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let progress: CGFloat
    let sailing: Bool
    let reverse: Bool
    let width: CGFloat
    let visible: ClosedRange<CGFloat>
    let active: Bool
    var body: some View {
        let route = NoahVoyageRoute(width: width)
        let point = route.arkPoint(progress)
        let onScreen = point.y > visible.lowerBound-180 && point.y < visible.upperBound+180
        TimelineView(.animation(minimumInterval: 1.0/30,paused: reduceMotion || !active || !onScreen)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            let heading = route.heading(progress)+(reverse ? Double.pi : 0)
            let bob = reduceMotion ? 0 : sin(time*1.7)*2.2
            let roll = reduceMotion ? 0 : sin(time*1.25)*0.018
            ZStack {
                Canvas { context,size in
                    let u = min(1.12,max(0.85,width/390))
                    let center = CGPoint(x: size.width/2,y: size.height/2)
                    for index in 0..<5 {
                        let phase = (time*(sailing ? 0.65 : 0.25)+Double(index)/5).truncatingRemainder(dividingBy: 1)
                        let y = center.y-40-phase*(sailing ? 110 : 45)
                        let spread = 12+phase*(sailing ? 50 : 30)
                        var foam = Path(); foam.move(to: CGPoint(x: center.x-spread*u,y: y))
                        foam.addQuadCurve(to: CGPoint(x: center.x+spread*u,y: y),control: CGPoint(x: center.x,y: y+20))
                        context.stroke(foam,with: .color(Color(hex: "#E2FFF4").opacity((1-phase)*(sailing ? 0.50 : 0.26))),style: StrokeStyle(lineWidth: (2-phase)*u,lineCap: .round))
                    }
                    let ripple = Path(ellipseIn: CGRect(x: center.x-44*u,y: center.y-35*u,width: 88*u,height: 100*u))
                    context.stroke(ripple,with: .color(Color(hex: "#B5F2DF").opacity(0.17)),lineWidth: 2)
                }.frame(width: 210,height: 320).rotationEffect(.radians(heading))
                Image("NoahVoyageArk").resizable().scaledToFit().frame(width: 112,height: 166)
                    .shadow(color: Color(hex: "#032E40").opacity(0.6),radius: 9,x: 3,y: 12)
                    .rotationEffect(.radians(heading+roll)).offset(y: bob)
            }.frame(width: 210,height: 320).position(point)
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}
