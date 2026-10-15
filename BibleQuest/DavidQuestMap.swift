import SwiftUI

// Artwork stays separate from the interactive trail so every stop remains accessible.
struct DavidQuestMap: View {
    let nodes: [AdventureNode]
    let mapHeight: CGFloat
    let progress: CGFloat
    let heroKey: String
    let completedIndices: Set<Int>
    let currentIndex: Int
    var onSelect: (Int) -> Void

    var body: some View {
        GeometryReader { geometry in
            let mapNodes = nodes.map { node in
                AdventureNode(title: node.title, emoji: node.emoji, y: node.y,
                              xOffset: node.xOffset * min(1, geometry.size.width / 390))
            }

            ZStack(alignment: .top) {
                DavidLandscape(mapHeight: mapHeight)

                AdventurePathShape(nodes: mapNodes)
                    .stroke(Color(hex: "#433B21").opacity(0.28),
                            style: StrokeStyle(lineWidth: 34, lineCap: .round))
                    .offset(y: 4)
                    .blur(radius: 3)

                AdventurePathShape(nodes: mapNodes)
                    .stroke(Color(hex: "#947244"),
                            style: StrokeStyle(lineWidth: 29, lineCap: .round))

                AdventurePathShape(nodes: mapNodes)
                    .stroke(Color(hex: "#EACB8B"),
                            style: StrokeStyle(lineWidth: 24, lineCap: .round))

                AdventurePathShape(nodes: mapNodes)
                    .stroke(Color(hex: "#FFF3C8").opacity(0.75),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 12]))

                AdventurePathShape(nodes: mapNodes)
                    .trim(from: 0, to: progress.clamped(to: 0...1))
                    .stroke(Color(hex: "#FFF0AA"),
                            style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .shadow(color: Color(hex: "#FFE091").opacity(0.8), radius: 7)

                ForEach(Array(mapNodes.enumerated()), id: \.offset) { index, node in
                    DavidQuestMarker(node: node, number: index + 1,
                                     isCurrent: index == currentIndex,
                                     isCompleted: completedIndices.contains(index)) {
                        onSelect(index)
                    }
                    .position(x: geometry.size.width / 2 + node.xOffset, y: node.y)
                }

                WalkingHero(heroKey: heroKey, progress: progress, nodes: mapNodes,
                            mapHeight: mapHeight, pathWidth: geometry.size.width)
                    // Keep the explorer next to the marker instead of covering its icon.
                    .offset(x: 48, y: -18)
                    .allowsHitTesting(false)

                DavidMapMotes()
            }
        }
        .frame(height: mapHeight)
    }
}

private struct DavidLandscape: View {
    let mapHeight: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let sectionHeight = mapHeight / 3
            ZStack(alignment: .top) {
                Color(hex: "#89965A")
                // Overlap and feather the paintings to avoid hard horizontal seams.
                ForEach(0..<3) { index in
                    Image(["DavidQuestMeadow", "DavidQuestStream", "DavidQuestValley"][index])
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: sectionHeight + 100)
                        .clipped()
                        .mask {
                            LinearGradient(stops: [
                                .init(color: index == 0 ? .white : .clear, location: 0),
                                .init(color: .white, location: 0.09),
                                .init(color: .white, location: 1)
                            ], startPoint: .top, endPoint: .bottom)
                        }
                        .offset(y: CGFloat(index) * sectionHeight - (index == 0 ? 0 : 50))
                }

                LinearGradient(colors: [Color(hex: "#FFF0B8").opacity(0.17), .clear,
                                        Color(hex: "#544A1F").opacity(0.12)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)

                // A soft canopy vignette adds depth without dimming the quest labels.
                HStack(spacing: 0) {
                    LinearGradient(colors: [Color(hex: "#102F24").opacity(0.26), .clear],
                                   startPoint: .leading, endPoint: .trailing)
                    Color.clear.frame(width: geometry.size.width * 0.5)
                    LinearGradient(colors: [.clear, Color(hex: "#102F24").opacity(0.26)],
                                   startPoint: .leading, endPoint: .trailing)
                }
            }
        }
        .frame(height: mapHeight)
        .clipped()
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

private struct DavidQuestMarker: View {
    let node: AdventureNode
    let number: Int
    let isCurrent: Bool
    let isCompleted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                ZStack {
                    if isCurrent {
                        Circle()
                            .stroke(Color(hex: "#FFF1B4").opacity(0.55), lineWidth: 2)
                            .frame(width: 85, height: 85)
                        Circle()
                            .fill(Color(hex: "#FFE4A0").opacity(0.18))
                            .frame(width: 94, height: 94)
                    }

                    Circle()
                        .fill(Color(hex: "#6D532E"))
                        .frame(width: 68, height: 68)
                        .offset(y: 5)

                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "#FFF9DE"), Color(hex: "#E9D4A3")],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 68, height: 68)
                        .overlay {
                            Circle().stroke(Color(hex: isCurrent ? "#F6CE6C" : "#FAEDCA"), lineWidth: 3)
                        }

                    Text(node.emoji).font(.system(size: 31))

                    Text(isCompleted ? "✓" : String(number))
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex: "#FFF5D5"))
                        .frame(width: 23, height: 23)
                        .background(Color(hex: isCompleted ? "#496B43" : "#795D35"), in: Circle())
                        .overlay(Circle().stroke(Color(hex: "#F7E6BC"), lineWidth: 1.5))
                        .offset(x: -27, y: -25)
                }
                .frame(height: 86)
                .shadow(color: Color(hex: "#20301A").opacity(0.32), radius: 8, y: 5)

                Text(node.title)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: "#FFF5D9"))
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#263E2E").opacity(0.94), in: Capsule())
                    .overlay(Capsule().stroke(Color(hex: "#E9CF8D").opacity(0.65), lineWidth: 1))
                    .shadow(color: .black.opacity(0.25), radius: 5, y: 3)
            }
            .frame(width: 172)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Stop \(number), \(node.title)\(isCompleted ? ", completed" : "")\(isCurrent ? ", current location" : "")")
    }
}

private struct DavidMapMotes: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                for index in 0..<38 {
                    let seed = Double(index)
                    let x = size.width * CGFloat((sin(seed * 127.1) + 1) / 2)
                    let baseY = size.height * CGFloat((sin(seed * 311.7) + 1) / 2)
                    let drift = CGFloat(sin(time * 0.3 + seed) * 12)
                    let radius: CGFloat = index.isMultiple(of: 3) ? 2 : 1.2
                    let point = CGRect(x: x + drift, y: baseY + drift * 2,
                                       width: radius * 2, height: radius * 2)
                    let opacity = 0.25 + (sin(time * 0.7 + seed) + 1) * 0.2
                    context.fill(Path(ellipseIn: point), with: .color(Color(hex: "#FFF3C0").opacity(opacity)))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct DavidMapControl: View {
    let icon: String
    let title: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(Color(hex: "#FFF3D0"))
            .padding(.horizontal, 16)
            .frame(height: 42)
            .background(Color(hex: "#203C2D").opacity(0.94), in: Capsule())
            .overlay(Capsule().stroke(Color(hex: "#D9C28A").opacity(0.6), lineWidth: 1))
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
}

struct DavidMapPlayButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 16, weight: .bold))
                Text(title).font(.system(size: 18, weight: .heavy, design: .rounded))
                Image(systemName: "arrow.right").font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(Color(hex: "#342B17"))
            .padding(.horizontal, 28)
            .frame(height: 54)
            .background(LinearGradient(colors: [Color(hex: "#FFE9AD"), Color(hex: "#DCAF56")],
                                       startPoint: .top, endPoint: .bottom), in: Capsule())
            .overlay(Capsule().stroke(Color(hex: "#FFF1C7"), lineWidth: 1.5))
            .shadow(color: Color(hex: "#1D2F1D").opacity(0.4), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }
}
