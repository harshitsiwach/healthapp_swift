import SwiftUI

struct EvidenceSheet: View {
    let citations: [String]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(citations.enumerated()), id: \.offset) { index, citation in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("[\(index + 1)]")
                                .font(.caption.bold())
                                .foregroundColor(.blue)
                            Text(formatDomain(from: citation))
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                        }
                        
                        Link(destination: URL(string: citation) ?? URL(string: "https://perplexity.ai")!) {
                            Text(citation)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Sources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDomain(from urlString: String) -> String {
        guard let url = URL(string: urlString), let host = url.host else {
            return "Web Source"
        }
        return host.replacingOccurrences(of: "www.", with: "")
    }
}
