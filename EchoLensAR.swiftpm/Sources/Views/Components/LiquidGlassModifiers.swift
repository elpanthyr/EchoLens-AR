import SwiftUI

struct LiquidGlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

struct LiquidGlassPill: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

struct LiquidGlassButton: ViewModifier {
    var isActive: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                isActive
                    ? AnyShapeStyle(.thinMaterial)
                    : AnyShapeStyle(.ultraThinMaterial),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

struct FrostedToolbar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 8)
    }
}

extension View {
    func liquidGlassCard(cornerRadius: CGFloat = 20, padding: CGFloat = 16) -> some View {
        modifier(LiquidGlassCard(cornerRadius: cornerRadius, padding: padding))
    }

    func liquidGlassPill() -> some View {
        modifier(LiquidGlassPill())
    }

    func liquidGlassButton(isActive: Bool = false) -> some View {
        modifier(LiquidGlassButton(isActive: isActive))
    }

    func frostedToolbar() -> some View {
        modifier(FrostedToolbar())
    }
}
