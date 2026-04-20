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
        static let heartbeat = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.3)
        static let splash = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.5)
        static let staggered = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)
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

// MARK: - Splash Particles (Water Drop Animation)

struct SplashParticles: View {
    let color: Color
    let isActive: Bool
    let particleCount: Int
    
    @State private var particles: [SplashParticle] = []
    
    init(color: Color, isActive: Bool, count: Int = 12) {
        self.color = color
        self.isActive = isActive
        self.particleCount = count
    }
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(color.opacity(particle.opacity))
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.x, y: particle.y)
                    .scaleEffect(particle.scale)
            }
        }
        .onChange(of: isActive) { _, active in
            if active { triggerSplash() }
        }
    }
    
    private func triggerSplash() {
        particles = (0..<particleCount).map { _ in
            SplashParticle(
                x: CGFloat.random(in: -30...30),
                y: 0,
                targetX: CGFloat.random(in: -60...60),
                targetY: CGFloat.random(in: -80 ... -20),
                size: CGFloat.random(in: 4...10),
                opacity: Double.random(in: 0.6...1.0),
                scale: 1.0
            )
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
            for i in particles.indices {
                particles[i].x = particles[i].targetX
                particles[i].y = particles[i].targetY
                particles[i].opacity = 0
                particles[i].scale = 0.2
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            particles = []
        }
    }
}

struct SplashParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let targetX: CGFloat
    let targetY: CGFloat
    let size: CGFloat
    var opacity: Double
    var scale: CGFloat
}

// MARK: - Confetti View

struct ConfettiView: View {
    let isActive: Bool
    @State private var particles: [ConfettiParticle] = []
    
    let colors: [Color] = [
        Color(red: 1.0, green: 0.25, blue: 0.35),
        Color(red: 0.30, green: 0.60, blue: 1.0),
        Color(red: 1.0, green: 0.85, blue: 0.20),
        Color(red: 0.20, green: 0.90, blue: 0.50),
        Color(red: 0.60, green: 0.35, blue: 1.0),
        Color(red: 1.0, green: 0.55, blue: 0.15),
    ]
    
    var body: some View {
        ZStack {
            ForEach(particles) { p in
                p.shape
                    .fill(p.color)
                    .frame(width: p.size, height: p.size * (p.isCircle ? 1 : 1.6))
                    .rotationEffect(.degrees(p.rotation))
                    .offset(x: p.x, y: p.y)
                    .opacity(p.opacity)
            }
        }
        .onChange(of: isActive) { _, active in
            if active { triggerConfetti() }
        }
    }
    
    private func triggerConfetti() {
        particles = (0..<30).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: -20...20),
                y: -10,
                targetX: CGFloat.random(in: -150...150),
                targetY: CGFloat.random(in: 100...400),
                size: CGFloat.random(in: 5...9),
                color: colors.randomElement()!,
                rotation: Double.random(in: 0...360),
                rotationTarget: Double.random(in: 360...1080),
                opacity: 1.0,
                isCircle: Bool.random()
            )
        }
        
        for i in particles.indices {
            let delay = Double.random(in: 0...0.15)
            withAnimation(.easeOut(duration: Double.random(in: 0.8...1.4)).delay(delay)) {
                particles[i].x = particles[i].targetX
                particles[i].y = particles[i].targetY
                particles[i].rotation += particles[i].rotationTarget
                particles[i].opacity = 0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            particles = []
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let targetX: CGFloat
    let targetY: CGFloat
    let size: CGFloat
    let color: Color
    var rotation: Double
    let rotationTarget: Double
    var opacity: Double
    let isCircle: Bool
    
    var shape: AnyShape {
        isCircle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 2))
    }
}

// Helper for type-erased Shape
struct AnyShape: Shape {
    private let _path: (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        _path = { rect in shape.path(in: rect) }
    }
    
    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

// MARK: - Heartbeat Pulse Modifier

struct HeartbeatModifier: ViewModifier {
    let active: Bool
    @State private var beating = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(beating && active ? 1.15 : 1.0)
            .animation(
                active
                    ? DesignSystem.Anim.heartbeat.repeatForever(autoreverses: true)
                    : .default,
                value: beating
            )
            .onAppear {
                if active { beating = true }
            }
            .onChange(of: active) { _, newValue in
                beating = newValue
            }
    }
}

// MARK: - Staggered Card Entrance

struct StaggeredEntrance: ViewModifier {
    let index: Int
    let baseDelay: Double
    @State private var appeared = false
    
    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 25)
            .scaleEffect(appeared ? 1 : 0.95)
            .onAppear {
                withAnimation(
                    DesignSystem.Anim.staggered
                        .delay(Double(index) * baseDelay)
                ) {
                    appeared = true
                }
            }
    }
}

// MARK: - Floating Particles Background

struct FloatingParticles: View {
    let color: Color
    let count: Int
    @State private var particles: [FloatingParticle] = []
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    Circle()
                        .fill(color.opacity(p.opacity))
                        .frame(width: p.size, height: p.size)
                        .position(x: p.x, y: p.y)
                        .blur(radius: p.blur)
                }
            }
            .onAppear {
                particles = (0..<count).map { _ in
                    FloatingParticle(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: CGFloat.random(in: 0...geo.size.height),
                        size: CGFloat.random(in: 3...8),
                        opacity: Double.random(in: 0.05...0.15),
                        blur: CGFloat.random(in: 1...3),
                        speed: Double.random(in: 0.3...0.8),
                        amplitude: CGFloat.random(in: 10...30)
                    )
                }
                startFloating()
            }
        }
        .allowsHitTesting(false)
    }
    
    private func startFloating() {
        for i in particles.indices {
            let duration = particles[i].speed * 4
            withAnimation(
                .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(Double.random(in: 0...2))
            ) {
                particles[i].y -= particles[i].amplitude
                particles[i].x += CGFloat.random(in: -15...15)
            }
        }
    }
}

struct FloatingParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let opacity: Double
    let blur: CGFloat
    let speed: Double
    let amplitude: CGFloat
}

// MARK: - Glow Pulse Modifier

struct GlowPulse: ViewModifier {
    let color: Color
    @State private var pulsing = false
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: color.opacity(pulsing ? 0.4 : 0.15),
                radius: pulsing ? 12 : 6
            )
            .animation(
                .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                value: pulsing
            )
            .onAppear { pulsing = true }
    }
}

// MARK: - Water Wave Fill Animation

struct AnimatedWaterFill: View {
    let fillPercent: Double
    let color: Color
    
    @State private var waveOffset: CGFloat = 0
    @State private var animatedFill: Double = 0
    @State private var rippleScale: CGFloat = 1.0
    @State private var rippleOpacity: Double = 0
    
    var body: some View {
        GeometryReader { geo in
            let cornerR = DesignSystem.CornerRadius.medium
            
            ZStack {
                // Outer glow
                RoundedRectangle(cornerRadius: cornerR)
                    .stroke(color.opacity(0.25), lineWidth: 1.5)
                    .shadow(color: color.opacity(0.15), radius: 8)
                
                // Water fill
                VStack {
                    Spacer()
                    ZStack {
                        // Back wave
                        WaveShape(offset: waveOffset + 0.5, amplitude: 4)
                            .fill(color.opacity(0.3))
                            .frame(height: geo.size.height * animatedFill + 6)
                            .clipShape(RoundedRectangle(cornerRadius: cornerR))
                        
                        // Front wave
                        WaveShape(offset: waveOffset, amplitude: 3)
                            .fill(
                                LinearGradient(
                                    colors: [color.opacity(0.8), color.opacity(0.5)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .frame(height: geo.size.height * animatedFill)
                            .clipShape(RoundedRectangle(cornerRadius: cornerR))
                        
                        // Bubbles
                        if animatedFill > 0.1 {
                            WaterBubbles(color: color, maxHeight: geo.size.height * animatedFill)
                        }
                    }
                    
                    // Ripple on drop
                    if rippleOpacity > 0 {
                        Ellipse()
                            .stroke(color.opacity(rippleOpacity), lineWidth: 2)
                            .frame(width: 40 * rippleScale, height: 8 * rippleScale)
                            .offset(y: -geo.size.height * animatedFill + 4)
                    }
                }
                
                // Percentage
                Text("\(Int(fillPercent * 100))%")
                    .font(DesignSystem.Typography.statSmall)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animatedFill = fillPercent
                }
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    waveOffset = .pi * 2
                }
            }
            .onChange(of: fillPercent) { old, new in
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    animatedFill = new
                }
                // Trigger ripple
                triggerRipple()
                if new >= 1.0 && old < 1.0 {
                    // Goal reached!
                }
            }
        }
    }
    
    private func triggerRipple() {
        rippleScale = 0.5
        rippleOpacity = 0.8
        withAnimation(.easeOut(duration: 0.6)) {
            rippleScale = 2.0
            rippleOpacity = 0
        }
    }
}

// MARK: - Water Bubbles

struct WaterBubbles: View {
    let color: Color
    let maxHeight: CGFloat
    @State private var bubbles: [WaterBubble] = []
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(bubbles) { b in
                    Circle()
                        .fill(color.opacity(b.opacity))
                        .frame(width: b.size, height: b.size)
                        .position(x: b.x, y: b.y)
                }
            }
            .onAppear {
                bubbles = (0..<5).map { _ in
                    WaterBubble(
                        x: CGFloat.random(in: 10...geo.size.width - 10),
                        y: CGFloat.random(in: maxHeight * 0.3...maxHeight * 0.9),
                        size: CGFloat.random(in: 3...7),
                        opacity: Double.random(in: 0.15...0.35),
                        speed: Double.random(in: 2...4)
                    )
                }
                startBubbles()
            }
        }
    }
    
    private func startBubbles() {
        for i in bubbles.indices {
            let dur = bubbles[i].speed
            withAnimation(
                .easeInOut(duration: dur)
                    .repeatForever(autoreverses: false)
                    .delay(Double.random(in: 0...dur))
            ) {
                bubbles[i].y -= maxHeight * 0.6
                bubbles[i].opacity = 0
            }
        }
    }
}

struct WaterBubble: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    var opacity: Double
    let speed: Double
}

// MARK: - View Extensions (Animation)

extension View {
    func heartbeat(active: Bool = true) -> some View {
        modifier(HeartbeatModifier(active: active))
    }
    
    func staggeredEntrance(index: Int, delay: Double = 0.08) -> some View {
        modifier(StaggeredEntrance(index: index, baseDelay: delay))
    }
    
    func glowPulse(_ color: Color) -> some View {
        modifier(GlowPulse(color: color))
    }
}
