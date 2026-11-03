import AppKit
import SwiftUI
import Combine

@MainActor
public final class DynamicIslandPanel: NSPanel {
    private var cancellables = Set<AnyCancellable>()
    private var screenChangeObserver: Any?
    private let viewModel = DynamicIslandViewModel.shared

    public init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 45),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .statusBar
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.becomesKeyOnlyIfNeeded = true
        self.acceptsMouseMovedEvents = true

        viewModel.panel = self
        viewModel.updateScreenGeometry()

        let hostingView = NSHostingView(rootView: DynamicIslandView(viewModel: viewModel))
        hostingView.autoresizingMask = [.width, .height]
        self.contentView = hostingView

        setupObservers()
        updatePanelPosition()
    }

    private func setupObservers() {
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.viewModel.updateScreenGeometry()
                self?.updatePanelPosition()
            }
        }

        NotificationCenter.default.publisher(for: .dynamicIslandVisibilityChanged)
            .sink { [weak self] _ in
                self?.updatePanelPosition()
            }
            .store(in: &cancellables)

        PomodoroService.shared.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updatePanelPosition()
            }
            .store(in: &cancellables)

        updatePanelPosition()
    }

    // MARK: - Frame Hesaplamaları

    public func hiddenTriggerFrame(screen: NSScreen) -> NSRect {
        let screenFrame = screen.frame
        let hasNotch = viewModel.hasNotch
        let notchHeight = viewModel.notchHeight
        let notchWidth = viewModel.notchWidth

        if hasNotch {
            let x = screenFrame.midX - (notchWidth / 2)
            let y = screenFrame.maxY - notchHeight
            return NSRect(x: x, y: y, width: notchWidth, height: notchHeight)
        } else {
            let width: CGFloat = 160
            let height: CGFloat = 3
            let x = screenFrame.midX - (width / 2)
            let y = screen.visibleFrame.maxY - height
            return NSRect(x: x, y: y, width: width, height: height)
        }
    }

    public func compactWingFrame(screen: NSScreen) -> NSRect {
        let screenFrame = screen.frame
        let hasNotch = viewModel.hasNotch
        let notchWidth = viewModel.notchWidth

        if hasNotch {
            let width: CGFloat = notchWidth + 130 // 220 + 130 = 350
            let height: CGFloat = 45
            let x = screenFrame.midX - (notchWidth / 2)
            let y = screenFrame.maxY - height
            return NSRect(x: x, y: y, width: width, height: height)
        } else {
            let width: CGFloat = 160
            let height: CGFloat = 45
            let x = screenFrame.midX - (width / 2)
            let y = screen.visibleFrame.maxY - height - 4
            return NSRect(x: x, y: y, width: width, height: height)
        }
    }

    public func expandedHUDFrame(screen: NSScreen) -> NSRect {
        let screenFrame = screen.frame
        let hasNotch = viewModel.hasNotch
        let notchHeight = viewModel.notchHeight
        let notchWidth = viewModel.notchWidth

        if hasNotch {
            let width: CGFloat = notchWidth + 130 // 350
            let height: CGFloat = notchHeight + 155 // 193
            let x = screenFrame.midX - (notchWidth / 2)
            let y = screenFrame.maxY - height
            return NSRect(x: x, y: y, width: width, height: height)
        } else {
            let width: CGFloat = 350
            let height: CGFloat = 160
            let x = screenFrame.midX - (width / 2)
            let y = screen.visibleFrame.maxY - height - 4
            return NSRect(x: x, y: y, width: width, height: height)
        }
    }

    public func targetFrame() -> NSRect {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            return NSRect(x: 100, y: 800, width: 350, height: 45)
        }

        if viewModel.isExpanded {
            return expandedHUDFrame(screen: screen)
        } else if viewModel.shouldBeVisible {
            return compactWingFrame(screen: screen)
        } else {
            return hiddenTriggerFrame(screen: screen)
        }
    }

    public func prepareForExpansion() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let frame = expandedHUDFrame(screen: screen)
        self.setFrame(frame, display: true)
    }

    public func finishCollapse() {
        updatePanelPosition()
    }

    public func updatePanelPosition() {
        let isEnabled = PomodoroService.shared.isDynamicIslandEnabled
        guard isEnabled else {
            self.orderOut(nil)
            return
        }

        let frame = targetFrame()
        self.setFrame(frame, display: true)
        self.orderFrontRegardless()
    }

    deinit {
        if let observer = screenChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
