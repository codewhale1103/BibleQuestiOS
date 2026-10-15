import SwiftUI

private enum FieldPalette {
    static let cream = Color(hex: "#FFF5D9")
    static let gold = Color(hex: "#EAC77F")
    static let forest = Color(hex: "#16392C")
}

struct ShepherdFieldHUD: View {
    let found: Int
    let seconds: Int
    let soundEnabled: Bool
    var compact = false
    let onBack: () -> Void
    let onSound: () -> Void
    let onPause: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 9 : 14) {
            HStack(spacing: 10) {
                FieldIconButton(icon: "arrow.left", label: "Back to adventure", action: onBack)
                Text(compact ? "DAVID" : "A DAVID ADVENTURE")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(FieldPalette.cream.opacity(0.75))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                FieldIconButton(icon: soundEnabled ? "speaker.wave.2" : "speaker.slash",
                                label: soundEnabled ? "Mute sound" : "Enable sound", action: onSound)
                FieldIconButton(icon: "pause", label: "Pause game", action: onPause)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Shepherd’s Field")
                    .font(.system(size: compact ? 26 : 34, weight: .semibold, design: .serif))
                    .foregroundStyle(FieldPalette.cream)
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.16), radius: 6, y: 2)
                if !compact {
                    Text("Find the little flock. Bring every lamb home.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(FieldPalette.cream.opacity(0.8))
                }
            }

            HStack(spacing: 8) {
                Image("ShepherdLamb")
                    .resizable().scaledToFit().frame(width: 28, height: 25)
                    .accessibilityHidden(true)
                Text("\(found)")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .foregroundStyle(FieldPalette.gold)
                Text("/ 7 home")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(FieldPalette.cream.opacity(0.8))
                Spacer()
                Image(systemName: "clock")
                    .font(.system(size: 11, weight: .medium))
                Text(String(format: "%d:%02d", seconds / 60, seconds % 60))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .monospacedDigit()
            }
            .foregroundStyle(FieldPalette.cream.opacity(0.72))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(found) of 7 lambs home. \(seconds) seconds elapsed")
        }
        .frame(maxWidth: 620)
    }
}

struct ShepherdFlockTray: View {
    let arrived: Set<Int>
    let message: String
    let hintAvailable: Bool
    var compact = false
    let onHint: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("SAFE IN THE FOLD")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(compact ? 1.2 : 2.1)
                    .foregroundStyle(FieldPalette.cream.opacity(0.65))
                Spacer()
                Image(systemName: "leaf")
                    .font(.system(size: 12))
                    .foregroundStyle(FieldPalette.gold)
            }
            HStack(spacing: 0) {
                ForEach(0..<7) { index in
                    ZStack {
                        Circle()
                            .fill(arrived.contains(index) ? FieldPalette.gold.opacity(0.13) : .white.opacity(0.04))
                            .overlay(Circle().stroke(FieldPalette.cream.opacity(0.12), lineWidth: 1))
                            .frame(width: compact ? 26 : 35, height: compact ? 26 : 35)
                        Image("ShepherdLamb")
                            .resizable().scaledToFit()
                            .frame(width: compact ? 31 : 39, height: compact ? 31 : 39)
                            .saturation(arrived.contains(index) ? 1 : 0)
                            .opacity(arrived.contains(index) ? 1 : 0.16)
                            .scaleEffect(arrived.contains(index) ? 1 : 0.78)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Lamb \(index + 1), \(arrived.contains(index) ? "safely home" : "still in the field")")
                }
            }
            Rectangle().fill(FieldPalette.cream.opacity(0.12)).frame(height: 1)
            HStack(alignment: .center, spacing: 12) {
                Text(message)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(FieldPalette.cream.opacity(0.82))
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.updatesFrequently)
                Button(action: onHint) {
                    HStack(spacing: 5) {
                        Image(systemName: "waveform")
                        Text("Call flock")
                    }
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(FieldPalette.gold)
                    .padding(.horizontal, 10)
                    .frame(minHeight: 44)
                    .background(FieldPalette.gold.opacity(0.09), in: Capsule())
                }
                .buttonStyle(ShepherdPressStyle())
                .disabled(!hintAvailable)
                .opacity(hintAvailable ? 1 : 0.4)
                .accessibilityHint("Gently highlights a lamb or its hiding place")
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(FieldPalette.forest.opacity(0.94))
                .overlay {
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .stroke(FieldPalette.cream.opacity(0.19), lineWidth: 1)
                }
        }
        .shadow(color: .black.opacity(0.15), radius: 18, y: 8)
    }
}

private struct FieldIconButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(FieldPalette.cream)
                .frame(width: 42, height: 42)
                .background(FieldPalette.forest.opacity(0.5), in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.17), lineWidth: 1))
        }
        .buttonStyle(ShepherdPressStyle())
        .accessibilityLabel(label)
    }
}

struct ShepherdPausePanel: View {
    let onResume: () -> Void
    let onRestart: () -> Void
    let onBack: () -> Void
    var body: some View {
        ZStack {
            Color(hex: "#0B241B").opacity(0.8).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "leaf")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(FieldPalette.gold)
                Text("A quiet moment")
                    .font(.system(size: 33, weight: .medium, design: .serif))
                    .foregroundStyle(FieldPalette.cream)
                Text("Your little flock will be right here.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(FieldPalette.cream.opacity(0.72))
                FieldPrimaryButton(title: "Keep exploring", icon: "play.fill", action: onResume)
                    .padding(.top, 8)
                Button("Start again", action: onRestart)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(FieldPalette.cream)
                    .frame(minHeight: 44)
                Button("Back to adventure", action: onBack)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(FieldPalette.cream.opacity(0.65))
                    .frame(minHeight: 44)
            }
            .padding(30)
            .frame(maxWidth: 380)
        }
        .accessibilityAddTraits(.isModal)
    }
}

struct ShepherdVictoryPanel: View {
    let seconds: Int
    let onReplay: () -> Void
    let onBack: () -> Void
    var body: some View {
        ZStack {
            Color(hex: "#0B241B").opacity(0.88).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 19) {
                    Text("THE FLOCK IS HOME")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(FieldPalette.gold)

                    ZStack {
                        Circle().fill(FieldPalette.gold.opacity(0.09)).frame(width: 174, height: 174)
                        Circle().stroke(FieldPalette.gold.opacity(0.25), lineWidth: 1).frame(width: 198, height: 198)
                        Image("ShepherdLamb").resizable().scaledToFit().frame(width: 170, height: 170)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 35))
                            .foregroundStyle(FieldPalette.gold)
                            .background(FieldPalette.forest, in: Circle())
                            .offset(x: 65, y: 62)
                    }
                    .padding(.vertical, 10)

                    Text("Every little life.\nSafely home.")
                        .font(.system(size: 36, weight: .medium, design: .serif))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(FieldPalette.cream)
                    Text("You helped David gather all seven lambs.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(FieldPalette.cream.opacity(0.7))
                        .multilineTextAlignment(.center)
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                        Text("7 rescued")
                        Text("·").padding(.horizontal, 4)
                        Image(systemName: "clock")
                        Text(String(format: "%d:%02d", seconds / 60, seconds % 60))
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(FieldPalette.gold)
                    .padding(.vertical, 3)

                    VStack(spacing: 9) {
                        Text("“The Lord is my shepherd;\nI shall not want.”")
                            .font(.system(size: 19, weight: .regular, design: .serif))
                            .italic()
                            .multilineTextAlignment(.center)
                            .foregroundStyle(FieldPalette.cream.opacity(0.9))
                        Text("PSALM 23:1")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(FieldPalette.cream.opacity(0.48))
                    }
                    .padding(.vertical, 17)
                    .frame(maxWidth: .infinity)
                    .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 18))

                    FieldPrimaryButton(title: "Continue the adventure", icon: "arrow.right", action: onBack)
                    Button("Explore again", action: onReplay)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(FieldPalette.cream.opacity(0.7))
                        .frame(minHeight: 44)
                }
                .padding(28)
                .frame(maxWidth: 420)
                .frame(maxWidth: .infinity)
            }
            .defaultScrollAnchor(.center)
        }
        .accessibilityAddTraits(.isModal)
    }
}

private struct FieldPrimaryButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Text(title)
                Image(systemName: icon).font(.system(size: 13, weight: .bold))
            }
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(Color(hex: "#2A3520"))
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(LinearGradient(colors: [Color(hex: "#F6E2AB"), Color(hex: "#D7B66F")],
                                       startPoint: .top, endPoint: .bottom), in: Capsule())
            .overlay(Capsule().stroke(Color(hex: "#FFEDC1").opacity(0.8), lineWidth: 1))
        }
        .buttonStyle(ShepherdPressStyle())
    }
}
