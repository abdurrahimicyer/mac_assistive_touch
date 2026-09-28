import Foundation

public final class ConfigStorageService {
    public static let shared = ConfigStorageService()

    private let fileManager = FileManager.default
    private let configFileName = "groups.json"

    private var configDirectoryUrl: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("MacAssistiveTouch", isDirectory: true)
    }

    private var configFileUrl: URL {
        configDirectoryUrl.appendingPathComponent(configFileName)
    }

    private init() {}

    public func loadGroups() -> [AppGroup] {
        if fileManager.fileExists(atPath: configFileUrl.path) {
            do {
                let data = try Data(contentsOf: configFileUrl)
                let decoded = try JSONDecoder().decode([AppGroup].self, from: data)
                if !decoded.isEmpty {
                    return decoded
                }
            } catch {
                print("⚠️ [ConfigStorageService] Config yüklenemedi: \(error.localizedDescription)")
            }
        }

        // Varsayılan grupları oluştur ve kaydet
        let defaults = defaultGroups()
        saveGroups(defaults)
        return defaults
    }

    public func saveGroups(_ groups: [AppGroup]) {
        do {
            try fileManager.createDirectory(at: configDirectoryUrl, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(groups)
            try data.write(to: configFileUrl, options: .atomic)

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .groupsDidChange, object: nil)
            }
        } catch {
            print("❌ [ConfigStorageService] Config kaydedilemedi: \(error.localizedDescription)")
        }
    }

    public func defaultGroups() -> [AppGroup] {
        return [
            AppGroup(
                name: "Development",
                icon: "chevron.left.forwardslash.chevron.right",
                items: [
                    AppItem(
                        name: "VS Code",
                        bundleIdentifier: "com.microsoft.VSCode",
                        path: "/Applications/Visual Studio Code.app",
                        iconFallback: "hammer.fill"
                    ),
                    AppItem(
                        name: "Antigravity",
                        bundleIdentifier: "com.google.antigravity",
                        path: "/Applications/Antigravity.app",
                        iconFallback: "sparkles"
                    ),
                    AppItem(
                        name: "Xcode",
                        bundleIdentifier: "com.apple.dt.Xcode",
                        path: "/Applications/Xcode.app",
                        iconFallback: "hammer"
                    ),
                    AppItem(
                        name: "Terminal",
                        bundleIdentifier: "com.apple.Terminal",
                        path: "/System/Applications/Utilities/Terminal.app",
                        iconFallback: "terminal.fill"
                    ),
                    AppItem(
                        name: "iTerm",
                        bundleIdentifier: "com.googlecode.iterm2",
                        path: "/Applications/iTerm.app",
                        iconFallback: "terminal"
                    )
                ]
            ),
            AppGroup(
                name: "Productivity",
                icon: "briefcase.fill",
                items: [
                    AppItem(
                        name: "Safari",
                        bundleIdentifier: "com.apple.Safari",
                        path: "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app",
                        iconFallback: "safari.fill"
                    ),
                    AppItem(
                        name: "Notes",
                        bundleIdentifier: "com.apple.Notes",
                        path: "/System/Applications/Notes.app",
                        iconFallback: "note.text"
                    ),
                    AppItem(
                        name: "Calendar",
                        bundleIdentifier: "com.apple.iCal",
                        path: "/System/Applications/Calendar.app",
                        iconFallback: "calendar"
                    ),
                    AppItem(
                        name: "Reminders",
                        bundleIdentifier: "com.apple.reminders",
                        path: "/System/Applications/Reminders.app",
                        iconFallback: "checklist"
                    )
                ]
            ),
            AppGroup(
                name: "Utilities",
                icon: "wrench.and.screwdriver.fill",
                items: [
                    AppItem(
                        name: "Settings",
                        bundleIdentifier: "com.apple.systempreferences",
                        path: "/System/Applications/System Settings.app",
                        iconFallback: "gear"
                    ),
                    AppItem(
                        name: "Activity Monitor",
                        bundleIdentifier: "com.apple.ActivityMonitor",
                        path: "/System/Applications/Utilities/Activity Monitor.app",
                        iconFallback: "waveform.path.ecg"
                    ),
                    AppItem(
                        name: "Calculator",
                        bundleIdentifier: "com.apple.calculator",
                        path: "/System/Applications/Calculator.app",
                        iconFallback: "plus.forwardslash.minus"
                    ),
                    AppItem(
                        name: "Finder",
                        bundleIdentifier: "com.apple.finder",
                        path: "/System/Library/CoreServices/Finder.app",
                        iconFallback: "folder.fill"
                    )
                ]
            )
        ]
    }
}

extension Notification.Name {
    public static let groupsDidChange = Notification.Name("GroupsDidChangeNotification")
    public static let autoHidePreferenceChanged = Notification.Name("AutoHidePreferenceChangedNotification")
    public static let userProfileChanged = Notification.Name("UserProfileChangedNotification")
}
