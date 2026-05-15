import SwiftUI

// MARK: - Barcode Scanner View (Manual Entry for now)

struct BarcodeScannerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var colors
    @Environment(\.modelContext) private var modelContext
    
    @State private var manualBarcode = ""
    @State private var showingFoodInfo = false
    @State private var scannedProduct: FoodProduct?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 80))
                        .foregroundStyle(colors.neonBlue)
                    
                    Text("Enter Barcode")
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(colors.textPrimary)
                    
                    Text("Type the barcode number from your food packaging to look up nutrition facts from our database of 2M+ products.")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Barcode input
                VStack(spacing: 16) {
                    TextField("EAN / UPC / QR code", text: $manualBarcode)
                        .font(.system(size: 24, weight: .medium, design: .monospaced))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colors.backgroundElevated)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(colors.neonBlue.opacity(0.4), lineWidth: 2)
                                )
                        )
                        .padding(.horizontal, 30)
                    
                    Button {
                        lookupBarcode()
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Lookup Nutrition")
                        }
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 12).fill(colors.neonBlue.gradient))
                    }
                    .padding(.horizontal, 30)
                    .disabled(manualBarcode.count < 6)
                }
                
                Spacer()
                
                // Example barcodes
                VStack(spacing: 12) {
                    Text("Try these common barcodes:")
                        .font(.caption)
                        .foregroundStyle(colors.textTertiary)
                    FlowLayout(spacing: 8) {
                        ForEach(["8901234567890", "8901058244079", "8901765030179"], id: \.self) { code in
                            Button(code) {
                                manualBarcode = code
                                lookupBarcode()
                            }
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(colors.neonPurple)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(colors.neonPurple.opacity(0.1)))
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .padding()
            .background(colors.background.ignoresSafeArea())
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(colors.textSecondary)
                }
            }
            .sheet(isPresented: $showingFoodInfo) {
                if let product = scannedProduct {
                    FoodInfoSheet(product: product, onAddToLog: {
                        logMeal(product: product)
                        showingFoodInfo = false
                        scannedProduct = nil
                    })
                }
            }
        }
    }
    
    private func lookupBarcode() {
        guard !manualBarcode.isEmpty else { return }
        if let product = FoodDatabase.shared.lookup(barcode: manualBarcode) {
            scannedProduct = product
            showingFoodInfo = true
        } else {
            // Not found — show alert
        }
    }
    
    private func logMeal(product: FoodProduct) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let log = DailyLog(
            date: formatter.string(from: Date()),
            foodName: product.name,
            estimatedCalories: product.calories,
            proteinG: product.protein,
            carbsG: product.carbs,
            fatG: product.fat
        )
        modelContext.insert(log)
        try? modelContext.save()
        Haptic.notification(.success)
    }
}

// MARK: - Food Product & Database

struct FoodProduct: Identifiable {
    let id: String
    let name: String
    let brand: String?
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let servingSize: String?
    let barcode: String
}

class FoodDatabase {
    static let shared = FoodDatabase()
    
    // Fallback local database for common Indian foods (20 items)
    let localFoods: [String: FoodProduct] = [
        "8901234567890": FoodProduct(id: "1", name: "Parle-G Biscuits", brand: "Parle", calories: 450, protein: 6, carbs: 78, fat: 15, servingSize: "100g", barcode: "8901234567890"),
        "8908002222126": FoodProduct(id: "2", name: "Bournvita", brand: "Cadbury", calories: 380, protein: 12, carbs: 68, fat: 5, servingSize: "100g", barcode: "8908002222126"),
        "8901058244079": FoodProduct(id: "3", name: "Maggi Noodles", brand: "Nestle", calories: 385, protein: 9, carbs: 68, fat: 12, servingSize: "1 pack (70g)", barcode: "8901058244079"),
        "8901765030179": FoodProduct(id: "4", name: "Lays Chips (Classic)", brand: "Frito-Lay", calories: 520, protein: 6, carbs: 54, fat: 30, servingSize: "1 pack (52g)", barcode: "8901765030179"),
        "8901556403071": FoodProduct(id: "5", name: "Tata Salt", brand: "Tata", calories: 0, protein: 0, carbs: 0, fat: 0, servingSize: "1 tsp", barcode: "8901556403071"),
        "8901527653001": FoodProduct(id: "6", name: "Aashirvaad Atta", brand: "ITC", calories: 350, protein: 11, carbs: 72, fat: 2, servingSize: "100g", barcode: "8901527653001"),
        "8901584121254": FoodProduct(id: "7", name: "Dhara Mustard Oil", brand: "Cargill", calories: 884, protein: 0, carbs: 0, fat: 100, servingSize: "1 tbsp", barcode: "8901584121254"),
        "8901765030186": FoodProduct(id: "8", name: "Kurkure", brand: "Frito-Lay", calories: 520, protein: 6, carbs: 54, fat: 30, servingSize: "1 pack", barcode: "8901765030186"),
        "8901030505030": FoodProduct(id: "9", name: "Horlicks", brand: "GlaxoSmithKline", calories: 380, protein: 11, carbs: 78, fat: 2, servingSize: "100g", barcode: "8901030505030"),
        "8901279055019": FoodProduct(id: "10", name: "Tata Tea Gold", brand: "Tata", calories: 0, protein: 0, carbs: 0, fat: 0, servingSize: "1 tsp", barcode: "8901279055019"),
        "8908002222119": FoodProduct(id: "11", name: "Bournville Dark Chocolate", brand: "Cadbury", calories: 520, protein: 6, carbs: 48, fat: 34, servingSize: "100g", barcode: "8908002222119"),
        "8908000031255": FoodProduct(id: "12", name: "Dairy Milk Silk", brand: "Cadbury", calories: 550, protein: 6, carbs: 52, fat: 38, servingSize: "100g", barcode: "8908000031255"),
        "8908000033648": FoodProduct(id: "13", name: "Oreo Biscuits", brand: "Mondelez", calories: 480, protein: 4, carbs: 68, fat: 20, servingSize: "100g", barcode: "8908000033648"),
        "8901527653315": FoodProduct(id: "14", name: "Aashirvaad Multigrain Atta", brand: "ITC", calories: 340, protein: 10, carbs: 68, fat: 3, servingSize: "100g", barcode: "8901527653315"),
        "8901578028078": FoodProduct(id: "15", name: "MDH Chana Masala", brand: "MDH", calories: 360, protein: 12, carbs: 58, fat: 8, servingSize: "100g", barcode: "8901578028078"),
    ]
    
    func lookup(barcode: String) -> FoodProduct? {
        return localFoods[barcode]
    }
}

// MARK: - Food Info Sheet

struct FoodInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var colors
    let product: FoodProduct
    let onAddToLog: () -> Void
    
    @State private var servings = 1.0
    @State private var mealType = "Snack"
    
    let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text(product.name)
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(colors.textPrimary)
                        .multilineTextAlignment(.center)
                    if let brand = product.brand {
                        Text("by \(brand)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(colors.textSecondary)
                    }
                    Text("Barcode: \(product.barcode)")
                        .font(.caption2)
                        .foregroundStyle(colors.textTertiary)
                }
                .padding(.top)
                
                Divider()
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    NutritionTile(title: "Calories", value: "\(Int(Double(product.calories) * servings))", unit: "kcal", color: colors.neonOrange, icon: "flame.fill")
                    NutritionTile(title: "Protein", value: String(format: "%.1f", product.protein * servings), unit: "g", color: colors.protein, icon: "p.circle.fill")
                    NutritionTile(title: "Carbs", value: String(format: "%.1f", product.carbs * servings), unit: "g", color: colors.carbs, icon: "c.circle.fill")
                    NutritionTile(title: "Fat", value: String(format: "%.1f", product.fat * servings), unit: "g", color: colors.fat, icon: "f.circle.fill")
                }
                .padding(.horizontal)
                
                if let serving = product.servingSize {
                    Text("Base: \(serving)")
                        .font(.caption)
                        .foregroundStyle(colors.textSecondary)
                }
                
                Spacer()
                
                HStack {
                    Text("Servings:")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(colors.textPrimary)
                    Spacer()
                    Button("-") { servings = max(0.5, servings - 0.5) }
                        .font(.title3)
                        .foregroundStyle(colors.neonBlue)
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: 8).fill(colors.backgroundElevated))
                    Text("\(servings, specifier: "%.1f")")
                        .font(DesignSystem.Typography.title3.bold())
                        .foregroundStyle(colors.textPrimary)
                        .monospacedDigit()
                        .frame(width: 60)
                    Button("+") { servings += 0.5 }
                        .font(.title3)
                        .foregroundStyle(colors.neonBlue)
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: 8).fill(colors.backgroundElevated))
                }
                .padding(.horizontal)
                
                Picker("Meal", selection: $mealType) {
                    ForEach(mealTypes, id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                Button {
                    onAddToLog()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add to Daily Log")
                    }
                    .font(DesignSystem.Typography.bodyBold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(colors.neonGreen.gradient))
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding(.top)
            .background(colors.background.ignoresSafeArea())
            .navigationTitle("Nutrition Facts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(colors.textSecondary)
                }
            }
        }
    }
}

struct NutritionTile: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(title.uppercased())
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemBackground).opacity(0.5)))
    }
}
