import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: StoreManager
    @StateObject private var history = MathHistoryStore()
    @State private var selectedTab: Tab = .solve

    enum Tab: Int, CaseIterable {
        case solve, history, settings

        var icon: String {
            switch self {
            case .solve:    return "camera.fill"
            case .history:  return "clock.fill"
            case .settings: return "gearshape.fill"
            }
        }
        var label: String {
            switch self {
            case .solve:    return "Solve"
            case .history:  return "History"
            case .settings: return "Settings"
            }
        }
        var tint: Color {
            switch self {
            case .solve:    return Color.appAccent
            case .history:  return Color(hex: "60A5FA")
            case .settings: return Color.appMuted
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBG.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .solve:
                    SolveView(history: history)
                        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 82) }
                case .history:
                    HistoryView(history: history)
                        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 82) }
                case .settings:
                    SettingsView()
                        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 82) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            customTabBar
        }
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.dark)
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    if selectedTab != tab {
                        Haptics.impact(.light)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(tab.tint.opacity(selectedTab == tab ? 0.15 : 0))
                                .frame(width: 52, height: 34)
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundStyle(selectedTab == tab ? tab.tint : Color.appMuted)
                                .scaleEffect(selectedTab == tab ? 1.08 : 1.0)
                        }
                        .frame(width: 52, height: 34)
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: selectedTab)

                        Text(tab.label)
                            .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundStyle(selectedTab == tab ? tab.tint : Color.appMuted)
                    }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 28)
        .background(
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(LinearGradient(
                    colors: [Color.white.opacity(0.05), Color.clear],
                    startPoint: .top, endPoint: .bottom
                ))
                Rectangle().frame(height: 0.5)
                    .foregroundStyle(Color.white.opacity(0.1))
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        )
        .ignoresSafeArea(edges: .bottom)
    }
}
