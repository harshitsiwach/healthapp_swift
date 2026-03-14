import SwiftUI

struct AIChatView: View {
    @StateObject private var viewModel = AIChatViewModel()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                
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
                        
                        HStack(alignment: .bottom, spacing: 12) {
                            TextField("Ask about your meals or health...", text: $viewModel.currentInput, axis: .vertical)
                                .focused($isInputFocused)
                                .lineLimit(1...5)
                                .padding(12)
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(uiColor: .separator), lineWidth: 0.5)
                                )
                            
                            Button(action: {
                                viewModel.sendMessage()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(viewModel.currentInput.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(viewModel.currentInput.isEmpty ? .gray : .white)
                                }
                            }
                            .disabled(viewModel.currentInput.isEmpty || viewModel.isGenerating)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                        .padding(.top, 8)
                        .background(Color(uiColor: .systemGroupedBackground))
                    }
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        isInputFocused = false
                    }
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
                    .background(message.isUser ? Color.blue : Color(uiColor: .secondarySystemGroupedBackground))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(message.isUser ? Color.clear : Color(uiColor: .separator).opacity(0.5), lineWidth: 0.5)
                    )
                
                if !message.isUser { Spacer(minLength: 40) }
            }
        }
    }
}
