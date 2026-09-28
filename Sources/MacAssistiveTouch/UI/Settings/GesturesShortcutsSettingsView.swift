import SwiftUI

public struct GesturesShortcutsSettingsView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var lang = LanguageManager.shared

    private var isDark: Bool {
        themeManager.currentTheme == .dark
    }

    private var isTr: Bool {
        lang.currentLanguage == .turkish
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // Section 1: Global Klavye Kısayolu
                settingsCard(title: isTr ? "Global Klavye Kısayolu" : "Global Keyboard Shortcut", icon: "keyboard.fill", iconColor: .blue) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(isTr
                            ? "Mac'inizde hangi uygulamada olursanız olun tek bir tuş kombinasyonuyla menüyü çağırabilir veya kapatabilirsiniz."
                            : "Toggle the launcher menu from any application with a single global key combination.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            HStack(spacing: 6) {
                                keyCapView("⌥ Option")
                                Text("+")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.secondary)
                                keyCapView(isTr ? "Space (Boşluk)" : "Space")
                            }

                            Spacer()

                            Text(isTr ? "Global Kısayol (Aktif)" : "Global Hotkey (Active)")
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.green.opacity(0.15))
                                .clipShape(Capsule())
                                .foregroundStyle(.green)
                        }
                        .padding(.top, 4)
                    }
                }

                // Section 2: Yüzen Buton Jestleri (Orb Gestures)
                settingsCard(title: isTr ? "Yüzen Buton Jestleri" : "Floating Orb Gestures", icon: "hand.tap.fill", iconColor: .orange) {
                    VStack(spacing: 12) {
                        gestureRow(
                            icon: "hand.point.up.left.fill",
                            iconColor: .blue,
                            title: isTr ? "Tek Dokunuş (Single Tap)" : "Single Tap",
                            description: isTr
                                ? "Assistive Hub menüsünü anında açar veya kapatır. Eğer buton kenara saklanmışsa doğrudan dışarı fırlar."
                                : "Toggles the Assistive Hub menu immediately. If hidden at edge, it smoothly pops out."
                        )

                        Divider()
                            .background(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))

                        gestureRow(
                            icon: "camera.viewfinder",
                            iconColor: .purple,
                            title: isTr ? "Çift Tıklama (Double Tap)" : "Double Tap",
                            description: isTr
                                ? "Akıllı 0.22s debounce filtresiyle menüyü açmadan doğrudan yerel Ekran Görüntüsü aracını başlatır."
                                : "Triggers macOS screenshot utility without opening the main menu panel."
                        )

                        Divider()
                            .background(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))

                        gestureRow(
                            icon: "lock.fill",
                            iconColor: .red,
                            title: isTr ? "Uzun Basış (Long Press ~0.5 sn)" : "Long Press (~0.5s)",
                            description: isTr
                                ? "Dokunsal titreşim geri bildirimi vererek Mac ekranını anında ve güvenle kilitler."
                                : "Locks your Mac screen securely with haptic feedback."
                        )

                        Divider()
                            .background(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))

                        gestureRow(
                            icon: "arrow.left.and.right",
                            iconColor: .teal,
                            title: isTr ? "Sürükle & Bırak (Drag & Snap)" : "Drag & Snap",
                            description: isTr
                                ? "Butonu ekranın istediğiniz yerine taşıyın; bıraktığınızda en yakın dikey kenara pürüzsüzce manyetik yapışır."
                                : "Move the orb anywhere on screen; it magnetically snaps to the nearest display border."
                        )
                    }
                }

                // Section 3: Güçlü Araçlar & Hızlı Kısayollar
                settingsCard(title: isTr ? "Verimlilik & Hızlı Araçlar" : "Productivity & Quick Tools", icon: "bolt.fill", iconColor: .yellow) {
                    VStack(spacing: 12) {
                        gestureRow(
                            icon: "magnifyingglass",
                            iconColor: .blue,
                            title: isTr ? "Spotlight Arama (⌘F veya Doğrudan Yazma)" : "Spotlight Search (⌘F or Type)",
                            description: isTr
                                ? "Menü açıldığında klavyeden harf yazmaya başlayın; anında filtrelensin ve Enter ile doğrudan başlasın."
                                : "Type immediately when panel opens to filter apps and launch with Return."
                        )

                        Divider()
                            .background(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))

                        gestureRow(
                            icon: "square.and.pencil",
                            iconColor: .orange,
                            title: isTr ? "Hızlı Karalama Defteri (Scratchpad)" : "Quick Scratchpad",
                            description: isTr
                                ? "Üst sağ mini dock'taki kalem ikonuyla anında açılır; notlar kalıcı olarak saklanır ve tek tıkla kopyalanır."
                                : "Open instantly from top-right mini dock pencil icon; persists notes locally."
                        )

                        Divider()
                            .background(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))

                        gestureRow(
                            icon: "doc.on.clipboard.fill",
                            iconColor: .indigo,
                            title: isTr ? "Pano Geçmişi (Clipboard Manager)" : "Clipboard History",
                            description: isTr
                                ? "Sol kenar çubuğundaki pano sekmesinden son kopyalanan 15 metne tek tıkla tekrar erişebilirsiniz."
                                : "Access your last 15 copied snippets from clipboard tab with a single click."
                        )
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Kart Kapsayıcısı
    @ViewBuilder
    private func settingsCard<Content: View>(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.system(size: 14, weight: .bold))
            }

            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isDark ? Color.white.opacity(0.05) : Color.white.opacity(0.70))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Jest Satırı
    @ViewBuilder
    private func gestureRow(icon: String, iconColor: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(isDark ? 0.22 : 0.12))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }

    // MARK: - Klavye Tuş Görünümü
    @ViewBuilder
    private func keyCapView(_ key: String) -> some View {
        Text(key)
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isDark ? Color.white.opacity(0.12) : Color.white)
                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(isDark ? Color.white.opacity(0.2) : Color.black.opacity(0.15), lineWidth: 1)
            )
    }
}
