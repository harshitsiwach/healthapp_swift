import SwiftUI

struct BackendBadge: View {
    let backendID: AIBackendID
    let modelName: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
            Text(displayName)
            if !modelName.isEmpty {
                Text("• \(modelName)")
                    .opacity(0.7)
            }
        }
        .font(.system(size: 10, weight: .medium))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor.opacity(0.15))
        .foregroundColor(backgroundColor)
        .clipShape(Capsule())
    }
    
    private var iconName: String {
        switch backendID {
        case .appleFoundation: return "applelogo"
        case .qwenLocal: return "cpu"
        case .geminiRemote: return "sparkles"
        case .perplexitySonar: return "globe.americas.fill"
        }
    }
    
    private var displayName: String {
        switch backendID {
        case .appleFoundation: return "Apple Intelligence"
        case .qwenLocal: return "Local AI"
        case .geminiRemote: return "Gemini"
        case .perplexitySonar: return "Perplexity"
        }
    }
    
    private var backgroundColor: Color {
        switch backendID {
        case .appleFoundation: return .primary
        case .qwenLocal: return .orange
        case .geminiRemote: return .purple
        case .perplexitySonar: return .teal
        }
    }
}
