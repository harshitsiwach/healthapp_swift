import SwiftUI

// MARK: - Watch App Main View

struct WatchMainView: View {
    @StateObject private var viewModel = WatchHealthViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Calorie Ring
                    WatchCalorieRing(
                        eaten: viewModel.caloriesEaten,
                        target: viewModel.caloriesTarget
                    )
                    
                    // Macros
                    HStack(spacing: 8) {
                        WatchMacroChip(label: "P", value: viewModel.proteinEaten, target: viewModel.proteinTarget, color: .red)
                        WatchMacroChip(label: "C", value: viewModel.carbsEaten, target: viewModel.carbsTarget, color: .orange)
                        WatchMacroChip(label: "F", value: viewModel.fatEaten, target: viewModel.fatTarget, color: .yellow)
                    }
                    
                    // Quick Actions
                    HStack(spacing: 8) {
                        NavigationLink(destination: WatchFoodLogView()) {
                            Label("Log", systemImage: "plus")
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                        
                        NavigationLink(destination: WatchWaterLogView()) {
                            Label("Water", systemImage: "drop.fill")
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        .tint(.cyan)
                    }
                    
                    // Streak
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                            .font(.caption2)
                        Text("\(viewModel.streak) day streak")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("Health")
            .onAppear {
                viewModel.loadData()
            }
        }
    }
}

// MARK: - Calorie Ring

struct WatchCalorieRing: View {
    let eaten: Int
    let target: Int
    
    var remaining: Int { max(target - eaten, 0) }
    var progress: Double { target > 0 ? min(Double(eaten) / Double(target), 1.0) : 0 }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 12)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progress > 0.9 ? Color.orange : Color.blue,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 2) {
                Text("\(remaining)")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                Text("kcal left")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 100, height: 100)
    }
}

// MARK: - Macro Chip

struct WatchMacroChip: View {
    let label: String
    let value: Double
    let target: Double
    let color: Color
    
    var progress: Double { target > 0 ? min(value / target, 1.0) : 0 }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(color)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(value))")
                    .font(.system(.caption2, design: .rounded))
                    .fontWeight(.semibold)
            }
            .frame(width: 40, height: 40)
        }
    }
}

// MARK: - Food Log View

struct WatchFoodLogView: View {
    @State private var searchText = ""
    
    let quickFoods = [
        ("Roti", 120),
        ("Rice (1 cup)", 200),
        ("Dal (1 bowl)", 150),
        ("Egg", 70),
        ("Banana", 100),
        ("Milk (1 glass)", 150),
        ("Chicken Breast", 165),
        ("Paneer (100g)", 265)
    ]
    
    var body: some View {
        List {
            Section("Quick Log") {
                ForEach(quickFoods, id: \.0) { food, calories in
                    Button {
                        // Log the food
                    } label: {
                        HStack {
                            Text(food)
                                .font(.caption)
                            Spacer()
                            Text("\(calories) kcal")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Log Food")
    }
}

// MARK: - Water Log View

struct WatchWaterLogView: View {
    @State private var glasses = 0
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "drop.fill")
                .font(.largeTitle)
                .foregroundStyle(.cyan)
            
            Text("\(glasses) glasses")
                .font(.title3)
                .fontWeight(.bold)
            
            HStack(spacing: 16) {
                Button {
                    glasses = max(0, glasses - 1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
                
                Button {
                    glasses += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
            }
            
            Text("\(Int(Double(glasses) * 0.25 * 1000)) ml")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Water")
    }
}

// MARK: - Watch Health ViewModel

@MainActor
class WatchHealthViewModel: ObservableObject {
    @Published var caloriesEaten = 0
    @Published var caloriesTarget = 2000
    @Published var proteinEaten = 0.0
    @Published var proteinTarget = 100.0
    @Published var carbsEaten = 0.0
    @Published var carbsTarget = 250.0
    @Published var fatEaten = 0.0
    @Published var fatTarget = 65.0
    @Published var streak = 0
    
    func loadData() {
        // In production: read from shared App Groups container
        // For now, use WCSession to request data from iPhone
    }
}
