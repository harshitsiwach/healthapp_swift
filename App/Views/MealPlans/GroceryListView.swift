import SwiftUI
import SwiftData

struct GroceryListView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var colors
    @Query private var allPreferences: [UserMealPreferences]
    
    @AppStorage("grocery_items") private var groceryItemsRaw: String = "[]"
    @State private var items: [GroceryItem] = []
    @State private var newItem = ""
    @State private var showingMealPlanItems = false
    
    private var preferences: UserMealPreferences? { allPreferences.first }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.md) {
                // Header stats
                HStack(spacing: DesignSystem.Spacing.md) {
                    statCard(count: items.filter { !$0.isChecked }.count, label: "Remaining", color: colors.neonGreen)
                    statCard(count: items.filter { $0.isChecked }.count, label: "Checked", color: colors.textTertiary)
                    statCard(count: items.count, label: "Total", color: colors.neonBlue)
                }
                .padding(.horizontal)
                
                // Add item
                HStack(spacing: DesignSystem.Spacing.sm) {
                    TextField("Add item...", text: $newItem)
                        .foregroundStyle(colors.textPrimary)
                        .onSubmit { addItem() }
                    
                    Button {
                        Haptic.selection()
                        addItem()
                    } label: {
                        let isEmpty = newItem.trimmingCharacters(in: .whitespaces).isEmpty
                        ZStack {
                            Circle()
                                .fill(isEmpty ? Color.gray.opacity(0.3) : colors.neonGreen)
                                .frame(width: 36, height: 36)
                                .shadow(color: isEmpty ? .clear : colors.neonGreen.opacity(0.4), radius: 6)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .disabled(newItem.trimmingCharacters(in: .whitespaces).isEmpty)
                    .buttonStyle(.scaleButton)
                }
                .padding(DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .fill(colors.backgroundCard)
                        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium).strokeBorder(colors.cardBorder))
                )
                .padding(.horizontal)
                
                // Generate from meal plan
                Button {
                    generateFromMealPlan()
                } label: {
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Generate from Meal Plan")
                            .font(DesignSystem.Typography.subheadline.bold())
                    }
                    .foregroundStyle(colors.neonPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .fill(colors.neonPurple.opacity(0.1))
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .strokeBorder(colors.neonPurple.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.scaleButton)
                .padding(.horizontal)
                
                // Quick add categories
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        quickAddButton("🥛 Dairy", items: ["Milk", "Curd", "Paneer", "Butter"])
                        quickAddButton("🥬 Vegetables", items: ["Onion", "Tomato", "Potato", "Spinach"])
                        quickAddButton("🍚 Grains", items: ["Rice", "Wheat flour", "Oats", "Dal"])
                        quickAddButton("🍳 Protein", items: ["Eggs", "Chicken", "Fish", "Chana"])
                        quickAddButton("🍎 Fruits", items: ["Banana", "Apple", "Mango", "Orange"])
                        quickAddButton("🧂 Spices", items: ["Turmeric", "Cumin", "Garam masala", "Salt"])
                    }
                    .padding(.horizontal)
                }
                
                // Items list
                if !items.isEmpty {
                    // Unchecked items
                    let unchecked = items.filter { !$0.isChecked }
                    let checked = items.filter { $0.isChecked }
                    
                    if !unchecked.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("To Buy (\(unchecked.count))")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundStyle(colors.neonGreen)
                                .padding(.horizontal)
                            
                            ForEach(unchecked) { item in
                                groceryRow(item: item)
                            }
                        }
                    }
                    
                    if !checked.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            HStack {
                                Text("Checked (\(checked.count))")
                                    .font(DesignSystem.Typography.subheadline)
                                    .foregroundStyle(colors.textTertiary)
                                Spacer()
                                Button("Clear All") {
                                    Haptic.selection()
                                    items.removeAll { $0.isChecked }
                                    saveItems()
                                }
                                .font(DesignSystem.Typography.captionBold)
                                .foregroundStyle(colors.neonRed)
                            }
                            .padding(.horizontal)
                            .padding(.top)
                            
                            ForEach(checked) { item in
                                groceryRow(item: item)
                            }
                        }
                    }
                } else {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "cart")
                            .font(.system(size: 50))
                            .foregroundStyle(colors.textTertiary)
                        Text("Your grocery list is empty")
                            .font(DesignSystem.Typography.headline)
                            .foregroundStyle(colors.textPrimary)
                        Text("Add items or generate from your meal plan")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(colors.textSecondary)
                    }
                    .padding(.vertical, DesignSystem.Spacing.xxl)
                }
                
                Spacer().frame(height: 100)
            }
            .padding(.top)
        }
        .background(colors.background.ignoresSafeArea())
        .navigationTitle("Grocery List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundStyle(colors.neonGreen)
            }
        }
        .onAppear { loadItems() }
    }
    
    // MARK: - Grocery Row
    
    private func groceryRow(item: GroceryItem) -> some View {
        Button {
            Haptic.selection()
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                items[idx].isChecked.toggle()
                saveItems()
            }
        } label: {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(item.isChecked ? colors.neonGreen : colors.textTertiary)
                
                Text(item.name)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(item.isChecked ? colors.textTertiary : colors.textPrimary)
                    .strikethrough(item.isChecked)
                
                Spacer()
                
                Button {
                    Haptic.impact(.light)
                    items.removeAll { $0.id == item.id }
                    saveItems()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(colors.neonRed.opacity(0.5))
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(colors.backgroundCard)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
    
    // MARK: - Quick Add
    
    private func quickAddButton(_ label: String, items: [String]) -> some View {
        Button {
            Haptic.selection()
            for item in items {
                if !self.items.contains(where: { $0.name.lowercased() == item.lowercased() }) {
                    self.items.append(GroceryItem(name: item))
                }
            }
            saveItems()
        } label: {
            Text(label)
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(colors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(colors.backgroundElevated))
        }
        .buttonStyle(.scaleButton)
    }
    
    // MARK: - Stats Card
    
    private func statCard(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(DesignSystem.Typography.statMedium)
                .foregroundStyle(color)
                .monospacedDigit()
            Text(label)
                .font(DesignSystem.Typography.caption2)
                .foregroundStyle(colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .fill(colors.backgroundCard)
                .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium).strokeBorder(color.opacity(0.2)))
        )
    }
    
    // MARK: - Actions
    
    private func addItem() {
        let trimmed = newItem.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if !items.contains(where: { $0.name.lowercased() == trimmed.lowercased() }) {
            items.append(GroceryItem(name: trimmed))
            saveItems()
        }
        newItem = ""
    }
    
    private func generateFromMealPlan() {
        let plan = MealPlanEngine.generateWeeklyPlan(preferences: preferences ?? UserMealPreferences())
        let allIngredients = plan.flatMap { $0.meals.flatMap { $0.ingredients } }
        let unique = Array(Set(allIngredients)).sorted()
        
        for ingredient in unique {
            if !items.contains(where: { $0.name.lowercased() == ingredient.lowercased() }) {
                items.append(GroceryItem(name: ingredient))
            }
        }
        saveItems()
        Haptic.notification(.success)
    }
    
    private func loadItems() {
        guard let data = groceryItemsRaw.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([GroceryItem].self, from: data) else { return }
        items = decoded
    }
    
    private func saveItems() {
        guard let data = try? JSONEncoder().encode(items),
              let str = String(data: data, encoding: .utf8) else { return }
        groceryItemsRaw = str
    }
}

struct GroceryItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var isChecked: Bool = false
}
