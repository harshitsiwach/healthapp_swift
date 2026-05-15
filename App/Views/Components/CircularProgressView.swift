import SwiftUI

struct CircularProgressView: View {
    @Environment(\.theme) var colors
    let progress: Double // 0.0 - 1.0
    var lineWidth: CGFloat = 12
    var size: CGFloat = 120
    var trackColor: Color = Color.gray.opacity(0.15)
    var progressColor: Color = .green
    var showPercentage: Bool = false
    
    @State private var animatedProgress: Double = 0
    
    private var clampedProgress: Double {
        min(max(progress, 0), 1.0)
    }
    
    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(trackColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
            
            // Progress
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [progressColor.opacity(0.6), progressColor],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * animatedProgress)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
            
            if showPercentage {
                Text("\(Int(clampedProgress * 100))%")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.heavy)
                    .foregroundStyle(colors.textPrimary)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                animatedProgress = clampedProgress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedProgress = min(max(newValue, 0), 1.0)
            }
        }
    }
}

// MARK: - Mini Variant

struct MiniCircularProgress: View {
    @Environment(\.theme) var colors
    let progress: Double
    var size: CGFloat = 40
    var lineWidth: CGFloat = 4
    var color: Color = .blue
    
    var body: some View {
        CircularProgressView(
            progress: progress,
            lineWidth: lineWidth,
            size: size,
            progressColor: color
        )
    }
}
