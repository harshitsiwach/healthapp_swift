import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content
    var material: Material = .ultraThinMaterial
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16
    
    init(
        material: Material = .ultraThinMaterial,
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.material = material
        self.cornerRadius = cornerRadius
        self.padding = padding
    }
    
    var body: some View {
        if #available(iOS 26, *) {
            content
                .padding(padding)
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        } else {
            content
                .padding(padding)
                .background(material, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        }
    }
}

// MARK: - Color Variants

struct GlassCardGreen<Content: View>: View {
    let content: Content
    @Environment(\.theme) var colors
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        if #available(iOS 26, *) {
            content
                .padding(16)
                .glassEffect(.regular.tint(colors.neonGreen.opacity(0.2)), in: .rect(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(colors.neonGreen.opacity(0.25), lineWidth: 0.5)
                )
        } else {
            content
                .padding(16)
                .background(
                    ZStack {
                        colors.neonGreen.opacity(0.08)
                        Rectangle().fill(.ultraThinMaterial)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(colors.neonGreen.opacity(0.25), lineWidth: 0.5)
                )
        }
    }
}

struct GlassCardYellow<Content: View>: View {
    let content: Content
    @Environment(\.theme) var colors
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        if #available(iOS 26, *) {
            content
                .padding(16)
                .glassEffect(.regular.tint(colors.neonYellow.opacity(0.2)), in: .rect(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(colors.neonYellow.opacity(0.25), lineWidth: 0.5)
                )
        } else {
            content
                .padding(16)
                .background(
                    ZStack {
                        colors.neonYellow.opacity(0.08)
                        Rectangle().fill(.ultraThinMaterial)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(colors.neonYellow.opacity(0.25), lineWidth: 0.5)
                )
        }
    }
}

struct GlassCardRed<Content: View>: View {
    let content: Content
    @Environment(\.theme) var colors
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        if #available(iOS 26, *) {
            content
                .padding(16)
                .glassEffect(.regular.tint(colors.neonRed.opacity(0.2)), in: .rect(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(colors.neonRed.opacity(0.2), lineWidth: 0.5)
                )
        } else {
            content
                .padding(16)
                .background(
                    ZStack {
                        colors.neonRed.opacity(0.06)
                        Rectangle().fill(.ultraThinMaterial)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(colors.neonRed.opacity(0.2), lineWidth: 0.5)
                )
        }
    }
}
