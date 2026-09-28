import SwiftUI

public struct AboutView: View {
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
            VStack(spacing: 22) {
                // Header: Logo + App Name + Version
                VStack(spacing: 12) {
                    if let logo = AppIconService.shared.appLogo() {
                        Image(nsImage: logo)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 84, height: 84)
                            .shadow(color: Color.blue.opacity(0.35), radius: 12, x: 0, y: 4)
                    }

                    VStack(spacing: 6) {
                        Text(lang.tr("app_title"))
                            .font(.system(size: 22, weight: .bold, design: .rounded))

                        HStack(spacing: 8) {
                            Text(lang.tr("about_version"))
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 3)
                                .background(isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.06))
                                .clipShape(Capsule())

                            Text(lang.tr("about_os"))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 14)

                Divider()
                    .padding(.horizontal, 24)

                // Geliştirici Kartı
                VStack(alignment: .leading, spacing: 10) {
                    Text(isTr ? "Geliştirici" : "Developer")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    developerCard
                }
                .padding(.horizontal, 24)

                // Kullanılan Teknolojiler (Maddeler Halinde)
                VStack(alignment: .leading, spacing: 12) {
                    Text(lang.tr("about_tech_header"))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    VStack(spacing: 8) {
                        techItemRow(
                            icon: "swift",
                            title: "Swift 6 & SwiftUI",
                            description: isTr
                                ? "Modern eşzamanlılık (Structured Concurrency) ve deklaratif arayüz mimarisi."
                                : "Modern Structured Concurrency and declarative user interface architecture.",
                            accentColor: .orange
                        )

                        techItemRow(
                            icon: "macwindow",
                            title: "AppKit & Zero-Lag NSPanel",
                            description: isTr
                                ? "Sıfır gecikmeli, sisteme entegre yüzen panel ve pencere yaşam döngüsü."
                                : "Zero-latency, deeply integrated floating panel and window lifecycle management.",
                            accentColor: .blue
                        )

                        techItemRow(
                            icon: "drop.fill",
                            title: "Liquid Glassmorphism",
                            description: isTr
                                ? "macOS doğal yarı saydamlık malzemeleri ve modern dinamik temalar."
                                : "Native macOS translucency materials and modern dynamic visual themes.",
                            accentColor: .purple
                        )

                        techItemRow(
                            icon: "gauge.with.needle",
                            title: "Mach Kernel Hardware Monitor",
                            description: isTr
                                ? "Doğrudan kernel telemetrisi ile gerçek zamanlı CPU, RAM ve donanım takibi."
                                : "Direct kernel telemetry for real-time CPU, RAM and hardware tracking.",
                            accentColor: .green
                        )

                        techItemRow(
                            icon: "keyboard.fill",
                            title: "Global Event Engine",
                            description: isTr
                                ? "Sistem genelinde çalışan klavye dinleyicisi ve anlık Spotlight arama motoru."
                                : "System-wide keyboard listener and instant Spotlight search engine.",
                            accentColor: .cyan
                        )
                    }
                }
                .padding(.horizontal, 24)

                // Footer & Telif
                VStack(spacing: 6) {
                    Text(lang.tr("about_copyright"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 14)
            }
            .frame(maxWidth: .infinity)
        }
        .background(isDark ? Color.black.opacity(0.18) : Color.white.opacity(0.35))
    }

    // MARK: - Geliştirici & Kurumsal Kart
    private var developerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(isDark ? 0.25 : 0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "person.fill")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(Color.orange)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Abdurrahim İçyer")
                        .font(.system(size: 16, weight: .bold))
                    Text(isTr ? "Geliştirici • Gratonya" : "Developer • Gratonya")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.orange)
                }

                Spacer()
            }

            // İletişim & Web Linkleri (Kişisel Site, Şirket, E-posta)
            HStack(spacing: 12) {
                // Kişisel Web Sitesi Linki
                Link(destination: URL(string: "https://www.abdurrahimicyer.com")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.orange)
                        Text("abdurrahimicyer.com")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.primary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                    )
                }
                .buttonStyle(.plain)

                // Şirket Web Sitesi Linki
                Link(destination: URL(string: "https://www.gratonya.com")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.blue)
                        Text("gratonya.com")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.primary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                    )
                }
                .buttonStyle(.plain)

                // E-posta Linki
                Link(destination: URL(string: "mailto:hello@gratonya.com")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.pink)
                        Text("hello@gratonya.com")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.primary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                    )
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Teknoloji Maddesi Satırı
    @ViewBuilder
    private func techItemRow(icon: String, title: String, description: String, accentColor: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(accentColor.opacity(isDark ? 0.22 : 0.12))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isDark ? Color.white.opacity(0.04) : Color.black.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05), lineWidth: 0.5)
        )
    }
}
