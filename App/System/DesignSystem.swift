import SwiftUI

// MARK: - Design System (Dark + Light Neon)

enum DesignSystem {
    
    // MARK: - Colors (Dynamic)
    
    struct ThemeColors {
        let isDark: Bool
        
        // Background
        var background: Color {
            isDark ? Color(red: 0.05, green: 0.05, blue: 0.08)
                   : Color(red: 0.96, green: 0.96, blue: 0.98)
        }
        var backgroundCard: Color {
            isDark ? Color(red: 0.10, green: 0.10, blue: 0.14)
                   : .white
        }
        var backgroundCardHover: Color {
            isDark ? Color(red: 0.13, green: 0.13, blue: 0.18)
                   : Color(red: 0.94, green: 0.94, blue: 0.96)
        }
        var backgroundElevated: Color {
            isDark ? Color(red: 0.08, green: 0.08, blue: 0.12)
                   : Color(red: 0.92, green: 0.92, blue: 0.95)
        }
        
        // Neon Accents (same for both themes)
        var neonRed: Color { Color(red: 1.0, green: 0.25, blue: 0.35) }
        var neonBlue: Color { Color(red: 0.30, green: 0.60, blue: 1.0) }
        var neonYellow: Color { Color(red: 1.0, green: 0.85, blue: 0.20) }
        var neonGreen: Color { Color(red: 0.20, green: 0.90, blue: 0.50) }
        var neonPurple: Color { Color(red: 0.60, green: 0.35, blue: 1.0) }
        var neonOrange: Color { Color(red: 1.0, green: 0.55, blue: 0.15) }
        
        // Macros
        var protein: Color { Color(red: 0.95, green: 0.35, blue: 0.40) }
        var carbs: Color { Color(red: 1.0, green: 0.65, blue: 0.20) }
        var fat: Color { Color(red: 1.0, green: 0.85, blue: 0.25) }
        var fiber: Color { Color(red: 0.35, green: 0.80, blue: 0.40) }
        
        // Text
        var textPrimary: Color {
            isDark ? .white : Color(red: 0.10, green: 0.10, blue: 0.12)
        }
        var textSecondary: Color {
            isDark ? .white.opacity(0.60) : Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.55)
        }
        var textTertiary: Color {
            isDark ? .white.opacity(0.35) : Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.30)
        }
        
        // Card border
        var cardBorder: Color {
            isDark ? .white.opacity(0.06) : .black.opacity(0.06)
        }
        
        // Semantic
        var success: Color { neonGreen }
        var warning: Color { neonOrange }
        var error: Color { neonRed }
        var info: Color { neonBlue }
    }
    
    // MARK: - Typography
    
    enum Typography {
        static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let title1 = Font.system(.title, design: .rounded).weight(.bold)
        static let title2 = Font.system(.title2, design: .rounded).weight(.bold)
        static let title3 = Font.system(.title3, design: .rounded).weight(.semibold)
        static let headline = Font.system(.headline, design: .rounded).weight(.semibold)
        static let subheadline = Font.system(.subheadline, design: .rounded).weight(.medium)
        static let body = Font.system(.body, design: .rounded)
        static let bodyBold = Font.system(.body, design: .rounded).weight(.semibold)
        static let callout = Font.system(.callout, design: .rounded)
        static let caption = Font.system(.caption, design: .rounded)
        static let captionBold = Font.system(.caption, design: .rounded).weight(.semibold)
        static let caption2 = Font.system(.caption2, design: .rounded)
        static let statLarge = Font.system(size: 42, weight: .black, design: .rounded).monospacedDigit()
        static let statMedium = Font.system(size: 28, weight: .heavy, design: .rounded).monospacedDigit()
        static let statSmall = Font.system(size: 18, weight: .bold, design: .rounded).monospacedDigit()
        static let heartRate = Font.system(size: 52, weight: .bold, design: .rounded).monospacedDigit()
    }
    
    // MARK: - Spacing
    
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    enum CornerRadius {
        static let small: CGFloat = 10
        static let medium: CGFloat = 14
        static let large: CGFloat = 20
        static let xlarge: CGFloat = 28
        static let pill: CGFloat = 100
    }
    
    // MARK: - Animation
    
    enum Anim {
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.5)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
    }
}

// MARK: - Theme Environment Key

private struct ThemeColorsKey: EnvironmentKey {
    static let defaultValue = DesignSystem.ThemeColors(isDark: true)
}

extension EnvironmentValues {
    var theme: DesignSystem.ThemeColors {
        get { self[ThemeColorsKey.self] }
        set { self[ThemeColorsKey.self] = newValue }
    }
}

// MARK: - Dark/Light Glass Card

struct ThemedGlassCard: ViewModifier {
    @Environment(\.theme) var colors
    var padding: CGFloat = DesignSystem.Spacing.md
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                    .fill(colors.backgroundCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                            .strokeBorder(colors.cardBorder, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Themed Background

struct ThemedBackground: View {
    @Environment(\.theme) var colors
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            // Ambient glows
            Circle()
                .fill(colors.neonRed.opacity(themeManager.isDark ? 0.06 : 0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(x: -120, y: -300)
            
            Circle()
                .fill(colors.neonBlue.opacity(themeManager.isDark ? 0.05 : 0.07))
                .frame(width: 250, height: 250)
                .blur(radius: 90)
                .offset(x: 150, y: 400)
            
            Circle()
                .fill(colors.neonPurple.opacity(themeManager.isDark ? 0.04 : 0.06))
                .frame(width: 200, height: 200)
                .blur(radius: 80)
                .offset(x: 0, y: 100)
        }
    }
}

// MARK: - Heart Rate Pulse Line

struct PulseLine: View {
    let dataPoints: [Double]
    let color: Color
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let step = w / CGFloat(max(dataPoints.count - 1, 1))
            
            ZStack {
                // Glow
                PulseShape(dataPoints: dataPoints, step: step, height: h)
                    .stroke(color.opacity(0.25), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .blur(radius: 6)
                
                // Main line
                PulseShape(dataPoints: dataPoints, step: step, height: h)
                    .trim(from: 0, to: animate ? 1 : 0)
                    .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                
                // Gradient fill
                PulseFillShape(dataPoints: dataPoints, step: step, height: h)
                    .fill(LinearGradient(colors: [color.opacity(0.15), color.opacity(0.0)],
                                         startPoint: .top, endPoint: .bottom))
                    .opacity(animate ? 1 : 0)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2)) { animate = true }
            }
        }
    }
}

struct PulseShape: Shape {
    let dataPoints: [Double]
    let step: CGFloat
    let height: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let maxVal = dataPoints.max() ?? 1
        let minVal = dataPoints.min() ?? 0
        let range = maxVal - minVal
        
        for (i, point) in dataPoints.enumerated() {
            let x = CGFloat(i) * step
            let normalized = range > 0 ? (point - minVal) / range : 0.5
            let y = height - (CGFloat(normalized) * height * 0.8 + height * 0.1)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                let prevX = CGFloat(i - 1) * step
                let prevNorm = range > 0 ? (dataPoints[i-1] - minVal) / range : 0.5
                let prevY = height - (CGFloat(prevNorm) * height * 0.8 + height * 0.1)
                let midX = (prevX + x) / 2
                path.addCurve(to: CGPoint(x: x, y: y),
                              control1: CGPoint(x: midX, y: prevY),
                              control2: CGPoint(x: midX, y: y))
            }
        }
        return path
    }
}

struct PulseFillShape: Shape {
    let dataPoints: [Double]
    let step: CGFloat
    let height: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let maxVal = dataPoints.max() ?? 1
        let minVal = dataPoints.min() ?? 0
        let range = maxVal - minVal
        
        path.move(to: CGPoint(x: 0, y: height))
        for (i, point) in dataPoints.enumerated() {
            let x = CGFloat(i) * step
            let normalized = range > 0 ? (point - minVal) / range : 0.5
            let y = height - (CGFloat(normalized) * height * 0.8 + height * 0.1)
            if i == 0 {
                path.addLine(to: CGPoint(x: x, y: y))
            } else {
                let prevX = CGFloat(i - 1) * step
                let prevNorm = range > 0 ? (dataPoints[i-1] - minVal) / range : 0.5
                let prevY = height - (CGFloat(prevNorm) * height * 0.8 + height * 0.1)
                let midX = (prevX + x) / 2
                path.addCurve(to: CGPoint(x: x, y: y),
                              control1: CGPoint(x: midX, y: prevY),
                              control2: CGPoint(x: midX, y: y))
            }
        }
        path.addLine(to: CGPoint(x: CGFloat(max(dataPoints.count - 1, 0)) * step, y: height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Activity Ring

struct ActivityRing: View {
    let progress: Double
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(gradient: Gradient(colors: [color.opacity(0.6), color]),
                                    center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            if animatedProgress > 0.05 {
                Circle()
                    .fill(color)
                    .frame(width: lineWidth + 2, height: lineWidth + 2)
                    .shadow(color: color, radius: 6)
                    .offset(y: -size / 2)
                    .rotationEffect(.degrees(360 * animatedProgress))
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.75).delay(0.2)) {
                animatedProgress = min(progress, 1.0)
            }
        }
    }
}

// MARK: - Hydration Beaker

struct HydrationBeaker: View {
    let fillPercent: Double
    let color: Color
    @State private var waveOffset: CGFloat = 0
    @State private var animatedFill: Double = 0
    
    var body: some View {
        GeometryReader { geo in
            let cornerR = DesignSystem.CornerRadius.medium
            
            ZStack {
                RoundedRectangle(cornerRadius: cornerR)
                    .stroke(color.opacity(0.3), lineWidth: 1.5)
                
                VStack {
                    Spacer()
                    WaveShape(offset: waveOffset, amplitude: 3)
                        .fill(LinearGradient(colors: [color.opacity(0.7), color.opacity(0.4)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(height: geo.size.height * animatedFill)
                        .clipShape(RoundedRectangle(cornerRadius: cornerR))
                }
                
                Text("\(Int(fillPercent * 100))%")
                    .font(DesignSystem.Typography.statSmall)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0)) { animatedFill = fillPercent }
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    waveOffset = .pi * 2
                }
            }
        }
    }
}

struct WaveShape: Shape {
    var offset: CGFloat
    var amplitude: CGFloat
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        for x in stride(from: 0, through: rect.width, by: 1) {
            let relativeX = x / rect.width
            let y = sin(relativeX * .pi * 2 + offset) * amplitude + rect.height * 0.08
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Neon Glow Modifier

struct NeonGlow: ViewModifier {
    let color: Color
    var intensity: Double = 0.5
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(intensity * 0.6), radius: 8)
            .shadow(color: color.opacity(intensity * 0.3), radius: 16)
    }
}

// MARK: - View Extensions

extension View {
    func themedCard(padding: CGFloat = DesignSystem.Spacing.md) -> some View {
        modifier(ThemedGlassCard(padding: padding))
    }
    
    func neonGlow(_ color: Color, intensity: Double = 0.5) -> some View {
        modifier(NeonGlow(color: color, intensity: intensity))
    }
}

// MARK: - Haptic Feedback

enum Haptic {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

// MARK: - Animated Counter

struct AnimatedCounter: View {
    let value: Int
    let font: Font
    let color: Color
    @State private var displayedValue: Int = 0
    
    var body: some View {
        Text("\(displayedValue)")
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText())
            .onAppear { withAnimation(.smooth) { displayedValue = value } }
            .onChange(of: value) { _, newValue in
                withAnimation(.smooth) { displayedValue = newValue }
            }
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ScaleButtonStyle {
    static var scaleButton: ScaleButtonStyle { ScaleButtonStyle() }
}
