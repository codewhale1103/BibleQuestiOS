import SwiftUI

struct ArkTimberHunt: View {
    @ObservedObject var controller: ArkWorkshopController
    let basketFrame: CGRect
    private let locations = [CGPoint(x: 0.17,y: 0.18),CGPoint(x: 0.76,y: 0.18),CGPoint(x: 0.46,y: 0.47),CGPoint(x: 0.17,y: 0.76),CGPoint(x: 0.82,y: 0.76)]
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<5,id: \.self) { index in
                if !controller.round.wood.contains(index) {
                    ArkHiddenTimber(controller: controller,index: index,basketFrame: basketFrame)
                        .position(x: locations[index].x*geo.size.width,y: locations[index].y*geo.size.height)
                        .zIndex(Double(5-index))
                }
            }
        }
    }
}
private struct ArkHiddenTimber: View {
    @ObservedObject var controller: ArkWorkshopController
    let index: Int
    let basketFrame: CGRect
    @State private var offset = CGSize.zero
    @State private var carrying = false
    @State private var started = false
    @State private var leafSwipe = CGSize.zero
    private var revealed: Bool { controller.round.uncovered.contains(index) }
    var body: some View {
        ZStack {
            if controller.timberHint == index {
                Ellipse().strokeBorder(ArkWorkshopPalette.gold.opacity(controller.reduceMotion ? 0.7 : 0.45+sin(controller.time*3)*0.3),lineWidth: 3).frame(width: 110,height: 75).blur(radius: 2)
            }
            ArkMaterialArt(index: index).frame(width: 84,height: 50).rotationEffect(.degrees(Double(index%3-1)*12)).shadow(color: .black.opacity(0.45),radius: 5,y: 5)
            ArkLeafCover(seed: index).frame(width: 114,height: 88)
                .rotationEffect(.degrees(revealed ? -35 : Double(leafSwipe.width)*0.15))
                .offset(x: revealed ? -70 : leafSwipe.width*0.3,y: revealed ? -40 : leafSwipe.height*0.3)
                .opacity(revealed ? 0 : 1).allowsHitTesting(false)
            if revealed && !carrying {
                Image(systemName: "hand.draw").font(.system(size: 16,weight: .light)).foregroundStyle(ArkWorkshopPalette.cream).padding(7).background(ArkWorkshopPalette.ink.opacity(0.85),in: Circle()).offset(x: 39,y: -25).allowsHitTesting(false)
            }
        }.frame(width: 118,height: 92).contentShape(Rectangle()).offset(offset)
            .scaleEffect(carrying ? 1.12 : 1).zIndex(carrying ? 100 : 0)
            .animation(controller.reduceMotion ? nil : .spring(response: 0.45,dampingFraction: 0.75),value: revealed)
            .gesture(DragGesture(minimumDistance: 3,coordinateSpace: .named("ArkGame"))
                .onChanged { value in
                    if !started { started = true; carrying = revealed }
                    if carrying { offset = value.translation }
                    else {
                        leafSwipe = value.translation
                        if hypot(value.translation.width,value.translation.height) > 22 { controller.uncover(index) }
                    }
                }
                .onEnded { value in
                    if carrying { controller.dropTimber(index,at: value.location,basket: basketFrame) }
                    else if hypot(value.translation.width,value.translation.height) > 22 { controller.uncover(index) }
                    withAnimation(controller.reduceMotion ? nil : .spring(response: 0.4,dampingFraction: 0.7)) { offset = .zero; leafSwipe = .zero }
                    carrying = false; started = false
                })
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(revealed ? "Hidden beam \(index+1), uncovered" : "Timber hiding place \(index+1)")
            .accessibilityHint(revealed ? "Drag this beam to the basket, or use the collect timber action" : "Sweep the leaves aside, or use the uncover timber action")
            .accessibilityAction(named: Text(revealed ? "Collect timber" : "Uncover timber")) { if revealed { controller.accessibleTimber(index) } else { controller.uncover(index) } }
    }
}
struct ArkLeafCover: View {
    let seed: Int
    var body: some View {
        Canvas { context,size in
            for index in 0..<14 {
                let i = Double(index),angle = i*2.39996+Double(seed)*0.7
                let center = CGPoint(x: size.width*0.5+cos(angle)*(10+i*1.7),y: size.height*0.5+sin(angle)*(8+i*1.4))
                context.drawLayer { leaf in
                    leaf.translateBy(x: center.x,y: center.y); leaf.rotate(by: .radians(angle))
                    var shape = Path(); shape.move(to: CGPoint(x: -22,y: 0)); shape.addQuadCurve(to: CGPoint(x: 22,y: 0),control: CGPoint(x: -3,y: -16)); shape.addQuadCurve(to: CGPoint(x: -22,y: 0),control: CGPoint(x: 3,y: 15)); shape.closeSubpath()
                    leaf.addFilter(.shadow(color: .black.opacity(0.25),radius: 2,x: 1,y: 3))
                    leaf.fill(shape,with: .linearGradient(Gradient(colors: [Color(hex: index%3 == 0 ? "#A9B47D" : "#739E71"),Color(hex: "#315A3F")]),startPoint: CGPoint(x: -14,y: -8),endPoint: CGPoint(x: 15,y: 12)))
                    var vein = Path(); vein.move(to: CGPoint(x: -18,y: 0)); vein.addLine(to: CGPoint(x: 18,y: 0)); leaf.stroke(vein,with: .color(Color(hex: "#CECF99").opacity(0.5)),lineWidth: 0.6)
                }
            }
        }.accessibilityHidden(true)
    }
}
struct ArkTimberBasket: View {
    let count: Int
    var body: some View {
        ZStack {
            Canvas { context,size in
                let rect = CGRect(x: 12,y: 23,width: size.width-24,height: size.height-32)
                context.fill(Path(roundedRect: rect,cornerRadius: 14),with: .linearGradient(Gradient(colors: [Color(hex: "#B9894F"),Color(hex: "#674326")]),startPoint: .zero,endPoint: CGPoint(x: 0,y: size.height)))
                for row in 0..<6 { var line = Path();let y = 30+CGFloat(row)*8;line.move(to: CGPoint(x: 14,y: y));line.addLine(to: CGPoint(x: size.width-14,y: y));context.stroke(line,with: .color(Color(hex: "#E1BA7C").opacity(0.45)),lineWidth: 2) }
                for col in 0..<9 { var line = Path();let x = 19+CGFloat(col)*12;line.move(to: CGPoint(x: x,y: 27));line.addLine(to: CGPoint(x: x-5,y: size.height-10));context.stroke(line,with: .color(Color(hex: "#493522").opacity(0.5)),lineWidth: 2) }
                context.stroke(Path(roundedRect: rect,cornerRadius: 14),with: .color(Color(hex: "#E6BA75")),lineWidth: 4)
            }
            ForEach(0..<count,id: \.self) { index in ArkMaterialArt(index: index).frame(width: 62,height: 36).rotationEffect(.degrees(Double(index%3-1)*8)).offset(x: CGFloat(index%2)*22-11,y: CGFloat(index/2)*8-13) }
            Text("TIMBER BASKET").font(.system(size: 6,weight: .bold)).tracking(1).foregroundStyle(ArkWorkshopPalette.cream).padding(5).background(ArkWorkshopPalette.ink.opacity(0.9),in: Capsule()).offset(y: 32)
        }.shadow(color: .black.opacity(0.3),radius: 6,y: 4)
    }
}
