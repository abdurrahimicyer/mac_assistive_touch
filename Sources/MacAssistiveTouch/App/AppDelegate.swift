import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var orbPanel: FloatingOrbPanel?
    private var orbViewModel: OrbViewModel?
    private var hubPanel: ActionHubPanel?
    private var hubViewModel: ActionHubViewModel?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Arka plan ajanı olarak çalıştır (Dock ikonu gizlenir)
        NSApp.setActivationPolicy(.accessory)

        setupStatusBarItem()
        setupOrbAndHubPanels()
        setupGlobalHotKey()
    }

    private func setupGlobalHotKey() {
        GlobalHotKeyService.shared.onHotKeyTriggered = { [weak self] in
            self?.toggleHub()
        }
        GlobalHotKeyService.shared.start()
    }

    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            let img = NSImage(systemSymbolName: "circle.circle", accessibilityDescription: "Mac Assistive Touch")
            img?.isTemplate = true
            button.image = img
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Mac Assistive Touch", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Menüyü Aç / Kapat (Toggle Hub)", action: #selector(toggleHub), keyEquivalent: "h"))
        menu.addItem(NSMenuItem(title: "Ayarlar... (Settings...)", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Konumu Sıfırla (Reset Position)", action: #selector(resetOrbPosition), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Çıkış (Quit)", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    private func setupOrbAndHubPanels() {
        let orbVM = OrbViewModel()
        self.orbViewModel = orbVM

        let orb = FloatingOrbPanel(viewModel: orbVM)
        self.orbPanel = orb

        let hubVM = ActionHubViewModel()
        self.hubViewModel = hubVM

        let hub = ActionHubPanel(viewModel: hubVM)
        self.hubPanel = hub

        // Menü açma/kapama koordinasyonu
        orbVM.onToggleMenu = { [weak self, weak orb, weak hub] in
            guard let self = self, let orb = orb, let hub = hub else { return }
            if hub.isVisible {
                hub.dismissPanel()
                self.orbViewModel?.isMenuPresented = false
            } else {
                hub.showNear(orbPanel: orb)
                self.orbViewModel?.isMenuPresented = true
            }
        }

        orbVM.onRequestDismissMenu = { [weak self, weak hub] in
            hub?.dismissPanel()
            self?.orbViewModel?.isMenuPresented = false
        }

        // Varsayılan başlangıç konumu: Ekranın sağ kenarı, dikeyde ortalanmış
        if let screen = NSScreen.main ?? NSScreen.screens.first {
            let visibleFrame = screen.visibleFrame
            let initialX = visibleFrame.maxX - 80
            let initialY = visibleFrame.midY - 34
            orb.setFrameOrigin(CGPoint(x: initialX, y: initialY))
        }

        orb.orderFrontRegardless()
    }

    @objc private func toggleHub() {
        orbViewModel?.toggleMenu()
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.showSettings()
    }

    @objc private func resetOrbPosition() {
        orbViewModel?.snapToNearestEdge()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
