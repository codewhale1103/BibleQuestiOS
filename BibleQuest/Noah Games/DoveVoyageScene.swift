import SwiftUI

enum DovePalette {
    static let ink = Color(hex:"#123F4A"),deep = Color(hex:"#092E3B"),cream = Color(hex:"#FFF7E5"),gold = Color(hex:"#F1D291"),aqua = Color(hex:"#C0E4DD")
}

/// Two feathered wings share a real shoulder pivot; the body never crossfades.
struct DoveBird:View {
    var time:Double
    var size:CGFloat = 120
    var right = true
    var perched = false
    var leaf = false
    var bank = 0.0
    var reduced = false
    private var flap:Double { reduced ? 0.1 : sin(time*7.5) }
    var body:some View {
        ZStack {
            if perched {
                Image("DovePerched").resizable().scaledToFit()
            } else {
                wing(far:true)
                Image("DoveFlightBody").resizable().scaledToFit().frame(width:size,height:size*2/3)
                wing(far:false)
            }
            if leaf {
                Image("DoveOliveLeaf").resizable().scaledToFit().frame(width:size*0.24,height:size*0.24).rotationEffect(.degrees(75)).position(x:size*(perched ? 1.0 : 1.05),y:size*(perched ? 0.17 : 0.25))
            }
        }.frame(width:size,height:size*2/3)
            .scaleEffect(x:right ? 1 : -1,y:1)
            .rotationEffect(.degrees(reduced ? 0 : bank))
            .offset(y:reduced || perched ? 0 : sin(time*3)*2)
            .shadow(color:DovePalette.deep.opacity(0.16),radius:5,y:4)
            .accessibilityHidden(true)
    }
    private func wing(far:Bool)->some View {
        let span = size*(far ? 0.62 : 0.70),f = far ? sin(time*7.5+0.35) : flap
        return Image("DoveFlightWing").resizable().scaledToFit().frame(width:span,height:span)
            .brightness(far ? -0.13 : 0)
            .rotation3DEffect(.degrees(reduced ? 24 : 28+f*30),axis:(x:1,y:0,z:0),anchor:UnitPoint(x:0.89,y:0.88),perspective:0.28)
            .rotationEffect(.degrees(reduced ? -8 : -10+f*37),anchor:UnitPoint(x:0.89,y:0.88))
            .position(x:size*0.54-span*0.39,y:size*0.31-span*0.38)
    }
}

struct DoveVoyageScene:View {
    @ObservedObject var controller:DoveVoyageController
    @State private var dragged:DovePoint?
    @State private var dragOrigin:DovePoint?
    private var r:DoveVoyageRound { controller.round }
    var body:some View {
        GeometryReader { g in
            ZStack {
                if r.closeup || [.intro,.between,.waiting,.ready].contains(r.phase) { closeScene(g.size) }
                else { flightScene(g.size) }
            }.frame(width:g.size.width,height:g.size.height).clipped()
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance:0).onChanged { v in
                    let p = point(v.location,g.size)
                    if r.flying { controller.steer(p) }
                    else if [.leaf,.landing,.settling].contains(r.phase) {
                        if dragOrigin == nil { dragOrigin = point(v.startLocation,g.size) }
                        if validDrag(dragOrigin!) { dragged = p }
                    }
                }.onEnded { v in
                    let end = point(v.location,g.size),start = dragOrigin ?? point(v.startLocation,g.size)
                    if r.flying { controller.release(end) }
                    else if validDrag(start) {
                        if r.phase == .leaf { controller.pluck(from:start,to:end) }
                        else if r.phase == .landing { controller.land(at:end) }
                        else if r.phase == .settling { controller.settle(at:end) }
                    }
                    withAnimation(.spring(response:0.4,dampingFraction:0.8)) { dragged = nil };dragOrigin = nil
                })
                .accessibilityElement(children:.ignore)
                .accessibilityLabel(r.closeup ? r.objective : "Ocean flight. "+r.objective)
                .accessibilityHint(r.flying ? "Use Follow the breeze below for a guided flight." : "The action button below offers the same interaction.")
                .onChange(of:r.phase) { _,_ in dragged = nil;dragOrigin = nil }
        }.clipShape(RoundedRectangle(cornerRadius:26))
            .overlay(RoundedRectangle(cornerRadius:26).strokeBorder(.white.opacity(0.2),lineWidth:1))
    }
    private func point(_ p:CGPoint,_ s:CGSize)->DovePoint { .init(x:p.x/s.width,y:p.y/s.height) }
    // Close-ups use the same normalized board as the story targets.
    private func validDrag(_ p:DovePoint)->Bool {
        if r.phase == .leaf { return p.close(DoveVoyageRound.leafHome)<0.19 }
        return p.close(.init(x:0.28,y:0.25))<0.28
    }
    private var backdrop:String {
        if r.flight == 0 { return "DoveMorningSea" }
        if r.flight == 1 && r.phase == .returning { return "DoveSunsetSea" }
        return "DoveLivingCoast"
    }
    private func flightScene(_ s:CGSize)->some View {
        let scale = s.height/1000,viewport = s.width/scale
        let left = min(3350-viewport,max(-80,controller.camera-viewport*0.46))
        let birdX = (r.position.x-left)*scale
        let t = controller.reduceMotion ? 0 : controller.time
        return ZStack {
            Image(backdrop).resizable().scaledToFill().frame(width:max(s.width,s.height*1.6),height:s.height)
                .offset(x:-(controller.camera-1700)*0.028).frame(width:s.width,height:s.height).clipped()
            LinearGradient(colors:[DovePalette.deep.opacity(0.03),.clear,DovePalette.deep.opacity(0.16)],startPoint:.top,endPoint:.bottom)
            DoveWater(time:t,camera:left*scale).allowsHitTesting(false)
            if r.position.x<800 {
                Image("NoahVoyageArk").resizable().scaledToFit().frame(width:s.height*0.34).rotationEffect(.degrees(sin(t)*1.3)).position(x:(190-left)*scale,y:s.height*0.64)
            }
            ForEach(DoveDiscovery.allCases) { d in
                if (d == .reflection || r.flight>0) && !r.discoveries.contains(d) {
                    VStack(spacing:5) {
                        Image(systemName:d.symbol).font(.system(size:17,weight:.light)).frame(width:40,height:40).background(.ultraThinMaterial,in:Circle()).overlay(Circle().strokeBorder(DovePalette.cream.opacity(0.7)))
                        Text("LOOK CLOSER").font(.system(size:6,weight:.bold)).tracking(1.5)
                    }.foregroundStyle(DovePalette.cream).shadow(color:DovePalette.deep.opacity(0.7),radius:4)
                        .position(x:(d.point.x-left)*scale,y:d.point.y*s.height+s.height*0.14)
                }
            }
            if r.flying {
                Circle().stroke(DovePalette.cream.opacity(0.25),style:StrokeStyle(lineWidth:1,dash:[3,9])).frame(width:92,height:92).scaleEffect(1+sin(t*1.5)*0.035)
                    .overlay(Circle().trim(from:0,to:r.progress).stroke(DovePalette.gold,style:StrokeStyle(lineWidth:3,lineCap:.round)).rotationEffect(.degrees(-90)))
                    .overlay(Image(systemName:r.phase == .returning ? "house" : r.flight == 0 ? "wind" : "leaf").font(.system(size:23,weight:.ultraLight)).foregroundStyle(DovePalette.cream.opacity(0.9)))
                    .position(x:(r.goal.x-left)*scale,y:r.goal.y*s.height)
                if let touch = controller.touch {
                    Path { p in p.move(to:CGPoint(x:birdX,y:r.position.y*s.height));p.addQuadCurve(to:CGPoint(x:touch.x*s.width,y:touch.y*s.height),control:CGPoint(x:birdX+(touch.x*s.width-birdX)*0.65,y:r.position.y*s.height-35)) }
                        .stroke(DovePalette.cream.opacity(0.5),style:StrokeStyle(lineWidth:1.5,lineCap:.round,dash:[3,7]))
                    Circle().stroke(DovePalette.cream.opacity(0.75),lineWidth:1).frame(width:42,height:42).overlay(Image(systemName:"wind").font(.system(size:15,weight:.light)).foregroundStyle(DovePalette.cream)).position(x:touch.x*s.width,y:touch.y*s.height)
                }
            }
            if ![.finale,.won].contains(r.phase) {
            DoveBird(time:t,size:min(116,s.width*0.28),right:r.facingRight,leaf:r.hasLeaf,bank:-r.verticalVelocity*25,reduced:controller.reduceMotion)
                .opacity(0.14).scaleEffect(x:1,y:-0.35).blur(radius:2).position(x:birdX,y:s.height*0.81)
            DoveBird(time:t,size:min(116,s.width*0.28),right:r.facingRight,leaf:r.hasLeaf,bank:-r.verticalVelocity*25,reduced:controller.reduceMotion)
                .position(x:birdX,y:r.position.y*s.height)
            }
            VStack {
                HStack {
                    Text(r.phase == .exploring ? "THE OPEN SKY" : r.phase == .returning ? "HOMEWARD" : ["THE SILVER SEA","A SIGN OF HOPE","A PLACE TO STAY"][r.flight]).font(.system(size:7,weight:.bold)).tracking(2)
                    Spacer()
                    if r.flying {
                        Image(systemName:r.goal.x<r.position.x ? "arrow.left" : "arrow.right").font(.system(size:15,weight:.light))
                        Text(r.phase == .returning ? "The ark" : r.leg == 0 ? "Explore" : r.flight == 0 ? "Open water" : r.flight == 1 ? "Olive grove" : "Green coast").font(.system(size:10,weight:.semibold,design:.rounded))
                    }
                }.padding(16).background(LinearGradient(colors:[DovePalette.deep.opacity(0.35),.clear],startPoint:.top,endPoint:.bottom))
                Spacer()
                if controller.discoveryUntil>controller.time,let d = controller.discovery {
                    Label("Discovered · "+d.title,systemImage:d.symbol).font(.system(size:11,weight:.semibold,design:.rounded)).padding(12).background(DovePalette.deep.opacity(0.78),in:Capsule()).padding(.bottom,20).transition(.opacity)
                } else if r.phase == .launching {
                    Text("A little window. A great big world.").font(.system(size:20,design:.serif)).shadow(radius:5).padding(.bottom,30)
                } else if r.flying {
                    Text(r.guiding ? "Let the gentle breeze carry you…" : "HOLD TO FLY · RELEASE TO GLIDE").font(.system(size:7,weight:.bold)).tracking(1.6).padding(12).background(DovePalette.deep.opacity(0.25),in:Capsule()).padding(.bottom,18)
                }
            }.foregroundStyle(DovePalette.cream).allowsHitTesting(false)
            if [.finale,.won].contains(r.phase) { finalBird(s,t:t) }
        }
    }
    @ViewBuilder private func closeScene(_ s:CGSize)->some View {
        let t = controller.reduceMotion ? 0 : controller.time
        let isHand = [.intro,.launching,.landing,.landed,.between,.waiting,.ready].contains(r.phase)
        ZStack {
            Image(isHand ? "DoveWelcomeWindow" : "DoveLivingCoast").resizable().scaledToFill().frame(width:s.width,height:s.height).clipped()
            if !isHand {
                Color(hex:"#385A32").opacity(0.08)
                Image("DoveOliveBranch").resizable().scaledToFit().frame(width:s.width*1.3).rotationEffect(.degrees(sin(t*0.8)*0.8)).position(x:s.width*0.68,y:s.height*0.51)
            }
            if r.phase == .leaf || r.phase == .leafTaken {
                Path { p in
                    p.move(to:CGPoint(x:s.width*0.62,y:s.height*0.53))
                    p.addQuadCurve(to:CGPoint(x:s.width*0.60,y:s.height*0.43),control:CGPoint(x:s.width*0.61,y:s.height*0.47))
                }.stroke(Color(hex:"#725338"),style:StrokeStyle(lineWidth:2,lineCap:.round))
                DoveBird(time:t,size:s.width*0.42,right:true,leaf:r.hasLeaf,reduced:controller.reduceMotion).position(x:s.width*0.24,y:s.height*0.56)
                if r.phase == .leaf {
                    target(DoveVoyageRound.beak,s:s,symbol:"leaf",title:"A little green hope")
                    Image("DoveOliveLeaf").resizable().scaledToFit().frame(width:s.width*0.18).rotationEffect(.degrees(sin(t*1.3)*7)).shadow(color:DovePalette.gold.opacity(0.8),radius:14).position(x:(dragged?.x ?? DoveVoyageRound.leafHome.x)*s.width,y:(dragged?.y ?? DoveVoyageRound.leafHome.y)*s.height)
                    smallCaption("PICK UP THE FRESH LEAF",at:.init(x:0.57,y:0.25),s:s)
                } else { smallCaption("A LITTLE LEAF. A GREAT BIG HOPE.",at:.init(x:0.5,y:0.23),s:s) }
            } else if [.landing,.settling].contains(r.phase) {
                let landing = r.phase == .landing,p = landing ? DoveVoyageRound.palm : DoveVoyageRound.perch
                target(p,s:s,symbol:landing ? "hand.raised" : "leaf",title:landing ? "Noah’s open hand" : "A peaceful resting place")
                DoveBird(time:t,size:s.width*0.40,right:true,leaf:r.hasLeaf,reduced:controller.reduceMotion).position(x:(dragged?.x ?? 0.28)*s.width,y:(dragged?.y ?? 0.25)*s.height)
            } else {
                let p = isHand ? DovePoint(x:0.49,y:0.55) : DovePoint(x:0.43,y:0.45)
                DoveBird(time:t,size:s.width*(isHand ? 0.39 : 0.38),perched:true,leaf:r.hasLeaf,reduced:controller.reduceMotion).position(x:p.x*s.width,y:p.y*s.height)
                if r.phase == .waiting { waitingSky(s,time:t) }
            }
            LinearGradient(colors:[DovePalette.deep.opacity(0.12),.clear,.clear,DovePalette.deep.opacity(0.15)],startPoint:.top,endPoint:.bottom).allowsHitTesting(false)
        }
    }
    private func target(_ p:DovePoint,s:CGSize,symbol:String,title:String)->some View {
        VStack(spacing:5) {
            Image(systemName:symbol).font(.system(size:23,weight:.ultraLight)).frame(width:64,height:64).background(DovePalette.cream.opacity(0.08),in:Circle()).overlay(Circle().stroke(DovePalette.cream.opacity(0.7),style:StrokeStyle(lineWidth:1.5,dash:[3,5])))
            Text(title).font(.system(size:9,weight:.semibold,design:.rounded)).padding(.horizontal,10).padding(.vertical,5).background(DovePalette.deep.opacity(0.65),in:Capsule())
        }.foregroundStyle(DovePalette.cream).position(x:p.x*s.width,y:p.y*s.height)
    }
    private func smallCaption(_ text:String,at p:DovePoint,s:CGSize)->some View { Text(text).font(.system(size:7,weight:.bold)).tracking(1.8).foregroundStyle(DovePalette.cream).shadow(color:.black.opacity(0.5),radius:5).position(x:p.x*s.width,y:p.y*s.height) }
    private func waitingSky(_ s:CGSize,time:Double)->some View {
        let day = r.days,fraction = r.phaseTime.truncatingRemainder(dividingBy:0.95)/0.95
        return ZStack {
            Color(hex:"#052238").opacity(controller.reduceMotion ? 0.2 : (0.5-0.5*cos(fraction*2*Double.pi))*0.65)
            VStack(spacing:20) {
                Image(systemName:fraction<0.5 ? "sun.max.fill" : "moon.stars.fill").font(.system(size:42,weight:.ultraLight)).foregroundStyle(DovePalette.gold)
                Text("\(min(7,day+1))").font(.system(size:66,weight:.light,design:.serif)).foregroundStyle(DovePalette.cream).contentTransition(.numericText())
                Text("NOAH WAITED SEVEN MORE DAYS").font(.system(size:8,weight:.bold)).tracking(2).foregroundStyle(DovePalette.cream)
                HStack(spacing:9) { ForEach(0..<7,id:\.self) { i in Circle().fill(i<day ? DovePalette.gold : DovePalette.cream.opacity(0.25)).frame(width:9,height:9) } }
            }.shadow(color:DovePalette.deep.opacity(0.5),radius:10).position(x:s.width/2,y:s.height*0.35)
        }.allowsHitTesting(false)
    }
    private func finalBird(_ s:CGSize,t:Double)->some View {
        ZStack {
            LinearGradient(colors:[.clear,DovePalette.deep.opacity(0.24)],startPoint:.top,endPoint:.bottom)
            Image("DoveOliveBranch").resizable().scaledToFit().frame(width:s.width*1.05).rotationEffect(.degrees(sin(t)*0.5)).position(x:s.width*0.7,y:s.height*0.64)
            DoveBird(time:t,size:s.width*0.40,perched:true,reduced:controller.reduceMotion).position(x:s.width*0.48,y:s.height*0.54)
        }
    }
}

private struct DoveWater:View {
    let time:Double
    let camera:Double
    var body:some View {
        Canvas { c,s in
            // Perspective compresses distant ripples; each layer travels independently.
            for row in 0..<23 {
                let depth = Double(row)/23,y = s.height*(0.43+depth*depth*0.57)
                var path = Path()
                let length = 12+depth*45,gap = 35+depth*95,speed = time*(3+depth*9)
                for col in -4...22 {
                    let x = Double(col)*gap+(sin(Double(row)*3.72)*60+speed-camera*0.06).truncatingRemainder(dividingBy:gap)
                    let wave = sin(time*1.3+Double(col)*2+Double(row))*2*depth
                    path.move(to:.init(x:x,y:y+wave));path.addQuadCurve(to:.init(x:x+length,y:y+wave),control:.init(x:x+length*0.5,y:y-2-depth*2))
                }
                c.stroke(path,with:.color(.white.opacity(0.04+depth*0.09)),style:StrokeStyle(lineWidth:0.5+depth,lineCap:.round))
            }
            for i in 0..<20 {
                let x = (Double(i)*103.7+time*2.5).truncatingRemainder(dividingBy:s.width),y = s.height*(0.51+Double(i%8)*0.06)
                let alpha = max(0,sin(time*1.1+Double(i)*2.7))
                c.fill(Path(ellipseIn:CGRect(x:x,y:y,width:2.3,height:1)),with:.color(DovePalette.cream.opacity(alpha*0.45)))
            }
            for i in 0..<5 {
                let x = (Double(i)*235+time*4-camera*0.02).truncatingRemainder(dividingBy:s.width+250)-150
                c.fill(Path(ellipseIn:CGRect(x:x,y:s.height*0.68+Double(i%3)*40,width:210,height:35)),with:.radialGradient(Gradient(colors:[DovePalette.deep.opacity(0.07),.clear]),center:CGPoint(x:x+105,y:s.height*0.68+Double(i%3)*40+17),startRadius:0,endRadius:110))
            }
        }.drawingGroup()
    }
}
