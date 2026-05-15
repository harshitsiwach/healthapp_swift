import SwiftUI

struct GradientBackground: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.theme) var colors
    
    // Aesthetic Opacities
    private var purpleOpacity: Double { colorScheme == .dark ? 0.45 : 0.25 }
    private var blueOpacity: Double { colorScheme == .dark ? 0.35 : 0.20 }
    private var mintOpacity: Double { colorScheme == .dark ? 0.30 : 0.15 }
    private var orangeOpacity: Double { colorScheme == .dark ? 0.25 : 0.10 }
    
    // Base Color
    private var baseColor: Color {
        if colorScheme == .dark {
            return Color(red: 0.05, green: 0.05, blue: 0.07)
        } else {
            return Color(red: 0.97, green: 0.97, blue: 0.99)
        }
    }
    
    var body: some View {
        ZStack {
            // Base background
            baseColor
                .ignoresSafeArea()
            
            // Gradient blobs
            Circle()
                .fill(
                    RadialGradient(
                        colors: [colors.neonPurple.opacity(purpleOpacity), colors.neonPurple.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 220
                    )
                )
                .frame(width: 440, height: 440)
                .offset(x: -100, y: -200)
                .blur(radius: 90)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [colors.neonBlue.opacity(blueOpacity), colors.neonBlue.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: 180, y: 120)
                .blur(radius: 100)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [colors.neonGreen.opacity(mintOpacity), colors.neonGreen.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .offset(x: -60, y: 420)
                .blur(radius: 80)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [colors.neonOrange.opacity(orangeOpacity), colors.neonOrange.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: 140, y: -380)
                .blur(radius: 70)
        }
    }
}
