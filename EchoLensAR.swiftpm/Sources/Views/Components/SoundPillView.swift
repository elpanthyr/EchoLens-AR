import SwiftUI

struct SoundPillView: View {
    let sound: DetectedSound
    @Environment(\.deviceLayout) var layout

    var body: some View {
        HStack(spacing: round(10 * layout.scale)) {
            Image(systemName: sound.sfSymbol)
                .font(.system(size: layout.pillIcon, weight: .semibold))
                .foregroundStyle(sound.displayColor)
                .frame(width: round(24 * layout.scale), height: round(24 * layout.scale))

            Text(sound.displayName)
                .font(.system(size: layout.pillLabel, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            ConfidenceBar(confidence: sound.confidence, color: sound.displayColor)
                .frame(width: layout.confidenceBarWidth, height: round(6 * layout.scale))

            Text("\(Int(sound.confidence * 100))%")
                .font(.system(size: layout.tiny, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, layout.pillHPadding)
        .padding(.vertical, layout.pillVPadding)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .transition(.blurReplace)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(sound.displayName), \(Int(sound.confidence * 100)) percent confidence")
    }
}

struct ConfidenceBar: View {
    let confidence: Double
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.15))

                Capsule()
                    .fill(color.gradient)
                    .frame(width: geometry.size.width * CGFloat(confidence))
            }
        }
    }
}

#Preview("Sound Pill") {
    ZStack {
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 12) {
            SoundPillView(sound: DetectedSound(category: .siren, confidence: 0.87))
            SoundPillView(sound: DetectedSound(category: .doorbell, confidence: 0.65))
            SoundPillView(sound: DetectedSound(category: .babyCrying, confidence: 0.92))
            SoundPillView(sound: DetectedSound(category: .smokeAlarm, confidence: 0.78))
        }
    }
}
