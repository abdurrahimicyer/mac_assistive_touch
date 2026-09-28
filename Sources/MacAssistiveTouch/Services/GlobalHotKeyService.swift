import AppKit

@MainActor
public final class GlobalHotKeyService {
    public static let shared = GlobalHotKeyService()

    private var globalMonitor: Any?
    private var localMonitor: Any?
    public var onHotKeyTriggered: (() -> Void)?

    private init() {}

    public func start() {
        stop()

        // 1. Arka plandayken (diğer uygulamalardayken) Option + Space dinle
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .option && event.keyCode == 49 {
                Task { @MainActor in
                    self?.onHotKeyTriggered?()
                }
            }
        }

        // 2. Kendi pencerelerimiz ön plandayken Option + Space dinle
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .option && event.keyCode == 49 {
                self?.onHotKeyTriggered?()
                return nil // Event'i tüket
            }
            return event
        }
    }

    public func stop() {
        if let gm = globalMonitor {
            NSEvent.removeMonitor(gm)
            globalMonitor = nil
        }
        if let lm = localMonitor {
            NSEvent.removeMonitor(lm)
            localMonitor = nil
        }
    }
}
