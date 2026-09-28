import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
public final class AppIconService {
    public static let shared = AppIconService()

    private let cache = NSCache<NSString, NSImage>()

    private init() {}

    public func appLogo() -> NSImage? {
        if let resourcePath = Bundle.main.path(forResource: "AppLogo", ofType: "png"),
           let img = NSImage(contentsOfFile: resourcePath) {
            return img
        }
        let fallbackPaths = [
            "Sources/MacAssistiveTouch/Resources/AppLogo.png",
            "/Users/abdurrahimicyer/Desktop/repos/mac_assistive_touch/Sources/MacAssistiveTouch/Resources/AppLogo.png"
        ]
        for path in fallbackPaths {
            if let img = NSImage(contentsOfFile: path) {
                return img
            }
        }
        return nil
    }

    public func icon(for item: AppItem) -> NSImage {
        if item.isWebLink {
            let config = NSImage.SymbolConfiguration(pointSize: 32, weight: .regular)
            if let sym = NSImage(systemSymbolName: "globe", accessibilityDescription: "Web")?.withSymbolConfiguration(config) {
                return sym
            }
        }

        let key = (item.path ?? item.bundleIdentifier) as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        // 1. Doğrudan path verilmişse kontrol et
        if let path = item.path, FileManager.default.fileExists(atPath: path) {
            let icon = NSWorkspace.shared.icon(forFile: path)
            icon.size = NSSize(width: 64, height: 64)
            cache.setObject(icon, forKey: key)
            return icon
        }

        // 2. Bundle identifier üzerinden uygulama URL'si bul
        if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: item.bundleIdentifier) {
            let icon = NSWorkspace.shared.icon(forFile: appUrl.path)
            icon.size = NSSize(width: 64, height: 64)
            cache.setObject(icon, forKey: key)
            return icon
        }

        // 3. Bilinen genel yollarda isme göre ara (/Applications/Name.app)
        let standardPaths = [
            "/Applications/\(item.name).app",
            "/System/Applications/\(item.name).app",
            "/System/Applications/Utilities/\(item.name).app",
            "/Applications/Xcode.app",
            "/Applications/Visual Studio Code.app"
        ]

        for path in standardPaths {
            if FileManager.default.fileExists(atPath: path) {
                let icon = NSWorkspace.shared.icon(forFile: path)
                icon.size = NSSize(width: 64, height: 64)
                cache.setObject(icon, forKey: key)
                return icon
            }
        }

        // 4. Varsayılan sistem generic uygulama ikonu
        let genericIcon = NSWorkspace.shared.icon(for: .application)
        genericIcon.size = NSSize(width: 64, height: 64)
        return genericIcon
    }
}
