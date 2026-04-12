import SwiftUI
import WidgetKit

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: HealthWidgetEntry
    
    var caloriesRemaining: Int {
        max(entry.caloriesTarget - entry.caloriesEaten, 0)
    }
    
    var progress: Double {
        guard entry.caloriesTarget > 0 else { return 0 }
        return min(Double(entry.caloriesEaten) / Double(entry.caloriesTarget), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Streak
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.caption2)
                Text("\(entry.streakCount)")
                    .font(.system(.caption2, design: .rounded))
                    .fontWeight(.bold)
                Spacer()
            }
            
            // Calorie Ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        progress > 0.9 ? Color.orange : Color.blue,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(caloriesRemaining)")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.black)
                        .minimumScaleFactor(0.6)
                    Text("kcal left")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: HealthWidgetEntry
    
    var caloriesRemaining: Int {
        max(entry.caloriesTarget - entry.caloriesEaten, 0)
    }
    
    var calorieProgress: Double {
        guard entry.caloriesTarget > 0 else { return 0 }
        return min(Double(entry.caloriesEaten) / Double(entry.caloriesTarget), 1.0)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Left: Calorie ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                
                Circle()
                    .trim(from: 0, to: calorieProgress)
                    .stroke(
                        calorieProgress > 0.9 ? Color.orange : Color.blue,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 1) {
                    Text("\(caloriesRemaining)")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.black)
                        .minimumScaleFactor(0.5)
                    Text("kcal left")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 90)
            
            // Right: Macros
            VStack(spacing: 10) {
                MacroRow(
                    icon: "p.circle.fill",
                    color: .red,
                    label: "Protein",
                    eaten: entry.proteinEaten,
                    target: entry.proteinTarget,
                    unit: "g"
                )
                
                MacroRow(
                    icon: "c.circle.fill",
                    color: .orange,
                    label: "Carbs",
                    eaten: entry.carbsEaten,
                    target: entry.carbsTarget,
                    unit: "g"
                )
                
                MacroRow(
                    icon: "f.circle.fill",
                    color: .yellow,
                    label: "Fats",
                    eaten: entry.fatEaten,
                    target: entry.fatTarget,
                    unit: "g"
                )
            }
            
            Spacer()
        }
        .padding(14)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let entry: HealthWidgetEntry
    
    var caloriesRemaining: Int {
        max(entry.caloriesTarget - entry.caloriesEaten, 0)
    }
    
    var calorieProgress: Double {
        guard entry.caloriesTarget > 0 else { return 0 }
        return min(Double(entry.caloriesEaten) / Double(entry.caloriesTarget), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Health")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                    Text(Date(), style: .date)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(entry.streakCount) day streak")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.orange.opacity(0.15), in: Capsule())
            }
            
            // Calorie progress bar
            VStack(spacing: 6) {
                HStack {
                    Text("\(entry.caloriesEaten) eaten")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(caloriesRemaining) left")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(caloriesRemaining < 200 ? .orange : .primary)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(calorieProgress > 0.9 ? Color.orange : Color.blue.gradient)
                            .frame(width: geo.size.width * calorieProgress)
                    }
                }
                .frame(height: 10)
            }
            
            // Macros grid
            HStack(spacing: 12) {
                MacroCard(
                    title: "Protein",
                    eaten: entry.proteinEaten,
                    target: entry.proteinTarget,
                    color: .red,
                    unit: "g"
                )
                
                MacroCard(
                    title: "Carbs",
                    eaten: entry.carbsEaten,
                    target: entry.carbsTarget,
                    color: .orange,
                    unit: "g"
                )
                
                MacroCard(
                    title: "Fats",
                    eaten: entry.fatEaten,
                    target: entry.fatTarget,
                    color: .yellow,
                    unit: "g"
                )
            }
            
            // Health Score
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.pink)
                Text("Health Score")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(entry.healthScore)/100")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(entry.healthScore >= 70 ? .green : entry.healthScore >= 40 ? .orange : .red)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Helper Views

struct MacroRow: View {
    let icon: String
    let color: Color
    let label: String
    let eaten: Double
    let target: Double
    let unit: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                
                Text("\(Int(eaten))/\(Int(target))\(unit)")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.semibold)
            }
        }
    }
}

struct MacroCard: View {
    let title: String
    let eaten: Double
    let target: Double
    let color: Color
    let unit: String
    
    var progress: Double {
        guard target > 0 else { return 0 }
        return min(eaten / target, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color.gradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(eaten))")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.5)
            }
            .frame(height: 44)
            
            Text("/ \(Int(target))\(unit)")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
