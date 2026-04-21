import WidgetKit
import SwiftUI

// MARK: - Dark Neon Theme for Widgets

extension Color {
    static let widgetBg = Color(red: 0.08, green: 0.08, blue: 0.12)
    static let widgetCard = Color(red: 0.12, green: 0.12, blue: 0.16)
    static let neonRed = Color(red: 1.0, green: 0.25, blue: 0.35)
    static let neonBlue = Color(red: 0.30, green: 0.60, blue: 1.0)
    static let neonYellow = Color(red: 1.0, green: 0.85, blue: 0.20)
    static let neonGreen = Color(red: 0.20, green: 0.90, blue: 0.50)
    static let neonOrange = Color(red: 1.0, green: 0.55, blue: 0.15)
    static let neonPurple = Color(red: 0.60, green: 0.35, blue: 1.0)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary = Color.white.opacity(0.30)
}

// MARK: - Small Widget (Calorie Ring)

struct SmallWidgetView: View {
    let entry: HealthWidgetEntry
    
    var caloriesRemaining: Int { max(entry.caloriesTarget - entry.caloriesEaten, 0) }
    var progress: Double {
        guard entry.caloriesTarget > 0 else { return 0 }
        return min(Double(entry.caloriesEaten) / Double(entry.caloriesTarget), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // Top: Streak
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.neonOrange)
                    .font(.system(size: 10))
                Text("\(entry.streakCount)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.neonOrange)
                Spacer()
                Text("🔥")
                    .font(.system(size: 10))
            }
            
            Spacer()
            
            // Center: Animated Ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 10)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: progress > 0.9
                                ? [.neonOrange, .neonRed]
                                : [.neonBlue, .neonGreen]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                // Glow dot at end
                if progress > 0.05 {
                    Circle()
                        .fill(progress > 0.9 ? Color.neonOrange : Color.neonGreen)
                        .frame(width: 8, height: 8)
                        .shadow(color: progress > 0.9 ? .neonOrange : .neonGreen, radius: 4)
                        .offset(y: -45)
                        .rotationEffect(.degrees(360 * progress))
                }
                
                // Center text
                VStack(spacing: 1) {
                    Text("\(caloriesRemaining)")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.textPrimary)
                        .minimumScaleFactor(0.6)
                    Text("kcal left")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Spacer()
            
            // Bottom: Quick stats
            HStack(spacing: 8) {
                miniStat(icon: "drop.fill", value: "\(Int(entry.proteinEaten))g", color: .neonRed)
                Spacer()
                miniStat(icon: "bolt.fill", value: "\(entry.caloriesEaten)", color: .neonGreen)
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            Color.widgetBg
        }
    }
    
    private func miniStat(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.textPrimary)
        }
    }
}

// MARK: - Medium Widget (Ring + Macros)

struct MediumWidgetView: View {
    let entry: HealthWidgetEntry
    
    var caloriesRemaining: Int { max(entry.caloriesTarget - entry.caloriesEaten, 0) }
    var progress: Double {
        guard entry.caloriesTarget > 0 else { return 0 }
        return min(Double(entry.caloriesEaten) / Double(entry.caloriesTarget), 1.0)
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Left: Compact ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: progress > 0.9
                                ? [.neonOrange, .neonRed]
                                : [.neonBlue, .neonGreen]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 1) {
                    Text("\(caloriesRemaining)")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.textPrimary)
                        .minimumScaleFactor(0.5)
                    Text("kcal left")
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundStyle(.textSecondary)
                }
            }
            .frame(width: 80, height: 80)
            
            // Right: Macros + Streak
            VStack(spacing: 8) {
                // Streak badge
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.neonOrange)
                        .font(.system(size: 9))
                    Text("\(entry.streakCount) day streak")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.neonOrange)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(.neonOrange.opacity(0.12)))
                
                // Macros
                macroRow(label: "Protein", eaten: entry.proteinEaten, target: entry.proteinTarget, color: .neonRed)
                macroRow(label: "Carbs", eaten: entry.carbsEaten, target: entry.carbsTarget, color: .neonYellow)
                macroRow(label: "Fat", eaten: entry.fatEaten, target: entry.fatTarget, color: .neonOrange)
            }
            
            Spacer()
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color.widgetBg
        }
    }
    
    private func macroRow(label: String, eaten: Double, target: Double, color: Color) -> some View {
        let pct = target > 0 ? min(eaten / target, 1.0) : 0
        return HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.textSecondary)
                .frame(width: 42, alignment: .leading)
            
            // Mini progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.15))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.gradient)
                        .frame(width: geo.size.width * pct)
                }
            }
            .frame(height: 4)
            
            Text("\(Int(eaten))/\(Int(target))")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(color)
                .frame(width: 52, alignment: .trailing)
        }
    }
}

// MARK: - Large Widget (Full Dashboard)

struct LargeWidgetView: View {
    let entry: HealthWidgetEntry
    
    var caloriesRemaining: Int { max(entry.caloriesTarget - entry.caloriesEaten, 0) }
    var progress: Double {
        guard entry.caloriesTarget > 0 else { return 0 }
        return min(Double(entry.caloriesEaten) / Double(entry.caloriesTarget), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Health")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.textPrimary)
                    Text(Date(), style: .date)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.textSecondary)
                }
                Spacer()
                
                // Streak
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.neonOrange)
                        .font(.system(size: 11))
                    Text("\(entry.streakCount)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.neonOrange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(.neonOrange.opacity(0.12)))
            }
            
            // Activity Rings Row
            HStack(spacing: 16) {
                // Big calorie ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.06), lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: progress > 0.9
                                    ? [.neonOrange, .neonRed]
                                    : [.neonGreen, .neonBlue]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 1) {
                        Text("\(caloriesRemaining)")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.textPrimary)
                            .minimumScaleFactor(0.5)
                        Text("kcal left")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.textSecondary)
                    }
                }
                .frame(width: 100, height: 100)
                
                // Side stats
                VStack(alignment: .leading, spacing: 10) {
                    statRow(icon: "arrow.down.circle.fill", label: "Eaten", value: "\(entry.caloriesEaten) kcal", color: .neonGreen)
                    statRow(icon: "target", label: "Target", value: "\(entry.caloriesTarget) kcal", color: .neonBlue)
                    statRow(icon: "heart.fill", label: "Score", value: "\(entry.healthScore)/100", color: entry.healthScore >= 70 ? .neonGreen : .neonOrange)
                }
                
                Spacer()
            }
            .frame(height: 110)
            
            // Macro cards
            HStack(spacing: 10) {
                macroCard(title: "Protein", eaten: entry.proteinEaten, target: entry.proteinTarget, color: .neonRed, icon: "p.circle.fill")
                macroCard(title: "Carbs", eaten: entry.carbsEaten, target: entry.carbsTarget, color: .neonYellow, icon: "c.circle.fill")
                macroCard(title: "Fat", eaten: entry.fatEaten, target: entry.fatTarget, color: .neonOrange, icon: "f.circle.fill")
            }
            
            // Water placeholder (widget doesn't have water data yet)
            HStack(spacing: 8) {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.neonBlue)
                    .font(.system(size: 14))
                
                Text("Hydration")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.textSecondary)
                
                Spacer()
                
                Text("Log in app")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.neonBlue)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.widgetCard)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.neonBlue.opacity(0.15), lineWidth: 1))
            )
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color.widgetBg
        }
    }
    
    private func statRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundStyle(.textTertiary)
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.textPrimary)
            }
        }
    }
    
    private func macroCard(title: String, eaten: Double, target: Double, color: Color, icon: String) -> some View {
        let pct = target > 0 ? min(eaten / target, 1.0) : 0
        return VStack(spacing: 6) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.textSecondary)
            }
            
            // Mini ring
            ZStack {
                Circle()
                    .stroke(color.opacity(0.12), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: pct)
                    .stroke(color.gradient, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(eaten))")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.textPrimary)
                    .minimumScaleFactor(0.5)
            }
            .frame(height: 44)
            
            Text("/ \(Int(target))g")
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .foregroundStyle(.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.widgetCard)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.15), lineWidth: 1))
        )
    }
}
