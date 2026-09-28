import ServiceManagement
import SwiftUI

@MainActor
public final class LaunchAtLoginService: ObservableObject {
    public static let shared = LaunchAtLoginService()

    @Published public var isEnabled: Bool = false

    private init() {
        self.isEnabled = (SMAppService.mainApp.status == .enabled)
    }

    public func setEnabled(_ enable: Bool) {
        do {
            if enable {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
            self.isEnabled = (SMAppService.mainApp.status == .enabled)
        } catch {
            print("⚠️ [LaunchAtLoginService] Durum güncellenemedi: \(error.localizedDescription)")
            self.isEnabled = (SMAppService.mainApp.status == .enabled)
        }
    }
}
