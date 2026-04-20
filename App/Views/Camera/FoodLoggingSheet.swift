import SwiftUI
import SwiftData

struct FoodLoggingSheet: View {
    @Environment(\.theme) var colors
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var camera = CameraManager()
    @StateObject private var viewModel = FoodLoggingViewModel()
    
    @State private var showCamera = true
    @State private var textInput = ""
    @State private var useTextMode = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                colors.background.ignoresSafeArea()
                
                Group {
                    switch viewModel.state {
                    case .idle:
                        inputView
                    case .analyzing:
                        analyzingView
                    case .review:
                        reviewView
                    case .error(let message):
                        errorView(message: message)
                    }
                }
            }
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        camera.stopSession()
                        dismiss()
                    }
                }
            }
        }
        .onDisappear {
            camera.stopSession()
        }
    }
    
    // MARK: - Input View
    
    private var inputView: some View {
        VStack(spacing: 0) {
            if useTextMode {
                textInputView
            } else {
                cameraInputView
            }
            
            // Toggle
            Button {
                withAnimation(.spring(response: 0.3)) {
                    useTextMode.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: useTextMode ? "camera.fill" : "keyboard")
                    Text(useTextMode ? "Use Camera" : "Type Instead")
                }
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.medium)
                .foregroundStyle(colors.neonBlue)
                .padding(.vertical, 12)
            }
        }
    }
    
    private var cameraInputView: some View {
        VStack(spacing: 20) {
            if let image = camera.capturedImage {
                // Show captured image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)
                
                HStack(spacing: 16) {
                    Button {
                        camera.capturedImage = nil
                    } label: {
                        Text("Retake")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(colors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        viewModel.analyzeImage(image)
                    } label: {
                        Text("Analyze ✨")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(colors.neonBlue.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
            } else {
                // Camera preview
                CameraPreview(session: camera.session)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)
                    .overlay(alignment: .bottom) {
                        Button {
                            camera.capturePhoto()
                        } label: {
                            Circle()
                                .fill(.white)
                                .frame(width: 72, height: 72)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.5), lineWidth: 3)
                                        .frame(width: 80, height: 80)
                                )
                        }
                        .padding(.bottom, 20)
                    }
            }
        }
    }
    
    private var textInputView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(colors.neonBlue)
            
            Text("What did you eat?")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.heavy)
            
            Text("e.g., \"2 roti and dal\" or \"1 plate chole chawal\"")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(colors.textSecondary)
                .multilineTextAlignment(.center)
            
            GlassCard {
                TextField("Describe your meal...", text: $textInput, axis: .vertical)
                    .font(.system(.body, design: .rounded))
                    .lineLimit(3...6)
            }
            .padding(.horizontal, 16)
            
            Button {
                guard !textInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                viewModel.analyzeText(textInput)
            } label: {
                Text("Analyze ✨")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(textInput.isEmpty ? AnyShapeStyle(Color.gray) : AnyShapeStyle(colors.neonBlue.gradient))
                    )
            }
            .buttonStyle(.plain)
            .disabled(textInput.isEmpty)
            .padding(.horizontal, 16)
            
            Spacer()
        }
    }
    
    // MARK: - Analyzing View
    
    private var analyzingView: some View {
        VStack(spacing: 24) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Analyzing your meal...")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
            Text("Our AI nutritionist is estimating calories")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(colors.textSecondary)
            Spacer()
        }
    }
    
    // MARK: - Review View
    
    private var reviewView: some View {
        ScrollView {
            VStack(spacing: 20) {
                GlassCard(material: .regularMaterial) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Review & Save")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.heavy)
                            Spacer()
                            Image(systemName: "sparkles")
                                .foregroundStyle(colors.neonBlue)
                        }
                        
                        editableField(label: "Food Name", text: $viewModel.foodName)
                        editableNumField(label: "Calories (kcal)", value: $viewModel.estimatedCalories)
                        editableDoubleField(label: "Protein (g)", value: $viewModel.proteinG)
                        editableDoubleField(label: "Carbs (g)", value: $viewModel.carbsG)
                        editableDoubleField(label: "Fat (g)", value: $viewModel.fatG)
                    }
                }
                
                Button {
                    saveMeal()
                } label: {
                    Text("Save Meal ✅")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.green.gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(colors.neonOrange)
            Text("Something went wrong")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
            Text(message)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button {
                viewModel.state = .idle
            } label: {
                Text("Try Again")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.blue.gradient, in: Capsule())
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }
    
    // MARK: - Field Helpers
    
    private func editableField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(colors.textSecondary)
            TextField(label, text: text)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
                .padding(10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private func editableNumField(label: String, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(colors.textSecondary)
            TextField(label, value: value, format: .number)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
                .keyboardType(.numberPad)
                .padding(10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private func editableDoubleField(label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(colors.textSecondary)
            TextField(label, value: value, format: .number.precision(.fractionLength(1)))
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
                .keyboardType(.decimalPad)
                .padding(10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private func saveMeal() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        
        let log = DailyLog(
            date: today,
            foodName: viewModel.foodName,
            estimatedCalories: viewModel.estimatedCalories,
            proteinG: viewModel.proteinG,
            carbsG: viewModel.carbsG,
            fatG: viewModel.fatG,
            imageUri: viewModel.savedImagePath
        )
        
        modelContext.insert(log)
        try? modelContext.save()
        dismiss()
    }
}
