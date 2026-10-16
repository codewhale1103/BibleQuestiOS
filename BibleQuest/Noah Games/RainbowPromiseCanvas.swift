import SwiftUI

enum PromisePalette {
    static let ink = Color(hex: "#14384B")
    static let cream = Color(hex: "#FFF5DE")
    static let gold = Color(hex: "#EED7A3")
    static func color(_ index: Int) -> Color { Color(hex: (PromiseColor(rawValue: index) ?? .red).hex) }
}
struct RainbowPromiseBoard: View {
    @ObservedObject var controller: RainbowPromiseController
    var preview = false
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Canvas { context,size in draw(&context,size: size) }.allowsHitTesting(false).accessibilityHidden(true)
                if !preview && controller.round.phase == .weaving {
                    ForEach(0..<5,id: \.self) { index in
                        let point = controller.round.arc.point(RainbowPromiseRound.stops[index])
                        Button { controller.tapStar(index) } label: { Color.clear.frame(width: 46,height: 46).contentShape(Circle()) }
                            .buttonStyle(.plain).position(x: point.x*geo.size.width,y: point.y*geo.size.height)
                            .accessibilityLabel("Light star \(index+1) of 5")
                            .accessibilityValue(index < controller.round.checkpoint ? "Complete" : index == controller.round.checkpoint ? "Next star" : "Follow the earlier stars first")
                            .accessibilityHint("Double tap to weave this part of the rainbow")
                    }
                }
            }.coordinateSpace(name: "PromiseBoard")
                .simultaneousGesture(DragGesture(minimumDistance: 0,coordinateSpace: .named("PromiseBoard"))
                    .onChanged { value in guard !preview,geo.size.width > 0,geo.size.height > 0 else { return }; controller.drag(PromisePoint(x: value.location.x/geo.size.width,y: value.location.y/geo.size.height)) }
                    .onEnded { value in guard !preview,geo.size.width > 0,geo.size.height > 0 else { return }; controller.endDrag(PromisePoint(x: value.location.x/geo.size.width,y: value.location.y/geo.size.height)) })
        }
    }
    private func arcPath(_ band: Int,size: CGSize,to progress: Double = 1) -> Path {
        let arc = PromiseArc(band: band)
        var path = Path()
        let samples = max(1,Int(progress*72))
        for step in 0...samples {
            let point = arc.point(Double(step)/Double(samples)*progress)
            let p = CGPoint(x: point.x*size.width,y: point.y*size.height)
            if step == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        return path
    }
    private func draw(_ context: inout GraphicsContext,size: CGSize) {
        let round = controller.round,time = controller.visualTime
        let thickness = max(4.5,size.width*0.026)
        for band in 0..<7 {
            let color = PromisePalette.color(band),path = arcPath(band,size: size)
            let complete = preview || band < round.completedBands
            let active = band == round.completedBands && [.choose,.weaving].contains(round.phase)
            if complete {
                context.drawLayer { layer in
                    layer.addFilter(.shadow(color: color.opacity(0.6),radius: preview ? 5 : 9))
                    layer.stroke(path,with: .color(color.opacity(preview ? 0.7 : 0.9)),style: StrokeStyle(lineWidth: thickness,lineCap: .round))
                    layer.stroke(path,with: .color(.white.opacity(0.20)),lineWidth: 1.2)
                }
            } else {
                context.stroke(path,with: .color(.white.opacity(active ? 0.5 : 0.16)),style: StrokeStyle(lineWidth: active ? 1.8 : 1,lineCap: .round,dash: active ? [2,7] : [1,9]))
            }
            if active && round.phase == .weaving && round.progress > 0 {
                let woven = arcPath(band,size: size,to: round.progress)
                context.drawLayer { layer in
                    layer.addFilter(.shadow(color: color,radius: 12))
                    layer.stroke(woven,with: .color(color),style: StrokeStyle(lineWidth: thickness,lineCap: .round))
                    layer.stroke(woven,with: .color(.white.opacity(0.5)),lineWidth: 1.5)
                }
            }
        }
        if !preview,round.phase == .weaving {
            for index in 0..<5 {
                let p = round.arc.point(RainbowPromiseRound.stops[index]),point = CGPoint(x: p.x*size.width,y: p.y*size.height)
                let done = index < round.checkpoint,next = index == round.checkpoint
                let color = PromisePalette.color(round.color.rawValue)
                let pulse = controller.reduceMotion ? 1 : 1+sin(time*3.5)*0.09
                let radius: CGFloat = next ? 12*pulse : 7
                promiseGlow(&context,at: point,radius: next ? 29 : 15,color: color.opacity(next ? 0.65 : done ? 0.45 : 0.12))
                let ring = Path(ellipseIn: CGRect(x: point.x-radius,y: point.y-radius,width: radius*2,height: radius*2))
                context.fill(ring,with: .color(PromisePalette.ink.opacity(next ? 0.8 : 0.4)))
                context.stroke(ring,with: .color(done ? color : .white.opacity(next ? 0.9 : 0.5)),lineWidth: next ? 1.5 : 0.8)
                let glyph = next ? "✦" : done ? "·" : "\(index+1)"
                context.draw(Text(glyph).font(.system(size: next ? 16 : 8,weight: .medium)).foregroundColor(done ? color : .white),at: point)
            }
            if let pointer = round.pointer {
                let point = CGPoint(x: pointer.x*size.width,y: pointer.y*size.height)
                promiseGlow(&context,at: point,radius: 25,color: PromisePalette.color(round.color.rawValue).opacity(0.8))
                context.fill(Path(ellipseIn: CGRect(x: point.x-3,y: point.y-3,width: 6,height: 6)),with: .color(.white))
            }
        }
        for spark in controller.sparks {
            let age = time-spark.born,color = PromisePalette.color(spark.band)
            let center = CGPoint(x: spark.point.x*size.width,y: spark.point.y*size.height)
            let radius = 12+age*(controller.reduceMotion ? 10 : 50)
            let ring = Path(ellipseIn: CGRect(x: center.x-radius,y: center.y-radius,width: radius*2,height: radius*2))
            context.stroke(ring,with: .color(.white.opacity(max(0,0.8-age))),lineWidth: 1)
            if !controller.reduceMotion {
                for index in 0..<14 {
                    let angle = Double(index)*2.39996,travel = age*(18+Double(index%5)*15)
                    let p = CGPoint(x: center.x+cos(angle)*travel,y: center.y+sin(angle)*travel-age*25)
                    promiseGlow(&context,at: p,radius: index%3 == 0 ? 3 : 1.8,color: color.opacity(max(0,1-age)))
                }
            }
        }
    }
}
struct PromiseLivingValley: View {
    @ObservedObject var controller: RainbowPromiseController
    var body: some View {
        Canvas { context,size in
            guard size.width > 0,size.height > 0 else { return }
            let time = controller.visualTime,life = Double(controller.round.completedBands)/7
            // Light over the pond becomes a colored reflection as the bow fills the sky.
            for index in 0..<16 {
                let y = size.height*(0.84+Double(index)*0.008)
                let sway = controller.reduceMotion ? 0 : sin(time*0.8+Double(index))*12
                let color = PromisePalette.color(index%max(1,controller.round.completedBands))
                var ripple = Path(); ripple.move(to: CGPoint(x: size.width*0.42+sway,y: y)); ripple.addQuadCurve(to: CGPoint(x: size.width*0.77+sway,y: y),control: CGPoint(x: size.width*0.6,y: y+3))
                context.stroke(ripple,with: .color(color.opacity(life*0.16)),lineWidth: 1)
            }
            if !controller.reduceMotion {
                for index in 0..<(8+controller.round.completedBands*5) {
                    let i = Double(index)
                    let x = (i*97+sin(time*0.3+i)*18+size.width).truncatingRemainder(dividingBy: size.width)
                    let rise = (i*41+time*(4+life*7)).truncatingRemainder(dividingBy: size.height)
                    let p = CGPoint(x: x,y: size.height-rise)
                    promiseGlow(&context,at: p,radius: index%4 == 0 ? 3 : 1.5,color: PromisePalette.gold.opacity((0.12+life*0.35)*(0.7+sin(time+i)*0.3)))
                }
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}
private func promiseGlow(_ context: inout GraphicsContext,at center: CGPoint,radius: CGFloat,color: Color) {
    let path = Path(ellipseIn: CGRect(x: center.x-radius,y: center.y-radius,width: radius*2,height: radius*2))
    context.fill(path,with: .radialGradient(Gradient(colors: [color,color.opacity(0)]),center: center,startRadius: 0,endRadius: radius))
}
