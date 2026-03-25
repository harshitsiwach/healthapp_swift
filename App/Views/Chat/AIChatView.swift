import SwiftUI

struct AIChatView: View {
    @StateObject private var viewModel = AIChatViewModel()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                GradientBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    messageList
                    inputArea
                }
            }
            .navigationTitle("Perplexity Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    BackendSelectorView(selection: $viewModel.selectedBackend)
                }
            }
        }
    }
    
    private var messageList: some View {
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
    }
    
    private var inputArea: some View {
        VStack(spacing: 8) {
            if viewModel.isGenerating {
                stopGeneratingButton
            }
            
            HStack(alignment: .bottom, spacing: 12) {
                textFieldArea
                sendButton
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            .padding(.top, 8)
            .background(inputBackground)
        }
    }
    
    private var stopGeneratingButton: some View {
        Button(action: {
            viewModel.stopGenerating()
        }) {
            HStack {
                Image(systemName: "stop.circle.fill")
                Text("Stop Generating")
            }
            .font(.caption.bold())
            .foregroundColor(.red)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Color.red.opacity(0.1), in: Capsule())
        }
        .padding(.top, 4)
    }
    
    private var textFieldArea: some View {
        TextField("Ask about your meals or health...", text: $viewModel.currentInput, axis: .vertical)
            .focused($isInputFocused)
            .lineLimit(1...5)
            .padding(12)
            .background(textFieldBackground)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
    }
    
    private var sendButton: some View {
        Button(action: {
            viewModel.sendMessage()
        }) {
            ZStack {
                Circle()
                    .fill(viewModel.currentInput.isEmpty ? AnyShapeStyle(Color.gray.opacity(0.3)) : AnyShapeStyle(PerplexityTheme.brandGradient))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "arrow.up")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(viewModel.currentInput.isEmpty ? .white.opacity(0.5) : .white)
            }
            .scaleEffect(isInputFocused ? 1.05 : 1.0)
            .animation(.spring(), value: isInputFocused)
        }
        .disabled(viewModel.currentInput.isEmpty || viewModel.isGenerating)
    }
    
    @ViewBuilder
    private var textFieldBackground: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer { }
        } else {
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        }
    }
    
    @ViewBuilder
    private var inputBackground: some View {
        if #available(iOS 26, *) {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        } else {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea(edges: .bottom)
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
                        .foregroundColor(PerplexityTheme.accent)
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
                PerplexityTheme.surface.opacity(0.9)
            } else {
                GlassEffectContainer { }
            }
        } else {
            if isUser {
                PerplexityTheme.surface
            } else {
                Color(UIColor.secondarySystemGroupedBackground).opacity(0.1)
            }
        }
    }
}

struct MessageBubbleOverlay: View {
    let isUser: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(isUser ? PerplexityTheme.accent.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
    }
}
