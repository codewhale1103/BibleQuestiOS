import SwiftUI

enum ArkWorkshopPalette {
    static let ink = Color(hex: "#163F40")
    static let cream = Color(hex: "#FFF2D6")
    static let gold = Color(hex: "#F0C77E")
    static let mint = Color(hex: "#B6D7BB")
    static let deckColors = [Color(hex: "#F0C77E"),Color(hex: "#A4D4C9"),Color(hex: "#C9B7DE")]
}
struct ArkPrimaryStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 16,weight: .bold,design: .rounded)).frame(maxWidth: .infinity,minHeight: 53).padding(.horizontal,18)
            .foregroundStyle(ArkWorkshopPalette.ink)
            .background(LinearGradient(colors: [ArkWorkshopPalette.cream,ArkWorkshopPalette.gold],startPoint: .topLeading,endPoint: .bottomTrailing),in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.5)))
            .shadow(color: .black.opacity(0.15),radius: 12,y: 5).scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
struct ArkIcon: View {
    let symbol: String
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) { Image(systemName: symbol).font(.system(size: 15,weight: .semibold)).frame(width: 46,height: 46).background(ArkWorkshopPalette.ink.opacity(0.9),in: Circle()).overlay(Circle().strokeBorder(ArkWorkshopPalette.cream.opacity(0.18))) }
            .buttonStyle(.plain).foregroundStyle(ArkWorkshopPalette.cream).accessibilityLabel(label)
    }
}
struct ArkHeader: View {
    @ObservedObject var controller: ArkWorkshopController
    let exit: () -> Void
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 9) {
                ArkIcon(symbol: "chevron.left",label: "Back to Noah’s voyage",action: exit)
                VStack(alignment: .leading,spacing: 3) {
                    Text("BUILD THE ARK").font(.system(size: 10,weight: .bold)).tracking(2)
                    Text("FIND · FIT · CREATE").font(.system(size: 6,weight: .bold)).tracking(1.3).foregroundStyle(ArkWorkshopPalette.gold)
                }.lineLimit(1).minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                ArkIcon(symbol: controller.soundOn ? "speaker.wave.2" : "speaker.slash",label: controller.soundOn ? "Turn sound off" : "Turn sound on",action: controller.toggleSound)
                ArkIcon(symbol: "pause.fill",label: "Pause Build the Ark",action: controller.pause)
            }
            HStack(spacing: 7) {
                ForEach(ArkWorkshopStep.allCases) { step in
                    HStack(spacing: 5) {
                        Image(systemName: step.rawValue < controller.round.discoveries ? "checkmark" : step.symbol)
                        Text(step.shortTitle).font(.system(size: 6,weight: .bold)).tracking(0.6).lineLimit(1).minimumScaleFactor(0.7)
                    }.font(.system(size: 9)).frame(maxWidth: .infinity,minHeight: 25)
                        .foregroundStyle(step.rawValue <= controller.round.step.rawValue ? ArkWorkshopPalette.cream : ArkWorkshopPalette.cream.opacity(0.5))
                        .background(ArkWorkshopPalette.ink.opacity(step.rawValue == controller.round.step.rawValue ? 0.95 : 0.75),in: Capsule())
                        .overlay(Capsule().strokeBorder(ArkWorkshopPalette.gold.opacity(step.rawValue == controller.round.step.rawValue ? 0.65 : 0.1)))
                }
            }.accessibilityElement(children: .ignore).accessibilityLabel("\(controller.round.discoveries) of 3 instructions remembered")
        }.foregroundStyle(ArkWorkshopPalette.cream)
    }
}
struct ArkMaterialArt: View {
    let index: Int
    var body: some View {
        if (0..<5).contains(index) {
            Canvas { context,size in
                let rect = CGRect(x: 2,y: 10,width: size.width-4,height: 22)
                let path = Path(roundedRect: rect,cornerRadius: 4)
                context.addFilter(.shadow(color: .black.opacity(0.35),radius: 3,x: 0,y: 3))
                context.fill(path,with: .linearGradient(Gradient(colors: [Color(hex: "#EDC790"),Color(hex: "#9A6139")]),startPoint: .zero,endPoint: CGPoint(x: 0,y: 35)))
                for line in 0..<6 {
                    var grain = Path(); let y = 13+CGFloat(line)*3
                    grain.move(to: CGPoint(x: 5,y: y)); grain.addCurve(to: CGPoint(x: size.width-5,y: y),control1: CGPoint(x: size.width*0.3,y: y+2),control2: CGPoint(x: size.width*0.6,y: y-2))
                    context.stroke(grain,with: .color(Color(hex: "#794622").opacity(0.45)),lineWidth: 0.6)
                }
                context.stroke(path,with: .color(Color(hex: "#F5D8A8").opacity(0.75)),lineWidth: 1)
            }.rotationEffect(.degrees(index == 0 ? -10 : index == 2 ? 7 : -4))
        } else if index == 1 {
            Ellipse().fill(LinearGradient(colors: [Color(hex: "#CBD1C6"),Color(hex: "#6C7D79")],startPoint: .topLeading,endPoint: .bottomTrailing)).frame(width: 33,height: 23).rotationEffect(.degrees(-9)).overlay(Ellipse().strokeBorder(.white.opacity(0.25)).frame(width: 27,height: 15).offset(x: -1,y: -2)).shadow(color: .black.opacity(0.3),radius: 3,y: 3)
        } else if index == 3 {
            Image(systemName: "leaf.fill").font(.system(size: 30,weight: .light)).foregroundStyle(LinearGradient(colors: [ArkWorkshopPalette.mint,Color(hex: "#597C58")],startPoint: .topLeading,endPoint: .bottomTrailing)).rotationEffect(.degrees(-12))
        } else {
            Canvas { context,size in
                var feather = Path(); feather.move(to: CGPoint(x: 11,y: 34)); feather.addQuadCurve(to: CGPoint(x: 30,y: 5),control: CGPoint(x: 3,y: 9)); feather.addQuadCurve(to: CGPoint(x: 11,y: 34),control: CGPoint(x: 40,y: 28))
                context.fill(feather,with: .linearGradient(Gradient(colors: [.white,ArkWorkshopPalette.cream.opacity(0.65)]),startPoint: CGPoint(x: 9,y: 10),endPoint: CGPoint(x: 30,y: 30)))
                var quill = Path(); quill.move(to: CGPoint(x: 7,y: 39)); quill.addQuadCurve(to: CGPoint(x: 29,y: 8),control: CGPoint(x: 17,y: 21)); context.stroke(quill,with: .color(Color(hex: "#A89973")),lineWidth: 1)
            }
        }
    }
}
