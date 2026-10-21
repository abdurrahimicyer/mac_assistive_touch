import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Gerçek Uygulama Ayarlar Ekranı (3-Kolonlu Stüdyo Düzeni)
public struct SettingsView: View {
    @StateObject private var categoryVM = CategoryManagementViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var lang = LanguageManager.shared
    @ObservedObject private var userProfile = UserProfileService.shared
    @ObservedObject private var launchService = LaunchAtLoginService.shared

    // Gerçek Ayarlar (AppStorage & UserDefaults)
    @AppStorage("OrbDimmedOpacity") private var orbDimmedOpacity: Double = 0.35
    @AppStorage("EnableMagneticSnap") private var enableMagneticSnap: Bool = true
    @AppStorage("EnableEdgeAutoHide") private var enableEdgeAutoHide: Bool = true

    // Sağ Kolon Aktif Sekme (0: Buton & Hareketler, 1: Tercihler, 2: Hakkında)
    @State private var inspectorTab: Int = 0

    // Kategori Ekleme Popover Durumu
    @State private var isShowingNewCategoryPopover: Bool = false
    @State private var newCategoryName: String = ""
    @State private var newCategoryIcon: String = "folder.fill"

    // Web Linki Ekleme Popover
    @State private var isShowingWebLinkPopover: Bool = false
    @State private var newWebLinkName: String = ""
    @State private var newWebLinkUrl: String = ""

    // Hover edilen öğe
    @State private var hoveredItemId: UUID? = nil

    // Sürüklenen Uygulama Öğesi (Reordering)
    @State private var draggedItem: AppItem? = nil

    private var isDark: Bool {
        themeManager.currentTheme == .dark
    }

    private var currentIdleDelay: Double {
        let saved = UserDefaults.standard.double(forKey: "OrbIdleDelay")
        return saved > 0 ? saved : 2.5
    }

    // Gerçek macOS Masaüstü Duvar Kağıdı
    private var desktopWallpaper: NSImage? {
        if let screen = NSScreen.main,
           let url = NSWorkspace.shared.desktopImageURL(for: screen),
           let img = NSImage(contentsOf: url) {
            return img
        }
        let fallbacks = [
            "/System/Library/Desktop Pictures/.thumbnails/Catalina Coast.heic",
            "/System/Library/Desktop Pictures/.thumbnails/Big Sur Mountains.heic",
            "/System/Library/Desktop Pictures/.thumbnails/Valley Light.heic"
        ]
        for path in fallbacks {
            if let img = NSImage(contentsOfFile: path) {
                return img
            }
        }
        return nil
    }

    public var body: some View {
        HStack(spacing: 0) {
            // ==========================================
            // 1. SOL KOLON: KATEGORİLER LİSTESİ
            // ==========================================
            categoriesSidebarColumn
                .frame(width: 250)
                .zIndex(2)

            // Dikey İnce Çizgi
            Rectangle()
                .fill(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                .frame(width: 1)
                .zIndex(2)

            // ==========================================
            // 2. ORTA KOLON: CANLI ÖNİZLEME & UYGULAMA SAHNESİ
            // ==========================================
            centerLiveStageColumn
                .frame(minWidth: 460, maxWidth: .infinity)
                .clipped()
                .zIndex(1)

            // Dikey İnce Çizgi
            Rectangle()
                .fill(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                .frame(width: 1)
                .zIndex(2)

            // ==========================================
            // 3. SAĞ KOLON: GERÇEK UYGULAMA AYARLARI
            // ==========================================
            settingsInspectorColumn
                .frame(width: 320)
                .zIndex(2)
        }
        .frame(minWidth: 1040, minHeight: 640)
        .background(isDark ? Color(white: 0.11) : Color(white: 0.95))
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }

    // =========================================================================
    // MARK: - 1. SOL KOLON (KATEGORİLER & KLASÖRLER)
    // =========================================================================
    private var categoriesSidebarColumn: some View {
        VStack(spacing: 0) {
            // Traffic lights için üst boşluk (Sol üstteki artı kaldırıldı)
            Spacer()
                .frame(height: 32)

            // Profil & Uygulama Başlık Kartı
            headerProfileCard
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            // Başlık: Kategorilerim
            HStack {
                Text(lang.tr("categories_header"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()

                Text("\(categoryVM.groups.count)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 8)

            // Kategoriler Listesi (Kaydırılabilir)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 4) {
                    ForEach(categoryVM.groups) { group in
                        categoryRow(group: group)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
            }

            Spacer(minLength: 0)

            // Alt Buton: Yeni Kategori Ekleme
            Button {
                newCategoryName = ""
                newCategoryIcon = "folder.fill"
                isShowingNewCategoryPopover = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.blue)
                    Text(lang.tr("add_new_category"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.blue)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(isDark ? Color.white.opacity(0.04) : Color.black.opacity(0.03))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $isShowingNewCategoryPopover, arrowEdge: .top) {
                newCategoryPopoverView
            }
        }
    }

    // Profil & Uygulama Kartı (Tek satır, taşma olmadan)
    private var headerProfileCard: some View {
        HStack(spacing: 10) {
            if let logo = AppIconService.shared.appLogo() {
                Image(nsImage: logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "circle.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.blue)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Mac Assistive Touch")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isDark ? .white : .black)
                    .lineLimit(1)

                Text("v1.1 • Abdurrahim İçyer")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isDark ? Color.white.opacity(0.06) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(isDark ? 0.2 : 0.04), radius: 4, x: 0, y: 1)
    }

    // Kategori Satırı (Tüm satır Button olarak tıklanabilir)
    private func categoryRow(group: AppGroup) -> some View {
        let isSelected = categoryVM.selectedGroupId == group.id
        return Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                categoryVM.selectedGroupId = group.id
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: group.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.blue : Color.secondary)
                    .frame(width: 22, height: 22)

                Text(group.name)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? (isDark ? Color.white : Color.black) : (isDark ? Color.white.opacity(0.85) : Color.black.opacity(0.85)))
                    .lineLimit(1)

                Spacer()

                Text("\(group.items.count)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isSelected ? Color.blue : Color.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.blue.opacity(0.18) : (isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isSelected ? (isDark ? Color.white.opacity(0.12) : Color.white) : (isDark ? Color.white.opacity(0.02) : Color.black.opacity(0.02)))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                categoryVM.deleteCategory(id: group.id)
            } label: {
                Label(lang.tr("delete_category"), systemImage: "trash")
            }
        }
    }

    // Yeni Kategori Ekleme Popover'ı (Doğrudan butona bağlı)
    private var newCategoryPopoverView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lang.tr("new_category_title"))
                .font(.system(size: 13, weight: .bold))

            TextField(lang.tr("category_name"), text: $newCategoryName)
                .textFieldStyle(.roundedBorder)

            VStack(alignment: .leading, spacing: 6) {
                Text(lang.tr("choose_icon"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: Array(repeating: GridItem(.fixed(26), spacing: 6), count: 6), spacing: 6) {
                    ForEach(["folder.fill", "star.fill", "heart.fill", "bolt.fill", "terminal.fill", "globe", "cpu", "paintbrush.fill", "music.note", "camera.fill", "gamecontroller.fill", "briefcase.fill"], id: \.self) { icon in
                        Button {
                            newCategoryIcon = icon
                        } label: {
                            Image(systemName: icon)
                                .font(.system(size: 12))
                                .foregroundStyle(newCategoryIcon == icon ? Color.white : Color.primary)
                                .frame(width: 26, height: 26)
                                .background(newCategoryIcon == icon ? Color.blue : (isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.06)))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                Button(lang.tr("cancel_button")) {
                    isShowingNewCategoryPopover = false
                }
                .buttonStyle(.plain)

                Spacer()

                Button(lang.tr("add_button")) {
                    let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        categoryVM.addCategory(name: trimmed, icon: newCategoryIcon)
                        isShowingNewCategoryPopover = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(14)
        .frame(width: 240)
    }

    // =========================================================================
    // MARK: - 2. ORTA KOLON (CANLI ÖNİZLEME & KATEGORİ UYGULAMALARI)
    // =========================================================================
    private var centerLiveStageColumn: some View {
        GeometryReader { geo in
            ZStack {
                // Sahne Arka Planı (Masaüstü Duvar Kağıdı veya Şık Degrade)
                wallpaperBackgroundView
                    .frame(width: geo.size.width - 24, height: geo.size.height - 24)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)

                VStack(spacing: 12) {
                    // Sahne Üst Barı: Kategori Başlığı ve Tema Düğmesi
                    HStack {
                        // Seçili Kategori Rozeti
                        if let group = categoryVM.selectedGroup {
                            HStack(spacing: 6) {
                                Image(systemName: group.icon)
                                    .font(.system(size: 12, weight: .bold))
                                Text(group.name)
                                    .font(.system(size: 12, weight: .bold))
                                Text("(\(group.items.count))")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }

                        Spacer()

                        // Sağ Üst: Tema Değiştirme Butonu
                        Button {
                            themeManager.toggleTheme()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: isDark ? "moon.fill" : "sun.max.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(isDark ? .indigo : .orange)
                                Text(isDark ? lang.tr("theme_dark_short") : lang.tr("theme_light_short"))
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 24)

                    Spacer(minLength: 4)

                    // ============================================
                    // MERKEZ: SEÇİLİ KATEGORİNİN GERÇEK UYGULAMALARI
                    // ============================================
                    realCategoryAppsPopup
                        .padding(.horizontal, 20)

                    Spacer(minLength: 4)

                    // ============================================
                    // EYLEM DÜĞMELERİ: UYGULAMA VE LİNK EKLE
                    // ============================================
                    HStack(spacing: 12) {
                        Button {
                            categoryVM.pickAndAddApp()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 12, weight: .bold))
                                Text(lang.tr("btn_add_app"))
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .clipShape(Capsule())
                            .shadow(color: Color.blue.opacity(0.35), radius: 6, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)

                        Button {
                            newWebLinkName = ""
                            newWebLinkUrl = ""
                            isShowingWebLinkPopover = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "link.badge.plus")
                                    .font(.system(size: 12, weight: .bold))
                                Text(lang.tr("add_web_link"))
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.65))
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $isShowingWebLinkPopover, arrowEdge: .top) {
                            newWebLinkPopoverView
                        }
                    }

                    // ============================================
                    // ALT BÖLÜM: GERÇEK FLOATING ORB ÖNİZLEMESİ
                    // ============================================
                    VStack(spacing: 4) {
                        liveOrbPreviewWidget
                            .opacity(orbDimmedOpacity)

                        Text("\(lang.tr("live_idle_opacity_prefix")) %\(Int(orbDimmedOpacity * 100)))")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white)
                            .shadow(color: Color.black.opacity(0.8), radius: 2, x: 0, y: 1)
                    }
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onDrop(of: [UTType.text], isTargeted: nil) { _ in
                draggedItem = nil
                categoryVM.save()
                return true
            }
        }
    }

    // Sahne Arkaplanı
    private var wallpaperBackgroundView: some View {
        ZStack {
            if let img = desktopWallpaper {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.15, green: 0.28, blue: 0.52),
                        Color(red: 0.22, green: 0.45, blue: 0.65),
                        Color(red: 0.35, green: 0.62, blue: 0.72)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .clipped()
    }

    // Seçili Kategorinin Gerçek Uygulamaları Cam Kartı
    private var realCategoryAppsPopup: some View {
        let items = categoryVM.selectedGroup?.items ?? []

        return VStack(spacing: 12) {
            if items.isEmpty {
                // Boş Durum
                VStack(spacing: 8) {
                    Image(systemName: "plus.app.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.7))

                    Text(lang.tr("empty_category"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(lang.tr("empty_category_sub"))
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.vertical, 40)
            } else {
                // Uygulamalar Izgarası (Gerçek İkonlar ve Başlıklar)
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ],
                        spacing: 16
                    ) {
                        ForEach(items) { item in
                            appItemCell(item: item)
                        }
                    }
                    .padding(18)
                    .background(HiddenScrollViewScroller())
                }
                .scrollIndicators(.hidden)
                .frame(maxHeight: 360)
            }
        }
        .frame(maxWidth: 480)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isDark ? Color.black.opacity(0.40) : Color.white.opacity(0.25))

                // Üst Işıma Yansıması (Glossy)
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.25), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.5), Color.white.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.black.opacity(0.25), radius: 14, x: 0, y: 6)
        .onDrop(of: [UTType.text], isTargeted: nil) { _ in
            draggedItem = nil
            categoryVM.save()
            return true
        }
    }

    // Uygulama Hücresi (Sürükle & Bırak Destekli)
    private func appItemCell(item: AppItem) -> some View {
        let isHovered = hoveredItemId == item.id
        let isDragged = draggedItem?.id == item.id

        return VStack(spacing: 5) {
            ZStack(alignment: .topTrailing) {
                // Uygulamanın Gerçek macOS İkonu
                Image(nsImage: AppIconService.shared.icon(for: item))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)

                // Silme Çarpısı (Hover'da görünür, sürüklerken gizlenir)
                if isHovered && !isDragged {
                    Button {
                        categoryVM.removeApp(itemId: item.id)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.red)
                            .background(Color.white.clipShape(Circle()))
                    }
                    .buttonStyle(.plain)
                    .offset(x: 5, y: -5)
                }
            }

            Text(item.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .shadow(color: Color.black.opacity(0.8), radius: 2, x: 0, y: 1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .opacity(isDragged ? 0.35 : 1.0)
        .scaleEffect(isDragged ? 1.05 : 1.0)
        .contentShape(Rectangle())
        .onHover { h in
            hoveredItemId = h ? item.id : nil
        }
        .onDrag {
            self.draggedItem = item
            return NSItemProvider(object: item.id.uuidString as NSString)
        }
        .onDrop(of: [UTType.text], delegate: AppItemDropDelegate(
            targetItem: item,
            draggedItem: $draggedItem,
            categoryVM: categoryVM
        ))
    }

    // Canlı Floating Orb Önizlemesi
    private var liveOrbPreviewWidget: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isDark ? Color.black.opacity(0.55) : Color.white.opacity(0.65))
                )
                .frame(width: 46, height: 46)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)

            // İç İkili Minimalist Halka
            ZStack {
                Circle()
                    .stroke(isDark ? Color.white.opacity(0.9) : Color.black.opacity(0.9), lineWidth: 2)
                    .frame(width: 22, height: 22)

                Circle()
                    .stroke(isDark ? Color.white.opacity(0.9) : Color.black.opacity(0.9), lineWidth: 2)
                    .frame(width: 10, height: 10)
            }
        }
    }

    // Web Linki Popover
    private var newWebLinkPopoverView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lang.tr("add_weblink_title"))
                .font(.system(size: 13, weight: .bold))

            TextField(lang.tr("title_placeholder"), text: $newWebLinkName)
                .textFieldStyle(.roundedBorder)

            TextField(lang.tr("url_placeholder"), text: $newWebLinkUrl)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button(lang.tr("cancel_button")) {
                    isShowingWebLinkPopover = false
                }
                .buttonStyle(.plain)

                Spacer()

                Button(lang.tr("add_button")) {
                    let name = newWebLinkName.trimmingCharacters(in: .whitespacesAndNewlines)
                    let url = newWebLinkUrl.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !url.isEmpty {
                        categoryVM.addWebLink(name: name, urlString: url)
                        isShowingWebLinkPopover = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newWebLinkUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(14)
        .frame(width: 260)
    }

    // =========================================================================
    // MARK: - 3. SAĞ KOLON (GERÇEK UYGULAMA AYARLARI & MÜFETTİŞ)
    // =========================================================================
    private var settingsInspectorColumn: some View {
        VStack(spacing: 0) {
            // Üst Sekmeler: Buton | Tercihler | Hakkında (Eşit Dağılımlı & Çizgi Tabanlı)
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    inspectorTabButton(title: lang.tr("tab_orb"), index: 0)
                    inspectorTabButton(title: lang.tr("tab_preferences"), index: 1)
                    inspectorTabButton(title: lang.tr("tab_about_short"), index: 2)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Rectangle()
                    .fill(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                    .frame(height: 1)
            }
            .padding(.bottom, 14)

            // İçerik (Kaydırılabilir)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    if inspectorTab == 0 {
                        // SEKME 1: YÜZEN BUTON (ORB) VE HAREKETLER
                        orbAppearanceSection
                        orbSnapAndHideSection
                        gesturesSection
                    } else if inspectorTab == 1 {
                        // SEKME 2: TERCİHLER VE SİSTEM
                        themeSelectorSection
                        languageSelectorSection
                        systemLaunchAndProfileSection
                    } else {
                        // SEKME 3: HAKKINDA VE GELİŞTİRİCİ
                        developerAboutSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
    }

    private func inspectorTabButton(title: String, index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                inspectorTab = index
            }
        } label: {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 13, weight: inspectorTab == index ? .bold : .medium))
                    .foregroundStyle(inspectorTab == index ? (isDark ? .white : .black) : .secondary)

                Rectangle()
                    .fill(inspectorTab == index ? Color.blue : Color.clear)
                    .frame(height: 2.5)
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // SECTION: YÜZEN BUTON ŞEFFAFLIK VE GECİKME
    private var orbAppearanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(lang.tr("header_orb_appearance"))
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(0.5)

            VStack(spacing: 12) {
                // Rölanti Şeffaflığı Slider
                VStack(spacing: 6) {
                    HStack {
                        Text(lang.tr("orb_opacity"))
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Text("%\(Int(orbDimmedOpacity * 100))")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    Slider(value: $orbDimmedOpacity, in: 0.20...0.80, step: 0.05)
                        .accentColor(.blue)
                }

                Divider().background(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))

                // Rölantiye Geçiş Süresi Slider
                VStack(spacing: 6) {
                    HStack {
                        Text(lang.tr("orb_idle_delay"))
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Text(String(format: lang.tr("seconds_format"), currentIdleDelay))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    Slider(value: Binding(
                        get: { currentIdleDelay },
                        set: {
                            UserDefaults.standard.set($0, forKey: "OrbIdleDelay")
                            NotificationCenter.default.post(name: .autoHidePreferenceChanged, object: nil)
                        }
                    ), in: 1.0...8.0, step: 0.5)
                    .accentColor(.blue)
                }
            }
            .padding(12)
            .background(isDark ? Color.white.opacity(0.06) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06), lineWidth: 1)
            )
        }
    }

    // SECTION: MANYETİK VE GİZLEME TOGGLE'LARI
    private var orbSnapAndHideSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(lang.tr("header_behavior_smart_edge"))
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(0.5)

            VStack(spacing: 10) {
                // Manyetik Kenara Yapış
                Toggle(isOn: $enableMagneticSnap) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lang.tr("magnetic_snap"))
                            .font(.system(size: 12, weight: .medium))
                        Text(lang.tr("magnetic_snap_desc"))
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .blue))

                Divider().background(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))

                // Kenarda Otomatik Gizlenme
                Toggle(isOn: Binding(
                    get: { enableEdgeAutoHide },
                    set: {
                        enableEdgeAutoHide = $0
                        NotificationCenter.default.post(name: .autoHidePreferenceChanged, object: nil)
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lang.tr("auto_hide_peek"))
                            .font(.system(size: 12, weight: .medium))
                        Text(lang.tr("auto_hide_peek_desc"))
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .blue))
            }
            .padding(12)
            .background(isDark ? Color.white.opacity(0.06) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06), lineWidth: 1)
            )
        }
    }

    // SECTION: HAREKETLER & KISAYOLLAR
    private var gesturesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(lang.tr("header_gestures_shortcuts"))
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(0.5)

            VStack(spacing: 8) {
                gestureInfoRow(action: lang.tr("gesture_single_click_short"), desc: lang.tr("gesture_single_click_desc_short"), icon: "hand.tap.fill")
                gestureInfoRow(action: lang.tr("gesture_double_click"), desc: lang.tr("gesture_double_click_desc"), icon: "camera.fill")
                gestureInfoRow(action: lang.tr("gesture_long_press"), desc: lang.tr("gesture_long_press_desc"), icon: "lock.fill")
                gestureInfoRow(action: lang.tr("gesture_drag_short"), desc: lang.tr("gesture_drag_desc_short"), icon: "arrow.up.and.down.and.arrow.left.and.right")
                gestureInfoRow(action: lang.tr("gesture_shortcut"), desc: "⌥ Option + Space", icon: "keyboard.fill")
            }
            .padding(12)
            .background(isDark ? Color.white.opacity(0.06) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06), lineWidth: 1)
            )
        }
    }

    private func gestureInfoRow(action: String, desc: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 18)

            Text(action)
                .font(.system(size: 11, weight: .bold))

            Spacer()

            Text(desc)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    // SECTION: GÖRSEL TEMA (Light / Dark)
    private var themeSelectorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(lang.tr("theme_section_caps"))
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(0.5)

            HStack(spacing: 6) {
                themeButton(theme: .light, title: lang.tr("theme_light_btn"), icon: "sun.max.fill", color: .orange)
                themeButton(theme: .dark, title: lang.tr("theme_dark_btn"), icon: "moon.fill", color: .indigo)
            }
            .padding(4)
            .background(isDark ? Color.white.opacity(0.06) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06), lineWidth: 1)
            )
        }
    }

    private func themeButton(theme: AppTheme, title: String, icon: String, color: Color) -> some View {
        let isSelected = themeManager.currentTheme == theme
        return Button {
            withAnimation(.spring(response: 0.25)) {
                themeManager.currentTheme = theme
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)

                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? (isDark ? .white : .black) : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 2)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? (isDark ? Color.white.opacity(0.14) : Color.white) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: isSelected && !isDark ? Color.black.opacity(0.08) : Color.clear, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    // SECTION: UYGULAMA DİLİ
    private var languageSelectorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(lang.tr("app_language_caps"))
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(0.5)

            HStack(spacing: 6) {
                ForEach(AppLanguage.allCases) { item in
                    let isSelected = lang.currentLanguage == item
                    Button {
                        withAnimation {
                            lang.setLanguage(item)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(item.flag)
                                .font(.system(size: 13))
                            Text(item.displayName)
                                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? (isDark ? .white : .black) : .secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)

                            Spacer(minLength: 2)

                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(isSelected ? (isDark ? Color.white.opacity(0.14) : Color.white) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .shadow(color: isSelected && !isDark ? Color.black.opacity(0.08) : Color.clear, radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(isDark ? Color.white.opacity(0.06) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06), lineWidth: 1)
            )
        }
    }

    // SECTION: SİSTEM BAŞLANGICI VE KULLANICI PROFİLİ
    private var systemLaunchAndProfileSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(lang.tr("system_personalization_caps"))
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(0.5)

            VStack(spacing: 10) {
                // Girişte Başlat
                Toggle(isOn: Binding(
                    get: { launchService.isEnabled },
                    set: { launchService.setEnabled($0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lang.tr("launch_at_login"))
                            .font(.system(size: 12, weight: .medium))
                        Text(lang.tr("launch_at_login_sub"))
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .blue))

                Divider().background(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))

                // Hitap İsmi
                VStack(alignment: .leading, spacing: 4) {
                    Text(lang.tr("greeting_section"))
                        .font(.system(size: 12, weight: .medium))

                    TextField(UserProfileService.systemDefaultName, text: $userProfile.customName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                }
            }
            .padding(12)
            .background(isDark ? Color.white.opacity(0.06) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06), lineWidth: 1)
            )
        }
    }

    // SECTION: HAKKINDA & GELİŞTİRİCİ
    private var developerAboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(lang.tr("project_developer_caps"))
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(0.5)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.blue)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Abdurrahim İçyer")
                            .font(.system(size: 13, weight: .bold))
                        Text(lang.tr("developer_role"))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Divider().background(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))

                // Bağlantılar
                VStack(spacing: 8) {
                    linkRow(title: "abdurrahimicyer.com", url: "https://www.abdurrahimicyer.com", icon: "globe")
                    linkRow(title: "gratonya.com", url: "https://www.gratonya.com", icon: "building.2.fill")
                    linkRow(title: lang.tr("github_repo"), url: "https://github.com/abdurrahimicyer/mac_assistive_touch", icon: "chevron.left.forwardslash.chevron.right")
                    linkRow(title: "hello@gratonya.com", url: "mailto:hello@gratonya.com", icon: "envelope.fill")
                }

                Divider().background(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))

                HStack {
                    Text(lang.tr("license_title"))
                        .font(.system(size: 11, weight: .medium))
                    Spacer()
                    Text(lang.tr("mit_license"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.green)
                }
            }
            .padding(14)
            .background(isDark ? Color.white.opacity(0.06) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06), lineWidth: 1)
            )
        }
    }

    private func linkRow(title: String, url: String, icon: String) -> some View {
        Button {
            if let targetUrl = URL(string: url) {
                NSWorkspace.shared.open(targetUrl)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(.blue)
                    .frame(width: 16)

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isDark ? .white : .black)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sürükle & Bırak Sıralama Delegesi
struct AppItemDropDelegate: DropDelegate {
    let targetItem: AppItem
    @Binding var draggedItem: AppItem?
    let categoryVM: CategoryManagementViewModel

    func dropEntered(info: DropInfo) {
        guard let currentDragged = draggedItem,
              currentDragged.id != targetItem.id else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            categoryVM.moveItem(sourceId: currentDragged.id, destinationId: targetItem.id)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        categoryVM.save()
        return true
    }
}

// MARK: - ScrollView Kaydırma Çubuğunu Gizleyici
struct HiddenScrollViewScroller: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let scrollView = view.enclosingScrollView {
                scrollView.hasVerticalScroller = false
                scrollView.verticalScroller = nil
                scrollView.autohidesScrollers = true
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let scrollView = nsView.enclosingScrollView {
                scrollView.hasVerticalScroller = false
                scrollView.verticalScroller = nil
                scrollView.autohidesScrollers = true
            }
        }
    }
}
