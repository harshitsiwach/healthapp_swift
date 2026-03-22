import SwiftUI

struct PerplexityFoodReviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    let analysisText: String
    let citations: [String]
    let onSave: () -> Void
    
    @State private var showingSources = false
    
    var body: some View {
        NavigationView {
            ZStack {
                GradientBackground().ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "sparkles.rectangle.stack.fill")
                                        .foregroundColor(.teal)
                                    Text("Perplexity Analysis")
                                        .font(.headline)
                                    Spacer()
                                    BackendBadge(backendID: .perplexitySonar, modelName: "sonar-pro")
                                }
                                
                                Divider()
                                
                                Text(analysisText)
                                    .font(.body)
                                    .lineSpacing(4)
                            }
                        }
                        
                        if !citations.isEmpty {
                            GlassCard {
                                HStack {
                                    Image(systemName: "link")
                                        .foregroundColor(.blue)
                                    Text("Sources Evaluated")
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Button("View \(citations.count)") {
                                        showingSources = true
                                    }
                                    .font(.caption.bold())
                                    .buttonStyle(.borderedProminent)
                                    .tint(.blue)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Meal Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save Logs") {
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .sheet(isPresented: $showingSources) {
                EvidenceSheet(citations: citations)
            }
        }
    }
}

#Preview {
    PerplexityFoodReviewView(
        analysisText: "This meal appears to be a balanced dinner with approximately 450 kcal.",
        citations: ["https://nutritiondata.self.com", "https://fdc.nal.usda.gov"],
        onSave: {}
    )
}
