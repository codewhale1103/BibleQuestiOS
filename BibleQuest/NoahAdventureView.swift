import SwiftUI
import Combine
import FirebaseAuth
import FirebaseDatabase

struct NoahAdventureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0
    @State private var furthest: CGFloat = 0
    @State private var isSailing = false
    @State private var isReverse = false
    @State private var destination = 0
    @State private var voyageTimer: AnyCancellable?
    @State private var anchorY: CGFloat = 240
    @State private var lastScrollY: CGFloat = -1000
    @State private var scrollY: CGFloat = 0
    @State private var loaded = false
    @State private var selectedChapter: NoahVoyageChapter?
    @State private var showRainbowGame = false
    @State private var rainbowFinished = false
    @State private var saveAlert = false
    @State private var savingRainbow = false
    @State private var showBuildGame = false
    @State private var buildFinished = false
    @State private var savingBuild = false
    @State private var buildSaveAlert = false
    @State private var showAnimalsGame = false
    @State private var animalsFinished = false
    @State private var savingAnimals = false
    @State private var animalsSaveAlert = false
    private var currentIndex: Int { NoahVoyageRoute(width: 390).index(at: progress) }
    private var storageKey: String { "NoahVoyageMap.\(Auth.auth().currentUser?.uid ?? "guest")" }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let wide = geo.size.width > geo.size.height*1.3
                let viewStart = max(0,-scrollY)
                let visibleStart = min(NoahVoyageRoute.height,max(0,viewStart-160))
                let visibleEnd = max(visibleStart,min(NoahVoyageRoute.height,viewStart+geo.size.height+260))
                let visible = visibleStart...visibleEnd
                ZStack {
                    Color(hex: "#0C4E62").ignoresSafeArea()
                    ScrollViewReader { proxy in
                        ScrollView(.vertical,showsIndicators: false) {
                            ZStack(alignment: .top) {
                                NoahQuestMap(progress: progress,furthest: furthest,sailing: isSailing,reverse: isReverse,compact: wide,visible: visible,active: scenePhase == .active && selectedChapter == nil && !showRainbowGame && !showBuildGame && !showAnimalsGame,onSelect: selectStop)
                                VStack(spacing: 0) {
                                    Spacer().frame(height: anchorY.clamped(to: 0...(NoahVoyageRoute.height-1)))
                                    Color.clear.frame(height: 1).id("ark-anchor")
                                    Spacer(minLength: 0)
                                }.frame(height: NoahVoyageRoute.height).allowsHitTesting(false)
                            }

                        }
                        .scrollDisabled(isSailing).ignoresSafeArea()
                        .onScrollGeometryChange(for: CGFloat.self) { geometry in geometry.contentOffset.y } action: { _,value in scrollY = -value }
                        .onAppear {
                            loadPosition()
                            moveAnchor(width: geo.size.width)
                            DispatchQueue.main.async { proxy.scrollTo("ark-anchor",anchor: .center) }
                        }
                        .onChange(of: progress) { _,_ in
                            moveAnchor(width: geo.size.width)
                            let y = anchorY
                            guard abs(y-lastScrollY) > (isSailing ? 0 : 12) else { return }
                            lastScrollY = y
                            var transaction = Transaction(); transaction.animation = !isSailing && !reduceMotion ? .easeOut(duration: 0.4) : nil
                            withTransaction(transaction) { proxy.scrollTo("ark-anchor",anchor: .center) }
                        }
                        .onChange(of: geo.size.width) { _,_ in
                            stopSailing(); moveAnchor(width: geo.size.width)
                            proxy.scrollTo("ark-anchor",anchor: .center)
                        }
                    }
                }
                .overlay(alignment: .top) {
                    NoahVoyageHeader(chapter: currentIndex,compact: wide,onBack: { stopSailing(); dismiss() }).frame(maxWidth: wide ? 310 : 530).frame(maxWidth: .infinity,alignment: wide ? .leading : .center).padding(.horizontal,16).padding(.top,8)
                }
                .overlay(alignment: .bottom) {
                    NoahVoyageDock(chapter: NoahVoyageChapter(rawValue: isSailing ? destination : currentIndex) ?? .call,sailing: isSailing,atEnd: progress >= 0.999,compact: wide,rainbowFinished: rainbowFinished,buildFinished: buildFinished,animalsFinished: animalsFinished,
                        onStart: { jump(to: 0) },onSail: toggleSailing,onLatest: { jump(to: furthest) },onDiscover: discover)
                        .frame(maxWidth: wide ? 330 : 480).frame(maxWidth: .infinity,alignment: wide ? .trailing : .center).padding(.horizontal,16).padding(.bottom,8)
                }
            }
            .toolbar(.hidden,for: .navigationBar,.tabBar).preferredColorScheme(.dark)
            .sheet(item: $selectedChapter) { chapter in NoahVoyageChapterSheet(chapter: chapter) }
            .fullScreenCover(isPresented: $showAnimalsGame) {
                ArkParadeGame(onComplete: {
                    animalsFinished = true
                    UserDefaults.standard.set(true,forKey: storageKey+".animalsComplete")
                    UserDefaults.standard.set(true,forKey: storageKey+".animalsPending")
                    saveAnimalsCompletion()
                },onExit: { showAnimalsGame = false })
            }
            .fullScreenCover(isPresented: $showBuildGame) {
                ArkWorkshopGame(onComplete: {
                    buildFinished = true
                    UserDefaults.standard.set(true,forKey: storageKey+".buildComplete")
                    UserDefaults.standard.set(true,forKey: storageKey+".buildPending")
                    saveBuildCompletion()
                },onExit: { showBuildGame = false })
            }
            .fullScreenCover(isPresented: $showRainbowGame) {
                RainbowPromiseGame(onComplete: {
                    rainbowFinished = true
                    UserDefaults.standard.set(true,forKey: storageKey+".rainbowComplete")
                    UserDefaults.standard.set(true,forKey: storageKey+".rainbowPending")
                    saveRainbowCompletion()
                },onExit: { showRainbowGame = false })
            }
            .onAppear(perform: loadRainbowCompletion)
            .onAppear(perform: loadBuildCompletion)
            .onAppear(perform: loadAnimalsCompletion)
            .alert("Every pair is safely aboard",isPresented: $animalsSaveAlert) {
                Button("Try saving again",action: saveAnimalsCompletion)
                Button("Later",role: .cancel) {}
            } message: { Text("Gather Animals is complete on this device. Your online progress could not be saved yet. You can retry without replaying.") }
            .alert("Your ark is complete",isPresented: $buildSaveAlert) {
                Button("Try saving again",action: saveBuildCompletion)
                Button("Later",role: .cancel) {}
            } message: { Text("Build the Ark is complete on this device. Your online progress could not be saved yet. You can retry without replaying.") }
            .alert("Your rainbow is complete",isPresented: $saveAlert) {
                Button("Try saving again",action: saveRainbowCompletion)
                Button("Later",role: .cancel) {}
            } message: { Text("Your progress could not be saved online yet. You can try again without replaying the game.") }
            .onDisappear { stopSailing() }
            .onChange(of: scenePhase) { _,value in if value != .active { stopSailing() } }
        }
    }
    private func loadPosition() {
        guard !loaded else { return }; loaded = true
        let saved = UserDefaults.standard.double(forKey: storageKey+".position")
        let latest = UserDefaults.standard.double(forKey: storageKey+".furthest")
        progress = saved.isFinite ? CGFloat(saved).clamped(to: 0...1) : 0
        furthest = max(progress,latest.isFinite ? CGFloat(latest).clamped(to: 0...1) : 0)
    }
    private func savePosition() {
        furthest = max(furthest,progress)
        UserDefaults.standard.set(Double(progress),forKey: storageKey+".position")
        UserDefaults.standard.set(Double(furthest),forKey: storageKey+".furthest")
    }
    private func moveAnchor(width: CGFloat) { anchorY = NoahVoyageRoute(width: width).point(progress).y-25 }
    private func selectStop(_ index: Int) {
        let target = NoahVoyageRoute.progress(for: index)
        if abs(progress-target) < 0.006 && !isSailing { discover() }
        else { sail(to: index) }
    }
    private func discover() {
        stopSailing()
        if currentIndex == NoahVoyageChapter.build.rawValue { showBuildGame = true }
        else if currentIndex == NoahVoyageChapter.animals.rawValue { showAnimalsGame = true }
        else if currentIndex == NoahVoyageChapter.promise.rawValue { showRainbowGame = true }
        else { selectedChapter = NoahVoyageChapter(rawValue: currentIndex) }
    }
    private func loadAnimalsCompletion() {
        animalsFinished = UserDefaults.standard.bool(forKey: storageKey+".animalsComplete")
        if animalsFinished && UserDefaults.standard.bool(forKey: storageKey+".animalsPending") { saveAnimalsCompletion() }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Database.database().reference().child("Users").child(uid).child("Adventures").child("Noah").child("GatherAnimals").observeSingleEvent(of: .value) { snapshot in
            if snapshot.value as? Bool == true { animalsFinished = true; UserDefaults.standard.set(true,forKey: storageKey+".animalsComplete") }
        }
    }
    private func saveAnimalsCompletion() {
        guard !savingAnimals,let uid = Auth.auth().currentUser?.uid else { return }
        savingAnimals = true
        let key = storageKey
        Database.database().reference().child("Users").child(uid).child("Adventures").child("Noah").child("GatherAnimals").setValue(true) { error,_ in
            DispatchQueue.main.async {
                savingAnimals = false
                if error != nil { animalsSaveAlert = true }
                else { UserDefaults.standard.set(false,forKey: key+".animalsPending") }
            }
        }
    }
    private func loadBuildCompletion() {
        // This workshop originally occupied God's Call; preserve an earned completion when moving it.
        let legacy = UserDefaults.standard.bool(forKey: storageKey+".callComplete")
        if legacy && !UserDefaults.standard.bool(forKey: storageKey+".buildComplete") {
            UserDefaults.standard.set(true,forKey: storageKey+".buildComplete")
            UserDefaults.standard.set(true,forKey: storageKey+".buildPending")
        }
        buildFinished = UserDefaults.standard.bool(forKey: storageKey+".buildComplete")
        if buildFinished && UserDefaults.standard.bool(forKey: storageKey+".buildPending") { saveBuildCompletion() }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Database.database().reference().child("Users").child(uid).child("Adventures").child("Noah").child("BuildTheArk").observeSingleEvent(of: .value) { snapshot in
            if snapshot.value as? Bool == true { buildFinished = true }
            else if !buildFinished {
                Database.database().reference().child("Users").child(uid).child("Adventures").child("Noah").child("GodsCall").observeSingleEvent(of: .value) { legacy in
                    if legacy.value as? Bool == true {
                        buildFinished = true
                        UserDefaults.standard.set(true,forKey: storageKey+".buildComplete")
                        UserDefaults.standard.set(true,forKey: storageKey+".buildPending")
                        saveBuildCompletion()
                    }
                }
            }
        }
    }
    private func saveBuildCompletion() {
        guard !savingBuild,let uid = Auth.auth().currentUser?.uid else { return }
        savingBuild = true
        let key = storageKey
        Database.database().reference().child("Users").child(uid).child("Adventures").child("Noah").child("BuildTheArk").setValue(true) { error,_ in
            DispatchQueue.main.async {
                savingBuild = false
                if error != nil { buildSaveAlert = true }
                else { UserDefaults.standard.set(false,forKey: key+".buildPending") }
            }
        }
    }
    private func loadRainbowCompletion() {
        rainbowFinished = UserDefaults.standard.bool(forKey: storageKey+".rainbowComplete")
        if rainbowFinished && UserDefaults.standard.bool(forKey: storageKey+".rainbowPending") { saveRainbowCompletion() }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Database.database().reference().child("Users").child(uid).child("Adventures").child("Noah").child("RainbowPromise").observeSingleEvent(of: .value) { snapshot in
            if snapshot.value as? Bool == true { rainbowFinished = true }
        }
    }
    private func saveRainbowCompletion() {
        guard !savingRainbow,let uid = Auth.auth().currentUser?.uid else { return }
        savingRainbow = true
        let key = storageKey
        let updates: [String: Any] = ["Users/\(uid)/Adventures/Noah/RainbowPromise": true,"Users/\(uid)/HeroAlbumUnlocked/Noah": true]
        Database.database().reference().updateChildValues(updates) { error,_ in
            DispatchQueue.main.async {
                savingRainbow = false
                if error != nil { saveAlert = true }
                else { UserDefaults.standard.set(false,forKey: key+".rainbowPending") }
            }
        }
    }
    private func toggleSailing() {
        if isSailing { stopSailing(); return }
        if progress >= 0.999 { discover(); return }
        sail(to: min(6,Int(floor(progress*6+0.001))+1))
    }
    private func sail(to index: Int) {
        stopSailing()
        let start = progress,target = NoahVoyageRoute.progress(for: index)
        guard abs(target-start) > 0.001 else { return }
        destination = index; isReverse = target < start
        if reduceMotion { progress = target; savePosition(); announceArrival(index); return }
        isSailing = true; lastScrollY = -1000
        let duration = max(0.4,abs(Double(target-start))*27)
        let began = ProcessInfo.processInfo.systemUptime
        voyageTimer = Timer.publish(every: 1.0/60,on: .main,in: .common).autoconnect().sink { _ in
            let elapsed = ProcessInfo.processInfo.systemUptime-began
            let t = min(1,max(0,elapsed/duration))
            // Gentle acceleration at departure and deceleration when entering the harbor.
            let smooth = t*t*(3-2*t)
            progress = start+CGFloat(smooth)*(target-start)
            if t >= 1 { progress = target; stopSailing(); announceArrival(index) }
        }
    }
    private func announceArrival(_ index: Int) {
        UISelectionFeedbackGenerator().selectionChanged()
        UIAccessibility.post(notification: .announcement,argument: "Arrived at \(NoahVoyageChapter(rawValue: index)?.title ?? "the harbor")")
    }
    private func stopSailing() { voyageTimer?.cancel(); voyageTimer = nil; isSailing = false; if loaded { savePosition() } }
    private func jump(to value: CGFloat) {
        stopSailing(); isReverse = false; lastScrollY = -1000; progress = value.clamped(to: 0...1); savePosition()
    }
}
#Preview { NoahAdventureView() }
