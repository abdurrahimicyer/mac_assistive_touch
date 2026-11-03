import Foundation
import Combine
import AppKit

public enum PomodoroPhase: String, CaseIterable, Codable {
    case focus
    case shortBreak
    case longBreak

    public var defaultMinutes: Int {
        switch self {
        case .focus: return 25
        case .shortBreak: return 5
        case .longBreak: return 15
        }
    }
}

public enum PomodoroState: Equatable {
    case idle
    case running
    case paused
}

@MainActor
public final class PomodoroService: ObservableObject {
    public static let shared = PomodoroService()

    // MARK: - Tercihler (UserDefaults)
    private let focusMinutesKey = "PomodoroFocusMinutes"
    private let shortBreakMinutesKey = "PomodoroShortBreakMinutes"
    private let longBreakMinutesKey = "PomodoroLongBreakMinutes"
    private let soundEnabledKey = "PomodoroSoundEnabled"
    private let dynamicIslandEnabledKey = "DynamicIslandEnabled"
    private let dynamicIslandAutoHideKey = "DynamicIslandAutoHide"

    @Published public var focusMinutes: Int {
        didSet {
            UserDefaults.standard.set(focusMinutes, forKey: focusMinutesKey)
            if state == .idle && phase == .focus {
                timeRemaining = TimeInterval(focusMinutes * 60)
                totalDuration = timeRemaining
            }
        }
    }

    @Published public var shortBreakMinutes: Int {
        didSet {
            UserDefaults.standard.set(shortBreakMinutes, forKey: shortBreakMinutesKey)
            if state == .idle && phase == .shortBreak {
                timeRemaining = TimeInterval(shortBreakMinutes * 60)
                totalDuration = timeRemaining
            }
        }
    }

    @Published public var longBreakMinutes: Int {
        didSet {
            UserDefaults.standard.set(longBreakMinutes, forKey: longBreakMinutesKey)
            if state == .idle && phase == .longBreak {
                timeRemaining = TimeInterval(longBreakMinutes * 60)
                totalDuration = timeRemaining
            }
        }
    }

    @Published public var isSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: soundEnabledKey)
        }
    }

    @Published public var isDynamicIslandEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isDynamicIslandEnabled, forKey: dynamicIslandEnabledKey)
            NotificationCenter.default.post(name: .dynamicIslandVisibilityChanged, object: nil)
        }
    }

    @Published public var isDynamicIslandAutoHide: Bool {
        didSet {
            UserDefaults.standard.set(isDynamicIslandAutoHide, forKey: dynamicIslandAutoHideKey)
            NotificationCenter.default.post(name: .dynamicIslandVisibilityChanged, object: nil)
        }
    }

    // MARK: - Aktif Sayaç Durumu
    @Published public var phase: PomodoroPhase = .focus
    @Published public var state: PomodoroState = .idle
    @Published public var timeRemaining: TimeInterval = 25 * 60
    @Published public var totalDuration: TimeInterval = 25 * 60
    @Published public var completedSessions: Int = 0

    private var timer: Timer?

    private init() {
        let savedFocus = UserDefaults.standard.integer(forKey: focusMinutesKey)
        self.focusMinutes = savedFocus > 0 ? savedFocus : 25

        let savedShort = UserDefaults.standard.integer(forKey: shortBreakMinutesKey)
        self.shortBreakMinutes = savedShort > 0 ? savedShort : 5

        let savedLong = UserDefaults.standard.integer(forKey: longBreakMinutesKey)
        self.longBreakMinutes = savedLong > 0 ? savedLong : 15

        if UserDefaults.standard.object(forKey: soundEnabledKey) != nil {
            self.isSoundEnabled = UserDefaults.standard.bool(forKey: soundEnabledKey)
        } else {
            self.isSoundEnabled = true
        }

        if UserDefaults.standard.object(forKey: dynamicIslandEnabledKey) != nil {
            self.isDynamicIslandEnabled = UserDefaults.standard.bool(forKey: dynamicIslandEnabledKey)
        } else {
            self.isDynamicIslandEnabled = false
        }

        if UserDefaults.standard.object(forKey: dynamicIslandAutoHideKey) != nil {
            self.isDynamicIslandAutoHide = UserDefaults.standard.bool(forKey: dynamicIslandAutoHideKey)
        } else {
            self.isDynamicIslandAutoHide = true
        }

        let initialSeconds = TimeInterval(self.focusMinutes * 60)
        self.timeRemaining = initialSeconds
        self.totalDuration = initialSeconds
    }

    // MARK: - İlerleme ve Formatlı Süre
    public var progress: Double {
        guard totalDuration > 0 else { return 0 }
        let elapsed = totalDuration - timeRemaining
        return min(max(elapsed / totalDuration, 0.0), 1.0)
    }

    public var formattedTime: String {
        let totalSec = max(Int(timeRemaining), 0)
        let min = totalSec / 60
        let sec = totalSec % 60
        return String(format: "%02d:%02d", min, sec)
    }

    // MARK: - Kontrol Metotları
    public func toggle() {
        switch state {
        case .idle, .paused:
            start()
        case .running:
            pause()
        }
    }

    public func start() {
        if state == .idle {
            setupDurationForCurrentPhase()
        }
        state = .running
        startTimer()
    }

    public func pause() {
        state = .paused
        timer?.invalidate()
        timer = nil
    }

    public func resume() {
        if state == .paused {
            state = .running
            startTimer()
        }
    }

    public func reset() {
        timer?.invalidate()
        timer = nil
        state = .idle
        setupDurationForCurrentPhase()
    }

    public func skip() {
        advanceToNextPhase()
    }

    public func selectPhase(_ newPhase: PomodoroPhase) {
        timer?.invalidate()
        timer = nil
        self.phase = newPhase
        self.state = .idle
        setupDurationForCurrentPhase()
    }

    // MARK: - Timer Döngüsü
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard state == .running else { return }

        if timeRemaining > 1 {
            timeRemaining -= 1
        } else {
            timeRemaining = 0
            timerCompleted()
        }
    }

    private func timerCompleted() {
        timer?.invalidate()
        timer = nil
        state = .idle

        if isSoundEnabled {
            playCompletionSound()
        }

        if phase == .focus {
            completedSessions += 1
        }

        advanceToNextPhase()
    }

    private func advanceToNextPhase() {
        timer?.invalidate()
        timer = nil
        state = .idle

        if phase == .focus {
            if completedSessions > 0 && completedSessions % 4 == 0 {
                phase = .longBreak
            } else {
                phase = .shortBreak
            }
        } else {
            phase = .focus
        }

        setupDurationForCurrentPhase()
    }

    private func setupDurationForCurrentPhase() {
        let minutes: Int
        switch phase {
        case .focus:
            minutes = focusMinutes
        case .shortBreak:
            minutes = shortBreakMinutes
        case .longBreak:
            minutes = longBreakMinutes
        }
        let sec = TimeInterval(minutes * 60)
        self.timeRemaining = sec
        self.totalDuration = sec
    }

    private func playCompletionSound() {
        if let sound = NSSound(named: "Glass") {
            sound.play()
        } else {
            NSSound.beep()
        }
    }
}

public extension Notification.Name {
    static let dynamicIslandVisibilityChanged = Notification.Name("DynamicIslandVisibilityChangedNotification")
}
