import SwiftUI

// MARK: - Design System

enum DesignSystem {
    
    // MARK: - Colors
    
    enum Colors {
        // Primary - Warm Saffron/Orange (Indian-inspired but modern)
        static let primary = Color(red: 1.0, green: 0.45, blue: 0.1) // Saffron
        static let primaryLight = Color(red: 1.0, green: 0.55, blue: 0.25)
        static let primaryDark = Color(red: 0.85, green: 0.35, blue: 0.0)
        
        // Secondary - Teal
        static let secondary = Color(red: 0.0, green: 0.72, blue: 0.65)
        static let secondaryLight = Color(red: 0.2, green: 0.82, blue: 0.75)
        
        // Accent - Purple for AI features
        static let accent = Color(red: 0.55, green: 0.35, blue: 0.95)
        
        // Semantic
        static let success = Color(red: 0.2, green: 0.78, blue: 0.35)
        static let warning = Color(red: 1.0, green: 0.72, blue: 0.0)
        static let error = Color(red: 0.95, green: 0.25, blue: 0.25)
        static let info = Color(red: 0.2, green: 0.6, blue: 1.0)
        
        // Food Macros
        static let protein = Color(red: 0.95, green: 0.3, blue: 0.3)
        static let carbs = Color(red: 1.0, green: 0.6, blue: 0.0)
        static let fat = Color(red: 1.0, green: 0.85, blue: 0.0)
        static let fiber = Color(red: 0.4, green: 0.75, blue: 0.3)
        
        // Backgrounds
        static let background = Color(UIColor.systemBackground)
        static let backgroundSecondary = Color(UIColor.secondarySystemBackground)
        static let backgroundTertiary = Color(UIColor.tertiarySystemBackground)
        
        // Text
        static let textPrimary = Color(UIColor.label)
        static let textSecondary = Color(UIColor.secondaryLabel)
        static let textTertiary = Color(UIColor.tertiaryLabel)
    }
    
    // MARK: - Typography
    
    enum Typography {
        // Display
        static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let title1 = Font.system(.title, design: .rounded).weight(.bold)
        static let title2 = Font.system(.title2, design: .rounded).weight(.bold)
        static let title3 = Font.system(.title3, design: .rounded).weight(.semibold)
        
        // Body
        static let headline = Font.system(.headline, design: .rounded).weight(.semibold)
        static let subheadline = Font.system(.subheadline, design: .rounded).weight(.medium)
        static let body = Font.system(.body, design: .rounded)
        static let bodyBold = Font.system(.body, design: .rounded).weight(.semibold)
        static let callout = Font.system(.callout, design: .rounded)
        
        // Small
        static let caption = Font.system(.caption, design: .rounded)
        static let captionBold = Font.system(.caption, design: .rounded).weight(.semibold)
        static let caption2 = Font.system(.caption2, design: .rounded)
        
        // Numbers
        static let calorieNumber = Font.system(size: 42, weight: .black, design: .rounded)
        static let macroNumber = Font.system(size: 18, weight: .bold, design: .rounded)
        static let statNumber = Font.system(size: 28, weight: .heavy, design: .rounded)
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
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 24
        static let pill: CGFloat = 100
    }
    
    // MARK: - Shadows
    
    enum Shadow {
        static let small = ShadowStyle(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        static let medium = ShadowStyle(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        static let large = ShadowStyle(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
        
        struct ShadowStyle {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.5)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
    }
}

// MARK: - Premium Card Modifier

struct PremiumCard: ViewModifier {
    var padding: CGFloat = DesignSystem.Spacing.md
    var shadow: DesignSystem.Shadow.ShadowStyle = DesignSystem.Shadow.medium
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous))
            .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

// MARK: - Gradient Background

struct PremiumGradientBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            // Ambient blobs
            Circle()
                .fill(DesignSystem.Colors.primary.opacity(colorScheme == .dark ? 0.08 : 0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -100, y: -200)
            
            Circle()
                .fill(DesignSystem.Colors.accent.opacity(colorScheme == .dark ? 0.06 : 0.1))
                .frame(width: 250, height: 250)
                .blur(radius: 70)
                .offset(x: 120, y: 200)
            
            Circle()
                .fill(DesignSystem.Colors.secondary.opacity(colorScheme == .dark ? 0.05 : 0.08))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: 50, y: 50)
        }
    }
}

// MARK: - Skeleton Loader

struct SkeletonLoader: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .redacted(reason: .placeholder)
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: isAnimating ? 400 : -400)
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        isAnimating = true
                    }
                }
            )
            .clipped()
    }
}

// MARK: - Pulse Animation

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    var active: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing && active ? 1.05 : 1.0)
            .opacity(isPulsing && active ? 0.8 : 1.0)
            .animation(
                active ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default,
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.4), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        phase = 500
                    }
                }
            )
            .clipped()
    }
}

// MARK: - View Extensions

extension View {
    func premiumCard(padding: CGFloat = DesignSystem.Spacing.md) -> some View {
        modifier(PremiumCard(padding: padding))
    }
    
    func skeleton() -> some View {
        modifier(SkeletonLoader())
    }
    
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
    
    func pulse(active: Bool = true) -> some View {
        modifier(PulseModifier(active: active))
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
            .onAppear {
                withAnimation(.smooth) {
                    displayedValue = value
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.smooth) {
                    displayedValue = newValue
                }
            }
    }
}

// MARK: - Circular Progress Ring

struct PremiumProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let color: Color
    let bgColor: Color
    
    @State private var animatedProgress: Double = 0
    
    init(progress: Double, lineWidth: CGFloat = 10, size: CGFloat = 120, color: Color = DesignSystem.Colors.primary, bgColor: Color = .gray.opacity(0.15)) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.color = color
        self.bgColor = bgColor
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(bgColor, lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    color.gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                animatedProgress = min(progress, 1.0)
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animatedProgress = min(newValue, 1.0)
            }
        }
    }
}

// MARK: - Macro Pill

struct MacroPill: View {
    let label: String
    let value: Double
    let target: Double
    let color: Color
    
    var progress: Double { target > 0 ? min(value / target, 1.0) : 0 }
    var remaining: Double { max(target - value, 0) }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xxs) {
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 5)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color.gradient, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text("\(Int(value))")
                        .font(DesignSystem.Typography.macroNumber)
                    Text("/\(Int(target))g")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }
            .frame(width: 60, height: 60)
        }
    }
}
