import Foundation

public struct AppGroup: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var name: String
    public var icon: String
    public var items: [AppItem]

    public init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        items: [AppItem] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.items = items
    }
}
