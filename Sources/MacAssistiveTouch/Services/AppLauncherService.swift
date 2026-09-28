import AppKit

@MainActor
public final class AppLauncherService {
    public static let shared = AppLauncherService()

    private init() {}

    public func launch(item: AppItem, completion: (@Sendable (Bool) -> Void)? = nil) {
        // 0. Web Bağlantısı ise varsayılan tarayıcıda aç
        if item.isWebLink, let urlString = item.urlString, let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
            completion?(true)
            return
        }

        // 1. Zaten çalışıyor mu kontrol et
        let runningApps = NSWorkspace.shared.runningApplications
        if let running = runningApps.first(where: {
            $0.bundleIdentifier == item.bundleIdentifier ||
            ($0.localizedName?.localizedCaseInsensitiveContains(item.name) == true)
        }) {
            running.activate(options: [.activateAllWindows])
            completion?(true)
            return
        }

        // 2. Doğrudan path üzerinden aç
        if let path = item.path, FileManager.default.fileExists(atPath: path) {
            let url = URL(fileURLWithPath: path)
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true

            NSWorkspace.shared.openApplication(at: url, configuration: config) { _, error in
                if let error = error {
                    print("❌ [AppLauncherService] Uygulama açılamadı (\(path)): \(error.localizedDescription)")
                    completion?(false)
                } else {
                    completion?(true)
                }
            }
            return
        }

        // 3. Bundle identifier üzerinden aç
        if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: item.bundleIdentifier) {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true

            NSWorkspace.shared.openApplication(at: appUrl, configuration: config) { _, error in
                if let error = error {
                    print("❌ [AppLauncherService] Uygulama açılamadı (\(item.bundleIdentifier)): \(error.localizedDescription)")
                    completion?(false)
                } else {
                    completion?(true)
                }
            }
            return
        }

        // 4. Son çare URL scheme / isim üzerinden açmayı dene
        if let appUrl = NSWorkspace.shared.urlForApplication(toOpen: URL(fileURLWithPath: "/Applications/\(item.name).app")) {
            NSWorkspace.shared.openApplication(at: appUrl, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
            completion?(true)
            return
        }

        print("⚠️ [AppLauncherService] Uygulama bulunamadı: \(item.name)")
        completion?(false)
    }
}
