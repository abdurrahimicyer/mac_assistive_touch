import SwiftUI
import AppKit

public struct IconPickerView: View {
    @Binding var selectedIcon: String
    var onSelect: ((String) -> Void)? = nil

    @ObservedObject private var lang = LanguageManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var searchQuery: String = ""
    @State private var selectedCategoryId: String = "all"
    @State private var customSymbolInput: String = ""

    private var isDark: Bool {
        themeManager.currentTheme == .dark
    }

    private let gridColumns = [
        GridItem(.adaptive(minimum: 40, maximum: 44), spacing: 8)
    ]

    public init(selectedIcon: Binding<String>, onSelect: ((String) -> Void)? = nil) {
        self._selectedIcon = selectedIcon
        self.onSelect = onSelect
    }

    private var currentCategoryTitle: String {
        if selectedCategoryId == "all" {
            return lang.currentLanguage == .turkish ? "Tümü" : "All"
        }
        if let cat = IconCatalogService.shared.categories.first(where: { $0.id == selectedCategoryId }) {
            return cat.title(for: lang.currentLanguage)
        }
        return lang.currentLanguage == .turkish ? "Tümü" : "All"
    }

    private var currentCategoryIcon: String {
        if selectedCategoryId == "all" {
            return "square.grid.2x2"
        }
        if let cat = IconCatalogService.shared.categories.first(where: { $0.id == selectedCategoryId }) {
            return cat.icon
        }
        return "square.grid.2x2"
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Üst Satır: Arama Kutusu + Kategori Dropdown Menüsü
            searchAndDropdownHeader

            Divider()
                .background(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))

            // İkonlar Izgarası
            symbolsGridView

            Divider()
                .background(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))

            // Özel SF Symbol İsmi Girişi
            customSymbolInputField
        }
    }

    // MARK: - Arama Kutusu ve Kategori Dropdown'ı Tek Satırda
    private var searchAndDropdownHeader: some View {
        HStack(spacing: 8) {
            // Sol: Arama Kutusu
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                TextField(
                    lang.currentLanguage == .turkish ? "Simge ara..." : "Search icon...",
                    text: $searchQuery
                )
                .textFieldStyle(.plain)
                .font(.system(size: 11))

                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
            )

            // Sağ: Kategori Dropdown Menüsü
            Menu {
                Button {
                    selectedCategoryId = "all"
                    SystemActionService.shared.performHapticFeedback()
                } label: {
                    Label(
                        lang.currentLanguage == .turkish ? "Tüm Simgeler (160+)" : "All Symbols (160+)",
                        systemImage: "square.grid.2x2"
                    )
                }

                Divider()

                ForEach(IconCatalogService.shared.categories) { cat in
                    Button {
                        selectedCategoryId = cat.id
                        SystemActionService.shared.performHapticFeedback()
                    } label: {
                        Label(cat.title(for: lang.currentLanguage), systemImage: cat.icon)
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: currentCategoryIcon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.accentColor)

                    Text(currentCategoryTitle)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.08), lineWidth: 0.5)
                )
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }

    // MARK: - İkonlar Izgarası
    private var symbolsGridView: some View {
        let symbols = IconCatalogService.shared.filter(
            query: searchQuery,
            categoryId: selectedCategoryId
        )

        return ScrollView(.vertical, showsIndicators: true) {
            if symbols.isEmpty {
                VStack(spacing: 8) {
                    Spacer(minLength: 35)
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text(lang.currentLanguage == .turkish ? "Eşleşen simge bulunamadı." : "No matching icons found.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 35)
                }
                .frame(maxWidth: .infinity)
            } else {
                LazyVGrid(columns: gridColumns, spacing: 8) {
                    ForEach(symbols, id: \.self) { symbol in
                        let isSelected = selectedIcon == symbol

                        Button {
                            selectedIcon = symbol
                            onSelect?(symbol)
                            SystemActionService.shared.performHapticFeedback()
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(isSelected ? Color.accentColor.opacity(isDark ? 0.35 : 0.18) : (isDark ? Color.white.opacity(0.04) : Color.black.opacity(0.03)))

                                if isSelected {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color.accentColor, lineWidth: 1.5)
                                }

                                Image(systemName: symbol)
                                    .font(.system(size: 16))
                                    .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                            }
                            .frame(width: 40, height: 40)
                        }
                        .buttonStyle(.plain)
                        .help(symbol)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 2)
            }
        }
        .frame(height: 230)
    }

    // MARK: - Özel SF Symbol İsmi Girişi
    private var customSymbolInputField: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(lang.currentLanguage == .turkish ? "Veya özel SF Symbol girin:" : "Or enter custom SF Symbol:")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                if !selectedIcon.isEmpty {
                    HStack(spacing: 4) {
                        Text(lang.currentLanguage == .turkish ? "Seçili:" : "Selected:")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Image(systemName: selectedIcon)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("Örn: sparkles.tv, apple.terminal", text: $customSymbolInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))

                let isValid = IconCatalogService.shared.isValidSymbol(customSymbolInput)

                if isValid {
                    Image(systemName: customSymbolInput)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 20, height: 20)

                    Button(lang.currentLanguage == .turkish ? "Uygula" : "Apply") {
                        selectedIcon = customSymbolInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSelect?(selectedIcon)
                        customSymbolInput = ""
                        SystemActionService.shared.performHapticFeedback()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
    }
}
