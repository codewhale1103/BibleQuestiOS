import SwiftUI

struct RainPoint {
    var x: Double
    var y: Double
    func cg(_ size: CGSize) -> CGPoint { .init(x:x*size.width,y:y*size.height) }
    func distance(_ other: RainPoint) -> Double { hypot(x-other.x,y-other.y) }
}
struct RainCurve {
    var a: RainPoint
    var b: RainPoint
    func point(_ t: Double) -> RainPoint {
        let u = 1-t,mid = (a.y+b.y)/2
        return .init(x: a.x*u*u*u+3*a.x*u*u*t+3*b.x*u*t*t+b.x*t*t*t,y:a.y*u*u*u+3*mid*u*u*t+3*mid*u*t*t+b.y*t*t*t)
    }
    func path(_ size: CGSize) -> Path {
        var p = Path();p.move(to: a.cg(size));p.addCurve(to: b.cg(size),control1: RainPoint(x:a.x,y:(a.y+b.y)/2).cg(size),control2: RainPoint(x:b.x,y:(a.y+b.y)/2).cg(size));return p
    }
}
enum RainLayout {
    static func peg(_ cell: RainCell) -> RainPoint { .init(x:0.25+Double(cell.column)*0.25,y:0.275+Double(cell.row)*0.12) }
    static func end(_ cell: RainCell,_ column: Int) -> RainPoint { cell.row == 3 ? .init(x:0.25+Double(column)*0.25,y:0.79) : peg(RainCell(cell.row+1,column)) }
    static func nearest(_ p: RainPoint) -> RainCell? {
        let c = Int(((p.x-0.25)/0.25).rounded()),r = Int(((p.y-0.275)/0.12).rounded()),cell = RainCell(r,c)
        return cell.valid && peg(cell).distance(p) < 0.115 ? cell : nil
    }
    static let gate = RainPoint(x:0.78,y:0.185)
    static func tray(_ index: Int,_ count: Int) -> RainPoint { .init(x:0.5+(Double(index)-Double(count-1)/2)*0.27,y:0.928) }
}

struct RainOrchestraBoard: View {
    @ObservedObject var controller: RainOrchestraController
    var demo = false
    @State private var drag: BoardDrag?
    @State private var dragPoint: RainPoint?
    @GestureState private var touching = false
    private enum BoardDrag { case tool(RainPiece),tile(RainCell),gate,bowl(Int) }
    private var round: RainOrchestraRound {
        if !demo { return controller.round }
        return RainOrchestraRound.showcase()
    }
    var body: some View {
        GeometryReader { g in
            let w = min(g.size.width,g.size.height/1.5,540.0),size = CGSize(width:w,height:w*1.5)
            ZStack {
                Image("RainOrchestraWorkshop").resizable().scaledToFill().frame(width:size.width,height:size.height).clipped().accessibilityHidden(true)
                Color(hex: "#062940").opacity(round.chapter == 2 || round.day%2 == 0 ? 0.30 : 0.04).blendMode(.multiply).allowsHitTesting(false).animation(.easeInOut(duration:controller.reduceMotion ? 0 : 2),value:round.day)
                Canvas { context,canvas in draw(context: &context,size:canvas) }.allowsHitTesting(false)
                instruments(size)
                if round.chapter >= 3 || demo { parade(size) }
                gate(size)
                if !demo { tray(size);accessibilityPegs(size) }
                if let drag,let p = dragPoint {
                    switch drag {
                    case .tool(let piece): RainToolBadge(piece:piece,selected:true).frame(width:w*0.18,height:w*0.18).position(p.cg(size)).shadow(color:.black.opacity(0.4),radius:8,y:6).allowsHitTesting(false)
                    case .tile(let cell): if let tile = round.tiles[cell] { RainToolBadge(piece:tile.piece,selected:true).frame(width:w*0.18,height:w*0.18).position(p.cg(size)).allowsHitTesting(false) }
                    default: EmptyView()
                    }
                }
            }.frame(width:size.width,height:size.height).clipShape(RoundedRectangle(cornerRadius:23))
                .overlay(RoundedRectangle(cornerRadius:23).strokeBorder(RainPalette.gold.opacity(0.3),lineWidth:1))
                .contentShape(Rectangle()).gesture(gesture(size)).allowsHitTesting(!demo && round.interactive).accessibilityHidden(demo)
                .onChange(of: touching) { _,active in if !active { drag = nil;dragPoint = nil } }
                .onChange(of: round.phase) { _,_ in drag = nil;dragPoint = nil }
                .position(x:g.size.width/2,y:g.size.height/2)
        }
    }
    private func gesture(_ size: CGSize) -> some Gesture {
        DragGesture(minimumDistance:0).updating($touching) { _,state,_ in state = true }
            .onChanged { value in route(value,size:size) }
            .onEnded { value in
                route(value,size:size)
                let end = RainPoint(x:value.location.x/size.width,y:value.location.y/size.height)
                let moved = hypot(value.translation.width,value.translation.height)>12
                switch drag {
                case .tool(let piece):
                    if moved,let cell = RainLayout.nearest(end) { controller.place(piece,at:cell) }
                    else { controller.select(piece) }
                case .tile(let from):
                    if moved { if let to = RainLayout.nearest(end) { controller.move(from,to:to) } else if end.y>0.87 { controller.remove(from) } }
                    else { controller.tap(from) }
                case .gate: if value.translation.height>size.height*0.025 || !moved { controller.pour() }
                case .bowl(let i): if !moved { controller.playBowl(i) }
                case nil: if !moved,let cell = RainLayout.nearest(end) { controller.tap(cell) }
                }
                drag = nil;dragPoint = nil
            }
    }
    private func route(_ value: DragGesture.Value,size:CGSize) {
        guard round.interactive else { return }
        let start = RainPoint(x:value.startLocation.x/size.width,y:value.startLocation.y/size.height)
        if drag == nil {
            if abs(start.x-RainLayout.gate.x)<0.13 && start.y>0.12 && start.y<0.255 { drag = .gate }
            else if start.y>0.875 {
                if let index = round.tools.indices.min(by:{abs(RainLayout.tray($0,round.tools.count).x-start.x)<abs(RainLayout.tray($1,round.tools.count).x-start.x)}) { drag = .tool(round.tools[index]);controller.select(round.tools[index]) }
            } else if start.y>0.735 && start.y<0.865 { drag = .bowl(min(2,max(0,Int(((start.x-0.25)/0.25).rounded())))) }
            else if let cell = RainLayout.nearest(start),round.tiles[cell] != nil { drag = .tile(cell) }
        }
        dragPoint = .init(x:value.location.x/size.width,y:value.location.y/size.height)
    }
    private func gate(_ size:CGSize) -> some View {
        let w = size.width,open = demo || round.pouring
        var pull = 0.0
        if case .gate = drag,let point = dragPoint { pull = max(0,min(w*0.065,(point.y-RainLayout.gate.y)*size.height)) }
        return ZStack {
            RoundedRectangle(cornerRadius:4).fill(.black.opacity(0.5)).frame(width:w*0.022,height:w*0.16)
            Capsule().fill(LinearGradient(colors:[RainPalette.cream,RainPalette.gold,Color(hex:"#8D582A")],startPoint:.topLeading,endPoint:.bottomTrailing)).frame(width:w*0.08,height:w*0.10)
                .overlay(Image(systemName:open ? "drop.fill" : "chevron.down").font(.system(size:w*0.032,weight:.bold)).foregroundStyle(RainPalette.ink)).offset(y:open ? w*0.04 : -w*0.025+pull)
            Text(open ? "RAINING" : "PULL").font(.system(size:w*0.019,weight:.heavy,design:.rounded)).tracking(1.2).foregroundStyle(RainPalette.cream).offset(x:-w*0.005,y:-w*0.10)
        }.frame(width:w*0.18,height:w*0.2).position(RainLayout.gate.cg(size)).shadow(color:.black.opacity(0.4),radius:4,y:3)
            .accessibilityElement(children:.ignore).accessibilityLabel(round.waterMoving ? "Water is flowing" : "Open the rain gate").accessibilityAddTraits(.isButton).accessibilityAction { controller.pour() }
    }
    private func instruments(_ size:CGSize) -> some View {
        ZStack {
            ForEach(0..<3,id:\.self) { i in
                let active = demo || round.targets.contains(i),age = controller.time-controller.noteTimes[i]
                RainInstrument(note:i,fill:demo ? 0.5 : round.fills[i],hit:age<1.2 ? max(0,1-age/1.2) : 0,active:active,drum:i==1 && round.chapter != 2)
                    .frame(width:size.width*0.195,height:size.width*0.24).position(x:size.width*(0.25+Double(i)*0.25),y:size.height*0.799)
                    .accessibilityElement(children:.ignore).accessibilityLabel("\(["Low bowl","Middle instrument","High bowl"][i])\(round.cycleNotes.contains(i) ? ", played by water" : "")").accessibilityAddTraits(.isButton).accessibilityAction { controller.playBowl(i) }
            }
        }
    }
    private func parade(_ size:CGSize) -> some View {
        let motion = controller.reduceMotion ? 0 : (round.wheelTurns*0.2).truncatingRemainder(dividingBy:1),alive = round.wheelTurns>0.1 || demo
        return HStack(spacing:size.width*0.018) {
            ForEach(Array(["ParadeMonkey","ParadeSheep","ParadeElephant"].enumerated()),id:\.offset) { i,name in
                Image(name).resizable().scaledToFit().frame(width:size.width*0.065,height:size.width*0.075)
                    .offset(y:alive && !controller.reduceMotion ? sin(controller.time*4+Double(i)*1.6)*size.width*0.005 : 0)
                    .overlay(alignment:.bottom) { Capsule().fill(RainPalette.gold).frame(width:size.width*0.05,height:3).offset(y:3) }
            }
        }.padding(.horizontal,8).padding(.vertical,3).background(.black.opacity(0.35),in:Capsule())
            .offset(x:controller.reduceMotion ? 0 : (motion-0.5)*size.width*0.15).position(x:size.width*0.5,y:size.height*0.864).accessibilityHidden(true)
    }
    private func tray(_ size:CGSize) -> some View {
        ZStack {
            ForEach(Array(round.tools.enumerated()),id:\.element) { i,piece in
                VStack(spacing:2) { RainToolBadge(piece:piece,selected:controller.selected==piece).frame(width:size.width*0.145,height:size.width*0.115);Text(piece.name).font(.system(size:size.width*0.022,weight:.bold,design:.rounded)).foregroundStyle(RainPalette.cream) }
                    .position(RainLayout.tray(i,round.tools.count).cg(size)).accessibilityElement(children:.ignore).accessibilityLabel("Choose \(piece.name), then tap an empty ring").accessibilityAddTraits(.isButton).accessibilityAction { controller.select(piece) }
            }
        }
    }
    private func accessibilityPegs(_ size:CGSize) -> some View {
        ZStack {
            ForEach(0..<12,id:\.self) { index in
                let cell = RainCell(index/3,index%3),tile = round.tiles[cell]
                Color.clear.frame(width:size.width*0.16,height:size.width*0.14).contentShape(Circle()).position(RainLayout.peg(cell).cg(size))
                    .accessibilityElement().accessibilityLabel("Row \(cell.row+1), \(["left","middle","right"][cell.column]), \(tile?.piece.name ?? "empty ring")")
                    .accessibilityValue(tile.map { "Flows to "+$0.destinations(from:cell.column).map{["left","middle","right"][$0]}.joined(separator:" and ") } ?? "Select a piece, then activate to place")
                    .accessibilityAddTraits(.isButton).accessibilityAction { controller.tap(cell) }
                    .accessibilityAction(named:"Remove channel") { controller.remove(cell) }
            }
        }.allowsHitTesting(false)
    }
    private func draw(context c:inout GraphicsContext,size s:CGSize) {
        let r = round,t = controller.reduceMotion ? 0 : controller.time,w = s.width
        let flow = r.network()
        // Fine rain on the exposed edges, with glints catching the gutter.
        if !controller.reduceMotion {
            for i in 0..<40 {
                let x = Double((i*173)%997)/997,y = (Double(i)*0.079+t*0.35).truncatingRemainder(dividingBy:1)
                guard x<0.10 || x>0.90 || y<0.09 else { continue }
                var p = Path();p.move(to:.init(x:x*w,y:y*s.height));p.addLine(to:.init(x:(x-0.007)*w,y:(y+0.022)*s.height));c.stroke(p,with:.color(.white.opacity(0.3)),lineWidth:0.8)
            }
        }
        let source = RainCurve(a:.init(x:0.50,y:0.12),b:RainLayout.peg(RainCell(0,1)))
        var spout = Path();spout.move(to:CGPoint(x:w*0.47,y:s.height*0.12));spout.addLine(to:CGPoint(x:w*0.47,y:s.height*0.21));spout.addQuadCurve(to:CGPoint(x:w*0.53,y:s.height*0.21),control:CGPoint(x:w*0.50,y:s.height*0.24));spout.addLine(to:CGPoint(x:w*0.53,y:s.height*0.12))
        c.stroke(spout,with:.linearGradient(.init(colors:[Color(hex:"#482516"),RainPalette.gold,Color(hex:"#854720")]),startPoint:CGPoint(x:w*0.47,y:0),endPoint:CGPoint(x:w*0.53,y:0)),style:.init(lineWidth:w*0.023,lineCap:.round))
        if demo || r.pouring { water(&c,curve:source,volume:1,time:t,size:s,from:0.67) }
        for row in 0..<4 {
            for col in 0..<3 {
                let cell = RainCell(row,col),a = RainLayout.peg(cell),p = a.cg(s),highlight = controller.highlight == cell && controller.hintUntil>controller.time
                if let tile = r.tiles[cell] {
                    for dest in tile.destinations(from:col) {
                        let curve = RainCurve(a:a,b:RainLayout.end(cell,dest)),path = curve.path(s)
                        var shadow = c;shadow.translateBy(x:1,y:w*0.012);shadow.stroke(path,with:.color(.black.opacity(0.55)),style:.init(lineWidth:w*0.062,lineCap:.round))
                        c.stroke(path,with:.color(Color(hex:"#DDB47B")),style:.init(lineWidth:w*0.054,lineCap:.round))
                        c.stroke(path,with:.linearGradient(.init(colors:[Color(hex:"#8F5830"),Color(hex:"#BF8A50"),Color(hex:"#684024")]),startPoint:p,endPoint:curve.b.cg(s)),style:.init(lineWidth:w*0.044,lineCap:.round))
                        // Fine grain catches light on the two carved edges of each trough.
                        for grain in [-1.0,1.0] {
                            var edge = c;edge.translateBy(x:w*0.018*grain,y:0)
                            edge.stroke(path,with:.color(Color(hex:"#F7D5A0").opacity(0.2)),style:.init(lineWidth:0.6,lineCap:.round,dash:[8,3,2,5]))
                        }
                        c.stroke(path,with:.color(Color(hex:"#2F251C")),style:.init(lineWidth:w*0.027,lineCap:.round))
                        let live = demo ? flow.inputs[cell,default:0] : (r.pourAge>=Double(cell.row)*0.32 && r.pourAge<RainOrchestraRound.pourDuration+Double(cell.row)*0.32 ? flow.inputs[cell,default:0] : 0)
                        if live>0 { water(&c,curve:curve,volume:live/Double(tile.destinations(from:col).count),time:t,size:s) }
                    }
                }
                let ring = CGRect(x:p.x-w*0.028,y:p.y-w*0.028,width:w*0.056,height:w*0.056)
                c.fill(Path(ellipseIn:ring),with:.radialGradient(.init(colors:[Color(hex:"#DFB777"),Color(hex:"#69452B")]),center:.init(x:p.x-w*0.01,y:p.y-w*0.012),startRadius:0,endRadius:w*0.04))
                c.fill(Path(ellipseIn:ring.insetBy(dx:w*0.009,dy:w*0.009)),with:.color(Color(hex:"#1F2827")))
                if highlight || r.tiles[cell] == nil && (demo || flow.inputs[cell,default:0]>0) {
                    let radius = w*(0.048+(controller.reduceMotion ? 0 : sin(t*3)*0.004))
                    c.stroke(Path(ellipseIn:CGRect(x:p.x-radius,y:p.y-radius,width:radius*2,height:radius*2)),with:.color((highlight ? RainPalette.gold : RainPalette.aqua).opacity(highlight ? 0.9 : 0.42)),style:.init(lineWidth:1.3,dash:[3,3]))
                    if r.tiles[cell] == nil { var plus = Path();plus.move(to:.init(x:p.x-w*0.012,y:p.y));plus.addLine(to:.init(x:p.x+w*0.012,y:p.y));plus.move(to:.init(x:p.x,y:p.y-w*0.012));plus.addLine(to:.init(x:p.x,y:p.y+w*0.012));c.stroke(plus,with:.color(RainPalette.cream.opacity(0.7)),lineWidth:1.4) }
                }
                if let tile = r.tiles[cell],tile.piece == .wheel { wheel(&c,at:p,radius:w*0.071,angle:controller.reduceMotion ? 0 : demo ? controller.time*1.4 : r.wheelTurns*6.28,size:s) }
                let live = demo ? flow.spills[cell,default:0] : (r.liveInput(cell)>0 ? flow.spills[cell,default:0] : 0)
                if live>0 {
                    for i in 0..<8 { let age = (t*1.3+Double(i)/8).truncatingRemainder(dividingBy:1),x = p.x+sin(Double(i)*2.2)*age*w*0.035,y = p.y+age*s.height*0.11;c.fill(Path(ellipseIn:CGRect(x:x,y:y,width:2.5,height:4)),with:.color(RainPalette.aqua.opacity(1-age))) }
                }
            }
        }
        if controller.time-controller.boatStart<5.5 && !demo {
            let age = controller.time-controller.boatStart
            var routes: [RainCurve] = [],col = 1
            for row in 0..<4 {
                let cell = RainCell(row,col)
                guard let tile = r.tiles[cell] else {
                    routes.append(RainCurve(a:RainLayout.peg(cell),b:RainPoint(x:RainLayout.peg(cell).x,y:0.97)));break
                }
                let dest = tile.destinations(from:col).first ?? col
                routes.append(RainCurve(a:RainLayout.peg(cell),b:RainLayout.end(cell,dest)));col = dest
            }
            let segment = min(routes.count-1,Int(age/1.1)),fraction = min(1,max(0,age/1.1-Double(segment)))
            let p = routes[segment].point(fraction).cg(s)
            var boat = Path();boat.move(to:.init(x:p.x-10,y:p.y-3));boat.addLine(to:.init(x:p.x+10,y:p.y-3));boat.addLine(to:.init(x:p.x+5,y:p.y+4));boat.addLine(to:.init(x:p.x-5,y:p.y+4));boat.closeSubpath();c.fill(boat,with:.color(RainPalette.gold));c.stroke(boat,with:.color(Color(hex:"#5D3D25")),lineWidth:1)
        }
    }
    private func water(_ c:inout GraphicsContext,curve:RainCurve,volume:Double,time:Double,size:CGSize,from:Double = 0) {
        let line = max(2,size.width*0.018*sqrt(volume)),path = curve.path(size)
        var glow = c;glow.addFilter(.shadow(color:RainPalette.aqua.opacity(0.25),radius:3));glow.stroke(path,with:.color(Color(hex:"#31A4B9").opacity(0.88)),style:.init(lineWidth:line,lineCap:.round))
        c.stroke(path,with:.color(Color(hex:"#B8F9F2").opacity(0.8)),style:.init(lineWidth:max(1,line*0.30),lineCap:.round,dash:[size.width*0.025,size.width*0.022],dashPhase:-time*size.width*0.16))
        for i in 0..<6 { let f = (time*0.55+Double(i)/6).truncatingRemainder(dividingBy:1);if f<from {continue};let p = curve.point(f).cg(size);c.fill(Path(ellipseIn:CGRect(x:p.x-1,y:p.y-1,width:2.2,height:2.2)),with:.color(.white.opacity(0.85))) }
    }
    private func wheel(_ c:inout GraphicsContext,at p:CGPoint,radius:Double,angle:Double,size:CGSize) {
        var wc = c;wc.translateBy(x:p.x,y:p.y);wc.rotate(by:.radians(angle))
        wc.draw(Image("RainWaterwheel"),in:CGRect(x:-radius,y:-radius,width:radius*2,height:radius*2))
    }
}
