import SwiftUI

struct CitationPill: View {
    let index: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("[\(index)]")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.15))
                .foregroundColor(.blue)
                .clipShape(Capsule())
        }
    }
}
