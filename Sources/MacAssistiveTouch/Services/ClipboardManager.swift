import AppKit
import SwiftUI

@MainActor
public final class ClipboardManager: ObservableObject {
    public static let shared = ClipboardManager()

    @Published public var history: [String] = []

    private var lastChangeCount = 0
    private var timer: Timer?

    private init() {
        self.lastChangeCount = NSPasteboard.general.changeCount
        startMonitoring()
    }

    public func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkForNewItem()
            }
        }
    }

    private func checkForNewItem() {
        let currentCount = NSPasteboard.general.changeCount
        if currentCount != lastChangeCount {
            lastChangeCount = currentCount
            if let string = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !string.isEmpty {
                if !history.contains(string) {
                    history.insert(string, at: 0)
                    if history.count > 15 {
                        history.removeLast()
                    }
                }
            }
        }
    }

    public func copyToClipboard(text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        self.lastChangeCount = pb.changeCount
        SystemActionService.shared.performHapticFeedback()
    }

    public func clearHistory() {
        history.removeAll()
    }
}
