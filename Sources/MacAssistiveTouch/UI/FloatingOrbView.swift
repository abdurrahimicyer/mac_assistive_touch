import SwiftUI

struct FloatingOrbView: View {
    @ObservedObject var viewModel: OrbViewModel
    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var isActivelyDragging = false

    private let orbSize: CGFloat = 42.0
    private let cornerRadius: CGFloat = 13.0

    private var isDark: Bool {
        themeManager.currentTheme == .dark
    }

    var body: some View {
        ZStack {
            // Dış Gövde: Frosted Glass Squircle (Light / Dark Uyumlu)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            isDark ?
                            Color.black.opacity(viewModel.isMenuPresented ? 0.75 : 0.55) :
                            Color.white.opacity(viewModel.isMenuPresented ? 0.85 : 0.65)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            isDark ?
                            (viewModel.isMenuPresented ? Color.white.opacity(0.7) : Color.white.opacity(viewModel.isHovered ? 0.45 : 0.22)) :
                            (viewModel.isMenuPresented ? Color.black.opacity(0.40) : Color.black.opacity(viewModel.isHovered ? 0.25 : 0.12)),
                            lineWidth: viewModel.isMenuPresented ? 1.5 : 1.0
                        )
                )
                .shadow(color: Color.black.opacity(isDark ? 0.35 : 0.18), radius: 6, x: 0, y: 3)

            // İç Minimalist Çift Halka (Temaya Göre Beyaz / Koyu Kontrast)
            ZStack {
                // Dış Halka
                Circle()
                    .stroke(
                        (isDark ? Color.white : Color.black).opacity(viewModel.isMenuPresented ? 1.0 : 0.88),
                        lineWidth: 2.0
                    )
                    .frame(width: 24, height: 24)

                // İç Halka
                Circle()
                    .stroke(
                        (isDark ? Color.white : Color.black).opacity(viewModel.isMenuPresented ? 1.0 : 0.88),
                        lineWidth: 2.0
                    )
                    .frame(width: 11, height: 11)
            }
            .animation(.easeInOut(duration: 0.25), value: themeManager.currentTheme)
            .scaleEffect(
                viewModel.isDragging ? 0.90 : (
                    viewModel.isMenuPresented ? 1.10 : (
                        viewModel.isHovered ? 1.05 : 1.0
                    )
                )
            )
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: viewModel.isDragging)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: viewModel.isHovered)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: viewModel.isMenuPresented)
        }
        .frame(width: orbSize, height: orbSize)
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
        .opacity((viewModel.isDimmed && !viewModel.isMenuPresented) ? (viewModel.isPeekHidden ? 0.68 : 0.35) : 1.0)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isDimmed)
        .onHover { hovering in
            viewModel.setHovered(hovering)
        }
        .gesture(
            DragGesture(minimumDistance: 3, coordinateSpace: .global)
                .onChanged { gesture in
                    let distance = hypot(gesture.translation.width, gesture.translation.height)
                    if distance > 4 {
                        if !isActivelyDragging {
                            viewModel.onDragStarted()
                            isActivelyDragging = true
                        }
                        viewModel.onDragChanged(translation: gesture.translation)
                    }
                }
                .onEnded { gesture in
                    let distance = hypot(gesture.translation.width, gesture.translation.height)
                    if isActivelyDragging && distance > 4 {
                        viewModel.onDragEnded()
                        isActivelyDragging = false
                    } else {
                        isActivelyDragging = false
                    }
                }
        )
        // Uzun Basma = Ekranı Kilitle
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    if !isActivelyDragging {
                        viewModel.onLongPress()
                    }
                }
        )
        // Çift Tıklama = Ekran Görüntüsü
        .simultaneousGesture(
            TapGesture(count: 2)
                .onEnded {
                    if !isActivelyDragging {
                        viewModel.onDoubleTap()
                    }
                }
        )
        // Tek Tıklama = Menü Aç/Kapat (Debounce ile Çift Tıktan Ayrıştırılmış)
        .simultaneousGesture(
            TapGesture(count: 1)
                .onEnded {
                    if !isActivelyDragging {
                        viewModel.handleSingleTap()
                    }
                }
        )
    }
}
