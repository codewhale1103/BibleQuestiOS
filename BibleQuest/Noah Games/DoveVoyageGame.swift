import SwiftUI

struct DoveVoyageGame:View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var controller = DoveVoyageController()
    @State private var journal = false
    var onComplete:(()->Void)? = nil
    var onExit:(()->Void)? = nil
    private var r:DoveVoyageRound { controller.round }
    private func exit() { controller.pause();if let onExit { onExit() } else { dismiss() } }
    var body:some View {
        GeometryReader { g in
            let wide = g.size.width>g.size.height*1.25
            ZStack {
                LinearGradient(colors:[Color(hex:"#174D58"),DovePalette.deep,Color(hex:"#082733")],startPoint:.topLeading,endPoint:.bottomTrailing).ignoresSafeArea()
                Group {
                if wide {
                    HStack(spacing:20) {
                        VStack(spacing:8) { header;flightRibbon;scene }.frame(maxWidth:.infinity,maxHeight:.infinity)
                        ScrollView(showsIndicators:false) { footer.padding(.vertical,10) }.frame(width:min(300,g.size.width*0.35))
                    }.padding(.horizontal,22).padding(.vertical,8)
                } else {
                    VStack(spacing:10) { header;flightRibbon;scene.frame(maxHeight:.infinity);footer }.padding(.horizontal,16).padding(.top,4).padding(.bottom,8)
                }
                }.allowsHitTesting(r.phase != .paused).accessibilityHidden(r.phase == .paused)
                if r.phase == .paused && !journal { pauseCard }
            }
        }.toolbar(.hidden,for:.navigationBar,.tabBar).preferredColorScheme(.dark)
            .onAppear { controller.reduceMotion = reduceMotion;controller.onComplete = onComplete;controller.attach() }
            .onDisappear { controller.detach() }
            .onChange(of:reduceMotion) { _,v in controller.reduceMotion = v }
            .onChange(of:scenePhase) { _,p in if p != .active { controller.pause() } }
            .sheet(isPresented:$journal,onDismiss:{controller.resume()}) { DoveJournal(discoveries:r.discoveries,onRead:controller.readDiscovery) }
            .animation(reduceMotion ? nil : .easeInOut(duration:0.5),value:r.phase)
    }
    private var header:some View {
        HStack(spacing:3) {
            icon("chevron.left","Back to Noah’s voyage",exit)
            VStack(alignment:.leading,spacing:3) {
                Text("THE DOVE RETURNS").font(.system(size:7,weight:.bold)).tracking(2.4).foregroundStyle(DovePalette.gold)
                Text("Wings of Hope").font(.system(size:25,design:.serif)).lineLimit(1).minimumScaleFactor(0.65).foregroundStyle(DovePalette.cream)
            }.frame(maxWidth:.infinity,alignment:.leading)
            icon("book.closed","Open the nature journal") { if r.phase != .intro && r.phase != .won { controller.pause() };journal = true }
            icon(controller.soundOn ? "speaker.wave.2" : "speaker.slash",controller.soundOn ? "Mute Wings of Hope" : "Turn sounds on",controller.toggleSound)
            if r.phase != .intro && r.phase != .won { icon("pause","Pause Wings of Hope",controller.pause) }
        }.frame(minHeight:46)
    }
    private func icon(_ symbol:String,_ text:String,_ action:@escaping()->Void)->some View {
        Button(action:action) { Image(systemName:symbol).font(.system(size:16,weight:.light)).frame(width:35,height:44).foregroundStyle(DovePalette.cream) }.buttonStyle(.plain).accessibilityLabel(text)
    }
    private var flightRibbon:some View {
        HStack(spacing:0) {
            ForEach(0..<3,id:\.self) { i in
                if i>0 { Rectangle().fill(DovePalette.aqua.opacity(0.15)).frame(height:1).padding(.horizontal,8) }
                HStack(spacing:6) {
                    Image(systemName:i<r.completedFlights ? "checkmark" : ["wind","leaf","sun.horizon"][i]).font(.system(size:11,weight:.light)).frame(width:28,height:28).background(i == r.flight ? DovePalette.gold.opacity(0.15) : .white.opacity(0.04),in:Circle()).overlay(Circle().strokeBorder(i == r.flight ? DovePalette.gold.opacity(0.6) : .white.opacity(0.1)))
                    Text(["SEARCH","THE LEAF","NEW LIFE"][i]).font(.system(size:6,weight:.bold)).tracking(1.1).lineLimit(1)
                }.foregroundStyle(i <= r.flight ? DovePalette.gold : DovePalette.aqua.opacity(0.45))
            }
        }.padding(.horizontal,4).padding(.bottom,2).accessibilityElement(children:.ignore).accessibilityLabel("Flight \(r.flight+1) of three. \(r.completedFlights) complete.")
    }
    private var scene:some View {
        GeometryReader { g in
            let portrait = r.closeup || [.intro,.between,.waiting,.ready].contains(r.phase)
            DoveVoyageScene(controller:controller)
                .frame(width:portrait ? min(g.size.width,g.size.height*2/3) : g.size.width,height:g.size.height)
                .frame(width:g.size.width,height:g.size.height)
        }.frame(minHeight:160).shadow(color:.black.opacity(0.2),radius:20,y:10)
    }
    @ViewBuilder private var footer:some View {
        switch r.phase {
        case .intro: intro
        case .between: between
        case .waiting:
            story("PATIENT LITTLE HEARTS","Hope takes a little time.","Noah waited seven more days before sending the dove again.")
        case .ready:
            VStack(spacing:13) {
                story("SEVEN DAYS LATER",r.flight == 1 ? "A fresh chance to discover." : "The world is growing green.",r.flight == 1 ? "Noah opened the window and sent the dove again." : "One more flight. What will our little dove find?")
                DoveButton("Open the window",symbol:"wind",action:controller.launch)
            }
        case .finale:
            story("LITTLE WINGS. GREAT BIG HOPE.","A place to stay.","This time, the dove did not return. New life was growing beyond the water. Noah kept waiting and trusting God.")
        case .won: won
        default: controls
        }
    }
    private var intro:some View {
        VStack(alignment:.leading,spacing:12) {
            Text("LITTLE WINGS. A GREAT BIG HOPE.").font(.system(size:7,weight:.bold)).tracking(2).foregroundStyle(DovePalette.gold)
            Text("A world waiting\nto be discovered.").font(.system(size:32,design:.serif)).foregroundStyle(DovePalette.cream).fixedSize(horizontal:false,vertical:true)
            Text("Guide a little dove over silver seas. Find a fresh olive leaf. Bring a little hope home.").font(.system(size:12,weight:.medium,design:.rounded)).lineSpacing(3).foregroundStyle(DovePalette.aqua).fixedSize(horizontal:false,vertical:true)
            HStack(spacing:9) {
                Label("3 beautiful flights",systemImage:"wind")
                Text("·")
                Label("Play at your pace",systemImage:"heart")
            }.font(.system(size:8,weight:.semibold,design:.rounded)).foregroundStyle(DovePalette.gold.opacity(0.85)).padding(.vertical,3)
            DoveButton("Let’s take flight",symbol:"arrow.up.right",action:controller.start)
        }.padding(.horizontal,6)
    }
    private var controls:some View {
        VStack(alignment:.leading,spacing:10) {
            HStack {
                Text(r.phase == .exploring ? "YOUR LITTLE WORLD" : "FLIGHT \(r.flight+1) · "+(r.phase == .returning ? "BRING HOPE HOME" : "FOLLOW YOUR WONDER")).font(.system(size:7,weight:.bold)).tracking(1.7).foregroundStyle(DovePalette.gold)
                Spacer()
                if r.discoveries.count>0 { Label("\(r.discoveries.count)/3",systemImage:"book.closed").font(.system(size:9,weight:.medium)).foregroundStyle(DovePalette.aqua) }
            }
            Text(r.objective).font(.system(size:22,design:.serif)).foregroundStyle(DovePalette.cream).fixedSize(horizontal:false,vertical:true)
            Text(instruction).font(.system(size:11,weight:.medium,design:.rounded)).lineSpacing(2).foregroundStyle(DovePalette.aqua).fixedSize(horizontal:false,vertical:true)
            HStack(spacing:9) {
                DoveButton("Read to me",symbol:"speaker.wave.2.fill",secondary:true,action:controller.read)
                if r.flying { DoveButton(r.guiding ? "Breeze is guiding…" : "Follow the breeze",symbol:"wind",action:controller.follow).disabled(r.guiding) }
                else if r.phase == .leaf { DoveButton("Pick up the leaf",symbol:"leaf") { controller.pluck(from:DoveVoyageRound.leafHome,to:DoveVoyageRound.beak) } }
                else if r.phase == .landing { DoveButton("Land gently",symbol:"hand.raised") { controller.land(at:DoveVoyageRound.palm) } }
                else if r.phase == .settling { DoveButton("Rest on the branch",symbol:"leaf") { controller.settle(at:DoveVoyageRound.perch) } }
                else { HStack { Image(systemName:"sparkle");Text(r.phase == .landed ? "Safe and sound" : r.phase == .settled ? "A peaceful place" : "Little wings, big hope") }.font(.system(size:10,weight:.semibold,design:.rounded)).foregroundStyle(DovePalette.gold).frame(maxWidth:.infinity,minHeight:48) }
            }
        }.padding(15).background(.white.opacity(0.045),in:RoundedRectangle(cornerRadius:22)).overlay(RoundedRectangle(cornerRadius:22).strokeBorder(.white.opacity(0.08)))
    }
    private var instruction:String {
        switch r.phase {
        case .leaf: "Drag the glowing leaf to the dove’s beak."
        case .landing: "Carry the dove down into Noah’s open palm."
        case .settling: "Carry the dove onto the glowing branch."
        case .landed: r.flight == 0 ? "No resting place yet. Noah welcomes the dove home." : "In the evening, a fresh olive leaf brought Noah hope."
        case .settled: "Green leaves. Warm sunshine. A place to stay."
        case .launching: "The window opens. A new little adventure begins."
        case .leafTaken: "A fresh olive leaf, held gently. Let’s take it home."
        default: "Hold either side to fly. Move up or down. Let go to glide."
        }
    }
    private var between:some View {
        VStack(spacing:14) {
            story(r.flight == 0 ? "FIRST FLIGHT · SAFELY HOME" : "SECOND FLIGHT · A FRESH OLIVE LEAF",r.flight == 0 ? "Sometimes hope means waiting." : "A little leaf changed everything.",r.flight == 0 ? "There was nowhere to rest. Noah reached out and brought the dove back into the ark." : "At evening, the dove returned with a fresh olive leaf. Noah knew the waters had gone down.")
            DoveButton("Wait seven more days",symbol:"sun.max",action:controller.waitDays)
        }
    }
    private func story(_ eyebrow:String,_ title:String,_ text:String)->some View {
        VStack(alignment:.leading,spacing:9) {
            Text(eyebrow).font(.system(size:7,weight:.bold)).tracking(1.8).foregroundStyle(DovePalette.gold)
            Text(title).font(.system(size:28,design:.serif)).foregroundStyle(DovePalette.cream).fixedSize(horizontal:false,vertical:true)
            Text(text).font(.system(size:12,weight:.medium,design:.rounded)).foregroundStyle(DovePalette.aqua).lineSpacing(3).fixedSize(horizontal:false,vertical:true)
        }.frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,6).padding(.vertical,4)
    }
    private var won:some View {
        VStack(spacing:12) {
            story("WINGS OF HOPE · COMPLETE","Little wings. Great big hope.","Three flights. A fresh leaf. A place to rest. God was still caring for Noah, and new life was growing.")
            HStack(spacing:10) { ForEach(0..<3,id:\.self) { i in VStack(spacing:5) { Image(systemName:["wind","leaf.fill","sun.horizon.fill"][i]).font(.system(size:21,weight:.light));Text(["Safely home","A fresh leaf","A place to stay"][i]).font(.system(size:8,weight:.semibold,design:.rounded)) }.foregroundStyle(DovePalette.gold).frame(maxWidth:.infinity).padding(.vertical,11).background(.white.opacity(0.04),in:RoundedRectangle(cornerRadius:14)) } }
            HStack(spacing:9) { DoveButton("Keep exploring",symbol:"wind",secondary:true,action:controller.explore);DoveButton("Back to the voyage",symbol:"sailboat",action:exit) }
            Button("Fly our story again",action:controller.start).font(.system(size:10,weight:.semibold,design:.rounded)).foregroundStyle(DovePalette.aqua).frame(minHeight:38).buttonStyle(.plain)
        }
    }
    private var pauseCard:some View {
        ZStack {
            DovePalette.deep.opacity(0.75).ignoresSafeArea()
            VStack(spacing:18) {
                Image(systemName:"wind").font(.system(size:38,weight:.ultraLight)).foregroundStyle(DovePalette.gold)
                Text("A quiet little pause.").font(.system(size:29,design:.serif)).foregroundStyle(DovePalette.cream)
                DoveButton("Keep flying",symbol:"play.fill",action:controller.resume)
                DoveButton("Back to the voyage",symbol:"sailboat",secondary:true,action:exit)
            }.padding(28).frame(maxWidth:340).background(DovePalette.deep,in:RoundedRectangle(cornerRadius:30)).overlay(RoundedRectangle(cornerRadius:30).strokeBorder(DovePalette.gold.opacity(0.3))).padding(20)
        }
    }
}

struct DoveButton:View {
    let title:String
    let symbol:String
    var secondary = false
    let action:()->Void
    init(_ title:String,symbol:String,secondary:Bool = false,action:@escaping()->Void) { self.title = title;self.symbol = symbol;self.secondary = secondary;self.action = action }
    var body:some View {
        Button(action:action) {
            HStack(spacing:7) { Image(systemName:symbol).font(.system(size:15,weight:.medium));Text(title).font(.system(size:12,weight:.bold,design:.rounded)).lineLimit(2).minimumScaleFactor(0.8) }.frame(maxWidth:.infinity,minHeight:49).padding(.horizontal,11)
                .foregroundStyle(secondary ? DovePalette.cream : DovePalette.ink)
                .background(LinearGradient(colors:secondary ? [Color(hex:"#315E67"),Color(hex:"#234F5B")] : [Color(hex:"#FCE8B9"),DovePalette.gold],startPoint:.topLeading,endPoint:.bottomTrailing),in:Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(secondary ? 0.2 : 0.35)))
                .shadow(color:.black.opacity(0.12),radius:5,y:3)
        }.buttonStyle(DovePressStyle())
    }
}
private struct DovePressStyle:ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration:Configuration)->some View { configuration.label.scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1).opacity(configuration.isPressed ? 0.8 : 1).animation(.easeOut(duration:0.15),value:configuration.isPressed) }
}

private struct DoveJournal:View {
    @Environment(\.dismiss) private var dismiss
    let discoveries:Set<DoveDiscovery>
    let onRead:(DoveDiscovery)->Void
    var body:some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:22) {
                    Text("A little book of wonder.").font(.system(size:33,design:.serif)).foregroundStyle(DovePalette.ink)
                    Text("Fly slowly. Look closely. The world has little stories to tell.").font(.system(size:14,design:.rounded)).foregroundStyle(DovePalette.ink.opacity(0.7))
                    ForEach(DoveDiscovery.allCases) { d in
                        HStack(alignment:.top,spacing:15) {
                            Image(systemName:d.symbol).font(.system(size:26,weight:.ultraLight)).foregroundStyle(DovePalette.ink).frame(width:50,height:58).background(DovePalette.gold.opacity(0.35),in:RoundedRectangle(cornerRadius:16))
                            VStack(alignment:.leading,spacing:6) {
                                Text(discoveries.contains(d) ? "DISCOVERED" : "LOOK FOR THIS ON YOUR FLIGHTS").font(.system(size:7,weight:.bold)).tracking(1.5).foregroundStyle(DovePalette.ink.opacity(0.55))
                                Text(d.title).font(.system(size:21,design:.serif))
                                Text(d.text).font(.system(size:13,design:.rounded)).lineSpacing(4)
                                Button { onRead(d) } label: { Label("Read to me",systemImage:"speaker.wave.2.fill").font(.system(size:11,weight:.bold,design:.rounded)).padding(.horizontal,14).frame(minHeight:44).background(DovePalette.gold.opacity(0.55),in:Capsule()) }.buttonStyle(.plain).accessibilityLabel("Read about "+d.title)
                            }
                        }.foregroundStyle(DovePalette.ink)
                    }
                    Divider()
                    Text("From the Bible").font(.system(size:25,design:.serif))
                    Text("Noah sent a dove to see whether the waters had gone down. It first returned with nowhere to rest. After seven more days, it returned in the evening with a fresh olive leaf. After another seven days, Noah sent it again, and it did not return.").font(.system(size:14,design:.rounded)).lineSpacing(5)
                    Text("GENESIS 8:8–12").font(.system(size:8,weight:.bold)).tracking(2)
                    Text("Our coast, discoveries, and final resting branch are an imagined setting for play. The Bible tells us the dove did not return; it does not describe where the dove stayed. Noah remained in the ark until God told him to come out.").font(.system(size:12,design:.rounded)).lineSpacing(4).foregroundStyle(DovePalette.ink.opacity(0.7))
                }.padding(25).frame(maxWidth:580).frame(maxWidth:.infinity)
            }.background(DovePalette.cream).foregroundStyle(DovePalette.ink).navigationTitle("The Nature Journal").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement:.topBarTrailing) { Button("Done") { dismiss() }.foregroundStyle(DovePalette.ink) } }
        }.preferredColorScheme(.light)
    }
}
