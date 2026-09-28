import SwiftUI

public struct AppearanceSettingsView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var userProfile = UserProfileService.shared
    @ObservedObject private var lang = LanguageManager.shared

    @AppStorage("OrbDimmedOpacity") private var orbDimmedOpacity: Double = 0.35
    @AppStorage("EnableMagneticSnap") private var enableMagneticSnap: Bool = true

    private var isDark: Bool {
        themeManager.currentTheme == .dark
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // Section 1: Uygulama Dili Seçimi (Language Selector)
                modernSectionCard(title: lang.tr("language_section"), icon: "globe", iconColor: .blue) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 14) {
                            ForEach(AppLanguage.allCases) { item in
                                languageCard(item: item)
                            }
                        }

                        Text(lang.tr("language_subtitle"))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                // Section 2: Görsel Tema Seçimi (Visual Theme Cards)
                modernSectionCard(title: lang.tr("theme_section"), icon: "paintbrush.fill", iconColor: .purple) {
                    HStack(spacing: 16) {
                        themeCard(
                            theme: .light,
                            title: lang.tr("theme_light"),
                            icon: "sun.max.fill",
                            iconColor: .orange,
                            gradient: [Color.white, Color(nsColor: .windowBackgroundColor)]
                        )

                        themeCard(
                            theme: .dark,
                            title: lang.tr("theme_dark"),
                            icon: "moon.stars.fill",
                            iconColor: .indigo,
                            gradient: [Color(white: 0.18), Color(white: 0.10)]
                        )
                    }
                }

                // Section 3: Yüzen Buton (Assistive Orb) Ayarları
                modernSectionCard(title: lang.tr("orb_section"), icon: "circle.circle.fill", iconColor: .orange) {
                    VStack(spacing: 16) {
                        // Slider: Rölanti Şeffaflığı
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(lang.tr("orb_opacity"))
                                    .font(.system(size: 13, weight: .medium))
                                Spacer()
                                Text("\(Int(orbDimmedOpacity * 100))%")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                                    .clipShape(Capsule())
                            }
                            Slider(value: $orbDimmedOpacity, in: 0.20...0.80, step: 0.05)
                        }

                        Divider()
                            .background(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))

                        // Slider: Rölantiye Geçiş Süresi
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(lang.tr("orb_idle_delay"))
                                    .font(.system(size: 13, weight: .medium))
                                Spacer()
                                Text(String(format: "%.1f sn", currentIdleDelay))
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                                    .clipShape(Capsule())
                            }
                            Slider(value: Binding(
                                get: { currentIdleDelay },
                                set: {
                                    UserDefaults.standard.set($0, forKey: "OrbIdleDelay")
                                    NotificationCenter.default.post(name: .autoHidePreferenceChanged, object: nil)
                                }
                            ), in: 1.0...8.0, step: 0.5)
                        }

                        Divider()
                            .background(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))

                        // Toggles
                        Toggle(lang.tr("orb_edge_snap"), isOn: Binding(
                            get: { UserDefaults.standard.bool(forKey: "EnableAutoHide") },
                            set: {
                                UserDefaults.standard.set($0, forKey: "EnableAutoHide")
                                NotificationCenter.default.post(name: .autoHidePreferenceChanged, object: nil)
                            }
                        ))
                        .font(.system(size: 13, weight: .medium))

                        Text(lang.tr("orb_edge_snap_desc"))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                // Section 4: Kullanıcı Profili & Selamlaşma
                modernSectionCard(title: lang.tr("greeting_section"), icon: "person.crop.circle.fill", iconColor: .blue) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(isDark ? 0.25 : 0.15))
                                    .frame(width: 40, height: 40)
                                Text(String(userProfile.effectiveName.prefix(1)).uppercased())
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(.orange)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(lang.tr("greeting_desc"))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)

                                HStack {
                                    TextField(lang.tr("greeting_placeholder"), text: $userProfile.customName)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(size: 13))

                                    if !userProfile.customName.isEmpty {
                                        Button(lang.tr("cancel_button")) {
                                            userProfile.resetToSystemDefault()
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                    }
                                }
                            }
                        }

                        HStack(spacing: 6) {
                            Text(lang.tr("greeting_sample"))
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Text(userProfile.greetingMessage)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.orange)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.orange.opacity(isDark ? 0.15 : 0.08))
                        )
                    }
                }

                // Section 5: Sistem Başlangıcı
                modernSectionCard(title: lang.tr("system_section"), icon: "power.circle.fill", iconColor: .green) {
                    VStack(alignment: .leading, spacing: 6) {
                        Toggle(lang.tr("launch_at_login"), isOn: Binding(
                            get: { LaunchAtLoginService.shared.isEnabled },
                            set: { LaunchAtLoginService.shared.setEnabled($0) }
                        ))
                        .font(.system(size: 13, weight: .medium))

                        Text(lang.tr("launch_at_login_desc"))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(20)
        }
    }

    private var currentIdleDelay: Double {
        let val = UserDefaults.standard.double(forKey: "OrbIdleDelay")
        return val >= 1.0 ? val : 2.5
    }

    // MARK: - Dil Kartı
    @ViewBuilder
    private func languageCard(item: AppLanguage) -> some View {
        let isSelected = lang.currentLanguage == item

        Button {
            lang.setLanguage(item)
            SystemActionService.shared.performHapticFeedback()
        } label: {
            HStack(spacing: 10) {
                Text(item.flag)
                    .font(.system(size: 20))

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.displayName)
                        .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(isSelected ? (isDark ? .white : .black) : .secondary)

                    Text(item == .turkish ? "Varsayılan" : "English UI")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? (isDark ? Color.white.opacity(0.12) : Color.white) : (isDark ? Color.white.opacity(0.04) : Color.black.opacity(0.02)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : (isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)), lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Modern Section Kartı
    @ViewBuilder
    private func modernSectionCard<Content: View>(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) -> some View {
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

    // MARK: - Görsel Tema Kartı
    @ViewBuilder
    private func themeCard(theme: AppTheme, title: String, icon: String, iconColor: Color, gradient: [Color]) -> some View {
        let isSelected = themeManager.currentTheme == theme

        Button {
            themeManager.currentTheme = theme
            SystemActionService.shared.performHapticFeedback()
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(colors: gradient, startPoint: .top, endPoint: .bottom))
                        .frame(height: 64)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.black.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)

                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(iconColor)
                }

                HStack(spacing: 6) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)

                    Text(title)
                        .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(isSelected ? (isDark ? .white : .black) : .secondary)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? (isDark ? Color.white.opacity(0.08) : Color.white) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : (isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.06)), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
