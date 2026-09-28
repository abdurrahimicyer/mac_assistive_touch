import SwiftUI
import AppKit

public struct ActionHubView: View {
    @ObservedObject var viewModel: ActionHubViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var sysMonitor = SystemMonitorService.shared
    @ObservedObject private var clipboardMgr = ClipboardManager.shared
    @ObservedObject private var userProfile = UserProfileService.shared
    @ObservedObject private var scratchpad = ScratchpadService.shared
    @ObservedObject private var lang = LanguageManager.shared

    weak var panel: ActionHubPanel?

    @State private var hoveredItemId: UUID? = nil
    @State private var hoveredActionId: String? = nil
    @State private var isShowingClipboard: Bool = false
    @State private var isShowingScratchpad: Bool = false
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool
    @State private var copiedFeedbackText: String? = nil
    @State private var dragStartTranslation: CGSize = .zero

    private let cardColumns = [
        GridItem(.adaptive(minimum: 120, maximum: 160), spacing: 14)
    ]

    private var isDark: Bool {
        themeManager.currentTheme == .dark
    }

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            HStack(spacing: 0) {
                // SOL: Dikey İkonik Sidebar
                sidebarView

                // Dikey İnce Ayırıcı
                Rectangle()
                    .fill(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                    .frame(width: 1)

                // SAĞ: Ana Dashboard & Kartlar
                mainContentView
            }

            // Sağ Alt Köşe: Yeniden Boyutlandırma Tutamacı (Resize Grip)
            resizeHandle
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                // Temel Frosted Glass Katmanı
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)

                // Light / Dark Zemin Renk Tonlaması (Şeffaf Frosted Glass)
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        isDark ?
                        Color.black.opacity(0.38) :
                        Color.white.opacity(0.35)
                    )

                // Işık Yansımalı Gradient Kenarlık
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: isDark ?
                            [Color.white.opacity(0.28), Color.white.opacity(0.05)] :
                            [Color.white.opacity(0.8), Color.white.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                if !isShowingScratchpad {
                    isSearchFocused = true
                }
            }
        }
        .background {
            Button("") {
                isSearchFocused = true
            }
            .keyboardShortcut("f", modifiers: .command)
            .opacity(0)
        }
    }

    // MARK: - Sol Dikey Sidebar (Icon-Only)
    private var sidebarView: some View {
        VStack(spacing: 16) {
            // Üst İkon / Logo
            ZStack {
                if let logo = AppIconService.shared.appLogo() {
                    Image(nsImage: logo)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 38, height: 38)
                        .clipShape(Circle())
                        .shadow(color: Color.blue.opacity(0.35), radius: 6, x: 0, y: 2)
                } else {
                    Circle()
                        .fill(isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.06))
                        .frame(width: 40, height: 40)
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isDark ? .white : .black)
                }
            }
            .padding(.top, 14)

            Divider()
                .background(isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.08))
                .padding(.horizontal, 12)

            // Dikey Kategori İkonları
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(viewModel.groups) { group in
                        let isSelected = !isShowingClipboard && !isShowingScratchpad && searchText.isEmpty && viewModel.selectedGroup?.id == group.id
                        Button {
                            isShowingClipboard = false
                            isShowingScratchpad = false
                            searchText = ""
                            viewModel.selectGroup(group)
                        } label: {
                            sidebarIconButton(icon: group.icon, isSelected: isSelected)
                        }
                        .buttonStyle(.plain)
                        .help(group.name)
                    }

                    // Pano (Clipboard) Sekmesi
                    Button {
                        isShowingClipboard = true
                        isShowingScratchpad = false
                        searchText = ""
                        SystemActionService.shared.performHapticFeedback()
                    } label: {
                        sidebarIconButton(icon: "doc.on.clipboard.fill", isSelected: isShowingClipboard && searchText.isEmpty)
                    }
                    .buttonStyle(.plain)
                    .help(lang.tr("clipboard_help"))
                }
                .padding(.horizontal, 8)
            }

            Spacer()

            // Alt Araçlar: Tema Değiştirici, Ayarlar & Kapat
            VStack(spacing: 10) {
                // Tema Değiştirici (☀️ / 🌙)
                Button {
                    themeManager.toggleTheme()
                    SystemActionService.shared.performHapticFeedback()
                } label: {
                    ZStack {
                        Circle()
                            .fill(isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.06))
                            .frame(width: 36, height: 36)
                        Image(systemName: isDark ? "sun.max.fill" : "moon.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(isDark ? Color.yellow.opacity(0.9) : Color.indigo)
                    }
                }
                .buttonStyle(.plain)
                .help(isDark ? lang.tr("theme_toggle_help_light") : lang.tr("theme_toggle_help_dark"))

                // Ayarlar Butonu (⚙️)
                Button {
                    viewModel.onDismiss?()
                    SettingsWindowController.shared.showSettings()
                    SystemActionService.shared.performHapticFeedback()
                } label: {
                    ZStack {
                        Circle()
                            .fill(isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.06))
                            .frame(width: 36, height: 36)
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(isDark ? .white.opacity(0.75) : .black.opacity(0.65))
                    }
                }
                .buttonStyle(.plain)
                .help(lang.tr("settings_help"))

                // Kapat Butonu
                Button {
                    viewModel.onDismiss?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(isDark ? .white.opacity(0.45) : .black.opacity(0.40))
                }
                .buttonStyle(.plain)
                .help(lang.tr("close_help"))
                .padding(.bottom, 14)
            }
        }
        .frame(width: 66)
    }

    @ViewBuilder
    private func sidebarIconButton(icon: String, isSelected: Bool) -> some View {
        ZStack {
            if isSelected {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        isDark ?
                        Color.white.opacity(0.22) :
                        Color.black.opacity(0.10)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                isDark ? Color.white.opacity(0.3) : Color.black.opacity(0.15),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 2)
            }

            Image(systemName: icon)
                .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(
                    isSelected ?
                    (isDark ? .white : .black) :
                    (isDark ? .white.opacity(0.55) : .black.opacity(0.45))
                )
                .scaleEffect(isSelected ? 1.08 : 1.0)
        }
        .frame(width: 44, height: 44)
    }

    // MARK: - Sağ Ana İçerik Alanı (Dashboard)
    private var mainContentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Üst Kısım: Selamlaşma, Donanım Monitörü & Hızlı Sistem Aksiyonları
            dashboardHeaderView

            // Anlık Arama Çubuğu (Spotlight Search)
            searchBarView

            // İçerik: Arama Sonuçları VEYA Karalama Defteri VEYA Pano Görünümü VEYA Uygulamalar Izgarası
            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                searchResultsView
            } else if isShowingScratchpad {
                scratchpadView
            } else if isShowingClipboard {
                clipboardHistoryView
            } else {
                cardsGridView
            }

            Spacer(minLength: 0)
        }
        .padding(18)
    }

    // MARK: - Dashboard Header & Donanım Kapsülleri
    private var dashboardHeaderView: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greetingMessage)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(isDark ? .white : .black)

                Text(
                    !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (lang.currentLanguage == .turkish ? "Arama Sonuçları: \"\(searchText)\"" : "Search Results: \"\(searchText)\"") :
                    (isShowingScratchpad ? (lang.currentLanguage == .turkish ? "Hızlı Karalama Defteri (Notlar)" : "Quick Scratchpad (Notes)") :
                    (isShowingClipboard ? (lang.currentLanguage == .turkish ? "Pano Geçmişi (Clipboard)" : "Clipboard History") :
                    (viewModel.selectedGroup?.name ?? "Assistive Hub")))
                )
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isDark ? .white.opacity(0.60) : .black.opacity(0.55))
            }

            Spacer()

            // Canlı Donanım Monitörü (Pil, CPU, RAM)
            HStack(spacing: 6) {
                if let battery = sysMonitor.batteryPercentage {
                    hardwarePill(
                        icon: sysMonitor.isCharging ? "battery.100.bolt" : "battery.75",
                        text: "\(battery)%",
                        color: battery < 20 ? .red : (isDark ? .white : .black)
                    )
                }

                hardwarePill(
                    icon: "cpu",
                    text: "\(Int(sysMonitor.cpuUsage))%",
                    color: sysMonitor.cpuUsage > 75 ? .orange : (isDark ? .white : .black)
                )

                hardwarePill(
                    icon: "memorychip",
                    text: String(format: "%.1fG", sysMonitor.ramUsageGB),
                    color: isDark ? .white : .black
                )
            }

            // Hızlı Sistem Aksiyonları Mini Dock
            HStack(spacing: 8) {
                systemActionButton(
                    id: "scratchpad",
                    icon: "square.and.pencil",
                    title: isShowingScratchpad
                        ? (lang.currentLanguage == .turkish ? "Uygulamalara Dön" : "Back to Apps")
                        : (lang.currentLanguage == .turkish ? "Hızlı Karalama Defteri" : "Quick Scratchpad"),
                    isActive: isShowingScratchpad
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isShowingScratchpad.toggle()
                        if isShowingScratchpad {
                            isShowingClipboard = false
                            searchText = ""
                        }
                    }
                    SystemActionService.shared.performHapticFeedback()
                }

                systemActionButton(
                    id: "screenshot",
                    icon: "camera.viewfinder",
                    title: lang.currentLanguage == .turkish ? "Ekran Görüntüsü" : "Screenshot"
                ) {
                    viewModel.triggerScreenshot()
                }

                systemActionButton(
                    id: "lock",
                    icon: "lock.fill",
                    title: lang.currentLanguage == .turkish ? "Ekranı Kilitle" : "Lock Screen"
                ) {
                    viewModel.triggerLockScreen()
                }

                systemActionButton(
                    id: "mission",
                    icon: "macwindow.on.rectangle",
                    title: "Mission Control"
                ) {
                    viewModel.triggerMissionControl()
                }

                systemActionButton(
                    id: "mute",
                    icon: "speaker.slash.fill",
                    title: lang.currentLanguage == .turkish ? "Sesi Kapat / Aç" : "Toggle Mute"
                ) {
                    viewModel.triggerToggleMute()
                }

                systemActionButton(
                    id: "trash",
                    icon: "trash.fill",
                    title: lang.currentLanguage == .turkish ? "Çöp Sepetini Boşalt" : "Empty Trash"
                ) {
                    viewModel.triggerEmptyTrash()
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
            )
        }
    }

    @ViewBuilder
    private func hardwarePill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .medium))
            Text(text)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
        }
        .foregroundStyle(color.opacity(0.85))
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
        )
    }

    private var greetingMessage: String {
        userProfile.greetingMessage
    }

    // MARK: - Anlık Arama Çubuğu (Spotlight Search)
    private var searchBarView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(searchIconColor)

            TextField(
                lang.currentLanguage == .turkish
                    ? "Uygulama veya link ara... (Enter: Aç, Esc: Temizle)"
                    : "Search apps or links... (Return: Open, Esc: Clear)",
                text: $searchText
            )
            .textFieldStyle(.plain)
            .font(.system(size: 12))
                .focused($isSearchFocused)
                .onSubmit {
                    if let first = searchResults.first {
                        viewModel.launchApp(first.item)
                    }
                }
                .onExitCommand {
                    if !searchText.isEmpty {
                        searchText = ""
                    } else {
                        panel?.dismissPanel()
                    }
                }

            searchTrailingButton
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(searchBackground)
    }

    private var searchIconColor: Color {
        isDark ? Color.white.opacity(0.55) : Color.black.opacity(0.45)
    }

    @ViewBuilder
    private var searchTrailingButton: some View {
        if !searchText.isEmpty {
            Button {
                searchText = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        } else {
            Text("⌘F")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .foregroundStyle(.secondary)
        }
    }

    private var searchBackground: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.08), lineWidth: 1)
            )
    }

    // MARK: - Arama Sonuçları
    private var searchResults: [(item: AppItem, groupName: String, groupIcon: String)] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return [] }
        var results: [(item: AppItem, groupName: String, groupIcon: String)] = []
        for group in viewModel.groups {
            for item in group.items {
                if item.name.lowercased().contains(query) ||
                   item.bundleIdentifier.lowercased().contains(query) ||
                   (item.urlString?.lowercased().contains(query) ?? false) {
                    results.append((item: item, groupName: group.name, groupIcon: group.icon))
                }
            }
        }
        return results
    }

    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(searchResults.count) uygulama/link bulundu")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                if let first = searchResults.first {
                    HStack(spacing: 4) {
                        Text("⏎ Enter:")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                        Text(lang.currentLanguage == .turkish ? "\"\(first.item.name)\" başlat" : "Launch \"\(first.item.name)\"")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.18))
                    .clipShape(Capsule())
                    .foregroundStyle(.orange)
                }
            }

            if searchResults.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 30))
                        .foregroundStyle(.secondary.opacity(0.4))
                    Text(lang.currentLanguage == .turkish
                        ? "\"\(searchText)\" ile eşleşen öğe bulunamadı"
                        : "No items found matching \"\(searchText)\"")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: cardColumns, spacing: 14) {
                        ForEach(searchResults, id: \.item.id) { result in
                            VStack(spacing: 4) {
                                modernAppCard(for: result.item)
                                HStack(spacing: 3) {
                                    Image(systemName: result.groupIcon)
                                        .font(.system(size: 9))
                                    Text(result.groupName)
                                        .font(.system(size: 9, weight: .medium))
                                }
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Hızlı Karalama Defteri (Scratchpad View)
    private var scratchpadView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.orange)
                    Text(lang.tr("scratchpad_title"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isDark ? .white : .black)
                }

                Spacer()

                Text("\(scratchpad.text.count) \(lang.tr("scratchpad_chars"))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)

                Button {
                    scratchpad.appendTimestamp()
                } label: {
                    Label(lang.tr("scratchpad_add_time"), systemImage: "clock")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    scratchpad.copyToClipboard()
                    copiedFeedbackText = lang.tr("scratchpad_copied")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        copiedFeedbackText = nil
                    }
                } label: {
                    Label(lang.tr("scratchpad_copy"), systemImage: "doc.on.doc")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                if !scratchpad.text.isEmpty {
                    Button(role: .destructive) {
                        scratchpad.clear()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            if let feedback = copiedFeedbackText {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(feedback)
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.green.opacity(0.15)))
                .transition(.opacity.combined(with: .scale))
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isDark ? Color.white.opacity(0.05) : Color.white.opacity(0.60))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.08), lineWidth: 1)
                    )

                if scratchpad.text.isEmpty {
                    Text(lang.tr("scratchpad_placeholder"))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary.opacity(0.6))
                        .padding(14)
                }

                TextEditor(text: $scratchpad.text)
                    .font(.system(size: 12, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(8)
            }
            .frame(maxHeight: .infinity)
        }
    }

    // MARK: - Cards Grid (VisionOS / Glassmorphism Stili)
    @ViewBuilder
    private var cardsGridView: some View {
        if let currentGroup = viewModel.selectedGroup {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: cardColumns, spacing: 14) {
                    ForEach(currentGroup.items) { item in
                        modernAppCard(for: item)
                    }
                }
                .padding(.vertical, 4)
            }
        } else {
            Spacer()
            Text(lang.tr("no_category"))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Pano Geçmişi Görünümü (Clipboard History)
    private var clipboardHistoryView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(lang.tr("clipboard_header"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                if !clipboardMgr.history.isEmpty {
                    Button(lang.tr("clipboard_clear")) {
                        clipboardMgr.clearHistory()
                    }
                    .font(.system(size: 11))
                    .buttonStyle(.plain)
                    .foregroundStyle(.red.opacity(0.8))
                }
            }

            if clipboardMgr.history.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text(lang.tr("clipboard_empty"))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(lang.tr("clipboard_empty_desc"))
                        .font(.caption)
                        .foregroundStyle(.secondary.opacity(0.7))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(clipboardMgr.history, id: \.self) { text in
                            Button {
                                clipboardMgr.copyToClipboard(text: text)
                                copiedFeedbackText = text
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                    copiedFeedbackText = nil
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.accentColor)

                                    Text(text)
                                        .font(.system(size: 12))
                                        .foregroundStyle(isDark ? .white : .black)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)

                                    Spacer()

                                    if copiedFeedbackText == text {
                                        Text(lang.tr("copied_badge"))
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(.green)
                                    } else {
                                        Image(systemName: "arrow.right.doc.on.clipboard")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary.opacity(0.6))
                                    }
                                }
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(isDark ? Color.white.opacity(0.08) : Color.white.opacity(0.6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.06), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Modern Uygulama / Web Kartı
    @ViewBuilder
    private func modernAppCard(for item: AppItem) -> some View {
        let isHovered = hoveredItemId == item.id
        let isRunning = viewModel.isRunning(item)

        Button {
            viewModel.launchApp(item)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                // Üst Kısım: İkon ve Canlı Durum / Web Rozeti
                HStack(alignment: .top) {
                    Image(nsImage: AppIconService.shared.icon(for: item))
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 42, height: 42)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)

                    Spacer()

                    // Durum Rozeti (Canlı Yeşil Toggle veya Web Rozeti)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(item.isWebLink ? Color.blue : (isRunning ? Color(nsColor: .systemGreen) : Color.secondary.opacity(0.5)))
                            .frame(width: 7, height: 7)
                        Text(item.isWebLink ? "Web" : (isRunning ? (lang.currentLanguage == .turkish ? "Açık" : "Active") : (lang.currentLanguage == .turkish ? "Kapalı" : "Closed")))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(
                                item.isWebLink ?
                                Color.blue :
                                (isRunning ?
                                 (isDark ? Color.green.opacity(0.9) : Color.green) :
                                 (isDark ? Color.white.opacity(0.4) : Color.black.opacity(0.4)))
                            )
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(
                                item.isWebLink ?
                                Color.blue.opacity(isDark ? 0.18 : 0.12) :
                                (isRunning ?
                                 Color.green.opacity(isDark ? 0.18 : 0.12) :
                                 (isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04)))
                            )
                    )
                }

                // Alt Kısım: Uygulama Adı ve Tıklama Aksiyonu
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isDark ? .white : .black)
                        .lineLimit(1)

                    Text(item.isWebLink
                        ? (lang.currentLanguage == .turkish ? "Tarayıcıda aç" : "Open in browser")
                        : (isRunning
                            ? (lang.currentLanguage == .turkish ? "Pencereye geç" : "Focus window")
                            : (lang.currentLanguage == .turkish ? "Uygulamayı başlat" : "Launch app")))
                        .font(.system(size: 10))
                        .foregroundStyle(isDark ? .white.opacity(0.5) : .black.opacity(0.45))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            isDark ?
                            Color.white.opacity(isHovered ? 0.14 : 0.07) :
                            Color.white.opacity(isHovered ? 0.85 : 0.50)
                        )
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            isDark ?
                            Color.white.opacity(isHovered ? 0.30 : 0.12) :
                            Color.white.opacity(isHovered ? 0.80 : 0.40),
                            lineWidth: 1
                        )
                }
            )
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.65), value: isHovered)
            .shadow(color: Color.black.opacity(isDark ? 0.18 : 0.06), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .onHover { inside in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredItemId = inside ? item.id : nil
            }
            if inside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    // MARK: - Sistem Aksiyon Butonu
    @ViewBuilder
    private func systemActionButton(id: String, icon: String, title: String, isActive: Bool = false, action: @escaping () -> Void) -> some View {
        let isHovered = hoveredActionId == id

        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: isActive ? .bold : .medium))
                .foregroundStyle(
                    isActive ?
                    Color.orange :
                    (isHovered ?
                    (isDark ? .white : .black) :
                    (isDark ? .white.opacity(0.7) : .black.opacity(0.6)))
                )
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(
                            isActive ?
                            Color.orange.opacity(isDark ? 0.25 : 0.15) :
                            (isHovered ?
                            (isDark ? Color.white.opacity(0.22) : Color.black.opacity(0.12)) :
                            Color.clear)
                        )
                )
                .scaleEffect(isHovered ? 1.12 : (isActive ? 1.05 : 1.0))
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isHovered)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isActive)
        }
        .buttonStyle(.plain)
        .help(title)
        .onHover { inside in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredActionId = inside ? id : nil
            }
            if inside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    // MARK: - Resize Handle Grip
    private var resizeHandle: some View {
        Image(systemName: "arrow.down.right.and.arrow.up.left")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(isDark ? .white.opacity(0.35) : .black.opacity(0.25))
            .padding(10)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        let deltaX = value.translation.width - dragStartTranslation.width
                        let deltaY = value.translation.height - dragStartTranslation.height
                        dragStartTranslation = value.translation
                        panel?.resizeBy(deltaWidth: deltaX, deltaHeight: deltaY)
                    }
                    .onEnded { _ in
                        dragStartTranslation = .zero
                    }
            )
            .onHover { inside in
                if inside {
                    NSCursor.crosshair.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}
