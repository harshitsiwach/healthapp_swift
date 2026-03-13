import Foundation

// MARK: - Grounded Answer Service

@MainActor
final class GroundedAnswerService {
    
    private let retriever: DocumentRetriever
    private let orchestrator: AIOrchestrator
    private let safetyFilter: HealthSafetyFilter
    
    struct GroundedAnswer {
        let answer: String
        let evidence: [DocumentRetriever.DocumentChunk]
        let confidence: Double
        let disclaimer: String?
    }
    
    init(
        retriever: DocumentRetriever? = nil,
        orchestrator: AIOrchestrator? = nil,
        safetyFilter: HealthSafetyFilter? = nil
    ) {
        self.retriever = retriever ?? DocumentRetriever()
        self.orchestrator = orchestrator ?? AIOrchestrator()
        self.safetyFilter = safetyFilter ?? HealthSafetyFilter()
    }
    
    // MARK: - Supported Actions
    
    enum DocumentAction: String, CaseIterable {
        case summarize = "Summarize Report"
        case explainAbnormal = "Explain Abnormal Values"
        case extractMedicines = "Extract Medicines"
        case explainDoctorNote = "Explain Doctor Note"
        case simplifyEnglish = "Simplify to Plain English"
        case generateFollowUp = "Generate Follow-up Questions"
        
        var prompt: String {
            switch self {
            case .summarize:
                return "Summarize this medical report in simple, patient-friendly language. Highlight the key findings."
            case .explainAbnormal:
                return "Identify and explain any abnormal values in this report. What do they mean for the patient?"
            case .extractMedicines:
                return "Extract all medicines, supplements, and treatments mentioned in this document."
            case .explainDoctorNote:
                return "Explain this doctor's note in simple language that a patient can understand."
            case .simplifyEnglish:
                return "Rewrite this medical text in plain, easy-to-understand English."
            case .generateFollowUp:
                return "Based on this report, generate 5 important follow-up questions the patient should ask their doctor."
            }
        }
    }
    
    // MARK: - Answer Generation
    
    func answer(
        query: String,
        action: DocumentAction? = nil,
        topK: Int = 5
    ) async throws -> GroundedAnswer {
        // Safety check
        let safety = await safetyFilter.checkInput(query, task: .medicalDocQA)
        if case .blocked(let category) = safety {
            return GroundedAnswer(
                answer: safetyFilter.safetyMessage(for: category),
                evidence: [],
                confidence: 0,
                disclaimer: safetyFilter.generalDisclaimer
            )
        }
        
        // Retrieve relevant chunks
        let chunks = retriever.retrieve(query: action?.prompt ?? query, topK: topK)
        
        guard !chunks.isEmpty else {
            throw AIError.retrievalEmpty
        }
        
        // Build context from chunks
        let context = chunks.map { "[\($0.sourceName) p.\($0.pageNumber ?? 0)]: \($0.text)" }.joined(separator: "\n\n")
        
        let systemPrompt = """
        You are a medical report assistant. Answer ONLY based on the provided evidence.
        Do not make up information. If the evidence doesn't contain the answer, say so.
        Always add a disclaimer that this is for educational purposes only.
        Present information clearly and in simple language.
        """
        
        let userPrompt = """
        Evidence:
        \(context)
        
        Question: \(action?.prompt ?? query)
        """
        
        let request = AIRequest(
            task: .medicalDocQA,
            userPrompt: userPrompt,
            systemPrompt: systemPrompt,
            retrievedContext: chunks.map { chunk in
                AIRetrievedChunk(
                    text: chunk.text,
                    sourceID: chunk.sourceID,
                    sourceName: chunk.sourceName,
                    relevanceScore: chunk.relevanceScore,
                    pageNumber: chunk.pageNumber
                )
            },
            generationConfig: GenerationPreset.medicalDocQA.config
        )
        
        let response = try await orchestrator.generate(request)
        
        return GroundedAnswer(
            answer: response.text,
            evidence: chunks,
            confidence: chunks.first?.relevanceScore ?? 0,
            disclaimer: safetyFilter.generalDisclaimer
        )
    }
}
