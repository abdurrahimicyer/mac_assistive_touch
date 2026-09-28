import Foundation

public struct AppItem: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var name: String
    public var bundleIdentifier: String
    public var path: String?
    public var iconFallback: String
    public var isWebLink: Bool
    public var urlString: String?

    public init(
        id: UUID = UUID(),
        name: String,
        bundleIdentifier: String = "",
        path: String? = nil,
        iconFallback: String = "app.fill",
        isWebLink: Bool = false,
        urlString: String? = nil
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.path = path
        self.iconFallback = iconFallback
        self.isWebLink = isWebLink
        self.urlString = urlString
    }
}
