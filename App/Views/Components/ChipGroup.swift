import SwiftUI

struct ChipGroup: View {
    let options: [String]
    @Binding var selected: String
    var columns: Int = 0 // 0 = flow layout
    var accentColor: Color = .blue
    
    var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer {
                if columns > 0 {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columns), spacing: 10) {
                        chipButtonsIOS26
                    }
                } else {
                    FlowLayout(spacing: 10) {
                        chipButtonsIOS26
                    }
                }
            }
        } else {
            if columns > 0 {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columns), spacing: 10) {
                    chipButtons
                }
            } else {
                FlowLayout(spacing: 10) {
                    chipButtons
                }
            }
        }
    }
    
    @available(iOS 26, *)
    @ViewBuilder
    private var chipButtonsIOS26: some View {
        ForEach(options, id: \.self) { option in
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selected = option
                }
            } label: {
                Text(option)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(selected == option ? .bold : .medium)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .glassEffect(selected == option ? .regular.tint(accentColor).interactive() : .regular.interactive(), in: .capsule)
                    .foregroundStyle(selected == option ? .white : .primary)
                    .overlay(
                        Capsule()
                            .stroke(selected == option ? Color.clear : Color.gray.opacity(0.2), lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)
            .scaleEffect(selected == option ? 1.05 : 1.0)
        }
    }

    @ViewBuilder
    private var chipButtons: some View {
        ForEach(options, id: \.self) { option in
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selected = option
                }
            } label: {
                Text(option)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(selected == option ? .bold : .medium)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if selected == option {
                                Capsule()
                                    .fill(accentColor.gradient)
                            } else {
                                Capsule()
                                    .fill(.ultraThinMaterial)
                            }
                        }
                    )
                    .foregroundStyle(selected == option ? .white : .primary)
                    .overlay(
                        Capsule()
                            .stroke(selected == option ? Color.clear : Color.gray.opacity(0.2), lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)
            .scaleEffect(selected == option ? 1.05 : 1.0)
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }
        
        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}

// MARK: - Number Chip Group

struct NumberChipGroup: View {
    let range: ClosedRange<Int>
    @Binding var selected: Int
    var accentColor: Color = .blue
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            if #available(iOS 26, *) {
                GlassEffectContainer {
                    HStack(spacing: 10) {
                        numberButtonsIOS26
                    }
                    .padding(.horizontal, 4)
                }
            } else {
                HStack(spacing: 10) {
                    numberButtons
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    @available(iOS 26, *)
    @ViewBuilder
    private var numberButtonsIOS26: some View {
        ForEach(Array(range), id: \.self) { number in
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selected = number
                }
            } label: {
                Text("\(number)")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(selected == number ? .bold : .medium)
                    .frame(width: 44, height: 44)
                    .glassEffect(selected == number ? .regular.tint(accentColor).interactive() : .regular.interactive(), in: .circle)
                    .foregroundStyle(selected == number ? .white : .primary)
            }
            .buttonStyle(.plain)
            .scaleEffect(selected == number ? 1.1 : 1.0)
        }
    }
    
    @ViewBuilder
    private var numberButtons: some View {
        ForEach(Array(range), id: \.self) { number in
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selected = number
                }
            } label: {
                Text("\(number)")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(selected == number ? .bold : .medium)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(selected == number ? AnyShapeStyle(accentColor.gradient) : AnyShapeStyle(.ultraThinMaterial))
                    )
                    .foregroundStyle(selected == number ? .white : .primary)
            }
            .buttonStyle(.plain)
            .scaleEffect(selected == number ? 1.1 : 1.0)
        }
    }
}
