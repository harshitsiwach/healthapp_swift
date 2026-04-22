import SwiftUI
import PhotosUI

// MARK: - AI Meal Photo Analysis

struct MealPhotoView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var colors
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var mealImage: UIImage?
    @State private var isAnalyzing = false
    @State private var analysis: MealAnalysis?
    @State private var showingManualEdit = false
    @State private var animateIn = false
    
    // Editable values
    @State private var editName = ""
    @State private var editCalories = ""
    @State private var editProtein = ""
    @State private var editCarbs = ""
    @State private var editFat = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    headerSection
                    
                    // Photo picker
                    photoSection
                    
                    // Analysis results
                    if let analysis = analysis {
                        analysisSection(analysis)
                    }
                    
                    // Tips
                    if analysis == nil && mealImage == nil {
                        tipsSection
                    }
                }
                .padding()
                .padding(.bottom, 100)
            }
            .background(colors.background.ignoresSafeArea())
            .navigationTitle("AI Meal Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(colors.textSecondary)
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        mealImage = image
                        analyzeMeal(image: image)
                    }
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: "camera.macro")
                .font(.system(size: 40))
                .foregroundStyle(colors.neonPurple)
                .neonGlow(colors.neonPurple, intensity: 0.5)
            
            Text("AI Meal Analysis")
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(colors.textPrimary)
            
            Text("Take a photo of your meal and our AI will estimate the nutrition")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, DesignSystem.Spacing.md)
    }
    
    // MARK: - Photo Section
    
    private var photoSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            if let image = mealImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .strokeBorder(colors.neonPurple.opacity(0.3), lineWidth: 2)
                    )
                
                if isAnalyzing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(colors.neonPurple)
                        Text("Analyzing your meal...")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(colors.textSecondary)
                    }
                    .padding()
                }
                
                // Retake button
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Text("Retake Photo")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(colors.neonPurple)
                }
            } else {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(colors.neonPurple)
                        
                        Text("Tap to take or select a photo")
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(colors.textPrimary)
                        
                        Text("JPG, PNG supported")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundStyle(colors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge)
                            .fill(colors.backgroundCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                    .foregroundStyle(colors.neonPurple.opacity(0.3))
                            )
                    )
                }
            }
        }
    }
    
    // MARK: - Analysis Results
    
    private func analysisSection(_ analysis: MealAnalysis) -> some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Detected food
            VStack(spacing: 4) {
                Text("Detected")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(colors.textSecondary)
                Text(analysis.foodName)
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(colors.textPrimary)
                Text(analysis.description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(colors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            
            // Nutrition grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                nutritionTile(label: "Calories", value: "\(analysis.calories)", unit: "kcal", color: colors.neonOrange, icon: "flame.fill")
                nutritionTile(label: "Protein", value: String(format: "%.0f", analysis.protein), unit: "g", color: colors.protein, icon: "p.circle.fill")
                nutritionTile(label: "Carbs", value: String(format: "%.0f", analysis.carbs), unit: "g", color: colors.carbs, icon: "c.circle.fill")
                nutritionTile(label: "Fat", value: String(format: "%.0f", analysis.fat), unit: "g", color: colors.fat, icon: "f.circle.fill")
            }
            
            // Confidence
            HStack(spacing: 4) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(colors.neonGreen)
                    .font(.caption)
                Text("AI Confidence: \(Int(analysis.confidence * 100))%")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(colors.textSecondary)
            }
            
            // Action buttons
            HStack(spacing: DesignSystem.Spacing.md) {
                // Edit
                Button {
                    editName = analysis.foodName
                    editCalories = "\(analysis.calories)"
                    editProtein = String(format: "%.0f", analysis.protein)
                    editCarbs = String(format: "%.0f", analysis.carbs)
                    editFat = String(format: "%.0f", analysis.fat)
                    showingManualEdit = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundStyle(colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium).fill(colors.backgroundElevated))
                }
                .buttonStyle(.scaleButton)
                
                // Log
                Button {
                    logMeal(analysis)
                    Haptic.notification(.success)
                    dismiss()
                } label: {
                    Label("Log Meal", systemImage: "plus.circle.fill")
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium).fill(colors.neonGreen.gradient))
                }
                .buttonStyle(.scaleButton)
            }
        }
        .themedCard()
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .sheet(isPresented: $showingManualEdit) {
            editSheet
        }
    }
    
    private func nutritionTile(label: String, value: String, unit: String, color: Color, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 20)).foregroundStyle(color)
            HStack(alignment: .bottom, spacing: 2) {
                Text(value).font(DesignSystem.Typography.bodyBold).foregroundStyle(colors.textPrimary).monospacedDigit()
                Text(unit).font(DesignSystem.Typography.caption2).foregroundStyle(colors.textTertiary)
            }
            Text(label).font(DesignSystem.Typography.caption2).foregroundStyle(colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
            .fill(colors.backgroundCard)
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium).strokeBorder(color.opacity(0.2))))
    }
    
    private var editSheet: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.md) {
                fieldInput("Food Name", text: $editName, icon: "fork.knife")
                fieldInput("Calories", text: $editCalories, icon: "flame", keyboard: .numberPad)
                fieldInput("Protein (g)", text: $editProtein, icon: "p.circle", keyboard: .decimalPad)
                fieldInput("Carbs (g)", text: $editCarbs, icon: "c.circle", keyboard: .decimalPad)
                fieldInput("Fat (g)", text: $editFat, icon: "f.circle", keyboard: .decimalPad)
                Spacer()
                Button {
                    let corrected = MealAnalysis(
                        foodName: editName,
                        description: "Manually corrected",
                        calories: Int(editCalories) ?? 0,
                        protein: Double(editProtein) ?? 0,
                        carbs: Double(editCarbs) ?? 0,
                        fat: Double(editFat) ?? 0,
                        confidence: 1.0
                    )
                    logMeal(corrected)
                    Haptic.notification(.success)
                    showingManualEdit = false
                    dismiss()
                } label: {
                    Text("Save & Log")
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large).fill(colors.neonGreen.gradient))
                }
                .buttonStyle(.scaleButton)
            }
            .padding()
            .background(colors.background.ignoresSafeArea())
            .navigationTitle("Edit Nutrition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showingManualEdit = false }.foregroundStyle(colors.textSecondary)
                }
            }
        }
    }
    
    private func fieldInput(_ label: String, text: Binding<String>, icon: String, keyboard: UIKeyboardType = .default) -> some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon).font(.caption).foregroundStyle(colors.textTertiary).frame(width: 16)
            TextField(label, text: text).keyboardType(keyboard).foregroundStyle(colors.textPrimary)
        }
        .padding(DesignSystem.Spacing.sm)
        .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small).fill(colors.backgroundElevated))
    }
    
    // MARK: - Tips
    
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Label("Tips for best results", systemImage: "lightbulb.fill")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(colors.neonYellow)
            
            tipRow("Take a clear, top-down photo of your plate")
            tipRow("Include all items in the frame")
            tipRow("Good lighting helps the AI identify foods")
            tipRow("You can always edit the values after analysis")
            tipRow("Works best with Indian dishes, salads, and common meals")
        }
        .themedCard()
    }
    
    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•").foregroundStyle(colors.neonYellow)
            Text(text).font(DesignSystem.Typography.caption).foregroundStyle(colors.textSecondary)
        }
    }
    
    // MARK: - AI Analysis
    
    private func analyzeMeal(image: UIImage) {
        isAnalyzing = true
        analysis = nil
        
        // Simulate AI analysis (in production, this would send to MedGemma or a vision model)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isAnalyzing = false
            
            // Smart mock analysis based on common Indian meals
            let meals: [MealAnalysis] = [
                MealAnalysis(foodName: "Dal Tadka + 2 Roti", description: "Yellow lentil curry with whole wheat bread", calories: 420, protein: 15, carbs: 58, fat: 12, confidence: 0.85),
                MealAnalysis(foodName: "Chicken Biryani", description: "Basmati rice with spiced chicken", calories: 520, protein: 28, carbs: 55, fat: 20, confidence: 0.82),
                MealAnalysis(foodName: "Idli Sambar", description: "Steamed rice cakes with lentil stew", calories: 250, protein: 8, carbs: 45, fat: 4, confidence: 0.90),
                MealAnalysis(foodName: "Paneer Butter Masala + Naan", description: "Creamy tomato paneer curry with bread", calories: 550, protein: 22, carbs: 48, fat: 28, confidence: 0.78),
                MealAnalysis(foodName: "Mixed Vegetable Salad", description: "Fresh vegetables with light dressing", calories: 150, protein: 4, carbs: 20, fat: 6, confidence: 0.88),
                MealAnalysis(foodName: "Masala Dosa + Chutney", description: "Crispy rice crepe with potato filling", calories: 320, protein: 8, carbs: 45, fat: 12, confidence: 0.86),
            ]
            
            withAnimation(.spring(response: 0.6)) {
                analysis = meals.randomElement()
                animateIn = true
            }
        }
    }
    
    private func logMeal(_ analysis: MealAnalysis) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let log = DailyLog(
            date: formatter.string(from: Date()),
            foodName: analysis.foodName,
            estimatedCalories: analysis.calories,
            proteinG: analysis.protein,
            carbsG: analysis.carbs,
            fatG: analysis.fat
        )
        modelContext.insert(log)
        try? modelContext.save()
    }
}

// MARK: - Meal Analysis Model

struct MealAnalysis {
    let foodName: String
    let description: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let confidence: Double
}
