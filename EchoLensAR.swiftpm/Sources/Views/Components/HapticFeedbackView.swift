import SwiftUI

struct HapticFeedbackView: View {
    let sound: DetectedSound
    @Environment(\.deviceLayout) var layout

    @State private var isAnimating = false
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: round(10 * layout.scale)) {
            Image(systemName: "iphone.radiowaves.left.and.right")
                .font(.system(size: layout.subtitle, weight: .semibold))
                .foregroundStyle(sound.displayColor)
                .offset(x: shakeOffset)

            HStack(spacing: round(3 * layout.scale)) {
                ForEach(0..<patternDotCount, id: \.self) { i in
                    Circle()
                        .fill(sound.displayColor)
                        .frame(width: dotSize(for: i), height: dotSize(for: i))
                        .opacity(isAnimating ? dotOpacity(for: i) : 0.3)
                        .animation(
                            .easeInOut(duration: dotDuration(for: i))
                            .repeatCount(12, autoreverses: true)
                            .delay(Double(i) * 0.08),
                            value: isAnimating
                        )
                }
            }

            Text(sound.hapticDescription)
                .font(.system(size: layout.tiny, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, layout.pillHPadding)
        .padding(.vertical, layout.pillVPadding)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: sound.displayColor.opacity(0.2), radius: 8, x: 0, y: 2)
        .onAppear {
            isAnimating = true
            startShakeAnimation()
        }
    }

    private var patternDotCount: Int {
        if let name = sound.customDisplayName {
            return 4 + (abs(name.hashValue) % 6)
        }
        switch sound.category {
        case .siren:            return 8
        case .doorbell:         return 4
        case .babyCrying:       return 6
        case .smokeAlarm:       return 10
        case .humanScreaming:   return 9
        case .childrenShouting: return 7
        }
    }

    private func dotSize(for index: Int) -> CGFloat {
        let base: CGFloat
        if let name = sound.customDisplayName {
            let seed = abs(name.hashValue)
            base = CGFloat(3 + ((seed + index) % 4))
        } else {
            switch sound.category {
            case .siren:            base = 4 + CGFloat(index) * 0.8
            case .doorbell:         base = index % 2 == 0 ? 7 : 3
            case .babyCrying:       base = index % 3 == 2 ? 2 : 6
            case .smokeAlarm:       base = 5
            case .humanScreaming:   base = 3 + CGFloat(index) * 1.0
            case .childrenShouting: base = index % 2 == 0 ? 5 : 4
            }
        }
        return round(base * layout.scale)
    }

    private func dotOpacity(for index: Int) -> Double {
        if let name = sound.customDisplayName {
            let seed = abs(name.hashValue)
            return 0.4 + (Double((seed + index) % 6) / 10.0)
        }
        switch sound.category {
        case .siren:            return 0.5 + Double(index) * 0.06
        case .doorbell:         return index % 2 == 0 ? 1.0 : 0.3
        case .babyCrying:       return index % 3 == 2 ? 0.2 : 0.9
        case .smokeAlarm:       return 0.9
        case .humanScreaming:   return 0.4 + Double(index) * 0.07
        case .childrenShouting: return index % 2 == 0 ? 0.8 : 0.5
        }
    }

    private func dotDuration(for index: Int) -> Double {
        if let name = sound.customDisplayName {
            let seed = abs(name.hashValue)
            return 0.15 + (Double((seed + index) % 4) * 0.05)
        }
        switch sound.category {
        case .siren:            return 0.6
        case .doorbell:         return 0.15
        case .babyCrying:       return 0.2
        case .smokeAlarm:       return 0.1
        case .humanScreaming:   return 0.35
        case .childrenShouting: return 0.25
        }
    }

    private func startShakeAnimation() {
        let shakeAmplitude = 3.0 * layout.scale
        let shakePattern: [CGFloat] = [shakeAmplitude, -shakeAmplitude, shakeAmplitude * 0.66, -shakeAmplitude * 0.66, shakeAmplitude * 0.33, -shakeAmplitude * 0.33, 0]
        for (i, offset) in shakePattern.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                withAnimation(.linear(duration: 0.05)) {
                    shakeOffset = offset
                }
            }
        }
    }
}

#Preview("Haptic Feedback") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 16) {
            HapticFeedbackView(sound: DetectedSound(category: .siren, confidence: 0.92))
            HapticFeedbackView(sound: DetectedSound(category: .doorbell, confidence: 0.88))
            HapticFeedbackView(sound: DetectedSound(category: .babyCrying, confidence: 0.95))
            HapticFeedbackView(sound: DetectedSound(category: .smokeAlarm, confidence: 0.91))
        }
    }
}
