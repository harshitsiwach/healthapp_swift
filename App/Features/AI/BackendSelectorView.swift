import SwiftUI

struct BackendSelectorView: View {
    @Binding var selection: AIBackendID
    
    var body: some View {
        Menu {
            Picker("Model", selection: $selection) {
                Text("Apple (Local)").tag(AIBackendID.appleFoundation)
                Text("Qwen (Local)").tag(AIBackendID.qwenLocal)
                Text("Gemini (Cloud)").tag(AIBackendID.geminiRemote)
                Text("Perplexity (Cloud)").tag(AIBackendID.perplexitySonar)
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "cpu")
                Text(labelFor(selection))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
            }
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(uiColor: .tertiarySystemFill), in: Capsule())
            .foregroundColor(.primary)
        }
    }
    
    private func labelFor(_ id: AIBackendID) -> String {
        switch id {
        case .appleFoundation: return "Apple"
        case .qwenLocal: return "Qwen"
        case .geminiRemote: return "Gemini"
        case .perplexitySonar: return "Perplexity"
        }
    }
}
