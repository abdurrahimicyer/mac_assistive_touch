import AppKit
import SwiftUI

@MainActor
public final class SettingsWindowController: NSObject, NSWindowDelegate {
    public static let shared = SettingsWindowController()

    private var settingsWindow: NSWindow?

    private override init() {
        super.init()
    }

    public func showSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "Mac Assistive Touch Studio"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = false
        window.minSize = NSSize(width: 1040, height: 640)
        window.center()
        window.setFrameAutosaveName("MacAssistiveTouchSettingsWindow")
        window.isReleasedWhenClosed = false
        window.delegate = self

        let hostingView = NSHostingView(rootView: SettingsView())
        window.contentView = hostingView

        self.settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func windowWillClose(_ notification: Notification) {
        settingsWindow = nil
    }
}
