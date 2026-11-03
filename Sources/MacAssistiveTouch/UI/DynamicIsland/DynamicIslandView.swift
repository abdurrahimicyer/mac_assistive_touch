import SwiftUI
import AppKit

public struct DynamicIslandView: View {
    @ObservedObject var viewModel: DynamicIslandViewModel
    @ObservedObject private var pomodoro = PomodoroService.shared
    @ObservedObject private var lang = LanguageManager.shared

    public init(viewModel: DynamicIslandViewModel) {
        self.viewModel = viewModel
    }

    private var phaseColor: Color {
        switch pomodoro.phase {
        case .focus: return Color(red: 1.0, green: 0.35, blue: 0.28)
        case .shortBreak: return Color(red: 0.25, green: 0.85, blue: 0.55)
        case .longBreak: return Color(red: 0.45, green: 0.55, blue: 1.0)
        }
    }

    private var phaseIcon: String {
        switch pomodoro.phase {
        case .focus: return "flame.fill"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "bed.double.fill"
        }
    }

    private var phaseTitle: String {
        switch pomodoro.phase {
        case .focus:
            let session = pomodoro.completedSessions + 1
            return lang.currentLanguage == .turkish ? "Odaklanma #\(session)" : "Focus Session #\(session)"
        case .shortBreak:
            return lang.currentLanguage == .turkish ? "Kısa Mola" : "Short Break"
        case .longBreak:
            return lang.currentLanguage == .turkish ? "Uzun Mola" : "Long Break"
        }
    }

    private var statusText: String {
        switch pomodoro.state {
        case .running:
            return lang.currentLanguage == .turkish ? "çalışıyor" : "running"
        case .paused:
            return lang.currentLanguage == .turkish ? "duraklatıldı" : "paused"
        case .idle:
            return lang.currentLanguage == .turkish ? "hazır" : "ready"
        }
    }

    public var body: some View {
        ZStack(alignment: .top) {
            if viewModel.hasNotch {
                notchedBackground

                if viewModel.isExpanded {
                    expandedContent
                        .padding(.top, viewModel.notchHeight + 8)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.94, anchor: .top)),
                            removal: .opacity.combined(with: .scale(scale: 0.96, anchor: .top))
                        ))
                } else if viewModel.shouldBeVisible {
                    HStack(spacing: 0) {
                        // Sol: Fiziksel Çentik Alanı
                        Color.clear
                            .frame(width: viewModel.notchWidth)

                        // Sağ: Çentiğin Sağında Canlı Sayaç Kanadı (Yükseklik: 45pt)
                        compactRightWingContent
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            } else {
                notchlessBackground

                if viewModel.isExpanded {
                    expandedContent
                        .padding(.top, 10)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.94, anchor: .top)),
                            removal: .opacity.combined(with: .scale(scale: 0.96, anchor: .top))
                        ))
                } else if viewModel.shouldBeVisible {
                    compactRightWingContent
                        .frame(maxHeight: .infinity)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.36, dampingFraction: 0.78), value: viewModel.isExpanded)
        .animation(.spring(response: 0.36, dampingFraction: 0.78), value: viewModel.shouldBeVisible)
        .animation(.easeInOut(duration: 0.2), value: pomodoro.state)
        .animation(.easeInOut(duration: 0.2), value: pomodoro.phase)
        .onHover { hovering in
            if hovering {
                viewModel.onMouseEnter()
            } else {
                viewModel.onMouseExit()
            }
        }
    }

    // MARK: - Arka Plan (Çentikli Ekran)
    private var notchedBackground: some View {
        ZStack {
            if viewModel.isExpanded {
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 24,
                    bottomTrailingRadius: 24,
                    topTrailingRadius: 0,
                    style: .continuous
                )
                .fill(Color.black)
                .shadow(
                    color: Color.black.opacity(0.5),
                    radius: 16,
                    x: 0,
                    y: 8
                )
            } else if viewModel.shouldBeVisible {
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 10,
                    bottomTrailingRadius: 22.5,
                    topTrailingRadius: 0,
                    style: .continuous
                )
                .fill(Color.black)
                .shadow(
                    color: Color.black.opacity(0.35),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            } else {
                Color.clear
            }
        }
    }

    // MARK: - Arka Plan (Çentiksiz / Harici Ekran)
    private var notchlessBackground: some View {
        ZStack {
            if viewModel.isExpanded {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.black)
                    .shadow(
                        color: Color.black.opacity(0.5),
                        radius: 16,
                        x: 0,
                        y: 8
                    )
            } else if viewModel.shouldBeVisible {
                Capsule()
                    .fill(Color.black)
                    .shadow(
                        color: Color.black.opacity(0.35),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            } else {
                Color.clear
            }
        }
    }

    // MARK: - Kompakt Sağ Kanat Sayacı (Yükseklik: 45pt, Dinamik Adanın Sağında)
    private var compactRightWingContent: some View {
        HStack(spacing: 6) {
            // Canlı Halka & Faz İkonu
            ZStack {
                Circle()
                    .stroke(phaseColor.opacity(0.25), lineWidth: 2)
                    .frame(width: 18, height: 18)

                Circle()
                    .trim(from: 0, to: CGFloat(pomodoro.progress))
                    .stroke(phaseColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 18, height: 18)
                    .rotationEffect(.degrees(-90))

                Image(systemName: phaseIcon)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(phaseColor)
            }

            // Geri Sayım Canlı Saati (25:00, 24:59 vb.)
            Text(pomodoro.formattedTime)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.white)

            // Durum Gösterge Noktası
            if pomodoro.state == .paused {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 5, height: 5)
            } else if pomodoro.state == .running {
                Circle()
                    .fill(Color.green)
                    .frame(width: 5, height: 5)
            }

            // Mini Süre Çipi (örn: 25m)
            Text("\(pomodoro.focusMinutes)m")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(phaseColor)
                .padding(.horizontal, 5)
                .padding(.vertical, 1.5)
                .background(phaseColor.opacity(0.2))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.togglePin()
        }
    }

    // MARK: - Genişletilmiş Görünüm (İnteraktif HUD)
    private var expandedContent: some View {
        VStack(spacing: 10) {
            // Üst Satır: Faz Rozeti, Seçim Çipleri ve Kontroller
            HStack(spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: phaseIcon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(phaseColor)

                    Text(phaseTitle)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(phaseColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(phaseColor.opacity(0.16))
                .clipShape(Capsule())

                Spacer()

                // Hızlı Faz Seçiciler
                HStack(spacing: 4) {
                    phaseChip(title: "\(pomodoro.focusMinutes)m", phase: .focus)
                    phaseChip(title: "\(pomodoro.shortBreakMinutes)m", phase: .shortBreak)
                    phaseChip(title: "\(pomodoro.longBreakMinutes)m", phase: .longBreak)
                }

                // Sabitle Butonu
                Button {
                    viewModel.togglePin()
                } label: {
                    Image(systemName: viewModel.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(viewModel.isPinned ? Color.blue : Color.white.opacity(0.6))
                        .frame(width: 22, height: 22)
                        .background(Color.white.opacity(viewModel.isPinned ? 0.18 : 0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(viewModel.isPinned ? lang.tr("island_unpin") : lang.tr("island_pin"))

                // Daralt Butonu
                Button {
                    viewModel.collapse()
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.7))
                        .frame(width: 22, height: 22)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(lang.tr("island_collapse"))
            }

            // Orta: Dijital Sayaç & İlerleme Çubuğu
            VStack(spacing: 6) {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(pomodoro.formattedTime)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)

                    Text(statusText)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }

                // İnce İlerleme Çubuğu
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 4)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [phaseColor, phaseColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(geo.size.width * CGFloat(pomodoro.progress), 4), height: 4)
                    }
                }
                .frame(height: 4)
            }

            // Alt: Kontrol Butonları
            HStack(spacing: 10) {
                // Başlat / Duraklat
                Button {
                    pomodoro.toggle()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: pomodoro.state == .running ? "pause.fill" : "play.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text(pomodoro.state == .running ? (lang.currentLanguage == .turkish ? "Duraklat" : "Pause") :
                                (lang.currentLanguage == .turkish ? "Başlat" : "Start"))
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(phaseColor)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                // Sıradaki Faza Geç
                Button {
                    pomodoro.skip()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(lang.currentLanguage == .turkish ? "Sonraki Faza Geç" : "Skip to Next Phase")

                // Sıfırla
                Button {
                    pomodoro.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(lang.currentLanguage == .turkish ? "Sayacı Sıfırla" : "Reset Timer")

                Spacer()

                // Tamamlanan Oturum Sayısı Rozeti
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.green)
                    Text("\(pomodoro.completedSessions)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    private func phaseChip(title: String, phase: PomodoroPhase) -> some View {
        let isSelected = pomodoro.phase == phase
        return Button {
            pomodoro.selectPhase(phase)
        } label: {
            Text(title)
                .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.6))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.06))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
