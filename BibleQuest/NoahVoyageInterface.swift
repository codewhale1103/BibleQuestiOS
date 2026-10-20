import SwiftUI

struct NoahVoyageHeader: View {
    let chapter: Int
    var compact = false
    let onBack: () -> Void
    var body: some View {
        HStack(spacing: 10) {
            Button(action: onBack) { Image(systemName: "chevron.left").font(.system(size: 13,weight: .semibold)).frame(width: 44,height: 44) }.buttonStyle(.plain).accessibilityLabel("Back to quests")
            VStack(alignment: .leading,spacing: 5) {
                Text("THE GREAT VOYAGE").font(.system(size: 8,weight: .bold)).tracking(2.6).foregroundStyle(Color(hex: "#E7CD9A"))
                Text("Noah’s Adventure").font(.system(size: compact ? 22 : 25,design: .serif)).lineLimit(1).minimumScaleFactor(0.7)
                HStack(spacing: 5) {
                    ForEach(0..<7,id: \.self) { index in Capsule().fill(Color(hex: index <= chapter ? "#E7CD9A" : "#547A84")).frame(width: 18,height: 2) }
                    Text("\(chapter+1) / 7").font(.system(size: 7,weight: .medium,design: .monospaced)).foregroundStyle(Color(hex: "#BDDBD8")).padding(.leading,4)
                }.accessibilityElement(children: .ignore).accessibilityLabel("Chapter \(chapter+1) of 7")
            }
            Spacer(minLength: 0)
            Image(systemName: "location.north.circle").font(.system(size: 30,weight: .ultraLight)).foregroundStyle(Color(hex: "#D8CBAB").opacity(0.75)).accessibilityHidden(true)
        }.foregroundStyle(Color(hex: "#FFF4DB")).padding(.horizontal,12).padding(.vertical,13)
            .background(LinearGradient(colors: [Color(hex: "#103747").opacity(0.96),Color(hex: "#103747").opacity(0.88)],startPoint: .topLeading,endPoint: .bottomTrailing),in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color(hex: "#B8D4CA").opacity(0.25),lineWidth: 0.8))
            .shadow(color: Color(hex: "#002837").opacity(0.25),radius: 16,y: 7)
    }
}
struct NoahVoyageDock: View {
    let chapter: NoahVoyageChapter
    let sailing: Bool
    let atEnd: Bool
    var compact = false
    var rainbowFinished = false
    var buildFinished = false
    var animalsFinished = false
    var floodFinished = false
    var waitingFinished = false
    var doveFinished = false
    let onStart: () -> Void
    let onSail: () -> Void
    let onLatest: () -> Void
    let onDiscover: () -> Void
    var body: some View {
        VStack(spacing: compact ? 6 : 12) {
            HStack {
                HStack(spacing: 6) { Circle().fill(Color(hex: "#BCE4CC")).frame(width: 4,height: 4); Text(sailing ? "UNDERWAY" : "AT ANCHOR").font(.system(size: 7,weight: .bold)).tracking(1.7) }.foregroundStyle(Color(hex: "#C2DED3"))
                Spacer()
                Text(chapter.passage).font(.system(size: 6,weight: .semibold)).tracking(0.8).foregroundStyle(Color(hex: "#A4C6C5"))
            }
            Button(action: onDiscover) {
                HStack {
                    VStack(alignment: .leading,spacing: 4) {
                        Text(sailing ? "Sailing toward" : chapter == .dove ? (doveFinished ? "FLY WINGS OF HOPE AGAIN" : "PLAY · FLY, DISCOVER & BRING HOPE") : chapter == .waiting ? (waitingFinished ? "PLAY THE RAIN ORCHESTRA AGAIN" : "PLAY · BUILD, FLOW & MAKE MUSIC") : chapter == .flood ? (floodFinished ? "PLAY ARK AFLOAT AGAIN" : "PLAY · EXPLORE, PREPARE & CARE") : chapter == .animals ? (animalsFinished ? "PLAY ARK PARADE AGAIN" : "PLAY · LISTEN, FIND & GUIDE") : chapter == .build ? (buildFinished ? "RETURN TO YOUR WORKSHOP" : "PLAY · HUNT, BUILD & PAINT") : chapter == .promise ? (rainbowFinished ? "PLAY THE PROMISE AGAIN" : "PLAY THE RAINBOW CHALLENGE") : "DISCOVER THIS CHAPTER").font(.system(size: 6,weight: .bold)).tracking(1.4).opacity(0.6)
                        Text(chapter.title).font(.system(size: compact ? 18 : 21,design: .serif))
                    }
                    Spacer()
                    Image(systemName: sailing ? "water.waves" : chapter == .dove || chapter == .promise || chapter == .build || chapter == .animals || chapter == .flood || chapter == .waiting ? "play.fill" : "arrow.up.right").font(.system(size: 20,weight: .light))
                }.foregroundStyle(Color(hex: "#143D49")).padding(.horizontal,17).frame(minHeight: compact ? 56 : 65)
                    .background(LinearGradient(colors: [Color(hex: "#FFF3D0"),Color(hex: "#DBBD84")],startPoint: .topLeading,endPoint: .bottomTrailing),in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.3)))
            }.buttonStyle(.plain).disabled(sailing).accessibilityLabel(sailing ? "Sailing to \(chapter.title)" : chapter == .dove ? (doveFinished ? "Replay The Dove Returns" : "Play The Dove Returns") : chapter == .waiting ? (waitingFinished ? "Replay 40 Days and Nights" : "Play 40 Days and Nights") : chapter == .flood ? (floodFinished ? "Replay Flood Begins" : "Play Flood Begins") : chapter == .animals ? (animalsFinished ? "Replay Gather Animals" : "Play Gather Animals") : chapter == .build ? (buildFinished ? "Replay Build the Ark" : "Play Build the Ark") : chapter == .promise ? (rainbowFinished ? "Replay Rainbow Promise" : "Play Rainbow Promise") : "Discover \(chapter.title)")
            HStack(spacing: 0) {
                control("arrow.uturn.backward","Start",action: onStart)
                Divider().overlay(Color(hex: "#92B5B5").opacity(0.25)).frame(height: 20)
                control(sailing ? "pause.fill" : atEnd ? "flag.checkered" : "sailboat",sailing ? "Pause" : atEnd ? "Harbor" : "Sail",action: onSail)
                Divider().overlay(Color(hex: "#92B5B5").opacity(0.25)).frame(height: 20)
                control("location","Latest",action: onLatest)
            }
        }.padding(.horizontal,16).padding(.top,13).padding(.bottom,4)
            .background(LinearGradient(colors: [Color(hex: "#123D4D").opacity(0.93),Color(hex: "#0B2B3C").opacity(0.98)],startPoint: .top,endPoint: .bottom),in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Color(hex: "#BCD1B8").opacity(0.25),lineWidth: 0.8))
            .shadow(color: Color(hex: "#002534").opacity(0.4),radius: 18,y: 7)
    }
    private func control(_ symbol: String,_ title: String,action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) { Image(systemName: symbol).font(.system(size: 12,weight: .light)); Text(title).font(.system(size: 10,weight: .semibold)).tracking(0.5) }.frame(maxWidth: .infinity,minHeight: compact ? 34 : 42)
        }.buttonStyle(.plain).foregroundStyle(Color(hex: "#DAE7D9"))
    }
}
struct NoahVoyageChapterSheet: View {
    @Environment(\.dismiss) private var dismiss
    let chapter: NoahVoyageChapter
    var body: some View {
        ScrollView {
            VStack(alignment: .leading,spacing: 20) {
                HStack {
                    Text("THE GREAT VOYAGE · \(String(format: "%02d",chapter.rawValue+1))").font(.system(size: 8,weight: .bold)).tracking(2.5).foregroundStyle(Color(hex: "#E4CE9E"))
                    Spacer()
                    Button { dismiss() } label: { Image(systemName: "xmark").font(.system(size: 12,weight: .semibold)).frame(width: 44,height: 44).background(.white.opacity(0.07),in: Circle()) }.accessibilityLabel("Close chapter")
                }
                Image(chapter.landmark).resizable().scaledToFit().frame(height: 180).frame(maxWidth: .infinity).shadow(color: Color(hex: "#A6DBCC").opacity(0.15),radius: 20).accessibilityHidden(true)
                VStack(alignment: .leading,spacing: 8) {
                    Text(chapter.title).font(.system(size: 35,design: .serif))
                    Text(chapter.subtitle).font(.system(size: 16,design: .serif)).foregroundStyle(Color(hex: "#DFC99C"))
                }
                Text(chapter.story).font(.system(size: 16)).lineSpacing(6).foregroundStyle(Color(hex: "#D4E3D9"))
                Text(chapter.passage).font(.system(size: 8,weight: .bold)).tracking(1.5).foregroundStyle(Color(hex: "#9BBEBD"))
                Button { dismiss() } label: { HStack { Text("Back to the voyage"); Spacer(); Image(systemName: "arrow.right") }.font(.system(size: 14,weight: .semibold)).foregroundStyle(Color(hex: "#183D49")).padding(18).background(Color(hex: "#EBD5A5"),in: RoundedRectangle(cornerRadius: 16)) }.buttonStyle(.plain)
            }.padding(26).frame(maxWidth: 540).frame(maxWidth: .infinity)
        }.background(Color(hex: "#103242").ignoresSafeArea()).foregroundStyle(Color(hex: "#FFF3DC")).preferredColorScheme(.dark)
            .presentationDetents([.large]).presentationDragIndicator(.visible)
    }
}
