import AppKit
import SwiftUI

public final class ActionHubPanel: NSPanel, NSWindowDelegate {
    private var globalClickMonitor: Any?
    private var localClickMonitor: Any?
    private weak var relatedOrbPanel: NSPanel?
    private let viewModel: ActionHubViewModel

    private static let defaultWidth: CGFloat = 620
    private static let defaultHeight: CGFloat = 420
    private static let minPanelWidth: CGFloat = 460
    private static let minPanelHeight: CGFloat = 340
    private static let maxPanelWidth: CGFloat = 850
    private static let maxPanelHeight: CGFloat = 700

    private let spacingFromOrb: CGFloat = 14

    public init(viewModel: ActionHubViewModel) {
        self.viewModel = viewModel

        let savedW = UserDefaults.standard.double(forKey: "ActionHubWidth")
        let savedH = UserDefaults.standard.double(forKey: "ActionHubHeight")
        let initialWidth = savedW >= Double(Self.minPanelWidth) ? CGFloat(savedW) : Self.defaultWidth
        let initialHeight = savedH >= Double(Self.minPanelHeight) ? CGFloat(savedH) : Self.defaultHeight

        let contentRect = NSRect(x: 0, y: 0, width: initialWidth, height: initialHeight)

        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )

        self.minSize = NSSize(width: Self.minPanelWidth, height: Self.minPanelHeight)
        self.maxSize = NSSize(width: Self.maxPanelWidth, height: Self.maxPanelHeight)

        self.level = .floating
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.becomesKeyOnlyIfNeeded = false
        self.delegate = self

        let hostingView = NSHostingView(rootView: ActionHubView(viewModel: viewModel, panel: self))
        hostingView.autoresizingMask = [.width, .height]
        hostingView.frame = contentRect
        self.contentView = hostingView

        viewModel.onDismiss = { [weak self] in
            self?.dismissPanel()
        }
    }

    public func showNear(orbPanel: NSPanel) {
        self.relatedOrbPanel = orbPanel
        viewModel.refreshRunningApps()
        viewModel.loadData()

        updatePosition(relativeTo: orbPanel)

        self.alphaValue = 0.0
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1.0
        }

        setupClickOutsideMonitors()
    }

    public func dismissPanel() {
        removeClickOutsideMonitors()

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            self?.orderOut(nil)
        })
    }

    public func updatePosition(relativeTo orbPanel: NSPanel) {
        let orbFrame = orbPanel.frame
        let screen = orbPanel.screen ?? NSScreen.main ?? NSScreen.screens.first
        guard let screen = screen else { return }

        let screenFrame = screen.visibleFrame
        let currentWidth = self.frame.width
        let currentHeight = self.frame.height

        // Yatay konum: Orb sağa daha yakınsa solunda aç, sola yakınsa sağında aç
        let distanceToLeft = abs(orbFrame.minX - screenFrame.minX)
        let distanceToRight = abs(screenFrame.maxX - orbFrame.maxX)

        let targetX: CGFloat
        if distanceToRight < distanceToLeft {
            targetX = orbFrame.minX - currentWidth - spacingFromOrb
        } else {
            targetX = orbFrame.maxX + spacingFromOrb
        }

        // Dikey konum: Orb ile dikeyde ortalanır ve ekran içinde tutulur
        let desiredY = orbFrame.midY - (currentHeight / 2)
        let minY = screenFrame.minY + 12
        let maxY = screenFrame.maxY - currentHeight - 12
        let targetY = min(max(desiredY, minY), maxY)

        self.setFrameOrigin(CGPoint(x: targetX, y: targetY))
    }

    public func resizeBy(deltaWidth: CGFloat, deltaHeight: CGFloat) {
        let currentFrame = self.frame
        let newWidth = min(max(currentFrame.width + deltaWidth, Self.minPanelWidth), Self.maxPanelWidth)
        let newHeight = min(max(currentFrame.height + deltaHeight, Self.minPanelHeight), Self.maxPanelHeight)

        let heightDiff = newHeight - currentFrame.height
        let newOriginY = currentFrame.origin.y - heightDiff

        let newFrame = NSRect(
            x: currentFrame.origin.x,
            y: newOriginY,
            width: newWidth,
            height: newHeight
        )
        self.setFrame(newFrame, display: true)
        saveCurrentSize()
    }

    private func saveCurrentSize() {
        UserDefaults.standard.set(Double(self.frame.width), forKey: "ActionHubWidth")
        UserDefaults.standard.set(Double(self.frame.height), forKey: "ActionHubHeight")
    }

    // MARK: - NSWindowDelegate
    public func windowDidResize(_ notification: Notification) {
        saveCurrentSize()
    }

    private func setupClickOutsideMonitors() {
        removeClickOutsideMonitors()

        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.handleOutsideClick()
            }
        }

        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return event }
            let clickLocation = NSEvent.mouseLocation
            if !self.frame.contains(clickLocation) && !(self.relatedOrbPanel?.frame.contains(clickLocation) ?? false) {
                self.dismissPanel()
            }
            return event
        }
    }

    private func handleOutsideClick() {
        let mouseLoc = NSEvent.mouseLocation
        if !self.frame.contains(mouseLoc) && !(self.relatedOrbPanel?.frame.contains(mouseLoc) ?? false) {
            dismissPanel()
        }
    }

    private func removeClickOutsideMonitors() {
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
        if let monitor = localClickMonitor {
            NSEvent.removeMonitor(monitor)
            localClickMonitor = nil
        }
    }

    override public var canBecomeKey: Bool {
        true
    }

    override public var canBecomeMain: Bool {
        true
    }
}
