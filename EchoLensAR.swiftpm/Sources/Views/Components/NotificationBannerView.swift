import SwiftUI

struct NotificationBannerView: View {
    let sound: DetectedSound
    var onDismiss: () -> Void
    @Environment(\.deviceLayout) var layout

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: round(12 * layout.scale)) {
            ZStack {
                RoundedRectangle(cornerRadius: round(8 * layout.scale))
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
                    .frame(width: layout.notifAppIcon, height: layout.notifAppIcon)

                Image(systemName: "ear.and.waveform")
                    .font(.system(size: layout.body, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("EchoLens AR")
                        .font(.system(size: layout.notifTitle, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("now")
                        .font(.system(size: layout.tiny, weight: .medium))
                        .foregroundStyle(.tertiary)
                }

                Text(notificationTitle)
                    .font(.system(size: layout.notifTitle, weight: .semibold, design: .rounded))
                    .foregroundStyle(sound.isCritical ? sound.displayColor : .primary)

                Text(notificationBody)
                    .font(.system(size: layout.notifBody, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(round(12 * layout.scale))
        .background {
            RoundedRectangle(cornerRadius: round(20 * layout.scale))
                .fill(.ultraThickMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: round(20 * layout.scale))
                        .strokeBorder(
                            sound.isCritical
                                ? sound.displayColor.opacity(0.4)
                                : .clear,
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 8)
        }
        .overlay(alignment: .topTrailing) {
            if sound.isCritical {
                Text("CRITICAL")
                    .font(.system(size: round(8 * layout.scale), weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, round(6 * layout.scale))
                    .padding(.vertical, round(3 * layout.scale))
                    .background(Color.red.gradient, in: Capsule())
                    .offset(x: -8, y: -4)
            }
        }
        .padding(.horizontal, layout.pagePadding)
        .adaptiveWidth()
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height < 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height < -40 {
                        onDismiss()
                    } else {
                        withAnimation(.spring(duration: 0.3)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Notification: \(sound.displayName) detected at \(Int(sound.confidence * 100)) percent confidence")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onDismiss() }
    }

    private var notificationTitle: String {
        let emoji = sound.isCritical ? "⚠️ " : ""
        return "\(emoji)\(sound.displayName) Detected"
    }

    private var notificationBody: String {
        let confidence = Int(sound.confidence * 100)
        let direction = directionLabel(for: sound.estimatedAzimuth)
        return "Confidence: \(confidence)% — Direction: \(direction)"
    }

    private func directionLabel(for azimuth: Double?) -> String {
        guard let az = azimuth else { return "Unknown" }
        let degrees = az * 180.0 / Double.pi
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
}

#Preview("Notification Banner") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            NotificationBannerView(
                sound: DetectedSound(category: .smokeAlarm, confidence: 0.94, estimatedAzimuth: -1.2),
                onDismiss: {}
            )
            Spacer()
        }
        .padding(.top, 50)
    }
}
