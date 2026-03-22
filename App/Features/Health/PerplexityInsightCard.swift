import SwiftUI

struct PerplexityInsightCard: View {
    @StateObject private var service = PerplexityTrendInsightsService.shared
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.purple)
                    Text("Weekly Trend Insight")
                        .font(.headline)
                    Spacer()
                    if service.currentInsight != nil {
                        BackendBadge(backendID: .perplexitySonar, modelName: "sonar-pro")
                    }
                }
                
                if service.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if let error = service.errorMessage {
                    Text("Error: \(error)")
                        .font(.caption)
                        .foregroundColor(.red)
                } else if let insight = service.currentInsight {
                    Text(insight)
                        .font(.subheadline)
                        .lineSpacing(4)
                } else {
                    Button(action: {
                        Task {
                            await service.generateWeeklyInsight()
                        }
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Generate Insight")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .font(.caption.bold())
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                }
            }
        }
    }
}

#Preview {
    PerplexityInsightCard()
        .padding()
}
