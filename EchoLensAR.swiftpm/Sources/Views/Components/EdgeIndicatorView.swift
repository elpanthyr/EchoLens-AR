import SwiftUI

struct PeripheralGlowView: View {
    let indicator: OffScreenIndicator

    enum GlowPhase: CaseIterable {
        case dim, bright

        var opacity: Double {
            switch self {
            case .dim:    return 0.25
            case .bright: return 0.65
            }
        }
    }

    var body: some View {
        PhaseAnimator(GlowPhase.allCases) { phase in
            glowStrip(opacity: phase.opacity)
        } animation: { _ in
            .easeInOut(duration: 0.9)
        }
        .accessibilityLabel("\(indicator.category.displayName) detected, \(edgeLabel)")
    }

    @ViewBuilder
    private func glowStrip(opacity: Double) -> some View {
        GeometryReader { geo in
            ZStack {
                glowGradient(in: geo.size)
                    .opacity(opacity)

                iconOverlay(in: geo.size)
            }
        }
    }

    @ViewBuilder
    private func glowGradient(in size: CGSize) -> some View {
        let glowWidth: CGFloat = 28

        switch indicator.edge {
        case .leading:
            HStack(spacing: 0) {
                LinearGradient(
                    colors: [indicator.category.color.opacity(0.8), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: glowWidth)
                .background(.ultraThinMaterial.opacity(0.3))
                Spacer()
            }
        case .trailing:
            HStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [.clear, indicator.category.color.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: glowWidth)
                .background(.ultraThinMaterial.opacity(0.3))
            }
        case .top:
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [indicator.category.color.opacity(0.8), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: glowWidth)
                .background(.ultraThinMaterial.opacity(0.3))
                Spacer()
            }
        case .bottom:
            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [.clear, indicator.category.color.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: glowWidth)
                .background(.ultraThinMaterial.opacity(0.3))
            }
        }
    }

    private func iconOverlay(in size: CGSize) -> some View {
        let position = iconPosition(in: size)

        return Image(systemName: indicator.category.sfSymbol)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(.white)
            .padding(10)
            .background(indicator.category.color.gradient, in: Circle())
            .shadow(color: indicator.category.color.opacity(0.6), radius: 10)
            .position(position)
    }

    private func iconPosition(in size: CGSize) -> CGPoint {
        let edgeInset: CGFloat = 14
        let verticalPos = edgeInset + (size.height - 2 * edgeInset) * indicator.normalizedPosition

        switch indicator.edge {
        case .leading:  return CGPoint(x: edgeInset, y: verticalPos)
        case .trailing: return CGPoint(x: size.width - edgeInset, y: verticalPos)
        case .top:
            let hPos = edgeInset + (size.width - 2 * edgeInset) * indicator.normalizedPosition
            return CGPoint(x: hPos, y: edgeInset)
        case .bottom:
            let hPos = edgeInset + (size.width - 2 * edgeInset) * indicator.normalizedPosition
            return CGPoint(x: hPos, y: size.height - edgeInset)
        }
    }

    private var edgeLabel: String {
        switch indicator.edge {
        case .leading:  return "to your left"
        case .trailing: return "to your right"
        case .top:      return "above you"
        case .bottom:   return "below you"
        }
    }
}

struct CenterFlashView: View {
    let category: SoundCategory
    @State private var isFlashing = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(category.color.opacity(isFlashing ? 0.15 : 0.0))
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Image(systemName: category.sfSymbol)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(category.color)

                Text(category.displayName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(category.color)
            }
            .scaleEffect(isFlashing ? 1.1 : 0.9)
            .opacity(isFlashing ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                isFlashing = false
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview("Peripheral Glow") {
    ZStack {
        Color.black.ignoresSafeArea()

        PeripheralGlowView(indicator: OffScreenIndicator(
            id: UUID(),
            category: .siren,
            edge: .trailing,
            normalizedPosition: 0.5,
            angle: 1.2
        ))

        PeripheralGlowView(indicator: OffScreenIndicator(
            id: UUID(),
            category: .doorbell,
            edge: .leading,
            normalizedPosition: 0.3,
            angle: -1.5
        ))
    }
}
