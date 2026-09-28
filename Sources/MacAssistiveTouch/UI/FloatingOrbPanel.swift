import AppKit
import SwiftUI

final class OrbHostingView: NSHostingView<FloatingOrbView> {
    weak var viewModel: OrbViewModel?
    private var trackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .mouseMoved,
            .activeAlways,
            .inVisibleRect
        ]
        let area = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(area)
        self.trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        viewModel?.onMouseEntered()
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        viewModel?.onMouseExited()
    }
}

final class FloatingOrbPanel: NSPanel {
    init(viewModel: OrbViewModel) {
        let contentRect = NSRect(x: 0, y: 0, width: 50, height: 50)

        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

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
        self.becomesKeyOnlyIfNeeded = true
        self.isMovableByWindowBackground = false
        self.acceptsMouseMovedEvents = true

        let hostingView = OrbHostingView(rootView: FloatingOrbView(viewModel: viewModel))
        hostingView.viewModel = viewModel
        hostingView.frame = contentRect
        self.contentView = hostingView

        viewModel.panel = self
    }

    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }
}
