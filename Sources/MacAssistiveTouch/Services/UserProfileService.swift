import Foundation
import AppKit

@MainActor
public final class UserProfileService: ObservableObject {
    public static let shared = UserProfileService()

    private let userDefaultsKey = "GreetingUserName"

    @Published public var customName: String {
        didSet {
            UserDefaults.standard.set(customName, forKey: userDefaultsKey)
            NotificationCenter.default.post(name: .userProfileChanged, object: nil)
        }
    }

    private init() {
        self.customName = UserDefaults.standard.string(forKey: userDefaultsKey) ?? ""
    }

    /// Sistemde oturum açmış kullanıcının varsayılan adı
    public static var systemDefaultName: String {
        let fullName = NSFullUserName().trimmingCharacters(in: .whitespacesAndNewlines)
        if !fullName.isEmpty {
            let first = fullName.components(separatedBy: " ").first ?? fullName
            if !first.isEmpty {
                return first
            }
        }
        let userName = NSUserName().trimmingCharacters(in: .whitespacesAndNewlines)
        if !userName.isEmpty {
            return userName.capitalized
        }
        return LanguageManager.shared.currentLanguage == .turkish ? "Dostum" : "Friend"
    }

    /// Ekranda gösterilecek aktif hitap ismi
    public var effectiveName: String {
        let trimmed = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? Self.systemDefaultName : trimmed
    }

    /// Günün saatine ve seçili dile göre sıcak selamlaşma mesajı
    public var greetingMessage: String {
        let isTr = LanguageManager.shared.currentLanguage == .turkish
        let hour = Calendar.current.component(.hour, from: Date())
        let prefix: String

        if isTr {
            switch hour {
            case 5..<12:
                prefix = "Günaydın"
            case 12..<18:
                prefix = "İyi günler"
            case 18..<24:
                prefix = "İyi akşamlar"
            default:
                prefix = "İyi geceler"
            }
        } else {
            switch hour {
            case 5..<12:
                prefix = "Good morning"
            case 12..<18:
                prefix = "Good afternoon"
            case 18..<24:
                prefix = "Good evening"
            default:
                prefix = "Good night"
            }
        }

        return "\(prefix), \(effectiveName) 👋"
    }

    /// İsmi varsayılan sistem adına sıfırla
    public func resetToSystemDefault() {
        customName = ""
    }
}
