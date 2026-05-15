import SwiftUI

struct WaterIntakeSheet: View {
    @Environment(\.theme) var colors
    @Environment(\.dismiss) var dismiss
    
    let currentML: Int
    let goal: Int
    let onAdd: (Int) -> Void
    
    @State private var customAmount: String = ""
    
    let quickAmounts = [250, 500, 750]
    
    var body: some View {
        NavigationStack {
            ZStack {
                colors.background.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Status
                    VStack(spacing: 8) {
                        Text("\(currentML) / \(goal) ml")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(colors.neonBlue)
                        
                        ProgressView(value: Double(currentML), total: Double(goal))
                            .tint(colors.neonBlue)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 40)
                    
                    // Quick Buttons
                    HStack(spacing: 16) {
                        ForEach(quickAmounts, id: \.self) { amount in
                            Button {
                                onAdd(amount)
                                dismiss()
                            } label: {
                                VStack {
                                    Image(systemName: "drop.fill")
                                    Text("\(amount)ml")
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Custom Entry
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Custom Amount")
                            .font(.headline)
                        
                        HStack {
                            TextField("Enter ml", text: $customAmount)
                                .keyboardType(.numberPad)
                                .padding(16)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                            
                            Button {
                                if let amount = Int(customAmount) {
                                    onAdd(amount)
                                    dismiss()
                                }
                            } label: {
                                Text("Add")
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 16)
                                    .background(colors.neonBlue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Hydration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
