import SwiftUI

public enum SettingsTab: String, CaseIterable, Identifiable {
    case categories = "categories"
    case appearance = "appearance"
    case gestures = "gestures"
    case about = "about"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .categories: return LanguageManager.shared.tr("tab_categories")
        case .appearance: return LanguageManager.shared.tr("tab_appearance")
        case .gestures: return LanguageManager.shared.tr("tab_gestures")
        case .about: return LanguageManager.shared.tr("tab_about")
        }
    }

    public var icon: String {
        switch self {
        case .categories: return "folder.fill"
        case .appearance: return "paintbrush.fill"
        case .gestures: return "bolt.fill"
        case .about: return "info.circle.fill"
        }
    }

    public var accentColor: Color {
        switch self {
        case .categories: return .blue
        case .appearance: return .purple
        case .gestures: return .orange
        case .about: return .orange
        }
    }

    public var subtitle: String {
        switch self {
        case .categories: return LanguageManager.shared.tr("tab_categories_sub")
        case .appearance: return LanguageManager.shared.tr("tab_appearance_sub")
        case .gestures: return LanguageManager.shared.tr("tab_gestures_sub")
        case .about: return LanguageManager.shared.tr("tab_about_sub")
        }
    }
}

public struct SettingsView: View {
    @StateObject private var categoryVM = CategoryManagementViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var lang = LanguageManager.shared
    @State private var activeTab: SettingsTab = .categories

    private var isDark: Bool {
        themeManager.currentTheme == .dark
    }

    public var body: some View {
        HStack(spacing: 0) {
            // SOL: Yeni Nesil Modern Sidebar
            sidebarView
                .frame(width: 220)

            // Dikey İnce Ayırıcı
            Rectangle()
                .fill(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                .frame(width: 1)

            // SAĞ: Seçili Sekme Detay Alanı
            detailContentView
        }
        .frame(width: 920, height: 560)
        .background(isDark ? Color(white: 0.12) : Color(white: 0.96))
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }

    // MARK: - Sol Sidebar
    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // macOS Traffic Light Butonları İçin Güvenli Üst Boşluk
            Spacer()
                .frame(height: 24)

            // Uygulama Başlığı & Mini Logo
            HStack(spacing: 10) {
                if let logo = AppIconService.shared.appLogo() {
                    Image(nsImage: logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 1)
                } else {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 28, height: 28)
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.orange)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(lang.tr("app_title"))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Text(lang.tr("settings_title"))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 6)

            // Navigasyon Butonları
            VStack(spacing: 4) {
                ForEach(SettingsTab.allCases) { tab in
                    let isSelected = activeTab == tab

                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            activeTab = tab
                        }
                        SystemActionService.shared.performHapticFeedback()
                    } label: {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(tab.accentColor.opacity(isSelected ? 0.9 : (isDark ? 0.20 : 0.12)))
                                    .frame(width: 24, height: 24)

                                Image(systemName: tab.icon)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(isSelected ? .white : tab.accentColor)
                            }

                            Text(tab.title)
                                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                                .foregroundStyle(isSelected ? (isDark ? .white : .black) : .secondary)

                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(isSelected ? (isDark ? Color.white.opacity(0.12) : Color.white) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(isSelected ? (isDark ? Color.white.opacity(0.15) : Color.black.opacity(0.08)) : Color.clear, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(isSelected ? (isDark ? 0.2 : 0.05) : 0), radius: 3, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)

            Spacer()

            // Alt Sürüm Rozeti
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                Text("v1.0.0 • \(lang.currentLanguage.displayName)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
        .background(isDark ? Color.black.opacity(0.18) : Color.black.opacity(0.02))
    }

    // MARK: - Sağ Detay Alanı
    private var detailContentView: some View {
        VStack(spacing: 0) {
            // Başlık Çubuğu
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(activeTab.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text(activeTab.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 14)

            Divider()
                .background(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))

            // İçerik
            Group {
                switch activeTab {
                case .categories:
                    CategoryManagementView(viewModel: categoryVM)
                case .appearance:
                    AppearanceSettingsView()
                case .gestures:
                    GesturesShortcutsSettingsView()
                case .about:
                    AboutView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
