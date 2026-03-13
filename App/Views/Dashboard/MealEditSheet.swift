import SwiftUI
import SwiftData

struct MealEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let meal: DailyLog
    
    @State private var foodName: String = ""
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Edit Meal")
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.heavy)
                                
                                fieldRow(label: "Food Name", text: $foodName)
                                fieldRow(label: "Calories (kcal)", text: $calories, keyboard: .numberPad)
                                fieldRow(label: "Protein (g)", text: $protein, keyboard: .decimalPad)
                                fieldRow(label: "Carbs (g)", text: $carbs, keyboard: .decimalPad)
                                fieldRow(label: "Fat (g)", text: $fat, keyboard: .decimalPad)
                            }
                        }
                        
                        Button {
                            saveMeal()
                        } label: {
                            Text("Save Changes")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(Color.blue.gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            deleteMeal()
                        } label: {
                            Text("Delete Meal")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            foodName = meal.foodName ?? ""
            calories = "\(meal.estimatedCalories)"
            protein = String(format: "%.1f", meal.proteinG)
            carbs = String(format: "%.1f", meal.carbsG)
            fat = String(format: "%.1f", meal.fatG)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func fieldRow(label: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
            TextField(label, text: text)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
                .keyboardType(keyboard)
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
    
    private func saveMeal() {
        meal.foodName = foodName
        meal.estimatedCalories = Int(calories) ?? meal.estimatedCalories
        meal.proteinG = Double(protein) ?? meal.proteinG
        meal.carbsG = Double(carbs) ?? meal.carbsG
        meal.fatG = Double(fat) ?? meal.fatG
        try? modelContext.save()
        dismiss()
    }
    
    private func deleteMeal() {
        modelContext.delete(meal)
        try? modelContext.save()
        dismiss()
    }
}
