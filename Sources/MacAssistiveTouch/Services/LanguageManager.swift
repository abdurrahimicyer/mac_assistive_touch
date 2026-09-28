import Foundation
import SwiftUI

public enum AppLanguage: String, CaseIterable, Identifiable {
    case turkish = "tr"
    case english = "en"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .turkish: return "Türkçe"
        case .english: return "English"
        }
    }

    public var flag: String {
        switch self {
        case .turkish: return "🇹🇷"
        case .english: return "🇬🇧"
        }
    }
}

public final class LanguageManager: ObservableObject {
    public static let shared = LanguageManager()

    private let storageKey = "selected_app_language"

    @Published public var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: storageKey)
        }
    }

    private init() {
        if let saved = UserDefaults.standard.string(forKey: storageKey),
           let lang = AppLanguage(rawValue: saved) {
            self.currentLanguage = lang
        } else {
            // Sistem dili kontrolü (Türkçe değilse varsayılan English)
            let locale = Locale.current.language.languageCode?.identifier ?? "tr"
            self.currentLanguage = locale.hasPrefix("tr") ? .turkish : .english
        }
    }

    public func setLanguage(_ lang: AppLanguage) {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentLanguage = lang
        }
    }

    /// Çoklu dil metin çevirisi
    public func tr(_ key: String) -> String {
        let isTr = currentLanguage == .turkish
        if let pair = translations[key] {
            return isTr ? pair.0 : pair.1
        }
        return key
    }

    // MARK: - Çeviri Sözlüğü (TR, EN)
    private let translations: [String: (String, String)] = [
        // Sidebar & Sekmeler
        "tab_categories": ("Kategoriler & Uygulamalar", "Categories & Apps"),
        "tab_categories_sub": ("Uygulama gruplarını, bağlantıları ve sıralamayı yönetin.", "Manage application groups, web links and order."),
        "tab_appearance": ("Görünüm & Stil", "Appearance & Style"),
        "tab_appearance_sub": ("Temayı, dili, yüzen butonu ve kullanıcı selamlaşmasını özelleştirin.", "Customize theme, language, floating orb and user greeting."),
        "tab_gestures": ("Jestler & Kısayollar", "Gestures & Shortcuts"),
        "tab_gestures_sub": ("Klavye kısayolları ve dokunma jestlerinin tam rehberi.", "Complete guide to keyboard shortcuts and touch gestures."),
        "tab_about": ("Hakkında", "About"),
        "tab_about_sub": ("Geliştirici bilgileri, iletişim ve kullanılan teknolojiler.", "Developer info, contact and tech stack."),

        // Pencere & Başlıklar
        "settings_title": ("Ayarlar & Tercihler", "Settings & Preferences"),
        "app_title": ("Mac Assistive Touch", "Mac Assistive Touch"),

        // Dil Seçimi
        "language_section": ("Uygulama Dili", "Application Language"),
        "language_subtitle": ("Tüm arayüz metinleri seçilen dile göre anında güncellenir.", "All interface texts will be updated instantly."),

        // Görünüm Ayarları
        "theme_section": ("Görsel Tema", "Visual Theme"),
        "theme_light": ("Açık Buzul", "Light Glass"),
        "theme_light_desc": ("Ultra saydam buzul beyazı cam malzeme.", "Ultra-translucent frosted glass material."),
        "theme_dark": ("Karanlık Obsidyen", "Dark Obsidian"),
        "theme_dark_desc": ("Derin siyah ve zarif yarı saydam cam yüzey.", "Deep obsidian black and elegant glass finish."),

        "orb_section": ("Yüzen Buton (Orb) Davranışı", "Floating Orb Behavior"),
        "orb_size": ("Buton Boyutu", "Orb Size"),
        "orb_opacity": ("Bekleme Opaklığı", "Idle Opacity"),
        "orb_idle_delay": ("Rölantiye Geçiş Süresi", "Idle Delay"),
        "orb_edge_snap": ("Kenara Yaklaşınca Gizlen (Hide & Peek)", "Hide & Peek at Screen Edge"),
        "orb_edge_snap_desc": ("Buton ekran kenarına yaklaştığında ince bir şerit olarak gizlenir; fareyle üzerine gelince hemen açılır.", "Orb docks into a thin strip at screen edges; hovers expand it instantly."),
        "orb_preview": ("Canlı Orb Önizlemesi", "Live Orb Preview"),

        "greeting_section": ("Kullanıcı Karşılama İsmi", "User Greeting Name"),
        "greeting_desc": ("Ana panel açıldığında günün saatine göre hitap edilecek isim.", "Name to greet you with when the main panel opens."),
        "greeting_placeholder": ("İsminiz (Boşsa macOS kullanıcı adı)", "Your name (Defaults to macOS user)"),
        "greeting_sample": ("Örnek Karşılama:", "Greeting Preview:"),

        "system_section": ("Sistem Tercihleri", "System Preferences"),
        "launch_at_login": ("Bilgisayar Açılışında Otomatik Başlat", "Launch at System Login"),
        "launch_at_login_desc": ("macOS başladığında Mac Assistive Touch arka planda hazır beklesin.", "Run Mac Assistive Touch automatically on system boot."),

        // Kategori Yönetimi
        "categories_header": ("Kategoriler", "Categories"),
        "category_name": ("Kategori Adı", "Category Name"),
        "add_web_link": ("Web Linki", "Web Link"),
        "add_app": ("Uygulama Ekle", "Add App"),
        "select_category_prompt": ("Bir kategori seçin veya yeni ekleyin.", "Select a category or add a new one."),
        "empty_category": ("Bu grupta henüz uygulama yok.", "No applications in this group yet."),
        "drag_drop_apps": ("Uygulamaları buraya sürükleyip bırakabilir veya '+ Uygulama Ekle' butonuna basabilirsiniz.", "Drag & drop applications here or click '+ Add App'."),
        "new_group_default": ("Yeni Grup", "New Group"),
        "new_category_title": ("Yeni Kategori Oluştur", "Create New Category"),
        "add_button": ("Ekle", "Add"),
        "cancel_button": ("İptal", "Cancel"),
        "choose_icon": ("Simge Seç:", "Choose Icon:"),
        "add_weblink_title": ("Web Bağlantısı Ekle", "Add Web Link"),
        "title_placeholder": ("Başlık (örn. GitHub, ChatGPT)", "Title (e.g. GitHub, ChatGPT)"),
        "url_placeholder": ("URL (örn. https://github.com)", "URL (e.g. https://github.com)"),

        // Jestler & Kısayollar
        "gestures_touch_title": ("Fare & Dokunma Jestleri", "Mouse & Touch Gestures"),
        "gesture_single_click": ("Tek Tıklama", "Single Click"),
        "gesture_single_click_desc": ("Yüzen butona sol tıklayarak ana panel launcher'ını açıp kapatın.", "Left-click floating orb to toggle the main launcher panel."),
        "gesture_drag": ("Sürükle & Bırak", "Drag & Drop"),
        "gesture_drag_desc": ("Butonu ekranın dilediğiniz köşesine veya kenarına özgürce taşıyın.", "Freely move the orb to any edge or corner of your screen."),
        "gesture_hide_peek": ("Kenara Gömül & Canlan (Hide & Peek)", "Hide & Peek at Screen Edge"),
        "gesture_hide_peek_desc": ("Butonu ekran kenarına bıraktığınızda rölantide gizlenir, fareyi kenara getirince anında görünür.", "Docks at screen border when idle; hovers expand it with zero lag."),
        "gesture_right_click": ("İkincil / Sağ Tıklama", "Right / Secondary Click"),
        "gesture_right_click_desc": ("Hızlı kilit veya menü işlemini tetikler.", "Triggers fast lock or contextual menu actions."),

        "shortcuts_keyboard_title": ("Klavye Kısayolları", "Keyboard Shortcuts"),
        "shortcut_hotkey": ("Global Panel Kısayolu", "Global Panel Hotkey"),
        "shortcut_search": ("Spotlight Hızlı Arama", "Spotlight Quick Search"),
        "shortcut_search_desc": ("Panel açıkken doğrudan arama alanına odaklanır.", "Focuses search field immediately when panel is open."),
        "shortcut_esc": ("Paneli Kapat / Temizle", "Close Panel / Clear"),
        "shortcut_esc_desc": ("Arama kutusunu temizler veya açık paneli hemen gizler.", "Clears search box or dismisses the open panel."),
        "shortcut_scratchpad": ("Karalama Defteri (Notlar)", "Quick Scratchpad (Notes)"),
        "shortcut_scratchpad_desc": ("Sağ üst hızlı işlemler çubuğundaki not simgesiyle anlık karalama açılır.", "Top-right quick action mini dock icon to capture instant notes."),

        // Hakkında
        "about_devs_header": ("Geliştirici Ekip & Mimari", "Developer Team & Architecture"),
        "about_contact_header": ("Resmi İletişim & Web", "Official Contact & Web"),
        "about_tech_header": ("Kullanılan Teknolojiler & Altyapı", "Technologies Used & Architecture"),
        "about_version": ("Sürüm 1.0.0", "Version 1.0.0"),
        "about_os": ("macOS 14+ Sonoma & Sequoia", "macOS 14+ Sonoma & Sequoia"),
        "about_copyright": ("Copyright © 2026 Abdurrahim İçyer • Gratonya. Tüm hakları saklıdır.", "Copyright © 2026 Abdurrahim İçyer • Gratonya. All rights reserved."),

        // Action Hub & Panel
        "search_placeholder": ("Uygulama veya web bağlantısı ara... (⌘F)", "Search apps or web links... (⌘F)"),
        "search_input_prompt": ("Uygulama veya link ara... (Enter: Aç, Esc: Temizle)", "Search apps or links... (Return: Open, Esc: Clear)"),
        "search_results_prefix": ("Arama Sonuçları", "Search Results"),
        "all_apps_tab": ("Tümü", "All"),
        "quick_actions_header": ("Hızlı Eylemler", "Quick Actions"),
        "action_lock": ("Ekranı Kilitle", "Lock Screen"),
        "action_screenshot": ("Ekran Görüntüsü", "Screenshot"),
        "action_sleep": ("Uyut", "Sleep"),
        "action_mute": ("Sesi Kapat / Aç", "Toggle Mute"),
        "action_unmute": ("Sesi Aç", "Unmute"),
        "action_trash": ("Çöp Sepetini Boşalt", "Empty Trash"),
        "action_scratchpad": ("Karalama Defteri", "Scratchpad"),
        "action_back_apps": ("Uygulamalara Dön", "Back to Apps"),
        "hardware_battery": ("Pil", "Battery"),
        "hardware_cpu": ("CPU", "CPU"),
        "hardware_ram": ("RAM", "RAM"),
        "battery_charging": ("Şarjda", "Charging"),

        // Karalama Defteri (Scratchpad)
        "scratchpad_title": ("Karalama Defteri", "Quick Scratchpad"),
        "scratchpad_chars": ("karakter", "characters"),
        "scratchpad_add_time": ("Tarih Ekle", "Add Timestamp"),
        "scratchpad_copy": ("Panoya Al", "Copy to Clipboard"),
        "scratchpad_copied": ("Karalama panoya kopyalandı!", "Notes copied to clipboard!"),
        "scratchpad_placeholder": ("Aklınıza gelen fikirleri, geçici kod parçalarını veya telefon numaralarını buraya not alabilirsiniz. Otomatik olarak kaydedilir...", "Jot down ideas, code snippets or quick notes here. Automatically saved..."),

        // Pano Geçmişi (Clipboard History)
        "clipboard_header": ("Son Kopyalananlar (Tıklayarak Panoya Alın)", "Recent Clippings (Click to Copy)"),
        "clipboard_clear": ("Temizle", "Clear"),
        "clipboard_empty": ("Pano geçmişi boş.", "Clipboard history is empty."),
        "clipboard_empty_desc": ("Mac'inizde herhangi bir metin kopyaladığınızda burada listelenecektir.", "Text copied on your Mac will appear here."),
        "copied_badge": ("Kopyalandı!", "Copied!"),
        "clipboard_help": ("Pano Geçmişi (Clipboard)", "Clipboard History"),

        // Arama & Kenar Çubuğu
        "search_no_results": ("ile eşleşen öğe bulunamadı", "no items found matching"),
        "search_launch": ("başlat", "launch"),
        "no_category": ("Kategori bulunamadı", "No category found"),
        "settings_help": ("Ayarlar (Settings)", "Settings"),
        "close_help": ("Kapat", "Close"),
        "theme_toggle_help_light": ("Açık Mod (Light Mode)", "Light Mode"),
        "theme_toggle_help_dark": ("Koyu Mod (Dark Mode)", "Dark Mode"),
    ]
}

/// Global pratik fonksiyon
public func loc(_ key: String) -> String {
    LanguageManager.shared.tr(key)
}
