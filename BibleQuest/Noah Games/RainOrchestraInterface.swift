import SwiftUI

enum RainPalette {
    static let ink = Color(hex:"#081F2B")
    static let cream = Color(hex:"#FFF0CF")
    static let gold = Color(hex:"#E7BC73")
    static let aqua = Color(hex:"#A8E2DC")
}
struct RainToolBadge: View {
    let piece: RainPiece
    var selected = false
    var body: some View {
        GeometryReader { g in
            ZStack {
                RoundedRectangle(cornerRadius:12).fill(LinearGradient(colors:[Color(hex:selected ? "#D3AB69" : "#835833"),Color(hex:"#402B21")],startPoint:.topLeading,endPoint:.bottomTrailing))
                RoundedRectangle(cornerRadius:12).strokeBorder(selected ? RainPalette.cream : RainPalette.gold.opacity(0.4),lineWidth:selected ? 1.5 : 0.7)
                if piece == .wheel {
                    Image("RainWaterwheel").resizable().scaledToFit().padding(4).shadow(color:.black.opacity(0.5),radius:1,y:2)
                } else {
                    Canvas { c,s in
                        var p = Path();p.move(to:CGPoint(x:s.width*0.5,y:s.height*0.18));p.addLine(to:CGPoint(x:s.width*0.5,y:s.height*0.4))
                        if piece == .fork { p.move(to:CGPoint(x:s.width*0.5,y:s.height*0.4));p.addQuadCurve(to:CGPoint(x:s.width*0.23,y:s.height*0.83),control:CGPoint(x:s.width*0.23,y:s.height*0.6));p.move(to:CGPoint(x:s.width*0.5,y:s.height*0.4));p.addQuadCurve(to:CGPoint(x:s.width*0.77,y:s.height*0.83),control:CGPoint(x:s.width*0.77,y:s.height*0.6)) }
                        else { p.addLine(to:CGPoint(x:s.width*0.5,y:s.height*0.83)) }
                        c.stroke(p,with:.color(RainPalette.gold),style:.init(lineWidth:8,lineCap:.round));c.stroke(p,with:.color(Color(hex:"#30281E")),style:.init(lineWidth:4,lineCap:.round));c.stroke(p,with:.color(RainPalette.aqua.opacity(0.8)),style:.init(lineWidth:1.3,lineCap:.round))
                    }
                }
            }.shadow(color:.black.opacity(0.4),radius:3,y:3)
        }.accessibilityHidden(true)
    }
}
private struct RainBowlShape: Shape {
    func path(in r:CGRect) -> Path {
        var p = Path();p.move(to:CGPoint(x:r.minX,y:r.minY));p.addQuadCurve(to:CGPoint(x:r.midX,y:r.maxY),control:CGPoint(x:r.minX+r.width*0.08,y:r.maxY));p.addQuadCurve(to:CGPoint(x:r.maxX,y:r.minY),control:CGPoint(x:r.maxX-r.width*0.08,y:r.maxY));p.addQuadCurve(to:CGPoint(x:r.minX,y:r.minY),control:CGPoint(x:r.midX,y:r.height*0.13));p.closeSubpath();return p
    }
}
struct RainInstrument: View {
    let note: Int
    let fill: Double
    let hit: Double
    let active: Bool
    let drum: Bool
    private var color: Color { [Color(hex:"#D9A562"),Color(hex:"#77BCB6"),Color(hex:"#ADA7D4")][note] }
    var body: some View {
        GeometryReader { g in
            let w = g.size.width,h = g.size.height
            ZStack {
                Ellipse().fill(.black.opacity(0.4)).frame(width:w*0.95,height:h*0.12).position(x:w/2,y:h*0.87)
                if hit>0 {
                    Image(systemName:"music.note").font(.system(size:w*0.28,weight:.light)).foregroundStyle(color.opacity(hit)).position(x:w*0.74,y:h*(0.15-(1-hit)*0.6))
                    ForEach(0..<3,id:\.self) { i in
                        Ellipse().strokeBorder(color.opacity(hit*0.8),lineWidth:1.5).frame(width:w*(1+Double(i)*0.3+(1-hit)*0.5),height:h*(0.3+Double(i)*0.13)).position(x:w/2,y:h*0.4)
                    }
                }
                if drum {
                    Image("RainMusicDrum").resizable().scaledToFit().frame(width:w*0.94,height:h*0.60).position(x:w/2,y:h*0.61+hit*h*0.018)
                    RainBowlShape().fill(LinearGradient(colors:[Color(hex:"#DAAB68"),Color(hex:"#814B29")],startPoint:.leading,endPoint:.trailing)).frame(width:w*0.58,height:h*0.24).overlay(alignment:.top) { Ellipse().fill(RainPalette.aqua.opacity(0.65)).frame(height:h*0.035).padding(.horizontal,3).opacity(fill) }.rotationEffect(.degrees(-hit*55),anchor:.topLeading).position(x:w*0.55,y:h*0.14)
                    if hit>0.1 { Capsule().fill(RainPalette.aqua.opacity(hit)).frame(width:3,height:h*0.23).rotationEffect(.degrees(20)).position(x:w*0.35,y:h*0.28) }
                } else {
                    let scale = note == 0 ? 1.0 : note == 2 ? 0.83 : 0.92
                    Image("RainMusicBowl").resizable().scaledToFit().frame(width:w*scale,height:h*0.86).position(x:w/2,y:h*0.46)
                    Ellipse().fill(RainPalette.aqua.opacity(fill*0.20)).frame(width:w*0.72*scale,height:h*0.10).position(x:w/2,y:h*0.28)
                    if fill>0.1 { Ellipse().strokeBorder(.white.opacity(fill*0.35),lineWidth:0.7).frame(width:w*0.54*scale,height:h*0.065).position(x:w/2,y:h*0.27) }
                }
                Text(note == 0 ? "LOW" : note == 2 ? "HIGH" : drum ? "DRUM" : "MID").font(.system(size:w*0.115,weight:.heavy,design:.rounded)).tracking(1.2).foregroundStyle(active ? RainPalette.cream : RainPalette.cream.opacity(0.45)).position(x:w/2,y:h*1.02)
            }.scaleEffect(1+hit*0.045).saturation(active ? 1 : 0.2).brightness(active ? 0 : -0.24)
        }.accessibilityHidden(true)
    }
}
struct RainButton: View {
    let title: String
    var symbol = "arrow.right"
    var secondary = false
    let action: () -> Void
    var body: some View {
        Button(action:action) {
            HStack(spacing:9) { Image(systemName:symbol);Text(title);Spacer(minLength:0);if !secondary { Image(systemName:"arrow.right").font(.system(size:12,weight:.bold)) } }
                .font(.system(size:15,weight:.bold,design:.rounded)).foregroundStyle(secondary ? RainPalette.cream : RainPalette.ink)
                .padding(.horizontal,17).frame(minHeight:53).background {
                    if secondary { RoundedRectangle(cornerRadius:18).fill(.white.opacity(0.07)).overlay(RoundedRectangle(cornerRadius:18).strokeBorder(RainPalette.gold.opacity(0.25))) }
                    else { RoundedRectangle(cornerRadius:18).fill(LinearGradient(colors:[RainPalette.cream,RainPalette.gold],startPoint:.topLeading,endPoint:.bottomTrailing)) }
                }
        }.buttonStyle(FloodPressStyle())
    }
}
struct RainDayRibbon: View {
    let day: Int
    let night: Bool
    var body: some View {
        HStack(spacing:9) {
            Image(systemName:night ? "moon.stars" : "cloud.sun.rain").font(.system(size:17,weight:.light)).foregroundStyle(RainPalette.gold).frame(width:24)
            VStack(alignment:.leading,spacing:5) {
                HStack(spacing:4) {
                    ForEach(0..<5,id:\.self) { group in
                        HStack(spacing:2) { ForEach(0..<8,id:\.self) { i in Capsule().fill(group*8+i<day ? RainPalette.gold : .white.opacity(0.14)).frame(height:3) } }
                    }
                }
                HStack { Text("STORY DAY \(day)");Spacer();Text("40 DAYS & NIGHTS") }.font(.system(size:6,weight:.bold)).tracking(1.4).foregroundStyle(RainPalette.aqua.opacity(0.8))
            }
        }.accessibilityElement(children:.ignore).accessibilityLabel("Story day \(day) of forty. Time is shortened for our game.")
    }
}

struct RainMusicStrip: View {
    @ObservedObject var controller:RainOrchestraController
    @State private var showSongs = false
    var body: some View {
        VStack(spacing:6) {
            HStack(spacing:10) {
                Image(systemName:"music.note").font(.system(size:18,weight:.light)).foregroundStyle(RainPalette.gold).frame(width:24)
                Button { showSongs = true } label: {
                    VStack(alignment:.leading,spacing:3) {
                        HStack(spacing:5) { Text(controller.song.title).font(.system(size:13,weight:.bold,design:.rounded));Image(systemName:"chevron.down").font(.system(size:8,weight:.bold)) }
                        Text(controller.song.detail).font(.system(size:9,weight:.medium,design:.rounded)).foregroundStyle(RainPalette.aqua)
                    }.foregroundStyle(RainPalette.cream).frame(maxWidth:.infinity,minHeight:44,alignment:.leading).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityLabel("Choose music: \(controller.song.title)")
                Button(action:controller.toggleMusic) {
                    HStack(spacing:6) { Image(systemName:controller.musicPlaying ? "pause.fill" : "play.fill");Text(controller.musicPlaying ? "Pause" : "Play song") }.font(.system(size:11,weight:.bold,design:.rounded)).foregroundStyle(RainPalette.ink).padding(.horizontal,12).frame(minHeight:44).background(RainPalette.gold,in:Capsule())
                }.buttonStyle(FloodPressStyle()).accessibilityLabel(controller.musicPlaying ? "Pause the song" : "Play \(controller.song.title)")
            }
            GeometryReader { g in
                Capsule().fill(.white.opacity(0.09))
                Capsule().fill(RainPalette.gold.opacity(0.8)).frame(width:max(0,g.size.width*controller.musicProgress))
            }.frame(height:2).accessibilityHidden(true)
        }.padding(.horizontal,12).padding(.vertical,5).background(.white.opacity(0.045),in:RoundedRectangle(cornerRadius:17)).overlay(RoundedRectangle(cornerRadius:17).strokeBorder(RainPalette.gold.opacity(0.18)))
            .sheet(isPresented:$showSongs) { RainSongPicker(controller:controller) }
    }
}

private struct RainSongPicker: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var controller:RainOrchestraController
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:15) {
                HStack {
                    VStack(alignment:.leading,spacing:5) {
                        Text("A LITTLE MUSIC, A LITTLE JOY").font(.system(size:7,weight:.bold)).tracking(1.4).foregroundStyle(RainPalette.gold)
                        Text("Pick a little song").font(.system(size:29,design:.serif)).foregroundStyle(RainPalette.cream)
                    }
                    Spacer()
                    Button { dismiss() } label: { Image(systemName:"xmark").font(.system(size:14,weight:.medium)).foregroundStyle(RainPalette.aqua).frame(width:44,height:44).background(.white.opacity(0.06),in:Circle()) }.buttonStyle(.plain).accessibilityLabel("Close song picker")
                }
                ForEach(RainSong.allCases) { song in
                    Button { controller.chooseSong(song);dismiss() } label: {
                        HStack(spacing:13) {
                            Image(systemName:song == .afterTheRain ? "sun.max" : "heart").font(.system(size:25,weight:.light)).foregroundStyle(RainPalette.gold).frame(width:43,height:50)
                            VStack(alignment:.leading,spacing:5) {
                                Text(song.title).font(.system(size:17,weight:.bold,design:.rounded)).foregroundStyle(RainPalette.cream)
                                Text(song.detail).font(.system(size:12)).foregroundStyle(RainPalette.aqua)
                            }.frame(maxWidth:.infinity,alignment:.leading)
                            Image(systemName:song == controller.song ? "checkmark.circle.fill" : "play.circle.fill").font(.system(size:28,weight:.light)).foregroundStyle(RainPalette.gold)
                        }.padding(13).background(.white.opacity(0.06),in:RoundedRectangle(cornerRadius:20)).overlay(RoundedRectangle(cornerRadius:20).strokeBorder(RainPalette.gold.opacity(song == controller.song ? 0.65 : 0.18)))
                    }.buttonStyle(FloodPressStyle()).accessibilityLabel("Play \(song.title), \(song.detail)")
                }
            }.padding(23).frame(maxWidth:540).frame(maxWidth:.infinity)
        }.background(RainPalette.ink.ignoresSafeArea()).preferredColorScheme(.dark).presentationDetents([.height(330),.large]).presentationDragIndicator(.visible)
    }
}
