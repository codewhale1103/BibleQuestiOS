import SwiftUI

struct RainOrchestraGame: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var controller = RainOrchestraController()
    @State private var notes = false
    var onComplete: (() -> Void)? = nil
    var onExit: (() -> Void)? = nil
    private func exit() { controller.pause();if let onExit { onExit() } else { dismiss() } }
    var body: some View {
        GeometryReader { g in
            let wide = g.size.width>g.size.height*1.25,r = controller.round
            ZStack {
                background(size:g.size)
                if r.phase == .intro { intro(wide:wide) }
                else if r.phase == .finale { finale(size:g.size) }
                else {
                    Group {
                        if wide {
                            HStack(spacing:18) {
                                ScrollView(showsIndicators:false) { VStack(spacing:10) { header;dayRibbon;instructions;controls } }.frame(width:min(310,g.size.width*0.37))
                                RainOrchestraBoard(controller:controller).frame(maxWidth:.infinity,maxHeight:.infinity)
                            }.padding(.horizontal,20).padding(.vertical,6)
                        } else {
                            VStack(spacing:8) { header;dayRibbon;instructions;RainOrchestraBoard(controller:controller).frame(maxHeight:.infinity);controls }.padding(.horizontal,17).padding(.vertical,4)
                        }
                    }.accessibilityHidden(r.phase == .paused || r.phase == .won).allowsHitTesting(r.phase != .paused && r.phase != .won)
                    if r.phase == .paused || r.phase == .won { panel(won:r.phase == .won) }
                }
            }.onChange(of:wide) { _,_ in controller.pause() }
        }.background(RainPalette.ink).preferredColorScheme(.dark).toolbar(.hidden,for:.navigationBar,.tabBar)
            .onAppear { controller.reduceMotion = reduceMotion;controller.onComplete = onComplete;controller.attach() }
            .onDisappear { controller.detach() }
            .onChange(of:scenePhase) { _,value in if value != .active { controller.pause() } }
            .onChange(of:reduceMotion) { _,value in controller.reduceMotion = value }
            .sheet(isPresented:$notes) { RainOrchestraNotes() }
    }
    private func background(size:CGSize) -> some View {
        let night = controller.round.chapter == 2 || controller.round.day%2 == 0
        return ZStack {
            Image("FloodStorm").resizable().scaledToFill().frame(width:size.width,height:size.height).clipped().opacity(0.28)
            FloodSea(time:reduceMotion ? 0 : controller.time,surface:0.6).opacity(0.7)
            LinearGradient(colors:[Color(hex:night ? "#111D34" : "#103E4B").opacity(0.90),RainPalette.ink.opacity(0.8),RainPalette.ink],startPoint:.top,endPoint:.bottom)
        }.ignoresSafeArea().accessibilityHidden(true).animation(.easeInOut(duration:reduceMotion ? 0 : 2),value:controller.round.day)
    }
    private var header: some View {
        HStack(spacing:4) {
            icon("chevron.left","Back to Noah's voyage",exit)
            VStack(alignment:.leading,spacing:3) { Text("40 DAYS & NIGHTS").font(.system(size:6,weight:.bold)).tracking(2).foregroundStyle(RainPalette.gold);Text("The Rain Orchestra").font(.system(size:23,design:.serif)).lineLimit(1).minimumScaleFactor(0.5).foregroundStyle(RainPalette.cream) }.frame(maxWidth:.infinity,alignment:.leading)
            icon(controller.soundOn ? "speaker.wave.2" : "speaker.slash",controller.soundOn ? "Mute rain orchestra" : "Turn rain orchestra sounds on",controller.toggleSound)
            if controller.round.phase != .intro { icon("pause","Pause rain orchestra",controller.pause) }
        }.frame(minHeight:44)
    }
    private func icon(_ symbol:String,_ label:String,_ action:@escaping()->Void) -> some View {
        Button(action:action) { Image(systemName:symbol).font(.system(size:17,weight:.light)).foregroundStyle(RainPalette.cream).frame(width:37,height:44) }.buttonStyle(.plain).accessibilityLabel(label)
    }
    private var dayRibbon: some View { RainDayRibbon(day:controller.round.day,night:controller.round.chapter == 2 || controller.round.day%2 == 0).padding(.horizontal,6).padding(.vertical,4) }
    private var instructions: some View {
        let r = controller.round
        return VStack(alignment:.leading,spacing:5) {
            HStack {
                Text(r.phase == .celebrating ? "A BEAUTIFUL LITTLE INVENTION" : r.phase == .freeplay ? "YOUR WATER WONDERLAND" : "SONG \(r.chapter+1) OF 5").font(.system(size:6,weight:.bold)).tracking(1.7).foregroundStyle(RainPalette.gold)
                Spacer()
                if r.phase == .playing && r.chapter == 2 { Button(action:controller.melody) { Label("Hear melody",systemImage:"music.note.list").font(.system(size:10,weight:.bold,design:.rounded)).foregroundStyle(RainPalette.gold).padding(.horizontal,10).frame(minHeight:32).background(.white.opacity(0.08),in:Capsule()) }.buttonStyle(.plain).accessibilityLabel("Hear the low, high, middle melody") }
            }
            Text(r.phase == .celebrating ? "Your water machine sings!" : r.phase == .freeplay ? "Make a little rain magic." : r.title).font(.system(size:25,design:.serif)).foregroundStyle(RainPalette.cream).lineLimit(1).minimumScaleFactor(0.7)
            if r.chapter == 2 && r.phase == .playing {
                Text("Turn the top channel to choose a bowl, then pour.").font(.system(size:10,weight:.medium,design:.rounded)).foregroundStyle(RainPalette.aqua)
                HStack(spacing:6) { ForEach(Array(RainOrchestraRound.melody.enumerated()),id:\.offset) { i,note in Text(["LOW","MIDDLE","HIGH"][note]).font(.system(size:9,weight:.heavy,design:.rounded)).tracking(1).foregroundStyle(i<r.melodyProgress ? RainPalette.ink : RainPalette.cream).padding(.horizontal,12).padding(.vertical,6).background(i<r.melodyProgress ? RainPalette.gold : .white.opacity(0.07),in:Capsule());if i<2 { Image(systemName:"arrow.right").font(.system(size:8)).foregroundStyle(RainPalette.aqua) } } }.accessibilityElement(children:.ignore).accessibilityLabel("Melody: low, high, middle. \(r.melodyProgress) of three matched.")
            } else {
                Text(r.phase == .celebrating ? "Water, wonder, and a little patient experimenting." : r.phase == .freeplay ? "Rearrange the channels. Tap bowls. Launch a tiny boat." : r.instruction).font(.system(size:11,weight:.medium,design:.rounded)).lineSpacing(2).foregroundStyle(RainPalette.aqua).fixedSize(horizontal:false,vertical:true)
            }
        }.padding(.horizontal,6).frame(minHeight:77,alignment:.topLeading)
    }
    private var controls: some View {
        let r = controller.round
        return VStack(spacing:6) {
            RainMusicStrip(controller:controller)
            if r.phase == .celebrating {
                RainButton(title:r.chapter == 4 ? "Watch the rain grow quiet" : "The next little song",symbol:r.chapter == 4 ? "cloud" : "music.note",action:controller.next)
            } else {
                HStack(spacing:9) {
                    if r.phase == .freeplay { RainButton(title:"Sail a boat",symbol:"sailboat",secondary:true,action:controller.boat) }
                    else { RainButton(title:"A little clue",symbol:"sparkles",secondary:true,action:controller.help) }
                    RainButton(title:r.waterMoving ? "Flowing…" : "Let it rain",symbol:"drop.fill",action:controller.pour).disabled(r.waterMoving).opacity(r.waterMoving ? 0.65 : 1)
                }
            }
            HStack(spacing:10) {
                if controller.captionUntil>controller.time { Text(controller.caption).font(.system(size:9,weight:.medium,design:.rounded)).foregroundStyle(RainPalette.gold).lineLimit(1).minimumScaleFactor(0.7) }
                else { Text("DRAG TO BUILD · TAP TO TURN").font(.system(size:6,weight:.bold)).tracking(1.4).foregroundStyle(RainPalette.aqua.opacity(0.7)) }
                Spacer(minLength:0)
                if r.interactive {
                    Button(action:controller.read) { Label("Read to me",systemImage:"speaker.wave.2.fill").font(.system(size:11,weight:.bold,design:.rounded)).foregroundStyle(RainPalette.ink).padding(.horizontal,12).frame(minHeight:44).background(RainPalette.gold,in:Capsule()) }.buttonStyle(FloodPressStyle()).accessibilityLabel("Read the instructions to me")
                    Button(action:controller.reset) { Image(systemName:"arrow.counterclockwise").font(.system(size:14,weight:.medium)).foregroundStyle(RainPalette.aqua) }.frame(width:40,height:44).buttonStyle(.plain).accessibilityLabel("Reset this water machine")
                }
            }.frame(minHeight:35)
        }
    }
    private func intro(wide:Bool) -> some View {
        VStack(spacing:8) {
            header.padding(.horizontal,17)
            if wide { HStack(spacing:23) { RainOrchestraBoard(controller:controller,demo:true);ScrollView(showsIndicators:false) { introCopy }.frame(width:315) }.padding(.horizontal,24) }
            else { RainOrchestraBoard(controller:controller,demo:true).frame(maxHeight:.infinity).padding(.horizontal,40);introCopy.padding(.horizontal,26).padding(.bottom,10) }
        }
    }
    private var introCopy: some View {
        VStack(alignment:.leading,spacing:12) {
            Text("A LITTLE RAIN. A WORLD OF WONDER.").font(.system(size:7,weight:.bold)).tracking(1.8).foregroundStyle(RainPalette.gold)
            Text("What if the rain\ncould sing?").font(.system(size:39,design:.serif)).foregroundStyle(RainPalette.cream).fixedSize(horizontal:false,vertical:true)
            Text("Build winding water paths. Wake up musical bowls. Turn a tiny animal parade. Make a beautiful song while the ark floats on.").font(.system(size:13)).lineSpacing(4).foregroundStyle(RainPalette.aqua)
            HStack(spacing:15) { Label("5 little inventions",systemImage:"sparkles");Label("Endless experimenting",systemImage:"hand.draw") }.font(.system(size:8,weight:.semibold)).foregroundStyle(RainPalette.gold)
            RainMusicStrip(controller:controller)
            RainButton(title:"Make the rain sing",symbol:"music.note",action:controller.start)
        }
    }
    private func finale(size:CGSize) -> some View {
        VStack(spacing:14) {
            header.padding(.horizontal,17)
            Spacer(minLength:0)
            Text("FORTY DAYS. FORTY NIGHTS.").font(.system(size:8,weight:.bold)).tracking(2.5).foregroundStyle(RainPalette.gold)
            Text("And then,\nthe rain grew quiet.").font(.system(size:38,design:.serif)).foregroundStyle(RainPalette.cream).multilineTextAlignment(.center)
            ZStack {
                Image("FloodExterior").resizable().scaledToFit().rotationEffect(.degrees(reduceMotion ? 0 : sin(controller.time*0.7)*1.1)).offset(y:reduceMotion ? 0 : sin(controller.time)*4)
            }.frame(maxHeight:size.height*0.35).padding(.horizontal,15).accessibilityHidden(true)
            Text("Noah and his family stayed in the ark longer, waiting and trusting God.").font(.system(size:15)).lineSpacing(5).multilineTextAlignment(.center).foregroundStyle(RainPalette.aqua).padding(.horizontal,35)
            RainDayRibbon(day:40,night:false).padding(30)
            Spacer(minLength:0)
        }
    }
    private func panel(won:Bool) -> some View {
        ZStack {
            RainPalette.ink.opacity(0.93).ignoresSafeArea()
            ScrollView {
                VStack(spacing:17) {
                    Image(systemName:won ? "music.note.house" : "pause.circle").font(.system(size:44,weight:.ultraLight)).foregroundStyle(RainPalette.gold)
                    Text(won ? "YOUR RAIN SONG IS COMPLETE" : "A QUIET LITTLE BREAK").font(.system(size:7,weight:.bold)).tracking(2).foregroundStyle(RainPalette.gold)
                    Text(won ? "Wonder in\nthe waiting." : "Your invention\nis right here.").font(.system(size:38,design:.serif)).foregroundStyle(RainPalette.cream).multilineTextAlignment(.center)
                    if won {
                        Text("Five water machines. Forty story days. You practiced patterns, made discoveries, and filled our pretend ark workshop with music.").font(.system(size:14)).lineSpacing(5).multilineTextAlignment(.center).foregroundStyle(RainPalette.aqua)
                        Text("Rain fell for 40 days and nights. Noah’s whole stay in the ark lasted much longer.").font(.system(size:12,weight:.semibold,design:.rounded)).lineSpacing(4).multilineTextAlignment(.center).foregroundStyle(RainPalette.gold)
                        RainMusicStrip(controller:controller)
                        RainButton(title:"Keep making music",symbol:"music.note",action:controller.freeplay)
                        RainButton(title:"Back to Noah’s voyage",symbol:"sailboat",secondary:true,action:exit)
                        Button("Play all five songs again",action:controller.start).font(.system(size:13,weight:.semibold)).foregroundStyle(RainPalette.gold).frame(minHeight:44)
                    } else {
                        RainButton(title:"Keep inventing",symbol:"play.fill",action:controller.resume)
                        RainButton(title:"Back to Noah’s voyage",symbol:"sailboat",secondary:true,action:exit)
                    }
                    Button("Story & sound notes") { notes = true }.font(.system(size:12)).foregroundStyle(RainPalette.aqua).frame(minHeight:44)
                }.padding(25).frame(maxWidth:415).background(RainPalette.ink,in:RoundedRectangle(cornerRadius:29)).overlay(RoundedRectangle(cornerRadius:29).strokeBorder(RainPalette.gold.opacity(0.3))).padding(23).frame(maxWidth:.infinity)
            }.defaultScrollAnchor(.center)
        }
    }
}
private struct RainOrchestraNotes: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView { VStack(alignment:.leading,spacing:19) {
            HStack { Text("Wonder in the waiting").font(.system(size:29,design:.serif));Spacer();Button { dismiss() } label:{Image(systemName:"xmark").frame(width:44,height:44)}.accessibilityLabel("Close rain orchestra notes") }
            Text("Genesis 7:12 tells of rain for forty days and forty nights. Genesis 8:1–5 tells how God remembered Noah and the waters began to go down. Noah’s family remained in the ark much longer than forty days. Our forty story markers shorten time for play.")
            Text("The Rain Orchestra is an imaginative water workshop, not an event described in Genesis. Children explore gravity, cause and effect, split streams, spatial reasoning, three-note patterns, and patient experimentation. Water is recirculated in our pretend machine; it is not a model of the ark’s construction.")
            Text("Drag a piece from the bottom shelf to a ring. Tap a placed piece to turn it. Drag between rings to swap pieces, or back to the shelf to remove one. You can also choose a piece and tap an empty ring. Pull the golden gate or tap Let it rain. Hints add one connection at a time. There are no penalties or countdowns.")
            Text("VoiceOver offers the same placement, rotation, removal, gate, and melody actions. Sound is optional. Reduced Motion removes ambient rain, rocking, and parade movement while retaining the water-route feedback.")
            Text("The workshop background, bowls, drum, and waterwheel were created for BibleQuest with the built-in image-generation tool. Channels, flowing water, note effects, and machinery are drawn and animated in the app. Music: “After the Rain,” an original BibleQuest instrumental, and a fresh instrumental arrangement of William B. Bradbury’s public-domain “Jesus Loves Me” refrain (1862). Recorded flute, harp, strings, mallets, and percussion use VS Chamber Orchestra: Community Edition samples by Sam Gossner and Simon Dalzell, released under CC0. No movie recordings or modern hymn arrangements are used. Musical bowl cues are original synthesized recordings. Narration is Anna – Children’s Book Narrator, ElevenLabs Multilingual v2, stored offline. Existing ark and animal illustrations are reused from Noah’s adventure.")
            RainButton(title:"Back to the music",symbol:"arrow.left") { dismiss() }
        }.font(.system(size:14)).lineSpacing(5).foregroundStyle(RainPalette.cream).padding(25).frame(maxWidth:600).frame(maxWidth:.infinity) }.background(RainPalette.ink.ignoresSafeArea()).preferredColorScheme(.dark).presentationDragIndicator(.visible)
    }
}
#Preview { RainOrchestraGame() }
