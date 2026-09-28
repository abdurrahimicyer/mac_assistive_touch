import Foundation
import AppKit

@MainActor
public final class ScratchpadService: ObservableObject {
    public static let shared = ScratchpadService()

    private let userDefaultsKey = "QuickScratchpadContent"

    @Published public var text: String {
        didSet {
            UserDefaults.standard.set(text, forKey: userDefaultsKey)
        }
    }

    private init() {
        self.text = UserDefaults.standard.string(forKey: userDefaultsKey) ?? ""
    }

    public func clear() {
        self.text = ""
    }

    public func appendTimestamp() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        let timestamp = "\n--- \(formatter.string(from: Date())) ---\n"
        self.text += (self.text.isEmpty ? "" : "\n") + timestamp
    }

    public func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(self.text, forType: .string)
        SystemActionService.shared.performHapticFeedback()
    }
}
