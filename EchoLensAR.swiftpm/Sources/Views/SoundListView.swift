import SwiftUI

struct SoundListView: View {
    @Bindable var soundManager: SoundAnalyzerManager
    @Environment(\.deviceLayout) var layout

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                if soundManager.detectedSounds.isEmpty {
                    emptyState
                } else {
                    soundList
                }
            }
            .navigationTitle("Detected Sounds")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var soundList: some View {
        ScrollView {
            LazyVStack(spacing: round(12 * layout.scale)) {
                ForEach(soundManager.detectedSounds) { sound in
                    SoundListRow(sound: sound)
                }
            }
            .padding(.horizontal, layout.pagePadding)
            .padding(.top, 8)
            .padding(.bottom, layout.tabBarBottomPadding)
            .adaptiveWidth()
            .animation(.spring(duration: 0.4), value: soundManager.detectedSounds.count)
        }
    }

    private var emptyState: some View {
        VStack(spacing: layout.sectionSpacing) {
            Image(systemName: "waveform.badge.magnifyingglass")
                .font(.system(size: layout.permissionIcon * 0.7))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hue: 0.55, saturation: 0.5, brightness: 0.7),
                            Color(hue: 0.7, saturation: 0.4, brightness: 0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.variableColor.iterative, isActive: true)

            Text("Listening for Sounds")
                .font(.system(size: layout.title * 0.85, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("Detected sounds will appear here\nwith time, direction, and confidence.")
                .font(.system(size: layout.subtitle, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .adaptiveWidth()
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(hue: 0.6, saturation: 0.12, brightness: 0.10),
                Color(hue: 0.7, saturation: 0.15, brightness: 0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct SoundListRow: View {
    let sound: DetectedSound
    @Environment(\.deviceLayout) var layout

    var body: some View {
        HStack(spacing: layout.cardPadding) {
            Image(systemName: sound.sfSymbol)
                .font(.system(size: layout.listIcon, weight: .semibold))
                .foregroundStyle(sound.displayColor)
                .frame(width: layout.featureIcon, height: layout.featureIcon)
                .background(sound.displayColor.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(sound.displayName)
                    .font(.system(size: layout.body, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                HStack(spacing: round(8 * layout.scale)) {
                    Label("\(Int(sound.confidence * 100))%", systemImage: "waveform")
                        .font(.system(size: layout.caption, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)

                    if let azimuth = sound.estimatedAzimuth {
                        Label(directionLabel(for: azimuth), systemImage: "location.fill")
                            .font(.system(size: layout.caption, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

                Text(timeLabel(for: sound.timestamp))
                    .font(.system(size: layout.tiny, design: .rounded))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            ConfidenceBar(confidence: sound.confidence, color: sound.displayColor)
                .frame(width: layout.confidenceBarWidth, height: round(6 * layout.scale))
        }
        .liquidGlassCard(cornerRadius: layout.cardRadius * 0.8, padding: layout.cardPadding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(sound.displayName), \(Int(sound.confidence * 100)) percent confidence")
    }

    private func directionLabel(for azimuth: Double) -> String {
        let degrees = azimuth * 180.0 / Double.pi
        switch degrees {
        case -22.5..<22.5:    return "Ahead"
        case 22.5..<67.5:     return "Front-Right"
        case 67.5..<112.5:    return "Right"
        case 112.5..<157.5:   return "Behind-Right"
        case -67.5 ..< -22.5: return "Front-Left"
        case -112.5 ..< -67.5:  return "Left"
        case -157.5 ..< -112.5: return "Behind-Left"
        default:              return "Behind"
        }
    }

    private func timeLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm:ss a"
        return formatter.string(from: date)
    }
}

#Preview("Sound List") {
    SoundListView(soundManager: {
        let m = SoundAnalyzerManager()
        m.detectedSounds = [
            DetectedSound(category: .siren, confidence: 0.92, estimatedAzimuth: -1.2),
            DetectedSound(category: .doorbell, confidence: 0.87, estimatedAzimuth: 0.8),
            DetectedSound(category: .smokeAlarm, confidence: 0.95, estimatedAzimuth: 0.0),
        ]
        return m
    }())
    .preferredColorScheme(.dark)
}
