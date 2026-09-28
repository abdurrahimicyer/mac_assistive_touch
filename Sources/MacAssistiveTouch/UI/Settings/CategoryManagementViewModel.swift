import SwiftUI
import AppKit
import UniformTypeIdentifiers

@MainActor
public final class CategoryManagementViewModel: ObservableObject {
    @Published public var groups: [AppGroup] = []
    @Published public var selectedGroupId: UUID?

    public var selectedGroup: AppGroup? {
        groups.first(where: { $0.id == selectedGroupId })
    }

    public init() {
        loadData()
    }

    public func loadData() {
        let loaded = ConfigStorageService.shared.loadGroups()
        self.groups = loaded
        if selectedGroupId == nil || !loaded.contains(where: { $0.id == selectedGroupId }) {
            self.selectedGroupId = loaded.first?.id
        }
    }

    public func save() {
        ConfigStorageService.shared.saveGroups(groups)
    }

    // MARK: - Kategori İşlemleri
    public func addCategory(name: String = "Yeni Grup", icon: String = "folder.fill") {
        let newGroup = AppGroup(
            name: name,
            icon: icon,
            items: []
        )
        groups.append(newGroup)
        selectedGroupId = newGroup.id
        save()
    }

    public func deleteCategory(id: UUID) {
        groups.removeAll(where: { $0.id == id })
        if selectedGroupId == id {
            selectedGroupId = groups.first?.id
        }
        save()
    }

    public func updateCategoryName(id: UUID, newName: String) {
        if let idx = groups.firstIndex(where: { $0.id == id }) {
            groups[idx].name = newName
            save()
        }
    }

    public func updateCategoryIcon(id: UUID, newIcon: String) {
        if let idx = groups.firstIndex(where: { $0.id == id }) {
            groups[idx].icon = newIcon
            save()
        }
    }

    // MARK: - Uygulama Ekleme & Çıkarma
    public func pickAndAddApp() {
        let panel = NSOpenPanel()
        panel.title = "Uygulama Seç"
        panel.prompt = "Ekle"
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.application]

        if panel.runModal() == .OK {
            for url in panel.urls {
                addApp(from: url)
            }
        }
    }

    public func addApp(from url: URL) {
        guard let currentGroupId = selectedGroupId,
              let groupIndex = groups.firstIndex(where: { $0.id == currentGroupId }) else {
            return
        }

        let bundle = Bundle(url: url)
        let bundleId = bundle?.bundleIdentifier ?? url.deletingPathExtension().lastPathComponent
        let displayName = FileManager.default.displayName(atPath: url.path)

        // Zaten ekli mi kontrol et
        if groups[groupIndex].items.contains(where: { $0.bundleIdentifier == bundleId || $0.path == url.path }) {
            return
        }

        let newItem = AppItem(
            name: displayName,
            bundleIdentifier: bundleId,
            path: url.path,
            iconFallback: "app.fill"
        )

        groups[groupIndex].items.append(newItem)
        save()
    }

    public func addWebLink(name: String, urlString: String) {
        guard let currentGroupId = selectedGroupId,
              let groupIndex = groups.firstIndex(where: { $0.id == currentGroupId }) else {
            return
        }

        var formattedUrl = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !formattedUrl.lowercased().hasPrefix("http://") && !formattedUrl.lowercased().hasPrefix("https://") {
            formattedUrl = "https://" + formattedUrl
        }

        let newItem = AppItem(
            name: name.isEmpty ? "Web Link" : name,
            bundleIdentifier: formattedUrl,
            path: nil,
            iconFallback: "globe",
            isWebLink: true,
            urlString: formattedUrl
        )

        groups[groupIndex].items.append(newItem)
        save()
    }

    public func removeApp(itemId: UUID) {
        guard let currentGroupId = selectedGroupId,
              let groupIndex = groups.firstIndex(where: { $0.id == currentGroupId }) else {
            return
        }
        groups[groupIndex].items.removeAll(where: { $0.id == itemId })
        save()
    }

    public func moveApp(fromOffsets: IndexSet, toOffset: Int) {
        guard let currentGroupId = selectedGroupId,
              let groupIndex = groups.firstIndex(where: { $0.id == currentGroupId }) else {
            return
        }
        groups[groupIndex].items.move(fromOffsets: fromOffsets, toOffset: toOffset)
        save()
    }
}
