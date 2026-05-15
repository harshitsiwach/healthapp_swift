import SwiftUI

struct AIChatView: View {
    @Environment(\.theme) var colors
    @StateObject private var viewModel = AIChatViewModel()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                colors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 16)
                            .padding(.bottom, 20)
                        }
                        .onChange(of: viewModel.messages) { _, _ in
                            withAnimation {
                                proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                            }
                        }
                    }
                    
                    // Input Area
                    VStack(spacing: 8) {
                        if viewModel.isGenerating {
                            TypingIndicatorView(color: colors.neonBlue)
                                .frame(height: 30)
                                .padding(.vertical, 4)
                            
                            Button(action: {
                                viewModel.stopGenerating()
                            }) {
                                HStack {
                                    Image(systemName: "stop.circle.fill")
                                    Text("Stop Generating")
                                }
                                .font(.caption.bold())
                                .foregroundColor(colors.error)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(colors.error.opacity(0.1), in: Capsule())
                            }
                            .padding(.top, 4)
                        }
                        
                        HStack(alignment: .bottom, spacing: 12) {
                            TextField("Ask about your meals or health...", text: $viewModel.currentInput, axis: .vertical)
                                .focused($isInputFocused)
                                .lineLimit(1...5)
                                .padding(12)
                                .background {
                                    if #available(iOS 26, *) {
                                        GlassEffectContainer { }
                                    } else {
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(.regularMaterial)
                                    }
                                }
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(colors.cardBorder, lineWidth: 0.5)
                                )
                            
                            Button(action: {
                                viewModel.sendMessage()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(viewModel.currentInput.isEmpty ? colors.textTertiary.opacity(0.3) : colors.neonBlue)
                                        .frame(width: 44, height: 44)
                                        .shadow(color: viewModel.currentInput.isEmpty ? .clear : colors.neonBlue.opacity(0.3), radius: 6)
                                    
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(viewModel.currentInput.isEmpty ? .white.opacity(0.5) : .white)
                                }
                                .scaleEffect(isInputFocused ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isInputFocused)
                            }
                            .disabled(viewModel.currentInput.isEmpty || viewModel.isGenerating)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                        .padding(.top, 8)
                        .background {
                            if #available(iOS 26, *) {
                                Rectangle()
                                Color(uiColor: .systemBackground)
                                    .ignoresSafeArea(edges: .bottom)
                            } else {
                                colors.backgroundCard
                                    .ignoresSafeArea(edges: .bottom)
                            }
                        }
                    }
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Picker("Model", selection: $viewModel.selectedBackend) {
                        Text("Gemma (Local)").tag(AIBackendID.gemmaLocal)
                        Text("Apple (Local)").tag(AIBackendID.appleFoundation)
                    }
                    .pickerStyle(.menu)
                    .tint(.primary)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isInputFocused = false
                    }
                    .font(.subheadline)
                    .foregroundStyle(colors.neonBlue)
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
            if !message.isUser {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                    Text(message.backendName ?? "AI")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 4)
            }
            
            HStack {
                if message.isUser { Spacer(minLength: 40) }
                
                Text(message.text)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(MessageBubbleBackground(isUser: message.isUser))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(20)
                    .overlay(MessageBubbleOverlay(isUser: message.isUser))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
                
                if !message.isUser { Spacer(minLength: 40) }
            }
        }
    }
}

struct MessageBubbleBackground: View {
    let isUser: Bool
    
    var body: some View {
        if #available(iOS 26, *) {
            if isUser {
                Color.blue.opacity(0.8)
            } else {
                GlassEffectContainer { }
            }
        } else {
            if isUser {
                Color.blue
            } else {
                Color(UIColor.secondarySystemGroupedBackground)
            }
        }
    }
}

struct MessageBubbleOverlay: View {
    let isUser: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(isUser ? Color.white.opacity(0.2) : Color.white.opacity(0.3), lineWidth: 0.5)
    }
}

struct TypingIndicatorView: View {
    let color: Color
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationOffset == CGFloat(index) ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.4)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.15),
                        value: animationOffset
                    )
            }
        }
        .onAppear {
            animationOffset = 1
        }
    }
}
