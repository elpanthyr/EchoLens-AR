import SwiftUI

struct LockScreenPreview: View {
    @Bindable var soundManager: SoundAnalyzerManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.deviceLayout) var layout

    var body: some View {
        ZStack {
            lockScreenBackground

            VStack(spacing: 0) {
                statusBar
                    .padding(.top, 12)

                timeDisplay
                    .padding(.top, round(30 * layout.scale))

                Text(dateString)
                    .font(.system(size: layout.buttonText, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.top, 4)

                Spacer()

                notificationStack

                Spacer()

                bottomBar
                    .padding(.bottom, 20)
            }
        }
        .ignoresSafeArea()
        .statusBarHidden()
    }

    private var lockScreenBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hue: 0.7, saturation: 0.35, brightness: 0.15),
                    Color(hue: 0.6, saturation: 0.25, brightness: 0.08),
                    Color(hue: 0.55, saturation: 0.3, brightness: 0.05),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(hue: 0.6, saturation: 0.4, brightness: 0.2).opacity(0.3),
                            .clear
                        ]),
                        center: .top,
                        startRadius: 50,
                        endRadius: 400
                    )
                )
                .offset(y: -200)
        }
    }

    private var statusBar: some View {
        HStack {
            Image(systemName: "lock.fill")
                .font(.system(size: round(9 * layout.scale)))
                .foregroundStyle(.white.opacity(0.7))
                .frame(maxWidth: .infinity)
        }
    }

    private var timeDisplay: some View {
        Text(timeString)
            .font(.system(size: round(72 * layout.scale), weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .monospacedDigit()
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: Date())
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    private var notificationStack: some View {
        ScrollView {
            VStack(spacing: round(8 * layout.scale)) {
                ForEach(soundManager.detectedSounds.prefix(6)) { sound in
                    lockScreenNotification(for: sound)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.horizontal, layout.pagePadding)
            .adaptiveWidth()
            .animation(.spring(duration: 0.4), value: soundManager.detectedSounds.count)
        }
        .frame(maxHeight: round(350 * layout.scale))
    }

    private func lockScreenNotification(for sound: DetectedSound) -> some View {
        HStack(spacing: round(10 * layout.scale)) {
            ZStack {
                RoundedRectangle(cornerRadius: round(6 * layout.scale))
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hue: 0.55, saturation: 0.7, brightness: 0.8),
                                Color(hue: 0.65, saturation: 0.6, brightness: 0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: round(28 * layout.scale), height: round(28 * layout.scale))

                Image(systemName: "ear.and.waveform")
                    .font(.system(size: layout.caption, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("ECHOLENS AR")
                        .font(.system(size: layout.tiny, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))

                    Spacer()

                    Text(timeAgo(from: sound.timestamp))
                        .font(.system(size: layout.tiny))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Text("\(sound.isCritical ? "⚠️ " : "")\(sound.displayName) Detected")
                    .font(.system(size: layout.subtitle, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Confidence: \(Int(sound.confidence * 100))%")
                    .font(.system(size: layout.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer(minLength: 0)
        }
        .padding(round(12 * layout.scale))
        .background {
            RoundedRectangle(cornerRadius: round(16 * layout.scale))
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: round(16 * layout.scale))
                        .strokeBorder(
                            sound.isCritical
                                ? sound.displayColor.opacity(0.3)
                                : .white.opacity(0.08),
                            lineWidth: 1
                        )
                )
        }
    }

    private var bottomBar: some View {
        VStack(spacing: round(16 * layout.scale)) {
            HStack {
                lockScreenButton(icon: "flashlight.off.fill")
                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Exit Preview")
                        .font(.system(size: layout.notifTitle, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, layout.cardPadding)
                        .padding(.vertical, layout.pillVPadding)
                        .background(.ultraThinMaterial, in: Capsule())
                }

                Spacer()
                lockScreenButton(icon: "camera.fill")
            }
            .padding(.horizontal, round(50 * layout.scale))

            Capsule()
                .fill(.white.opacity(0.4))
                .frame(width: round(130 * layout.scale), height: round(5 * layout.scale))
        }
    }

    private func lockScreenButton(icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: layout.body + 2))
            .foregroundStyle(.white.opacity(0.7))
            .frame(width: round(44 * layout.scale), height: round(44 * layout.scale))
            .background(.ultraThinMaterial, in: Circle())
    }

    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 5 { return "now" }
        else if interval < 60 { return "\(Int(interval))s ago" }
        else if interval < 3600 { return "\(Int(interval / 60))m ago" }
        return "\(Int(interval / 3600))h ago"
    }
}

#Preview("Lock Screen") {
    LockScreenPreview(soundManager: {
        let m = SoundAnalyzerManager()
        m.detectedSounds = [
            DetectedSound(category: .smokeAlarm, confidence: 0.94),
            DetectedSound(category: .siren, confidence: 0.88),
            DetectedSound(category: .doorbell, confidence: 0.85),
        ]
        return m
    }())
}
