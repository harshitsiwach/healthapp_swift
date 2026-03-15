import SwiftUI

struct SaveMealToHealthView: View {
    @StateObject private var syncService = HealthSyncService()
    let mealName: String
    let calories: Double
    let carbs: Double
    let protein: Double
    let fat: Double
    
    @State private var isSaved = false
    @State private var isSaving = false
    
    var body: some View {
        Button {
            Task {
                isSaving = true
                try? await syncService.saveNutrition(calories: calories, carbs: carbs, protein: protein, fat: fat, name: mealName)
                isSaved = true
                isSaving = false
            }
        } label: {
            HStack {
                Image(systemName: isSaved ? "checkmark.circle.fill" : "apple.logo")
                Text(isSaved ? "Saved to Apple Health" : "Sync to Apple Health")
            }
            .font(.system(.subheadline, design: .rounded))
            .fontWeight(.bold)
            .foregroundStyle(isSaved ? .white : .pink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Group {
                    if #available(iOS 26, *) {
                        Capsule()
                            .fill(Color.clear)
                            .glassEffect(isSaved ? .regular.tint(.green) : .regular.tint(.pink).interactive(), in: .capsule)
                    } else {
                        Capsule()
                            .fill(isSaved ? AnyShapeStyle(Color.green.gradient) : AnyShapeStyle(Color.pink.opacity(0.1)))
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .disabled(isSaved || isSaving)
    }
}
