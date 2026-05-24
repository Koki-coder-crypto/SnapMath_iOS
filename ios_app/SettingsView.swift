import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: StoreManager
    @State private var showPaywall = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("Settings")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)

                    // Pro Status
                    proStatusCard

                    // Settings Sections
                    settingsSection(title: "General", items: [
                        SettingsItem(icon: "star.fill", color: Color(hex: "F59E0B"),
                                     title: "Rate SnapMath", subtitle: "Love it? Leave a review!",
                                     action: { openAppStore() }),
                        SettingsItem(icon: "square.and.arrow.up", color: Color(hex: "60A5FA"),
                                     title: "Share App", subtitle: "Tell your friends",
                                     action: { shareApp() }),
                    ])

                    settingsSection(title: "Support", items: [
                        SettingsItem(icon: "questionmark.circle.fill", color: Color.appAccent,
                                     title: "Help & FAQ", subtitle: "Get answers to common questions",
                                     action: {}),
                        SettingsItem(icon: "envelope.fill", color: Color(hex: "A78BFA"),
                                     title: "Contact Support", subtitle: "kouki_1203@icloud.com",
                                     action: { contactSupport() }),
                        SettingsItem(icon: "arrow.counterclockwise.circle.fill", color: Color(hex: "38BDF8"),
                                     title: "Restore Purchases", subtitle: "Recover your subscription",
                                     action: { Task { await store.restorePurchases() } }),
                    ])

                    settingsSection(title: "Legal", items: [
                        SettingsItem(icon: "lock.shield.fill", color: Color(hex: "2ECC71"),
                                     title: "Privacy Policy", subtitle: nil,
                                     action: { openURL("https://github.com/Koki-coder-crypto/LynQ_backend/blob/master/app_store/privacy_policy.html") }),
                        SettingsItem(icon: "doc.text.fill", color: Color.appMuted,
                                     title: "Terms of Use", subtitle: nil,
                                     action: { openURL("https://github.com/Koki-coder-crypto/LynQ_backend/blob/master/app_store/terms_of_service.html") }),
                    ])

                    Text("SnapMath v1.0.0\nPowered by Claude AI")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appMuted.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 20)

                    Spacer(minLength: 100)
                }
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView().environmentObject(store) }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { appeared = true }
        }
    }

    private var proStatusCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.appAccent.opacity(0.15)).frame(width: 52, height: 52)
                    Image(systemName: store.isPro ? "crown.fill" : "lock.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.appAccent)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.isPro ? "SnapMath Pro" : "Free Plan")
                        .font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                    Text(store.isPro ? "Unlimited solves • All features" :
                         "\(max(0, StoreManager.freeUsesPerMonth - UserDefaults.standard.integer(forKey: "monthly_uses"))) free solves remaining")
                        .font(.system(size: 13)).foregroundStyle(Color.appMuted)
                }
                Spacer()
                if store.isPro {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.appAccent)
                }
            }
            if !store.isPro {
                Button {
                    Haptics.impact(.medium)
                    showPaywall = true
                } label: {
                    Text("Upgrade to Pro")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(GradientButtonStyle())
            }
        }
        .padding(18)
        .glassSurface(cornerRadius: 24)
        .padding(.horizontal, 20)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
    }

    private func settingsSection(title: String, items: [SettingsItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.appMuted)
                .padding(.horizontal, 20)

            VStack(spacing: 1) {
                ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                    Button(action: { Haptics.impact(.light); item.action() }) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(item.color.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: item.icon)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(item.color)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.white)
                                if let sub = item.subtitle {
                                    Text(sub).font(.system(size: 12)).foregroundStyle(Color.appMuted)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.appMuted)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .background {
                            if i == 0 {
                                RoundedRectangle(cornerRadius: 20).fill(Color.appSurface)
                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.appBorder, lineWidth: 1))
                            } else {
                                RoundedRectangle(cornerRadius: 0).fill(Color.appSurface)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.appBorder, lineWidth: 1))
            .padding(.horizontal, 20)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
    }

    private func openAppStore() {
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id0") { UIApplication.shared.open(url) }
    }
    private func shareApp() {
        let av = UIActivityViewController(activityItems: ["Check out SnapMath - AI math solver!"], applicationActivities: nil)
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.windows.first?.rootViewController?.present(av, animated: true)
    }
    private func contactSupport() {
        if let url = URL(string: "mailto:kouki_1203@icloud.com?subject=SnapMath Support") { UIApplication.shared.open(url) }
    }
    private func openURL(_ string: String) {
        if let url = URL(string: string) { UIApplication.shared.open(url) }
    }
}

struct SettingsItem {
    let icon: String; let color: Color; let title: String; let subtitle: String?; let action: () -> Void
}
