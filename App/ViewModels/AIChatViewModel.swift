import Foundation
import SwiftUI

// MARK: - Chat Message Model
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
    var backendName: String?
    
    init(text: String, isUser: Bool, backendName: String? = nil) {
        self.text = text
        self.isUser = isUser
        self.timestamp = Date()
        self.backendName = backendName
    }
}

// MARK: - Chat ViewModel
@MainActor
final class AIChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentInput: String = ""
    @Published var isGenerating: Bool = false
    @Published var selectedBackend: AIBackendID = .gemmaLocal {
        didSet {
            orchestrator.activeBackendOverride = selectedBackend
        }
    }
    
    private let orchestrator = AIOrchestrator.shared
    private var activeStreamTask: Task<Void, Never>?
    
    init() {
        // Add a welcome message
        messages.append(ChatMessage(
            text: "Hi! I'm your health AI. I'm running directly on your device when possible. How can I help you with your meals or nutrition today?",
            isUser: false,
            backendName: "System"
        ))
        // Set initial override based on the published state
        self.orchestrator.activeBackendOverride = self.selectedBackend
    }
    
    func sendMessage() {
        let input = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        
        // Add user message
        messages.append(ChatMessage(text: input, isUser: true))
        currentInput = ""
        isGenerating = true
        
        // Add an empty AI message to stream into
        messages.append(ChatMessage(text: "", isUser: false, backendName: "Thinking..."))
        
        activeStreamTask = Task {
            let request = AIRequest(
                task: .chat,
                userPrompt: input,
                systemPrompt: "You are a friendly Indian health and nutrition assistant. Keep your answers concise, practical, and focused on wellness. Suggest culturally appropriate Indian foods when asked.",
                generationConfig: GenerationPreset.fastChat.config
            )
            
            do {
                let stream = orchestrator.stream(request)
                
                var fullResponse = ""
                var backendAttribution: AIBackendAttribution?
                
                for try await event in stream {
                    guard !Task.isCancelled else { break }
                    
                    fullResponse += event.token
                    
                    // We don't have the attribution in the token event directly in this simple version, 
                    // but we can infer it or update it at the end if we had it.
                    // For now, update the last message text:
                    if let lastIndex = messages.indices.last {
                        messages[lastIndex] = ChatMessage(
                            text: fullResponse,
                            isUser: false,
                            backendName: "AI Model" // Will update when generation finishes if we can
                        )
                    }
                }
                
                // Fetch the backend used for display (we can get it actively)
                let activeBackend = try await orchestrator.activeBackend(for: .chat)
                if let lastIndex = messages.indices.last {
                    messages[lastIndex] = ChatMessage(
                        text: fullResponse,
                        isUser: false,
                        backendName: activeBackend.displayName
                    )
                }
                
            } catch {
                if let lastIndex = messages.indices.last {
                    messages[lastIndex] = ChatMessage(
                        text: "Sorry, I ran into an error: \(error.localizedDescription)",
                        isUser: false,
                        backendName: "Error"
                    )
                }
            }
            
            isGenerating = false
        }
    }
    
    func stopGenerating() {
        activeStreamTask?.cancel()
        isGenerating = false
    }
}
