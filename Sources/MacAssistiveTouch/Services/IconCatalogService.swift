import Foundation
import AppKit

public struct IconGroup: Identifiable {
    public let id: String
    public let titleTr: String
    public let titleEn: String
    public let icon: String
    public let symbols: [String]

    public func title(for language: AppLanguage) -> String {
        language == .turkish ? titleTr : titleEn
    }
}

public final class IconCatalogService {
    public static let shared = IconCatalogService()

    private init() {}

    /// Kategorilere ayrılmış 160+ zengin yerel SF Symbols
    public let categories: [IconGroup] = [
        IconGroup(
            id: "dev",
            titleTr: "Yazılım & Kod",
            titleEn: "Dev & Code",
            icon: "curlybraces",
            symbols: [
                "curlybraces", "terminal.fill", "chevron.left.forwardslash.chevron.right",
                "laptopcomputer", "desktopcomputer", "cpu", "memorychip",
                "server.rack", "network", "externaldrive.fill", "internaldrive",
                "opticaldiscdrive", "dot.radiowaves.left.and.right", "wifi",
                "antenna.radiowaves.left.and.right", "keyboard.fill", "macmini",
                "macpro.gen3", "display", "command", "option", "swift",
                "hammer.fill", "wrench.and.screwdriver.fill", "gearshape.2.fill"
            ]
        ),
        IconGroup(
            id: "productivity",
            titleTr: "İş & Üretkenlik",
            titleEn: "Productivity",
            icon: "briefcase.fill",
            symbols: [
                "briefcase.fill", "folder.fill", "doc.text.fill", "checklist",
                "calendar", "note.text", "book.fill", "bookmark.fill",
                "chart.bar.fill", "chart.pie.fill", "chart.line.uptrend.xyaxis",
                "creditcard.fill", "banknote.fill", "tray.full.fill", "paperplane.fill",
                "newspaper.fill", "archivebox.fill", "printer.fill", "square.and.pencil",
                "list.bullet.rectangle.portrait.fill", "clock.fill", "stopwatch.fill",
                "timer", "target", "checkmark.seal.fill"
            ]
        ),
        IconGroup(
            id: "design",
            titleTr: "Tasarım & Medya",
            titleEn: "Design & Media",
            icon: "paintpalette.fill",
            symbols: [
                "paintpalette.fill", "paintbrush.fill", "camera.fill", "camera.viewfinder",
                "video.fill", "film.fill", "photo.fill", "photo.on.rectangle.angled",
                "music.note", "music.quarternote.3", "waveform", "headphones",
                "speaker.wave.3.fill", "mic.fill", "wand.and.stars", "sparkles",
                "crop", "slider.horizontal.3", "eyedropper.halffull", "theatermasks.fill",
                "lightbulb.fill", "sun.max.fill", "moon.stars.fill", "prism"
            ]
        ),
        IconGroup(
            id: "communication",
            titleTr: "İletişim & Sosyal",
            titleEn: "Social & Web",
            icon: "bubble.left.and.bubble.right.fill",
            symbols: [
                "bubble.left.and.bubble.right.fill", "message.fill", "envelope.fill",
                "globe", "link", "network.badge.shield.half.filled", "phone.fill",
                "video.bubble.fill", "person.fill", "person.2.fill", "person.3.fill",
                "person.crop.circle.fill", "at", "bell.fill", "megaphone.fill",
                "quote.bubble.fill", "hand.thumbsup.fill", "heart.fill", "star.fill",
                "bookmark.circle.fill", "paperclip", "location.fill"
            ]
        ),
        IconGroup(
            id: "tools",
            titleTr: "Sistem & Araçlar",
            titleEn: "System & Tools",
            icon: "gearshape.fill",
            symbols: [
                "gearshape.fill", "wrench.adjustable.fill", "lock.fill", "key.fill",
                "shield.checkerboard", "bolt.fill", "battery.100.bolt", "gauge.with.needle.fill",
                "waveform.path.ecg", "cross.case.fill", "trash.fill", "shippingbox.fill",
                "arrow.triangle.2.circlepath", "magnifyingglass", "eye.fill", "power",
                "restart", "sleep", "macwindow", "macwindow.on.rectangle"
            ]
        ),
        IconGroup(
            id: "lifestyle",
            titleTr: "Yaşam & Eğlence",
            titleEn: "Lifestyle",
            icon: "gamecontroller.fill",
            symbols: [
                "gamecontroller.fill", "arcade.stick.console", "cup.and.saucer.fill",
                "mug.fill", "fork.knife", "cart.fill", "bag.fill", "airplane",
                "car.fill", "bicycle", "figure.walk", "figure.run", "flame.fill",
                "trophy.fill", "medal.fill", "gift.fill", "flag.fill", "crown.fill"
            ]
        )
    ]

    /// Tüm simgelerin tek bir listede birleşimi (Tekrarsız)
    public var allSymbols: [String] {
        var set = Set<String>()
        var list = [String]()
        for cat in categories {
            for sym in cat.symbols {
                if !set.contains(sym) {
                    set.insert(sym)
                    list.append(sym)
                }
            }
        }
        return list
    }

    /// Bir SF Symbol isminin macOS'ta geçerli olup olmadığını doğrular
    public func isValidSymbol(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return NSImage(systemSymbolName: trimmed, accessibilityDescription: nil) != nil
    }

    /// Arama sorgusuna göre simgeleri filtreler
    public func filter(query: String, categoryId: String? = nil) -> [String] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let baseList: [String]
        if let catId = categoryId, catId != "all", let group = categories.first(where: { $0.id == catId }) {
            baseList = group.symbols
        } else {
            baseList = allSymbols
        }

        if q.isEmpty {
            return baseList
        }

        return baseList.filter { symbol in
            symbol.lowercased().contains(q)
        }
    }
}
