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

// MARK: - Color Variants

struct GlassCardGreen<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            .background(
                ZStack {
                    Color.green.opacity(0.08)
                    Rectangle().fill(.ultraThinMaterial)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.green.opacity(0.25), lineWidth: 0.5)
            )
    }
}

struct GlassCardYellow<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            .background(
                ZStack {
                    Color.yellow.opacity(0.08)
                    Rectangle().fill(.ultraThinMaterial)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.yellow.opacity(0.25), lineWidth: 0.5)
            )
    }
}

struct GlassCardRed<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            .background(
                ZStack {
                    Color.red.opacity(0.06)
                    Rectangle().fill(.ultraThinMaterial)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.red.opacity(0.2), lineWidth: 0.5)
            )
    }
}
