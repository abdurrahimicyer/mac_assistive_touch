import AppKit
import SwiftUI
import Combine

@MainActor
public final class DynamicIslandViewModel: ObservableObject {
    public static let shared = DynamicIslandViewModel()

    @Published public var isExpanded: Bool = false
    @Published public var isPinned: Bool = false
    @Published public var isHovered: Bool = false
    @Published public var hasNotch: Bool = false
    @Published public var notchHeight: CGFloat = 38
    @Published public var notchWidth: CGFloat = 220

    private var collapseWorkItem: DispatchWorkItem?
    private var cancellables = Set<AnyCancellable>()
    weak var panel: DynamicIslandPanel?

    public init() {
        updateScreenGeometry()

        // Sayaç durumu değiştiğinde panel görünürlüğünü güncelle
        PomodoroService.shared.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.panel?.updatePanelPosition()
            }
            .store(in: &cancellables)
    }

    public func updateScreenGeometry() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let topInset = screen.safeAreaInsets.top
        self.hasNotch = topInset > 0
        self.notchHeight = topInset > 0 ? topInset : 38

        if let leftArea = screen.auxiliaryTopLeftArea, let rightArea = screen.auxiliaryTopRightArea {
            let width = rightArea.minX - leftArea.maxX
            if width > 50 {
                self.notchWidth = width
            }
        } else if topInset > 0 {
            self.notchWidth = 220
        }
    }

    public var shouldBeVisible: Bool {
        let pomodoro = PomodoroService.shared
        guard pomodoro.isDynamicIslandEnabled else { return false }
        if isExpanded || isPinned || isHovered { return true }
        if !pomodoro.isDynamicIslandAutoHide { return true }
        return pomodoro.state != .idle
    }

    public func onMouseEnter() {
        collapseWorkItem?.cancel()
        collapseWorkItem = nil
        isHovered = true
        panel?.updatePanelPosition()
    }

    public func onMouseExit() {
        collapseWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.isHovered = false
            if !self.isPinned && self.isExpanded {
                self.collapse()
            } else {
                self.panel?.updatePanelPosition()
            }
        }
        collapseWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: item)
    }

    public func togglePin() {
        isPinned.toggle()
        if isPinned && !isExpanded {
            expand()
        } else {
            panel?.updatePanelPosition()
        }
    }

    public func expand() {
        collapseWorkItem?.cancel()
        collapseWorkItem = nil
        panel?.prepareForExpansion()
        withAnimation(.spring(response: 0.36, dampingFraction: 0.78)) {
            isExpanded = true
        }
    }

    public func collapse() {
        collapseWorkItem?.cancel()
        collapseWorkItem = nil
        isPinned = false
        withAnimation(.spring(response: 0.36, dampingFraction: 0.78)) {
            isExpanded = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) { [weak self] in
            guard let self = self, !self.isExpanded else { return }
            self.panel?.finishCollapse()
        }
    }
}
