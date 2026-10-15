import SwiftUI
import Combine

struct ShepherdsFieldGame: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onComplete: (() -> Void)? = nil

    @StateObject private var audio = ShepherdFieldAudio()
    @State private var round = ShepherdRound()
    @State private var arrived: Set<Int> = []
    @State private var seconds = 0
    @State private var isPaused = false
    @State private var soundEnabled = true
    @State private var showWin = false
    @State private var isVisible = false
    @State private var completionDelivered = false
    @State private var clueID: Int?
    @State private var message = "Tap a lamb to guide it home. Peek behind rocks and bushes."
    @State private var roundID = UUID()
    @State private var flightTasks: [Int: Task<Void, Never>] = [:]
    @State private var clueTask: Task<Void, Never>?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            let layout = ShepherdFieldLayout(size: geometry.size)
            ZStack {
                ShepherdFieldBackdrop()

                field(layout: layout)
                    .allowsHitTesting(!isPaused && !showWin)
                    .accessibilityHidden(isPaused || showWin)

                ShepherdFieldAtmosphere()
            }
            .overlay(alignment: .top) {
                ShepherdFieldHUD(found: round.rescued.count, seconds: seconds,
                                 soundEnabled: soundEnabled,
                                 compact: layout.isLandscape,
                                 onBack: { dismiss() }, onSound: toggleSound,
                                 onPause: { isPaused = true })
                    .frame(width: layout.hudWidth)
                    .padding(.top, 8)
                    .padding(.leading, layout.isLandscape ? 12 : 0)
                    .frame(maxWidth: .infinity, alignment: layout.isLandscape ? .leading : .center)
                    .opacity(showWin ? 0 : 1)
                    .accessibilityHidden(isPaused || showWin)
            }
            .overlay(alignment: .bottom) {
                ShepherdFlockTray(arrived: arrived, message: message,
                                  hintAvailable: !round.isComplete, compact: layout.isLandscape,
                                  onHint: callFlock)
                    .frame(width: layout.trayWidth)
                    .padding(.bottom, 12)
                    .padding(.leading, layout.isLandscape ? 12 : 0)
                    .frame(maxWidth: .infinity, alignment: layout.isLandscape ? .leading : .center)
                    .opacity(showWin ? 0 : 1)
                    .accessibilityHidden(isPaused || showWin)
            }
            .overlay {
                if isPaused {
                    ShepherdPausePanel(onResume: { isPaused = false }, onRestart: resetGame,
                                       onBack: { dismiss() })
                        .transition(.opacity)
                }
                if showWin {
                    ShepherdVictoryPanel(seconds: seconds, onReplay: resetGame,
                                         onBack: { dismiss() })
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.94)))
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar, .tabBar)
        .onReceive(timer) { _ in
            guard isVisible, scenePhase == .active, !isPaused, !round.isComplete else { return }
            seconds += 1
        }
        .onAppear { isVisible = true }
        .onDisappear {
            isVisible = false
            cancelEffects()
            audio.stop()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { audio.stop() }
        }
        .animation(.easeInOut(duration: 0.2), value: isPaused)
    }

    private func field(layout: ShepherdFieldLayout) -> some View {
        ZStack {
            // Lambs have stable identities, so a discovered lamb travels into its own flock slot.
            ForEach(ShepherdLambSpot.flock) { lamb in
                if round.isVisible(lamb), !arrived.contains(lamb.id) {
                    let rescued = round.rescued.contains(lamb.id)
                    Button { collect(lamb.id) } label: {
                        ShepherdLambSprite(index: lamb.id, isMoving: rescued,
                                           highlighted: clueID == lamb.id)
                            .frame(width: 80 * layout.scale, height: 80 * layout.scale)
                            .contentShape(Circle())
                    }
                    .buttonStyle(ShepherdPressStyle())
                    .disabled(rescued)
                    .scaleEffect(rescued ? 0.44 : 1)
                    .opacity(rescued ? 0.05 : 1)
                    .position(rescued ? layout.flockPosition(lamb.id) : layout.position(lamb))
                    .animation(reduceMotion ? .easeOut(duration: 0.18) :
                        .spring(response: 0.8, dampingFraction: 0.84), value: rescued)
                    .accessibilityLabel("Bring lamb \(lamb.id + 1) home")
                }
            }

            ForEach(ShepherdLambSpot.flock.filter { $0.cover != nil }) { lamb in
                if let kind = lamb.cover {
                    let opened = round.revealed.contains(lamb.id)
                    ShepherdHidingPlace(kind: kind, opened: opened,
                                        highlighted: clueID == lamb.id && !opened,
                                        movesLeft: lamb.x < 0.5, scale: layout.scale) {
                        reveal(lamb.id)
                    }
                    .position(layout.position(lamb))
                    .accessibilityLabel("Search \(kind.name)")
                    .accessibilityHidden(opened)
                }
            }

            ForEach(ShepherdLambSpot.flock) { lamb in
                if round.rescued.contains(lamb.id), !arrived.contains(lamb.id) {
                    ShepherdDiscoveryBurst()
                        .position(layout.position(lamb))
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private func reveal(_ id: Int) {
        guard !isPaused, !showWin else { return }
        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.55, dampingFraction: 0.76)) {
            guard round.reveal(id) else { return }
            clueID = nil
            message = "There you are! Tap the little lamb to bring it home."
        }
        play(.rustle)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.6)
    }

    private func collect(_ id: Int) {
        guard !isPaused, !showWin, round.rescue(id) else { return }
        clueID = nil
        message = round.isComplete ? "Every little lamb is safe and sound." :
            "Safe and sound. \(7 - round.rescued.count) more to bring home."
        play(.found)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        let generation = roundID
        flightTasks[id] = Task { @MainActor in
            do { try await Task.sleep(for: .seconds(reduceMotion ? 0.2 : 0.85)) }
            catch { return }
            guard !Task.isCancelled, generation == roundID, isVisible else { return }
            withAnimation(.spring(response: 0.38, dampingFraction: 0.65)) { _ = arrived.insert(id) }
            flightTasks[id] = nil
            guard round.isComplete, arrived.count == 7, !completionDelivered else { return }
            completionDelivered = true
            onComplete?()
            do { try await Task.sleep(for: .seconds(0.45)) }
            catch { return }
            guard !Task.isCancelled, generation == roundID, isVisible else { return }
            play(.complete)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { showWin = true }
        }
    }

    private func callFlock() {
        guard !isPaused, !showWin, let lamb = round.nextClue else { return }
        clueTask?.cancel()
        clueID = lamb.id
        message = round.isVisible(lamb) ? "A little friend is waiting in the golden glow." :
            "Listen closely… try the glowing \(lamb.cover?.name ?? "hiding place")."
        play(.call)
        UISelectionFeedbackGenerator().selectionChanged()
        let generation = roundID
        clueTask = Task { @MainActor in
            do { try await Task.sleep(for: .seconds(4)) }
            catch { return }
            guard generation == roundID, clueID == lamb.id else { return }
            clueID = nil
            message = "Tap a lamb to guide it home. Peek behind rocks and bushes."
        }
    }

    private func toggleSound() {
        soundEnabled.toggle()
        if soundEnabled { play(.call) } else { audio.stop() }
    }

    private func play(_ sound: ShepherdFieldAudio.Cue) {
        guard soundEnabled, scenePhase == .active else { return }
        audio.play(sound)
    }

    private func cancelEffects() {
        flightTasks.values.forEach { $0.cancel() }
        flightTasks.removeAll()
        clueTask?.cancel()
    }

    private func resetGame() {
        cancelEffects()
        roundID = UUID()
        round = ShepherdRound()
        arrived = []
        seconds = 0
        clueID = nil
        completionDelivered = false
        message = "Tap a lamb to guide it home. Peek behind rocks and bushes."
        withAnimation(.easeOut(duration: 0.25)) {
            showWin = false
            isPaused = false
        }
    }
}

struct ShepherdFieldLayout {
    let size: CGSize
    var isLandscape: Bool { size.width > size.height }
    var hudWidth: CGFloat { isLandscape ? min(280, size.width * 0.34) : min(size.width - 44, 620) }
    var trayWidth: CGFloat { isLandscape ? hudWidth : min(size.width - 32, 500) }
    private var field: CGRect {
        if isLandscape {
            return CGRect(x: hudWidth + 32, y: 32,
                          width: size.width - hudWidth - 48, height: size.height - 64)
        }
        let width = min(size.width - 32, 660)
        return CGRect(x: (size.width - width) / 2, y: 172,
                      width: width, height: max(205, size.height - 350))
    }
    var scale: CGFloat { min(1.35, max(0.7, min(field.width / 358, field.height / 440))) }
    func position(_ lamb: ShepherdLambSpot) -> CGPoint {
        CGPoint(x: field.minX + field.width * lamb.x, y: field.minY + field.height * lamb.y)
    }
    func flockPosition(_ id: Int) -> CGPoint {
        let innerWidth = trayWidth - 36
        let left = isLandscape ? 30 : (size.width - innerWidth) / 2
        return CGPoint(x: left + innerWidth * (CGFloat(id) + 0.5) / 7,
                       y: size.height - 90)
    }
}

#Preview("Shepherd’s Field") {
    NavigationStack { ShepherdsFieldGame() }
}
