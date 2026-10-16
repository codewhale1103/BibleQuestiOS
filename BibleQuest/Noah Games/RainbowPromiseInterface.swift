import SwiftUI

struct PromisePrimaryStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 14,weight: .semibold)).frame(maxWidth: .infinity,minHeight: 51).padding(.horizontal,18)
            .foregroundStyle(PromisePalette.ink).background(LinearGradient(colors: [PromisePalette.cream,PromisePalette.gold],startPoint: .topLeading,endPoint: .bottomTrailing),in: RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(.white.opacity(0.4)))
            .shadow(color: .black.opacity(0.18),radius: 12,y: 6).scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
struct PromiseIcon: View {
    let symbol: String
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) { Image(systemName: symbol).font(.system(size: 12,weight: .semibold)).frame(width: 42,height: 44).background(PromisePalette.ink.opacity(0.70),in: Circle()).overlay(Circle().strokeBorder(.white.opacity(0.15))) }
            .buttonStyle(.plain).foregroundStyle(PromisePalette.cream).accessibilityLabel(label)
    }
}
struct PromiseIntro: View {
    @ObservedObject var controller: RainbowPromiseController
    let exit: () -> Void
    let info: () -> Void
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height*1.3
            ZStack(alignment: .bottomLeading) {
                RainbowPromiseBoard(controller: controller,preview: true).frame(width: geo.size.width*(wide ? 0.57 : 1),height: geo.size.height*(wide ? 0.9 : 0.52))
                    .position(x: geo.size.width*(wide ? 0.75 : 0.5),y: geo.size.height*(wide ? 0.49 : 0.26)).allowsHitTesting(false)
                Image("RainbowPromiseDove").resizable().scaledToFit().frame(width: wide ? 160 : 140)
                    .rotationEffect(.degrees(controller.reduceMotion ? 0 : sin(controller.visualTime*0.8)*3))
                    .position(x: geo.size.width*(wide ? 0.78 : 0.72),y: geo.size.height*(wide ? 0.46 : 0.25)).accessibilityHidden(true)
                LinearGradient(stops: [.init(color: .clear,location: 0),.init(color: PromisePalette.ink.opacity(0.86),location: 0.4),.init(color: PromisePalette.ink,location: 1)],startPoint: wide ? .trailing : .top,endPoint: wide ? .leading : .bottom).ignoresSafeArea().allowsHitTesting(false)
                VStack(alignment: .leading,spacing: wide ? 10 : 15) {
                    Text("NOAH’S ADVENTURE · THE PROMISE").font(.system(size: 8,weight: .bold)).tracking(2.4).foregroundStyle(PromisePalette.gold)
                    Text("Rainbow\nPromise.").font(.system(size: wide ? 46 : 52,design: .serif)).lineSpacing(-2).fixedSize(horizontal: false,vertical: true)
                    Text("Seven colors. One faithful promise.").font(.system(size: 16,design: .serif)).foregroundStyle(PromisePalette.gold)
                    Text("Choose each color. Weave its light across the sky. Discover the promise God made to Noah and every living creature.").font(.system(size: wide ? 12 : 14)).lineSpacing(3).foregroundStyle(PromisePalette.cream.opacity(0.77)).fixedSize(horizontal: false,vertical: true)
                    HStack(spacing: 24) { detail("7","COLORS TO WEAVE"); detail("3","STORY DISCOVERIES"); detail("1","PROMISE TO REMEMBER") }.padding(.vertical,4)
                    Button { controller.start() } label: { HStack { Text("Bring the sky to life"); Spacer(); Image(systemName: "sparkles") } }.buttonStyle(PromisePrimaryStyle())
                    Button("The story & rainbow science",action: info).font(.system(size: 11,weight: .medium)).foregroundStyle(PromisePalette.cream.opacity(0.65)).frame(maxWidth: .infinity,minHeight: 35)
                }.frame(maxWidth: wide ? 355 : 450,alignment: .leading).padding(.leading,wide ? 70 : 25).padding(.trailing,25).padding(.bottom,wide ? 5 : 10)
                VStack { HStack { PromiseIcon(symbol: "chevron.left",label: "Back to the voyage",action: exit); Spacer() }; Spacer() }.padding(.horizontal,18).padding(.top,5)
            }.foregroundStyle(PromisePalette.cream)
        }
    }
    private func detail(_ value: String,_ title: String) -> some View { VStack(alignment: .leading,spacing: 4) { Text(value).font(.system(size: 29,design: .serif)); Text(title).font(.system(size: 6,weight: .bold)).tracking(0.7).foregroundStyle(PromisePalette.cream.opacity(0.5)) } }
}
struct PromiseHeader: View {
    @ObservedObject var controller: RainbowPromiseController
    let exit: () -> Void
    var body: some View {
        VStack(spacing: 11) {
            HStack(spacing: 10) {
                PromiseIcon(symbol: "chevron.left",label: "Back to the voyage",action: exit)
                VStack(alignment: .leading,spacing: 3) {
                    Text("RAINBOW PROMISE").font(.system(size: 9,weight: .bold)).tracking(1.7)
                    Text("WEAVE THE LIGHT").font(.system(size: 7,weight: .medium)).tracking(1.7).foregroundStyle(PromisePalette.gold)
                }
                Spacer(minLength: 0)
                PromiseIcon(symbol: controller.soundOn ? "speaker.wave.2" : "speaker.slash",label: controller.soundOn ? "Mute sound" : "Enable sound",action: controller.toggleSound)
                PromiseIcon(symbol: "pause",label: "Pause rainbow",action: controller.pause)
            }
            HStack(spacing: 6) {
                ForEach(PromiseColor.allCases) { color in Capsule().fill(color.rawValue < controller.round.completedBands ? Color(hex: color.hex) : .white.opacity(0.20)).frame(height: 3) }
                Text("\(controller.round.completedBands)/7").font(.system(size: 9,weight: .semibold,design: .monospaced)).fixedSize().padding(.leading,8)
                Text(String(format: "%04d",controller.round.score)).font(.system(size: 11,weight: .medium,design: .monospaced)).fixedSize().foregroundStyle(PromisePalette.gold).padding(.leading,8).accessibilityLabel("Score \(controller.round.score)")
            }.accessibilityElement(children: .combine).accessibilityLabel("\(controller.round.completedBands) of 7 colors, score \(controller.round.score)")
        }.foregroundStyle(PromisePalette.cream)
    }
}
struct PromiseColorChoices: View {
    @ObservedObject var controller: RainbowPromiseController
    var body: some View {
        HStack(spacing: 10) {
            ForEach(controller.round.choices) { color in
                Button { controller.choose(color) } label: {
                    VStack(spacing: 9) {
                        Image(systemName: color.symbol).font(.system(size: 22,weight: .light)).foregroundStyle(Color(hex: color.hex)).shadow(color: Color(hex: color.hex).opacity(0.55),radius: 8)
                        Text(color.name).font(.system(size: 12,weight: .semibold)).foregroundStyle(PromisePalette.cream)
                    }.frame(maxWidth: .infinity,minHeight: 85)
                        .background(PromisePalette.ink.opacity(0.89),in: RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color(hex: color.hex).opacity(0.5),lineWidth: 1))
                        .opacity(controller.round.wrongColors.contains(color.rawValue) ? 0.42 : 1)
                }.buttonStyle(.plain).accessibilityLabel("Choose \(color.name)")
            }
        }
    }
}
struct PromiseDiscoveryPanel: View {
    @ObservedObject var controller: RainbowPromiseController
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height*1.3
            let lesson = controller.round.phase == .lesson
            let discovery = controller.round.question
            ZStack {
                PromisePalette.ink.opacity(0.94).ignoresSafeArea()
                ScrollView {
                    HStack(spacing: 25) {
                        if wide { Image("RainbowPromiseDove").resizable().scaledToFit().frame(width: 160).accessibilityHidden(true) }
                        VStack(alignment: .leading,spacing: wide ? 12 : 18) {
                            Text("STORY DISCOVERY · \(controller.round.discoveries+1) OF 3").font(.system(size: 8,weight: .bold)).tracking(2).foregroundStyle(PromisePalette.gold)
                            if lesson {
                                Image(systemName: "checkmark.seal").font(.system(size: 35,weight: .ultraLight)).foregroundStyle(PromisePalette.gold).accessibilityHidden(true)
                                Text(discovery.title).font(.system(size: wide ? 30 : 36,design: .serif)).fixedSize(horizontal: false,vertical: true)
                                Text(discovery.explanation).font(.system(size: wide ? 14 : 17)).lineSpacing(5).foregroundStyle(PromisePalette.cream.opacity(0.8))
                                Text(discovery.reference).font(.system(size: 8,weight: .bold)).tracking(1.6).foregroundStyle(PromisePalette.gold)
                                Button(controller.round.completedBands == 7 ? "Let the promise shine" : "Return to the light",action: controller.continueLesson).buttonStyle(PromisePrimaryStyle())
                            } else {
                                Text(discovery.question).font(.system(size: wide ? 29 : 34,design: .serif)).fixedSize(horizontal: false,vertical: true)
                                ForEach(discovery.choices.indices,id: \.self) { index in
                                    let wrong = controller.round.wrongAnswers.contains(index)
                                    Button { controller.answer(index) } label: {
                                        HStack(spacing: 14) {
                                            Text(String(format: "%02d",index+1)).font(.system(size: 10,weight: .medium,design: .monospaced)).foregroundStyle(PromisePalette.gold)
                                            Text(discovery.choices[index]).font(.system(size: wide ? 13 : 15,weight: .medium)).lineSpacing(3).multilineTextAlignment(.leading).frame(maxWidth: .infinity,alignment: .leading)
                                            Image(systemName: "arrow.up.right").font(.system(size: 12,weight: .light)).opacity(0.5)
                                        }.padding(16).frame(minHeight: wide ? 50 : 62)
                                            .background(.white.opacity(wrong ? 0.025 : 0.065),in: RoundedRectangle(cornerRadius: 16))
                                            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(PromisePalette.gold.opacity(wrong ? 0.30 : 0.14)))
                                    }.buttonStyle(.plain).disabled(wrong).opacity(wrong ? 0.6 : 1)
                                }
                                Text(controller.round.wrongAnswers.isEmpty ? "Take your time. The story holds the answer." : discovery.hint).font(.system(size: 12)).lineSpacing(3).foregroundStyle(PromisePalette.gold.opacity(0.8)).fixedSize(horizontal: false,vertical: true)
                                Text(discovery.reference).font(.system(size: 7,weight: .bold)).tracking(1.4).foregroundStyle(PromisePalette.cream.opacity(0.45))
                            }
                        }.frame(maxWidth: wide ? 455 : 420,alignment: .leading)
                    }.padding(wide ? 20 : 27).frame(maxWidth: .infinity)
                }.defaultScrollAnchor(.center,for: .alignment)
            }.foregroundStyle(PromisePalette.cream)
        }
    }
}
struct PromiseRoundPanel: View {
    @ObservedObject var controller: RainbowPromiseController
    let exit: () -> Void
    let info: () -> Void
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height*1.3,won = controller.round.phase == .won
            ZStack {
                PromisePalette.ink.opacity(0.94).ignoresSafeArea()
                ScrollView {
                    HStack(spacing: 25) {
                        if wide && won { Image("RainbowPromiseDove").resizable().scaledToFit().frame(width: 160).accessibilityHidden(true) }
                        VStack(alignment: .leading,spacing: wide ? 10 : 18) {
                            Text(won ? "A WORLD MADE NEW" : "A QUIET MOMENT IN THE VALLEY").font(.system(size: 8,weight: .bold)).tracking(2.4).foregroundStyle(PromisePalette.gold)
                            if won && !wide { RainbowPromiseBoard(controller: controller,preview: true).frame(height: 145).allowsHitTesting(false).accessibilityHidden(true) }
                            if won { HStack(spacing: 8) { ForEach(0..<3,id: \.self) { i in Image(systemName: i < controller.round.stars ? "star.fill" : "star").foregroundStyle(PromisePalette.gold) } }.accessibilityElement(children: .ignore).accessibilityLabel("\(controller.round.stars) stars earned") }
                            Text(won ? "Seven colors.\nOne promise." : "The light\ncan wait.").font(.system(size: wide ? 34 : 43,design: .serif)).fixedSize(horizontal: false,vertical: true)
                            if won {
                                HStack(spacing: 28) { stat("\(controller.round.score)","SCORE"); stat("7/7","COLORS"); stat("3/3","DISCOVERIES") }
                                Text("The rainbow is a sign of God’s covenant with the earth.").font(.system(size: wide ? 13 : 17,design: .serif)).lineSpacing(4).foregroundStyle(PromisePalette.cream.opacity(0.8))
                                Text("GENESIS 9:13–17 · BEST \(controller.bestScore)").font(.system(size: 7,weight: .bold)).tracking(1.1).foregroundStyle(PromisePalette.gold)
                                Button("Return to the voyage",action: exit).buttonStyle(PromisePrimaryStyle())
                                Button("Weave another rainbow",action: controller.start).font(.system(size: 12,weight: .semibold)).frame(maxWidth: .infinity,minHeight: 40)
                            } else {
                                Text("Your colors, stars and discoveries are saved for this round.").font(.system(size: 15)).lineSpacing(4).foregroundStyle(PromisePalette.cream.opacity(0.7))
                                Button("Keep weaving",action: controller.resume).buttonStyle(PromisePrimaryStyle())
                                HStack { Button("Start again",action: controller.start); Spacer(); Button("Back to the voyage",action: exit) }.font(.system(size: 12,weight: .semibold)).frame(minHeight: 44)
                                Button("The story & rainbow science",action: info).font(.system(size: 12)).foregroundStyle(PromisePalette.gold).frame(minHeight: 40)
                            }
                        }.frame(maxWidth: wide ? 440 : 420,alignment: .leading)
                    }.padding(wide ? 20 : 28).frame(maxWidth: .infinity)
                }.defaultScrollAnchor(.center,for: .alignment)
            }.foregroundStyle(PromisePalette.cream)
        }
    }
    private func stat(_ value: String,_ title: String) -> some View { VStack(alignment: .leading,spacing: 3) { Text(value).font(.system(size: 27,design: .serif)); Text(title).font(.system(size: 6,weight: .bold)).tracking(1).foregroundStyle(PromisePalette.cream.opacity(0.5)) } }
}
struct PromiseLearningSheet: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment: .leading,spacing: 22) {
                HStack { Text("A LITTLE WONDER").font(.system(size: 8,weight: .bold)).tracking(2.8).foregroundStyle(PromisePalette.gold); Spacer(); PromiseIcon(symbol: "xmark",label: "Close discoveries") { dismiss() } }
                Text("A promise.\nA world of color.").font(.system(size: 37,design: .serif))
                Text("The story").font(.system(size: 21,design: .serif)).foregroundStyle(PromisePalette.gold)
                Text("In Genesis 9, the rainbow is a sign of God’s covenant with the earth. A covenant is a solemn promise.").font(.system(size: 16)).lineSpacing(5)
                Link("Read Genesis 9:8–17",destination: URL(string: "https://www.biblegateway.com/passage/?search=Genesis+9%3A8-17&version=KJV")!).font(.system(size: 12,weight: .semibold)).foregroundStyle(PromisePalette.gold)
                HStack(spacing: 0) { ForEach(PromiseColor.allCases) { color in Rectangle().fill(Color(hex: color.hex)) } }.frame(height: 4).clipShape(Capsule())
                Text("The light").font(.system(size: 21,design: .serif)).foregroundStyle(PromisePalette.gold)
                Text("Sunlight contains many colors. Raindrops bend and reflect that light, spreading it into a rainbow. We use seven familiar color names to explore a continuous spectrum.").font(.system(size: 16)).lineSpacing(5)
                Text("Red is on the outer edge of a primary rainbow; violet is on the inner edge.").font(.system(size: 14)).lineSpacing(4).foregroundStyle(PromisePalette.cream.opacity(0.7))
                Link("Explore the science with NASA",destination: URL(string: "https://science.nasa.gov/image-article/apod-2010-august-7-rainbow-at-sunset/")!).font(.system(size: 12,weight: .semibold)).foregroundStyle(PromisePalette.gold)
                Button("Back to the wonder") { dismiss() }.buttonStyle(PromisePrimaryStyle())
            }.padding(27).frame(maxWidth: 530).frame(maxWidth: .infinity)
        }.foregroundStyle(PromisePalette.cream).background(PromisePalette.ink.ignoresSafeArea()).presentationDragIndicator(.visible).preferredColorScheme(.dark)
    }
}
