import AppKit
import Foundation

@MainActor
public final class SystemActionService {
    public static let shared = SystemActionService()

    private init() {}

    // MARK: - Dokunsal Geri Bildirim (Haptic Feedback)
    public func performHapticFeedback() {
        NSHapticFeedbackManager.defaultPerformer.perform(
            .generic,
            performanceTime: .now
        )
    }

    // MARK: - Ekran Görüntüsü Alma (Screenshot)
    public func takeScreenshot() {
        performHapticFeedback()

        // 1. macOS Resmi Screenshot.app (Cmd + Shift + 5 GUI Aracı)
        let screenshotAppUrl = URL(fileURLWithPath: "/System/Applications/Utilities/Screenshot.app")
        if FileManager.default.fileExists(atPath: screenshotAppUrl.path) {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.openApplication(at: screenshotAppUrl, configuration: config) { _, error in
                if error != nil {
                    // Fallback: Terminal screencapture
                    self.runInteractiveScreencapture()
                }
            }
        } else {
            runInteractiveScreencapture()
        }
    }

    private nonisolated func runInteractiveScreencapture() {
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.3) {
            let desktopPath = (FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first?.path ?? "/tmp")
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
            let fileName = "Screenshot-\(dateFormatter.string(from: Date())).png"
            let targetPath = "\(desktopPath)/\(fileName)"

            let task = Process()
            task.launchPath = "/usr/sbin/screencapture"
            // -i: İnteraktif alan/pencere seçimi
            task.arguments = ["-i", targetPath]
            try? task.run()
        }
    }

    // MARK: - Ekranı Kilitle
    public func lockScreen() {
        performHapticFeedback()
        if let libHandle = dlopen("/System/Library/PrivateFrameworks/login.framework/Versions/Current/login", RTLD_LAZY) {
            defer { dlclose(libHandle) }
            if let sym = dlsym(libHandle, "SACLockScreenImmediate") {
                typealias SACLockScreenImmediateFunc = @convention(c) () -> Void
                let lockFunc = unsafeBitCast(sym, to: SACLockScreenImmediateFunc.self)
                lockFunc()
                return
            }
        }

        let script = "tell application \"System Events\" to key code 12 using {control down, command down}"
        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)
    }

    // MARK: - Mission Control
    public func openMissionControl() {
        performHapticFeedback()
        let missionControlUrl = URL(fileURLWithPath: "/System/Applications/Mission Control.app")
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: missionControlUrl, configuration: config, completionHandler: nil)
    }

    // MARK: - Çöp Sepetini Boşalt (Native FileManager ile İzin Sorunsuz)
    public func emptyTrash() {
        performHapticFeedback()

        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            if let trashUrl = fileManager.urls(for: .trashDirectory, in: .userDomainMask).first {
                do {
                    let items = try fileManager.contentsOfDirectory(at: trashUrl, includingPropertiesForKeys: nil)
                    for item in items {
                        try? fileManager.removeItem(at: item)
                    }
                    // Çöp boşaltma sesi
                    DispatchQueue.main.async {
                        NSSound(named: "Trash")?.play()
                    }
                } catch {
                    print("⚠️ [SystemActionService] Trash temizleme hatası: \(error.localizedDescription)")
                }
            }

            // Yedek Finder temizleme çağrısı
            let script = "tell application \"Finder\" to empty trash"
            var error: NSDictionary?
            NSAppleScript(source: script)?.executeAndReturnError(&error)
        }
    }

    // MARK: - Sesi Kapat / Aç
    public func toggleMute() {
        performHapticFeedback()
        DispatchQueue.global(qos: .userInitiated).async {
            let script = "set volume output muted not (output muted of (get volume settings))"
            var error: NSDictionary?
            NSAppleScript(source: script)?.executeAndReturnError(&error)
        }
    }
}
