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
        menu.delegate = self
        statusItem?.menu = menu
        rebuildStatusMenu(menu)
    }

    private func rebuildStatusMenu(_ menu: NSMenu) {
        menu.removeAllItems()

        let titleItem = NSMenuItem(title: "Mac Assistive Touch", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(
            title: LanguageManager.shared.tr("menu_toggle_hub"),
            action: #selector(toggleHub),
            keyEquivalent: "h"
        ))

        let settingsItem = NSMenuItem(
            title: LanguageManager.shared.tr("menu_settings"),
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        if let settingsImg = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil) {
            settingsImg.isTemplate = true
            settingsItem.image = settingsImg
        }
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem(
            title: LanguageManager.shared.tr("menu_reset_position"),
            action: #selector(resetOrbPosition),
            keyEquivalent: "r"
        ))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(
            title: LanguageManager.shared.tr("menu_quit"),
            action: #selector(quitApp),
            keyEquivalent: "q"
        ))
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

// MARK: - Menü Çubuğu Dinamik Dil Güncellemesi
extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        rebuildStatusMenu(menu)
    }
}
