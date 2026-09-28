import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct CategoryManagementView: View {
    @ObservedObject var viewModel: CategoryManagementViewModel
    @ObservedObject private var lang = LanguageManager.shared

    @State private var isShowingNewCategoryPopover = false
    @State private var newCategoryName = ""
    @State private var newCategoryIcon = "folder.fill"
    @State private var isShowingIconPickerPopover = false
    @State private var isShowingWebLinkPopover = false
    @State private var newWebLinkName = ""
    @State private var newWebLinkUrl = ""
    @State private var isDropTargeted = false

    public var body: some View {
        HSplitView {
            // SOL: Kategoriler Listesi
            categoriesSidebar
                .frame(minWidth: 170, maxWidth: 220)

            // SAĞ: Seçili Kategori Detayı ve Uygulamalar
            if let group = viewModel.selectedGroup {
                categoryDetailView(group: group)
                    .frame(minWidth: 420)
            } else {
                VStack {
                    Spacer()
                    Text(lang.tr("select_category_prompt"))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(minWidth: 420)
            }
        }
    }

    // MARK: - Sol Sidebar
    private var categoriesSidebar: some View {
        VStack(spacing: 0) {
            List(selection: $viewModel.selectedGroupId) {
                Section(lang.tr("categories_header")) {
                    ForEach(viewModel.groups) { group in
                        HStack(spacing: 8) {
                            Image(systemName: group.icon)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 18)

                            Text(group.name)
                                .font(.system(size: 13, weight: .medium))

                            Spacer()

                            Text("\(group.items.count)")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.secondary.opacity(0.15)))
                        }
                        .tag(group.id)
                        .padding(.vertical, 2)
                    }
                }
            }
            .listStyle(.sidebar)

            Divider()

            // Ekle / Sil Butonları
            HStack(spacing: 12) {
                Button {
                    newCategoryName = "Yeni Grup"
                    newCategoryIcon = "folder.fill"
                    isShowingNewCategoryPopover = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
                .help("Yeni Kategori Ekle")
                .popover(isPresented: $isShowingNewCategoryPopover) {
                    newCategoryPopover
                }

                Button {
                    if let id = viewModel.selectedGroupId {
                        viewModel.deleteCategory(id: id)
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.groups.count <= 1 || viewModel.selectedGroupId == nil)
                .help("Seçili Kategoriyi Sil")

                Spacer()
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor))
        }
    }

    // MARK: - Yeni Kategori Popover
    private var newCategoryPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lang.tr("new_category_title"))
                .font(.headline)

            HStack(spacing: 10) {
                // Seçilen simgenin canlı önizlemesi
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: newCategoryIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }

                TextField(lang.tr("category_name"), text: $newCategoryName)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13, weight: .medium))
            }

            // Zengin İkon Seçici Bileşeni
            IconPickerView(selectedIcon: $newCategoryIcon)

            HStack {
                Spacer()
                Button(lang.tr("cancel_button")) {
                    isShowingNewCategoryPopover = false
                }
                Button(lang.tr("add_button")) {
                    viewModel.addCategory(
                        name: newCategoryName.isEmpty ? lang.tr("new_group_default") : newCategoryName,
                        icon: newCategoryIcon
                    )
                    isShowingNewCategoryPopover = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(14)
        .frame(width: 350)
    }

    // MARK: - Sağ Detay Görünümü
    @ViewBuilder
    private func categoryDetailView(group: AppGroup) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Kategori Bilgileri Düzenleme
            HStack(spacing: 10) {
                Button {
                    isShowingIconPickerPopover = true
                } label: {
                    Image(systemName: group.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 36, height: 36)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .help(lang.currentLanguage == .turkish ? "Simgeyi Değiştir" : "Change Icon")
                .popover(isPresented: $isShowingIconPickerPopover) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(lang.currentLanguage == .turkish ? "Kategori Simgesi Seç" : "Select Category Icon")
                            .font(.headline)
                        IconPickerView(selectedIcon: Binding(
                            get: { group.icon },
                            set: { viewModel.updateCategoryIcon(id: group.id, newIcon: $0) }
                        )) { _ in
                            isShowingIconPickerPopover = false
                        }
                    }
                    .padding(14)
                    .frame(width: 350)
                }

                TextField(lang.tr("category_name"), text: Binding(
                    get: { group.name },
                    set: { viewModel.updateCategoryName(id: group.id, newName: $0) }
                ))
                .textFieldStyle(.roundedBorder)
                .font(.title3.bold())
                .frame(maxWidth: 220)

                Spacer(minLength: 12)

                Button {
                    newWebLinkName = ""
                    newWebLinkUrl = ""
                    isShowingWebLinkPopover = true
                } label: {
                    Label(lang.tr("add_web_link"), systemImage: "globe")
                }
                .buttonStyle(.bordered)
                .fixedSize(horizontal: true, vertical: false)
                .popover(isPresented: $isShowingWebLinkPopover) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(lang.tr("add_weblink_title"))
                            .font(.headline)
                        TextField(lang.tr("title_placeholder"), text: $newWebLinkName)
                            .textFieldStyle(.roundedBorder)
                        TextField(lang.tr("url_placeholder"), text: $newWebLinkUrl)
                            .textFieldStyle(.roundedBorder)
                        HStack {
                            Spacer()
                            Button(lang.tr("cancel_button")) { isShowingWebLinkPopover = false }
                            Button(lang.tr("add_button")) {
                                if !newWebLinkUrl.isEmpty {
                                    viewModel.addWebLink(name: newWebLinkName, urlString: newWebLinkUrl)
                                }
                                isShowingWebLinkPopover = false
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(14)
                    .frame(width: 280)
                }

                Button {
                    viewModel.pickAndAddApp()
                } label: {
                    Label(lang.tr("add_app"), systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            Divider()

            // Uygulamalar Listesi
            if group.items.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary.opacity(0.6))
                    Text(lang.tr("empty_category"))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(lang.tr("drag_drop_apps"))
                        .font(.caption)
                        .foregroundStyle(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(group.items) { item in
                        HStack(spacing: 12) {
                            // Sıralama Tutamacı
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary.opacity(0.5))
                                .padding(.trailing, 2)

                            Image(nsImage: AppIconService.shared.icon(for: item))
                                .resizable()
                                .interpolation(.high)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.system(size: 13, weight: .semibold))
                                Text(item.path ?? item.bundleIdentifier)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }

                            Spacer()

                            Button {
                                viewModel.removeApp(itemId: item.id)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.red.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                            .help("Uygulamayı Gruptan Kaldır")
                        }
                        .padding(.vertical, 4)
                    }
                    .onMove { indices, newOffset in
                        viewModel.moveApp(fromOffsets: indices, toOffset: newOffset)
                    }
                }
                .listStyle(.inset)
            }
        }
        .background(isDropTargeted ? Color.accentColor.opacity(0.08) : Color.clear)
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
    }

    // MARK: - Drag & Drop İşleyicisi
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else {
                    if let url = item as? URL {
                        DispatchQueue.main.async {
                            if url.pathExtension == "app" {
                                self.viewModel.addApp(from: url)
                            }
                        }
                    }
                    return
                }

                DispatchQueue.main.async {
                    if url.pathExtension == "app" {
                        self.viewModel.addApp(from: url)
                    }
                }
            }
        }
        return true
    }
}
