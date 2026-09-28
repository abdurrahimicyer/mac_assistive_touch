import SwiftUI
import AppKit

@MainActor
public final class OrbViewModel: ObservableObject {
    @Published public var isHovered: Bool = false
    @Published public var isDragging: Bool = false
    @Published public var isDimmed: Bool = false
    @Published public var isMenuPresented: Bool = false
    @Published public var isPeekHidden: Bool = false

    public weak var panel: NSPanel?
    public var onToggleMenu: (() -> Void)?
    public var onRequestDismissMenu: (() -> Void)?

    private var idleTimer: Timer?
    private var idleDelay: TimeInterval {
        let saved = UserDefaults.standard.double(forKey: "OrbIdleDelay")
        return saved >= 1.0 ? saved : 2.5
    }
    private let margin: CGFloat = 8.0
    private var initialWindowOrigin: CGPoint = .zero

    private var isSnappedToLeft: Bool = false

    public init() {
        startIdleTimer()

        // Ayarlardan Auto-Hide açılıp kapandığında anında tepki ver
        NotificationCenter.default.addObserver(
            forName: .autoHidePreferenceChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                let isEnabled = UserDefaults.standard.bool(forKey: "EnableAutoHide")
                if !isEnabled && self.isPeekHidden {
                    self.unpeek(animated: true)
                    self.wakeUp(animated: true)
                } else if isEnabled {
                    self.startIdleTimer()
                }
            }
        }
    }

    public func onMouseEntered() {
        isHovered = true
        wakeUp(animated: true)
    }

    public func onMouseExited() {
        isHovered = false
        startIdleTimer()
    }

    public func setHovered(_ hovered: Bool) {
        if hovered {
            onMouseEntered()
        } else {
            onMouseExited()
        }
    }

    public func wakeUp(animated: Bool = true) {
        idleTimer?.invalidate()
        idleTimer = nil

        if isPeekHidden {
            unpeek(animated: animated)
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            isDimmed = false
        }
    }

    public func startIdleTimer() {
        idleTimer?.invalidate()
        guard !isDragging && !isHovered && !isMenuPresented else { return }

        idleTimer = Timer.scheduledTimer(withTimeInterval: idleDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                guard !self.isDragging && !self.isHovered && !self.isMenuPresented else { return }

                withAnimation(.easeInOut(duration: 0.5)) {
                    self.isDimmed = true
                }
                if UserDefaults.standard.bool(forKey: "EnableAutoHide") {
                    self.peek()
                }
            }
        }
    }

    public func onDragStarted() {
        wakeUp(animated: false)
        isDragging = true
        onRequestDismissMenu?()
        if let panel = panel {
            initialWindowOrigin = panel.frame.origin
        }
    }

    public func onDragChanged(translation: CGSize) {
        guard let panel = panel else { return }
        let newOrigin = CGPoint(
            x: initialWindowOrigin.x + translation.width,
            y: initialWindowOrigin.y - translation.height
        )
        panel.setFrameOrigin(newOrigin)
    }

    public func onDragEnded() {
        isDragging = false
        snapToNearestEdge()
        startIdleTimer()
    }

    public func snapToNearestEdge() {
        guard let panel = panel else { return }
        let currentScreen = panel.screen ?? NSScreen.main ?? NSScreen.screens.first
        guard let screen = currentScreen else { return }

        let screenFrame = screen.visibleFrame
        let orbFrame = panel.frame

        let distanceToLeft = abs(orbFrame.minX - screenFrame.minX)
        let distanceToRight = abs(screenFrame.maxX - orbFrame.maxX)

        let targetX: CGFloat
        if distanceToLeft < distanceToRight {
            targetX = screenFrame.minX + margin
            isSnappedToLeft = true
        } else {
            targetX = screenFrame.maxX - orbFrame.width - margin
            isSnappedToLeft = false
        }

        let minY = screenFrame.minY + margin
        let maxY = screenFrame.maxY - orbFrame.height - margin
        let targetY = min(max(orbFrame.minY, minY), maxY)

        let targetOrigin = CGPoint(x: targetX, y: targetY)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.28
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrameOrigin(targetOrigin)
        }
    }

    // MARK: - Peek & Hide (Kenara Gömülme & Çıkma)
    private func peek() {
        guard let panel = panel else { return }
        let currentScreen = panel.screen ?? NSScreen.main ?? NSScreen.screens.first
        guard let screen = currentScreen else { return }

        let screenFrame = screen.visibleFrame
        let orbFrame = panel.frame

        // Hangi kenara daha yakın olduğunu dinamik doğrula
        let distanceToLeft = abs(orbFrame.minX - screenFrame.minX)
        let distanceToRight = abs(screenFrame.maxX - orbFrame.maxX)
        isSnappedToLeft = (distanceToLeft < distanceToRight)

        // Ekranda rahatça dokunulabilecek şık 20pt genişliğinde bir tutamaç bırak
        let visibleTabWidth: CGFloat = 20.0
        let peekX: CGFloat
        if isSnappedToLeft {
            peekX = screenFrame.minX - (orbFrame.width - visibleTabWidth)
        } else {
            peekX = screenFrame.maxX - visibleTabWidth
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.35
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrameOrigin(CGPoint(x: peekX, y: panel.frame.origin.y))
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            self.isPeekHidden = true
        }
    }

    public func unpeek(animated: Bool = true) {
        guard isPeekHidden else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            self.isPeekHidden = false
        }

        guard let panel = panel else { return }
        let currentScreen = panel.screen ?? NSScreen.main ?? NSScreen.screens.first
        guard let screen = currentScreen else { return }

        let screenFrame = screen.visibleFrame
        let orbFrame = panel.frame

        let targetX: CGFloat = isSnappedToLeft ? (screenFrame.minX + margin) : (screenFrame.maxX - orbFrame.width - margin)
        let minY = screenFrame.minY + margin
        let maxY = screenFrame.maxY - orbFrame.height - margin
        let targetY = min(max(orbFrame.minY, minY), maxY)
        let targetOrigin = CGPoint(x: targetX, y: targetY)

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().setFrameOrigin(targetOrigin)
            }
        } else {
            panel.setFrameOrigin(targetOrigin)
        }
    }

    // MARK: - Jestler (Gestures)
    private var singleTapWorkItem: DispatchWorkItem?

    public func handleSingleTap() {
        if isPeekHidden {
            // Kenara saklanmışken dokunulduğunda doğrudan dışarı fırlasın ve uyansın
            unpeek(animated: true)
            wakeUp(animated: true)
            return
        }

        singleTapWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.toggleMenu()
            }
        }
        singleTapWorkItem = workItem
        // Çift tıklama eşiği: 0.22 saniye içinde ikinci tık gelmezse menüyü aç
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22, execute: workItem)
    }

    public func toggleMenu() {
        if isPeekHidden {
            unpeek(animated: false)
        }
        wakeUp(animated: false)
        onToggleMenu?()
    }

    public func onDoubleTap() {
        // Tek tık zamanlayıcısını iptal et -> Menü HİÇ AÇILMAZ!
        singleTapWorkItem?.cancel()
        singleTapWorkItem = nil

        // Menü zaten açıksa da derhal kapat
        onRequestDismissMenu?()

        wakeUp(animated: false)
        SystemActionService.shared.performHapticFeedback()

        // Menünün ekrandan tamamen kaybolması için 0.18 sn pay bırakıp ekran görüntüsünü tetikle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            SystemActionService.shared.takeScreenshot()
        }
    }

    public func onLongPress() {
        singleTapWorkItem?.cancel()
        singleTapWorkItem = nil

        wakeUp(animated: false)
        SystemActionService.shared.performHapticFeedback()
        SystemActionService.shared.lockScreen()
    }
}
