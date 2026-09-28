import SwiftUI
import AppKit

@MainActor
public final class ActionHubViewModel: ObservableObject {
    @Published public var groups: [AppGroup] = []
    @Published public var selectedGroup: AppGroup?
    @Published public var runningBundleIds: Set<String> = []

    public var onDismiss: (() -> Void)?

    public init() {
        loadData()
        refreshRunningApps()

        // Canlı bildirim dinleyicisini bağla
        AppRunningMonitor.shared.onChange = { [weak self] in
            self?.refreshRunningApps()
        }

        NotificationCenter.default.addObserver(
            forName: .groupsDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.loadData()
            }
        }
    }

    public func loadData() {
        let loaded = ConfigStorageService.shared.loadGroups()
        self.groups = loaded
        if let currentId = self.selectedGroup?.id,
           let updatedCurrent = loaded.first(where: { $0.id == currentId }) {
            self.selectedGroup = updatedCurrent
        } else {
            self.selectedGroup = loaded.first
        }
    }

    public func selectGroup(_ group: AppGroup) {
        SystemActionService.shared.performHapticFeedback()
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedGroup = group
        }
    }

    public func refreshRunningApps() {
        let running = NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier }
        self.runningBundleIds = Set(running)
    }

    public func isRunning(_ item: AppItem) -> Bool {
        runningBundleIds.contains(item.bundleIdentifier)
    }

    public func launchApp(_ item: AppItem) {
        SystemActionService.shared.performHapticFeedback()
        AppLauncherService.shared.launch(item: item) { [weak self] _ in
            Task { @MainActor in
                self?.refreshRunningApps()
                self?.onDismiss?()
            }
        }
    }

    // MARK: - Hızlı Sistem Aksiyonları
    public func triggerScreenshot() {
        onDismiss?()
        SystemActionService.shared.takeScreenshot()
    }

    public func triggerLockScreen() {
        onDismiss?()
        SystemActionService.shared.lockScreen()
    }

    public func triggerMissionControl() {
        onDismiss?()
        SystemActionService.shared.openMissionControl()
    }

    public func triggerEmptyTrash() {
        SystemActionService.shared.emptyTrash()
    }

    public func triggerToggleMute() {
        SystemActionService.shared.toggleMute()
    }
}
