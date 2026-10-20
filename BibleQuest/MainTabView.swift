import SwiftUI
import FirebaseAuth

struct MainTabView: View {
    @State private var selection = 0

    var body: some View {
        ZStack {
            NavigationStack {
                HomePage(onProfile: { selection = 3 })
                    .safeAreaInset(edge: .bottom, spacing: 0) { dock }
            }
            .opacity(selection == 0 ? 1 : 0)
            .allowsHitTesting(selection == 0)
            .accessibilityHidden(selection != 0)
            .zIndex(selection == 0 ? 1 : 0)

            NavigationStack {
                StoriesView()
                    .safeAreaInset(edge: .bottom, spacing: 0) { dock }
            }
            .opacity(selection == 1 ? 1 : 0)
            .allowsHitTesting(selection == 1)
            .accessibilityHidden(selection != 1)
            .zIndex(selection == 1 ? 1 : 0)

            NavigationStack {
                WisdomView(isActive: selection == 2)
                    .safeAreaInset(edge: .bottom, spacing: 0) { dock }
            }
            .opacity(selection == 2 ? 1 : 0)
            .allowsHitTesting(selection == 2)
            .accessibilityHidden(selection != 2)
            .zIndex(selection == 2 ? 1 : 0)

            NavigationStack {
                ProfilePage()
                    .safeAreaInset(edge: .bottom, spacing: 0) { dock }
            }
            .opacity(selection == 3 ? 1 : 0)
            .allowsHitTesting(selection == 3)
            .accessibilityHidden(selection != 3)
            .zIndex(selection == 3 ? 1 : 0)
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    private var dock: some View {
        AdventureTabBar(selection: $selection)
            .frame(maxWidth: 520)
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 6)
            .frame(maxWidth: .infinity)
            .background {
                LinearGradient(colors: [.white.opacity(0), Color(hex: "#FFF9EF").opacity(0.96)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea(edges: .bottom)
            }
    }
}

/// Lives inside each navigation root so readers and games can use the full screen.
private struct AdventureTabBar: View {
    @Binding var selection: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let names = ["Home", "Stories", "Wisdom", "Profile"]
    private let icons = ["house.fill", "book.closed.fill", "lightbulb.fill", "person.crop.circle.fill"]
    private let colors = [Color(hex: "#D66A35"), Color(hex: "#4775D1"), Color(hex: "#A87817"), Color(hex: "#8B61C5")]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(names.indices, id: \.self) { index in
                let active = selection == index
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.68)) {
                        selection = index
                    }
                } label: {
                    VStack(spacing: 5) {
                        ZStack(alignment: .topTrailing) {
                            RoundedRectangle(cornerRadius: active ? 16 : 14)
                                .fill(colors[index].opacity(active ? 1 : 0.11))
                                .frame(width: 45, height: 37)
                                .rotationEffect(.degrees(active ? -6 : 0))
                            Image(systemName: icons[index])
                                .font(.system(size: 21, weight: .semibold))
                                .foregroundStyle(active ? .white : colors[index])
                                .frame(width: 45, height: 37)
                            if active {
                                Image(systemName: "sparkle")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color(hex: "#FFD56E"))
                                    .offset(x: 4, y: -4)
                            }
                        }
                        Text(names[index])
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundStyle(active ? colors[index] : Color(hex: "#6F777A"))
                    }
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(names[index])
                .accessibilityAddTraits(active ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.white, in: RoundedRectangle(cornerRadius: 29))
        .overlay(RoundedRectangle(cornerRadius: 29).stroke(Color(hex: "#E9E4DC"), lineWidth: 1))
        .shadow(color: Color(hex: "#304B43").opacity(0.12), radius: 18, y: 6)
    }
}

struct ProfilePage: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            Text("Profile")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .padding(.top, 24)

            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundStyle(Color(hex: "#2C7CF6"))

            Text(appState.profile?.displayName ?? "Explorer")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.bqTitle)

            Button(role: .destructive) {
                // 🔹 Sign out from Firebase
                try? Auth.auth().signOut()

                // 🔹 Update app state so RootView shows LoginView
                appState.isLoggedIn = false
            } label: {
                Text("Logout")
                    .font(.system(.headline, design: .rounded))
                    .frame(maxWidth: 220, minHeight: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.bqCardSurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.bqBackgroundTop, Color.bqBackgroundBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}


#Preview {
    MainTabView().environmentObject(AppState())
}
