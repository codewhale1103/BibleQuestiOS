import SwiftUI

private enum WisdomGardenStyle {
    static let paper = Color(hex: "#FFF9F0")
    static let ink = Color(hex: "#493B52")
    static let muted = Color(hex: "#857A83")
    static let leaf = Color(hex: "#367B66")
}

private enum WisdomSeed: Int, CaseIterable, Identifiable {
    case guidance, trust, words, kindness, honesty, listening
    var id: Int { rawValue }
    var topic: String {
        switch self {
        case .guidance: "Guidance"
        case .trust: "Trust"
        case .words: "Words"
        case .kindness: "Kindness"
        case .honesty: "Honesty"
        case .listening: "Listening"
        }
    }
    var title: String {
        switch self {
        case .guidance: "Ask God for Wisdom"
        case .trust: "Trust the Lord"
        case .words: "Guard Your Words"
        case .kindness: "Choose Kindness"
        case .honesty: "Walk in Integrity"
        case .listening: "Listen and Learn"
        }
    }
    var verse: String {
        switch self {
        case .guidance: "If any of you lacks wisdom, let him ask of God."
        case .trust: "Trust in Yahweh with all your heart, and don't lean on your own understanding."
        case .words: "Whoever guards his mouth and his tongue keeps his soul from troubles."
        case .kindness: "A gentle answer turns away wrath, but a harsh word stirs up anger."
        case .honesty: "He who walks blamelessly walks surely."
        case .listening: "A wise man will hear, and will increase in learning."
        }
    }
    var reference: String {
        switch self {
        case .guidance: "James 1:5"
        case .trust: "Proverbs 3:5"
        case .words: "Proverbs 21:23"
        case .kindness: "Proverbs 15:1"
        case .honesty: "Proverbs 10:9"
        case .listening: "Proverbs 1:5"
        }
    }
    var symbol: String {
        switch self {
        case .guidance: "sun.max.fill"
        case .trust: "cloud.sun.fill"
        case .words: "bubble.left.and.bubble.right.fill"
        case .kindness: "heart.fill"
        case .honesty: "shield.fill"
        case .listening: "ear"
        }
    }
    var tint: Color {
        switch self {
        case .guidance: Color(hex: "#966B1F")
        case .trust: Color(hex: "#4779A0")
        case .words: Color(hex: "#8060A7")
        case .kindness: Color(hex: "#B55877")
        case .honesty: Color(hex: "#367B66")
        case .listening: Color(hex: "#AD6833")
        }
    }
    var pastel: Color {
        switch self {
        case .guidance: Color(hex: "#FFF0C5")
        case .trust: Color(hex: "#E1EEFB")
        case .words: Color(hex: "#EEE3F8")
        case .kindness: Color(hex: "#FBE1E9")
        case .honesty: Color(hex: "#DFF0E5")
        case .listening: Color(hex: "#FBE7D4")
        }
    }
    var smallStep: String {
        switch self {
        case .guidance: "Before one decision today, pause and ask God to help you choose what is good."
        case .trust: "Think of one thing that worries you. Tell God about it, then take one small step you can do."
        case .words: "Before you speak, ask: is it true, is it kind, and will it help? Try it in your next conversation."
        case .kindness: "If someone upsets you, take a breath and answer gently. You can be kind and still say how you feel."
        case .honesty: "Choose one moment to tell the truth, even if it feels a little hard. Ask for help if you need it."
        case .listening: "Let someone finish their story without interrupting. Ask one question to understand them better."
        }
    }
}

struct WisdomView: View {
    var isActive = true
    @StateObject private var speech = WisdomSpeech()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("BibleQuestSavedWisdomSeeds") private var savedSeedIDs = ""
    @AppStorage("BibleQuestWisdomPracticeDay") private var practiceDay = ""
    @AppStorage("BibleQuestWisdomPracticeSeeds") private var practisedSeedIDs = ""
    @State private var selectedSeed: WisdomSeed = .guidance
    @State private var reflectionExpanded = false
    @State private var showsSaved = false
    @State private var bloomCount = 0
    @Namespace private var topicAnimation

    private var savedSeeds: Set<Int> { seedIDs(from: savedSeedIDs) }
    private var practisedSeeds: Set<Int> { seedIDs(from: practisedSeedIDs) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heading
                topics
                VStack(spacing: 0) {
                    gardenIllustration
                    seedCard
                        .id(selectedSeed)
                        .transition(.opacity.combined(with: .offset(y: reduceMotion ? 0 : 8)))
                }
                .background(.white, in: RoundedRectangle(cornerRadius: 29))
                .clipShape(RoundedRectangle(cornerRadius: 29))
                .overlay(RoundedRectangle(cornerRadius: 29).stroke(.white, lineWidth: 1.5))
                .shadow(color: selectedSeed.tint.opacity(0.12), radius: 16, y: 8)
                dailyGarden
                playground
                Label("Wisdom grows when we live it.", systemImage: "leaf.fill")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(WisdomGardenStyle.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .frame(maxWidth: 660)
            .padding(.horizontal, 22)
            .padding(.top, 20)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(WisdomGardenStyle.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showsSaved) { savedSheet }
        .onAppear(perform: refreshPracticeDay)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshPracticeDay() } else { speech.stop() }
        }
        .onDisappear { speech.stop() }
        .onChange(of: isActive) { _, active in if !active { speech.stop() } }
        .onChange(of: showsSaved) { _, _ in speech.stop() }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in refreshPracticeDay() }
        .sensoryFeedback(.selection, trigger: selectedSeed)
        .sensoryFeedback(.success, trigger: bloomCount)
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(WisdomGardenStyle.leaf)
                    .rotationEffect(.degrees(-18))
                    .accessibilityHidden(true)
                Text("THE WISDOM GARDEN")
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .tracking(1.5)
                    .foregroundStyle(WisdomGardenStyle.leaf)
                Spacer(minLength: 8)
                Button { showsSaved = true } label: {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color(hex: "#936A36"))
                        .frame(width: 44, height: 44)
                        .background(Color(hex: "#F8E8CB"), in: RoundedRectangle(cornerRadius: 15))
                        .overlay(alignment: .topTrailing) {
                            if !savedSeeds.isEmpty {
                                Text("\(savedSeeds.count)")
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(width: 18, height: 18)
                                    .background(WisdomGardenStyle.leaf, in: Circle())
                                    .offset(x: 4, y: -4)
                            }
                        }
                }
                .buttonStyle(WisdomGardenPressStyle())
                .accessibilityLabel("Saved verses, \(savedSeeds.count) saved")
            }
            Text("Little truths.\nBrighter days.")
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .tracking(-0.7)
                .foregroundStyle(WisdomGardenStyle.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("A little wisdom. A little wonder. A lot of heart.")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(WisdomGardenStyle.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var topics: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What could you grow today?")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(WisdomGardenStyle.ink)
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(WisdomSeed.allCases) { seed in
                        Button { choose(seed) } label: {
                            HStack(spacing: 7) {
                                Image(systemName: seed.symbol)
                                Text(seed.topic)
                            }
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(selectedSeed == seed ? .white : seed.tint)
                            .padding(.horizontal, 14).padding(.vertical, 12)
                            .background {
                                if selectedSeed == seed {
                                    Capsule().fill(seed.tint).matchedGeometryEffect(id: "seed", in: topicAnimation)
                                } else { Capsule().fill(seed.pastel) }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(seed.topic) wisdom")
                        .accessibilityAddTraits(selectedSeed == seed ? [.isSelected] : [])
                    }
                }
                .padding(.vertical, 3)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var gardenIllustration: some View {
        GeometryReader { geometry in
            Image("WisdomGarden")
                .resizable().scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .overlay(alignment: .topLeading) {
                    Label("A SEED TO GROW", systemImage: "sparkles")
                        .font(.system(.caption2, design: .rounded, weight: .heavy))
                        .tracking(1)
                        .foregroundStyle(WisdomGardenStyle.ink)
                        .padding(.horizontal, 11).padding(.vertical, 8)
                        .background(.white.opacity(0.9), in: Capsule())
                        .padding(14)
                }
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 23, weight: .light))
                        .foregroundStyle(Color(hex: "#FFE8AF"))
                        .symbolEffect(.pulse, options: .repeating, isActive: !reduceMotion && scenePhase == .active)
                        .padding(18)
                }
        }
        .frame(height: 135)
        .accessibilityHidden(true)
    }

    private var seedCard: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: selectedSeed.symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(selectedSeed.tint)
                    .frame(width: 46, height: 46)
                    .background(selectedSeed.pastel, in: RoundedRectangle(cornerRadius: 16))
                    .rotationEffect(.degrees(-6))
                    .accessibilityHidden(true)
                Text(selectedSeed.title)
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(WisdomGardenStyle.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button { toggleSaved(selectedSeed) } label: {
                    Image(systemName: savedSeeds.contains(selectedSeed.id) ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(selectedSeed.tint)
                        .contentTransition(reduceMotion ? .identity : .symbolEffect(.replace))
                        .frame(width: 42, height: 44)
                }
                .buttonStyle(WisdomGardenPressStyle())
                .accessibilityLabel("\(savedSeeds.contains(selectedSeed.id) ? "Unsave" : "Save") \(selectedSeed.title)")
                .accessibilityAddTraits(savedSeeds.contains(selectedSeed.id) ? [.isSelected] : [])
            }
            HStack(alignment: .top, spacing: 10) {
                Text("“\(selectedSeed.verse)”")
                    .font(.system(.title3, design: .serif, weight: .medium))
                    .lineSpacing(5)
                    .foregroundStyle(WisdomGardenStyle.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                speakerButton(for: selectedSeed)
            }
            Text(selectedSeed.reference)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(selectedSeed.tint)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(selectedSeed.pastel.opacity(0.85), in: Capsule())

            Button {
                if reflectionExpanded && speech.activeID == "practice-\(selectedSeed.id)" { speech.stop() }
                withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.82)) {
                    reflectionExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "leaf")
                    Text("Put it into practice")
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(reflectionExpanded ? 180 : 0))
                }
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(selectedSeed.tint)
                .padding(.vertical, 12)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(reflectionExpanded ? "Expanded" : "Collapsed")

            if reflectionExpanded {
                VStack(alignment: .leading, spacing: 15) {
                    Text("ONE LITTLE STEP")
                        .font(.system(.caption2, design: .rounded, weight: .heavy))
                        .tracking(1.2)
                        .foregroundStyle(selectedSeed.tint)
                    HStack(alignment: .top, spacing: 10) {
                        Text(selectedSeed.smallStep)
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .lineSpacing(4)
                            .foregroundStyle(WisdomGardenStyle.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        speakerButton(for: selectedSeed, practice: true)
                    }
                    Button(action: togglePractice) {
                        HStack(spacing: 9) {
                            Image(systemName: practisedSeeds.contains(selectedSeed.id) ? "checkmark.circle.fill" : "circle")
                            Text(practisedSeeds.contains(selectedSeed.id) ? "Practised today" : "I tried this today")
                        }
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(practisedSeeds.contains(selectedSeed.id) ? .white : selectedSeed.tint)
                        .padding(.horizontal, 17).padding(.vertical, 13)
                        .frame(maxWidth: .infinity)
                        .background(practisedSeeds.contains(selectedSeed.id) ? selectedSeed.tint : .white, in: Capsule())
                        .overlay(Capsule().stroke(selectedSeed.tint.opacity(0.2), lineWidth: 1))
                        .overlay {
                            if !reduceMotion { WisdomLeafBurst(trigger: bloomCount, tint: selectedSeed.tint) }
                        }
                    }
                    .buttonStyle(WisdomGardenPressStyle())
                    .accessibilityAddTraits(practisedSeeds.contains(selectedSeed.id) ? [.isSelected] : [])
                    .accessibilityHint(practisedSeeds.contains(selectedSeed.id) ? "Tap again to undo today's practice" : "Mark this small step as tried today")
                }
                .padding(16)
                .background(selectedSeed.pastel.opacity(0.68), in: RoundedRectangle(cornerRadius: 19))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(21)
        .background(LinearGradient(colors: [selectedSeed.pastel.opacity(0.5), .white], startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private var dailyGarden: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("Your little steps")
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(WisdomGardenStyle.ink)
                Spacer(minLength: 0)
                Text(practisedSeeds.isEmpty ? "A fresh start" : "\(practisedSeeds.count) today")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(WisdomGardenStyle.leaf)
                    .contentTransition(reduceMotion ? .identity : .numericText())
            }
            HStack(spacing: 0) {
                ForEach(WisdomSeed.allCases) { seed in
                    Image(systemName: practisedSeeds.contains(seed.id) ? "leaf.fill" : "leaf")
                        .font(.system(size: 23, weight: .medium))
                        .foregroundStyle(practisedSeeds.contains(seed.id) ? seed.tint : Color(hex: "#C9D5C6"))
                        .frame(maxWidth: .infinity)
                        .rotationEffect(.degrees(practisedSeeds.contains(seed.id) ? -12 : 0))
                        .accessibilityHidden(true)
                }
            }
            Text(practisedSeeds.isEmpty ? "Try a little step from any verse. Good things take practice." : "One small choice at a time. That’s how good things grow.")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(WisdomGardenStyle.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(Color(hex: "#EFF4E9"), in: RoundedRectangle(cornerRadius: 23))
        .accessibilityElement(children: .combine)
    }

    private var playground: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .firstTextBaseline) {
                Text("The wisdom playground")
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(WisdomGardenStyle.ink)
                Spacer(minLength: 0)
                Image(systemName: "sparkles")
                    .foregroundStyle(Color(hex: "#C99444"))
                    .accessibilityHidden(true)
            }
            Text("Give your curiosity a little room to play.")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(WisdomGardenStyle.muted)
            NavigationLink { AlphabetWisdomGameView() } label: {
                WisdomPlayTile(title: "Alphabet of Faith", subtitle: "Little letters. Big Bible discoveries.", symbol: "textformat.abc", tint: Color(hex: "#3977A1"), pastel: Color(hex: "#E1EDF9"))
            }
            .buttonStyle(WisdomGardenPressStyle())
            NavigationLink { NumbersWisdomGameView() } label: {
                WisdomPlayTile(title: "Bible Numbers", subtitle: "Count your way through the stories.", symbol: "number", tint: Color(hex: "#B36937"), pastel: Color(hex: "#FBE8D5"))
            }
            .buttonStyle(WisdomGardenPressStyle())
            NavigationLink { WordBuilderWisdomGameView() } label: {
                WisdomPlayTile(title: "Word Builder", subtitle: "A little jumble. A lovely discovery.", symbol: "puzzlepiece.extension.fill", tint: Color(hex: "#8060A7"), pastel: Color(hex: "#EEE3F8"))
            }
            .buttonStyle(WisdomGardenPressStyle())
        }
    }

    private var savedSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Little lights to keep.")
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .foregroundStyle(WisdomGardenStyle.ink)
                    if savedSeeds.isEmpty {
                        VStack(spacing: 15) {
                            Image(systemName: "bookmark")
                                .font(.system(size: 36, weight: .light))
                                .foregroundStyle(WisdomGardenStyle.leaf)
                                .padding(22).background(Color(hex: "#E7F0E3"), in: Circle())
                            Text("Keep a little light")
                                .font(.system(.title3, design: .rounded, weight: .heavy))
                                .foregroundStyle(WisdomGardenStyle.ink)
                            Text("Tap the bookmark on a verse to find it here whenever you need it.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(WisdomGardenStyle.muted)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 25)
                    } else {
                        ForEach(WisdomSeed.allCases.filter { savedSeeds.contains($0.id) }) { seed in
                            HStack(alignment: .top, spacing: 0) {
                                Button { choose(seed); showsSaved = false } label: {
                                    VStack(alignment: .leading, spacing: 9) {
                                        Label(seed.title, systemImage: seed.symbol)
                                            .font(.system(.headline, design: .rounded))
                                            .foregroundStyle(seed.tint)
                                        Text("“\(seed.verse)”")
                                            .font(.system(.body, design: .serif))
                                            .foregroundStyle(WisdomGardenStyle.ink)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Text(seed.reference)
                                            .font(.system(.caption, design: .rounded, weight: .bold))
                                            .foregroundStyle(seed.tint)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Open this verse in the garden")
                                VStack(spacing: 4) {
                                    speakerButton(for: seed)
                                    Button { toggleSaved(seed) } label: {
                                        Image(systemName: "bookmark.fill")
                                            .foregroundStyle(seed.tint)
                                            .frame(width: 44, height: 44)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Unsave \(seed.title)")
                                }
                                .padding(.top, 7)
                                .padding(.trailing, 7)
                            }
                            .background(seed.pastel, in: RoundedRectangle(cornerRadius: 20))
                        }
                    }
                }
                .padding(22)
            }
            .background(WisdomGardenStyle.paper)
            .navigationTitle("Saved verses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showsSaved = false } } }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func speakerButton(for seed: WisdomSeed, practice: Bool = false) -> some View {
        let id = "\(practice ? "practice" : "verse")-\(seed.id)"
        let speaking = speech.activeID == id
        let reference = seed.reference.replacingOccurrences(of: ":", with: ", verse ")
        let text = practice ? seed.smallStep : "\(seed.title). \(seed.verse) \(reference)."
        return Button { speech.toggle(id: id, text: text) } label: {
            Image(systemName: speaking ? "stop.fill" : "speaker.wave.2.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(speaking ? .white : seed.tint)
                .frame(width: 44, height: 44)
                .background(speaking ? seed.tint : seed.pastel, in: Circle())
        }
        .buttonStyle(WisdomGardenPressStyle())
        .accessibilityLabel("\(speaking ? "Stop reading" : practice ? "Read practical step" : "Read verse"): \(seed.title)")
        .accessibilityHint(speaking ? "Stops the spoken reading" : "Reads aloud in a gentle voice")
        .accessibilityAddTraits(speaking ? [.isSelected] : [])
    }

    private func seedIDs(from value: String) -> Set<Int> {
        Set(value.split(separator: ",").compactMap { Int($0) }.filter { WisdomSeed(rawValue: $0) != nil })
    }
    private func choose(_ seed: WisdomSeed) {
        speech.stop()
        withAnimation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.85)) {
            selectedSeed = seed
            reflectionExpanded = false
        }
    }
    private func toggleSaved(_ seed: WisdomSeed) {
        var ids = savedSeeds
        if ids.contains(seed.id) {
            ids.remove(seed.id)
            if speech.activeID == "verse-\(seed.id)" { speech.stop() }
        } else { ids.insert(seed.id) }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
            savedSeedIDs = ids.sorted().map(String.init).joined(separator: ",")
        }
    }
    private func togglePractice() {
        refreshPracticeDay()
        var ids = practisedSeeds
        let adding = !ids.contains(selectedSeed.id)
        if adding { ids.insert(selectedSeed.id) } else { ids.remove(selectedSeed.id) }
        withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.75)) {
            practisedSeedIDs = ids.sorted().map(String.init).joined(separator: ",")
        }
        if adding { bloomCount += 1 }
    }
    private func refreshPracticeDay() {
        let date = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let key = "\(date.year ?? 0)-\(date.month ?? 0)-\(date.day ?? 0)"
        if practiceDay != key {
            practisedSeedIDs = ""
            practiceDay = key
        }
    }
}

private struct WisdomPlayTile: View {
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color
    let pastel: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(tint.opacity(0.13))
                    .frame(width: 50, height: 52).rotationEffect(.degrees(9))
                RoundedRectangle(cornerRadius: 15).fill(.white.opacity(0.85))
                    .frame(width: 50, height: 52).rotationEffect(.degrees(-7))
                Image(systemName: symbol)
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(tint)
            }
            .frame(width: 55, height: 60)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(WisdomGardenStyle.ink)
                Text(subtitle)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(tint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "play.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 33, height: 33)
                .background(.white.opacity(0.75), in: Circle())
                .accessibilityHidden(true)
        }
        .padding(17)
        .background(pastel, in: RoundedRectangle(cornerRadius: 23))
        .overlay(RoundedRectangle(cornerRadius: 23).stroke(.white, lineWidth: 1.5))
        .accessibilityElement(children: .combine)
    }
}

private struct WisdomGardenPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.87 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

private struct WisdomLeafBurst: View {
    let trigger: Int
    let tint: Color
    private struct BloomValues {
        var progress = 0.0
        var opacity = 0.0
    }
    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .keyframeAnimator(initialValue: BloomValues(), trigger: trigger) { _, value in
                ZStack {
                    ForEach(0..<12) { index in
                        let angle = Double(index) / 12 * Double.pi * 2
                        let reach = 65.0 + Double(index % 3) * 13
                        Image(systemName: index.isMultiple(of: 3) ? "sparkle" : "leaf.fill")
                            .font(.system(size: index.isMultiple(of: 3) ? 13 : 11, weight: .medium))
                            .foregroundStyle(index.isMultiple(of: 3) ? Color(hex: "#D7AA41") : tint)
                            .rotationEffect(.degrees(Double(index) * 37 + value.progress * 110))
                            .scaleEffect(1 - value.progress * 0.45)
                            .offset(x: cos(angle) * reach * value.progress,
                                    y: sin(angle) * reach * value.progress - value.progress * 20)
                            .opacity(value.opacity)
                    }
                }
            } keyframes: { _ in
                KeyframeTrack(\.progress) {
                    MoveKeyframe(0)
                    CubicKeyframe(1, duration: 0.85)
                }
                KeyframeTrack(\.opacity) {
                    MoveKeyframe(1)
                    LinearKeyframe(1, duration: 0.2)
                    LinearKeyframe(0, duration: 0.65)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct AlphabetWisdomGameView: View {
    var body: some View {
        BibleQuizGameView(
            title: "Alphabet of Faith",
            icon: "🔤",
            subtitle: "Pick the Bible word that starts with the shown letter.",
            questions: [
                .init(prompt: "Which word starts with A?", options: ["Ark", "Boat", "Stone"], correctAnswer: "Ark", explanation: "Noah built an ark."),
                .init(prompt: "Which word starts with B?", options: ["Bible", "Crown", "River"], correctAnswer: "Bible", explanation: "The Bible is God's Word."),
                .init(prompt: "Which word starts with C?", options: ["Faith", "Cross", "Lion"], correctAnswer: "Cross", explanation: "Jesus died on the cross."),
                .init(prompt: "Which word starts with D?", options: ["David", "Eden", "Moses"], correctAnswer: "David", explanation: "David trusted God against Goliath."),
                .init(prompt: "Which word starts with E?", options: ["Temple", "Eden", "Jonah"], correctAnswer: "Eden", explanation: "God planted the Garden of Eden."),
                .init(prompt: "Which word starts with F?", options: ["Faith", "Grace", "Angel"], correctAnswer: "Faith", explanation: "Faith means trusting God."),
                .init(prompt: "Which word starts with G?", options: ["Goliath", "Prophet", "Prayer"], correctAnswer: "Goliath", explanation: "Goliath was the giant David faced."),
                .init(prompt: "Which word starts with H?", options: ["Hope", "Story", "Stone"], correctAnswer: "Hope", explanation: "Our hope is in the Lord.")
            ]
        )
    }
}

private struct NumbersWisdomGameView: View {
    var body: some View {
        BibleQuizGameView(
            title: "Bible Numbers",
            icon: "🔢",
            subtitle: "Choose the right number from Bible stories.",
            questions: [
                .init(prompt: "How many days and nights did rain fall in Noah's flood?", options: ["7", "40", "100"], correctAnswer: "40", explanation: "Genesis says rain fell for 40 days and nights."),
                .init(prompt: "How many stones did David pick up before facing Goliath?", options: ["2", "5", "10"], correctAnswer: "5", explanation: "David took five smooth stones."),
                .init(prompt: "How many disciples did Jesus choose?", options: ["12", "7", "3"], correctAnswer: "12", explanation: "Jesus called 12 disciples."),
                .init(prompt: "How many days was Jonah in the big fish?", options: ["3", "12", "30"], correctAnswer: "3", explanation: "Jonah was inside three days and nights."),
                .init(prompt: "On which day did God rest after creation?", options: ["6th", "7th", "8th"], correctAnswer: "7th", explanation: "God rested on the seventh day."),
                .init(prompt: "How many loaves were used when Jesus fed the crowd in one miracle?", options: ["5", "12", "2"], correctAnswer: "5", explanation: "A boy brought five loaves and two fish."),
                .init(prompt: "How many fish did the boy bring in that same miracle?", options: ["2", "5", "7"], correctAnswer: "2", explanation: "The meal was five loaves and two fish."),
                .init(prompt: "How many commandments did God give Moses?", options: ["5", "8", "10"], correctAnswer: "10", explanation: "God gave the Ten Commandments.")
            ]
        )
    }
}

private struct WordBuilderWisdomGameView: View {
    var body: some View {
        BibleQuizGameView(
            title: "Word Builder",
            icon: "🧩",
            subtitle: "Unscramble each Bible word.",
            questions: [
                .init(prompt: "Unscramble: KRA", options: ["Ark", "Jar", "Car"], correctAnswer: "Ark", explanation: "Noah built the ark."),
                .init(prompt: "Unscramble: VLOE", options: ["Vole", "Love", "Lave"], correctAnswer: "Love", explanation: "God is love."),
                .init(prompt: "Unscramble: ASHFIT", options: ["Faiths", "Fiasth", "Faith"], correctAnswer: "Faith", explanation: "Faith trusts God's promises."),
                .init(prompt: "Unscramble: RPEAYR", options: ["Prayer", "Parery", "Ryrpea"], correctAnswer: "Prayer", explanation: "Prayer is talking with God."),
                .init(prompt: "Unscramble: SGNO", options: ["Nogs", "Song", "Snog"], correctAnswer: "Song", explanation: "Many Psalms are songs to God."),
                .init(prompt: "Unscramble: CEGAR", options: ["Grace", "Cager", "Ragec"], correctAnswer: "Grace", explanation: "Grace is God's undeserved kindness."),
                .init(prompt: "Unscramble: EPSHO", options: ["Spore", "Hope", "Shoep"], correctAnswer: "Hope", explanation: "Hope looks to God."),
                .init(prompt: "Unscramble: RYCEM", options: ["Mercy", "Cream", "Mecyr"], correctAnswer: "Mercy", explanation: "God is rich in mercy.")
            ]
        )
    }
}

private struct BibleQuizGameView: View {
    let title: String
    let icon: String
    let subtitle: String
    let questions: [BibleQuizQuestion]

    @State private var currentIndex: Int = 0
    @State private var score: Int = 0
    @State private var selectedAnswer: String?

    private var currentQuestion: BibleQuizQuestion {
        questions[currentIndex]
    }

    private var isLastQuestion: Bool {
        currentIndex == questions.count - 1
    }

    private var hasFinished: Bool {
        currentIndex >= questions.count
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.bqBackgroundTop, Color.bqBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(icon) \(title)")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.bqTitle)
                        Text(subtitle)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Color.bqSubtitle)
                    }
                    .padding(.top, 16)

                    if hasFinished {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Great Job!")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color.bqTitle)
                            Text("Your score: \(score) / \(questions.count)")
                                .font(.system(.title3, design: .rounded))
                                .foregroundStyle(Color.bqBody)

                            Button {
                                currentIndex = 0
                                score = 0
                                selectedAnswer = nil
                            } label: {
                                Text("Play Again")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, minHeight: 52)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(Color(hex: "#2C7CF6"))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color.white.opacity(0.94))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.9), lineWidth: 1.5)
                        )
                    } else {
                        Text("Question \(currentIndex + 1) of \(questions.count)")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Color.bqSubtitle)

                        VStack(alignment: .leading, spacing: 12) {
                            Text(currentQuestion.prompt)
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color.bqTitle)

                            ForEach(currentQuestion.options, id: \.self) { option in
                                Button {
                                    handleSelect(option)
                                } label: {
                                    HStack {
                                        Text(option)
                                            .font(.system(.headline, design: .rounded))
                                            .foregroundStyle(buttonTextColor(option))
                                        Spacer()
                                        if let selectedAnswer {
                                            if option == currentQuestion.correctAnswer {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(Color(hex: "#22A060"))
                                            } else if option == selectedAnswer {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(Color.red.opacity(0.85))
                                            }
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(buttonBackgroundColor(option))
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(selectedAnswer != nil)
                            }

                            if selectedAnswer != nil {
                                Text(currentQuestion.explanation)
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(Color.bqBody)
                                    .padding(.top, 2)

                                Button {
                                    nextQuestion()
                                } label: {
                                    Text(isLastQuestion ? "See Score" : "Next Question")
                                        .font(.system(.headline, design: .rounded))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity, minHeight: 50)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(Color(hex: "#2C7CF6"))
                                        )
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 4)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color.white.opacity(0.94))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.9), lineWidth: 1.5)
                        )
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func handleSelect(_ option: String) {
        guard selectedAnswer == nil else { return }
        selectedAnswer = option
        if option == currentQuestion.correctAnswer {
            score += 1
        }
    }

    private func nextQuestion() {
        if isLastQuestion {
            currentIndex = questions.count
            selectedAnswer = nil
            return
        }
        currentIndex += 1
        selectedAnswer = nil
    }

    private func buttonBackgroundColor(_ option: String) -> Color {
        guard let selectedAnswer else { return Color(hex: "#EEF5FF") }
        if option == currentQuestion.correctAnswer {
            return Color(hex: "#DFF5E8")
        }
        if option == selectedAnswer {
            return Color(hex: "#FFE5E5")
        }
        return Color(hex: "#EEF5FF")
    }

    private func buttonTextColor(_ option: String) -> Color {
        guard let selectedAnswer else { return Color.bqTitle }
        if option == currentQuestion.correctAnswer {
            return Color(hex: "#1A7A47")
        }
        if option == selectedAnswer {
            return Color(hex: "#B42318")
        }
        return Color.bqTitle
    }
}

private struct BibleQuizQuestion: Hashable {
    let prompt: String
    let options: [String]
    let correctAnswer: String
    let explanation: String
}


#Preview {
    NavigationStack { WisdomView() }
}
