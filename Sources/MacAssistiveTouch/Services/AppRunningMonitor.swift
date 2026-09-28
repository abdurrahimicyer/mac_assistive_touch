import AppKit

public final class AppRunningMonitor: @unchecked Sendable {
    public static let shared = AppRunningMonitor()

    private let lock = NSLock()
    private var observers: [NSObjectProtocol] = []
    public var onChange: (@MainActor () -> Void)?

    private init() {
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    public func startMonitoring() {
        stopMonitoring()

        let center = NSWorkspace.shared.notificationCenter

        let launchObs = center.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.onChange?()
            }
        }

        let termObs = center.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.onChange?()
            }
        }

        lock.lock()
        observers = [launchObs, termObs]
        lock.unlock()
    }

    public func stopMonitoring() {
        lock.lock()
        let currentObservers = observers
        observers.removeAll()
        lock.unlock()

        for obs in currentObservers {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
        }
    }
}
