# AI_INTEGRATION.md

Use the content below as a separate file.

***

# AI Integration Instructions

## Goal

Integrate private, on-device AI into the native iOS app so the product can run local language-model features for nutrition guidance, food understanding, report explanation, and grounded medical Q&A.

This file only covers AI integration.  
Do not use this file for UI migration, navigation recreation, or non-AI app-shell work.

The AI layer must be modular, swappable, measurable, and safe.  
The app must support local inference first, with any remote fallback hidden behind explicit feature flags.

## Runtime facts

Apple’s Foundation Models framework is available on iOS 26+ and provides access to Apple’s on-device model for language understanding, structured output, and tool calling, and it works on Apple Intelligence-compatible devices when Apple Intelligence is enabled. [developer.apple](https://developer.apple.com/documentation/FoundationModels)
Qwen3.5-0.8B is published in Hugging Face Transformers format, supports 201 languages and dialects, and runs in non-thinking mode by default. [huggingface](https://huggingface.co/Qwen/Qwen3.5-0.8B-Base)
Swift libraries such as LocalLLMClient show that iOS local inference can be exposed behind a shared interface over llama.cpp and MLX, with support for streaming and multimodal usage. [dev](https://dev.to/tattn/localllmclient-a-swift-package-for-local-llms-using-llamacpp-and-mlx-1bcp)

## Primary architecture decision

Do not bind product features directly to a single model runtime.

Create a backend-agnostic AI layer with two runtime paths:

- `AppleFoundationBackend`
- `CustomLocalModelBackend`

The app must always talk to a single orchestration layer, never directly to a backend from a view or view model.

## Required architecture

Create these top-level modules:

- `AI/Backends`
- `AI/Core`
- `AI/Models`
- `AI/Prompts`
- `AI/Retrieval`
- `AI/Safety`
- `AI/Telemetry`

Create this protocol:

```swift
protocol AIBackend {
    var id: String { get }
    var displayName: String { get }
    var supportsVision: Bool { get }
    var supportsToolCalling: Bool { get }
    var maxContextWindow: Int? { get }

    func prepare() async throws
    func warmup() async
    func generate(_ request: AIRequest) async throws -> AIResponse
    func stream(_ request: AIRequest) -> AsyncThrowingStream<AITokenEvent, Error>
    func cancelCurrentGeneration()
    func healthCheck() async -> AIBackendHealth
}
```

Create these concrete implementations:

- `AppleFoundationBackend`
- `QwenLocalBackend`

Create one orchestrator:

```swift
protocol AIOrchestrating {
    func activeBackend(for task: AITask) async -> AIBackend
    func generate(_ request: AIRequest) async throws -> AIResponse
    func stream(_ request: AIRequest) -> AsyncThrowingStream<AITokenEvent, Error>
}
```

The entire app must call the orchestrator, not individual backends.

## Backend selection rules

Use this runtime selection order:

1. `QwenLocalBackend` if custom model is installed, verified, and healthy.
2. `AppleFoundationBackend` if device capability is available and the feature flag is enabled.
3. Remote fallback only if explicitly enabled for that feature and that user state.

Keep this logic inside `AIOrchestrator`.  
Never spread backend-choice logic across screens.

## Apple backend instructions

Implement `AppleFoundationBackend` as an optional acceleration path, not the only AI path.

Use it for:

- summarization
- structured extraction
- short-form grounded rewriting
- tool-driven response formatting
- fallback chat on supported devices

Do not assume every user device supports it.  
All capability checks must be runtime-based.

Add a dedicated capability service:

```swift
struct AppleModelCapability {
    let isSupportedOS: Bool
    let isAppleIntelligenceCapable: Bool
    let isAppleIntelligenceEnabled: Bool
    let canUseFoundationModels: Bool
}
```

This backend should be easy to disable from configuration.  
No product-critical flow should hard depend on Apple’s backend alone.

## Qwen backend instructions

Implement `QwenLocalBackend` as the main portable local-model path.

Do not try to run raw Hugging Face model files directly inside the app.  
Instead, require a separate model-preparation pipeline outside the iOS app that converts and packages approved source checkpoints into the runtime format your iOS inference layer expects.

Create a standalone model prep pipeline that does the following:

1. Download approved model source weights.
2. Convert to app runtime format.
3. Quantize to target profile.
4. Generate manifest metadata.
5. Generate checksum.
6. Run smoke tests.
7. Publish versioned artifacts for app download.

The app itself must only consume prepared model artifacts.  
It must not perform training, conversion, or heavy build-time model transforms on device.

## Runtime implementation guidance

Use a custom local runtime boundary so the app owns the interface even if the underlying engine changes later.

Accepted engine directions:

- llama.cpp-style runtime
- MLX-based runtime
- thin wrapper over one of the above if it speeds up prototyping

Do not make the wrapper the center of the design.  
Your app’s own backend abstraction is the stable contract.

The Qwen backend must support:

- prompt submission
- token streaming
- cancellation
- warmup
- health checks
- runtime metrics
- model unload or memory relief hooks

## AI request model

Create a unified request type:

```swift
struct AIRequest {
    let task: AITask
    let systemPrompt: String?
    let userPrompt: String
    let images: [AIImageInput]
    let retrievedContext: [AIRetrievedChunk]
    let generationConfig: GenerationConfig
    let tools: [AIToolDefinition]
    let outputSchema: AIOutputSchema?
    let conversationID: String?
}
```

Supported task enums should include:

- `chat`
- `nutritionSummary`
- `foodAnalysis`
- `medicalDocQA`
- `reportSummary`
- `structuredExtraction`
- `healthCaution`
- `ocrRewrite`

Keep tasks explicit.  
Do not use one generic “chat everything” mode for all product flows.

## Generation profiles

Create configurable presets:

- `fast_chat`
- `nutrition_summary`
- `food_analysis`
- `medical_doc_qa`
- `report_simplify`
- `health_caution`

Each preset should contain:

- temperature
- max output tokens
- top-p
- repetition penalty if supported
- stop tokens if supported
- timeout budget

Store presets centrally.  
Do not hardcode generation settings inside views.

## Model asset management

Create these types:

- `ModelManifest`
- `ModelInstallState`
- `ModelStore`
- `ModelDownloader`
- `ModelIntegrityValidator`
- `ModelVersionManager`

The manifest must include:

```json
{
  "id": "qwen3_5_0_8b_local_q4",
  "display_name": "Qwen3.5 0.8B Local",
  "runtime": "custom_local",
  "version": "1.0.0",
  "quantization": "q4",
  "file_size_bytes": 0,
  "checksum_sha256": "",
  "supports_vision": false,
  "supports_tool_calling": false,
  "context_window": 0,
  "min_ios_version": "18.0",
  "download_url": "",
  "license": ""
}
```

Required downloader behavior:

- resumable downloads
- progress updates
- checksum verification
- version cleanup
- low-storage detection
- interrupted-download recovery

Expose model state in UI:

- not installed
- downloading
- verifying
- ready
- warming up
- failed
- incompatible

## Local storage and privacy

Store model files in app-controlled storage, not user-visible document space unless there is a clear product reason.

Sensitive app data that must remain local by default:

- uploaded medical reports
- OCR output
- retrieval chunks
- generated summaries
- chat history
- model install metadata

Add user controls for:

- delete downloaded model
- clear AI cache
- clear document index
- clear all AI-derived data

AI history deletion must actually remove local artifacts, not only hide them from UI.

## Retrieval-first design

Do not force the local model to memorize nutrition facts or user medical documents.

Use retrieval-first architecture for all factual flows:

### Food and nutrition flow

1. Parse meal input from image or text.
2. Normalize to canonical dish candidates.
3. Estimate portion or ask a clarifying question.
4. Pull structured nutrition facts from the local database.
5. Ask the model to explain the result in plain language.

### Medical document flow

1. Import PDF or image.
2. OCR if needed.
3. Chunk into retrievable units.
4. Save chunk text plus metadata.
5. Retrieve top relevant chunks for a question.
6. Generate an answer only from retrieved evidence.

The model should explain, simplify, and personalize.  
The database and retrieval layer should provide factual grounding.

## OCR and document pipeline

Create these components:

- `DocumentImporter`
- `OCRService`
- `DocumentChunker`
- `DocumentIndex`
- `DocumentRetriever`
- `GroundedAnswerService`

Minimum supported user actions:

- summarize report
- explain abnormal values
- extract medicines
- explain doctor note
- simplify into plain English
- simplify into plain Hindi later
- generate follow-up questions

Every document answer must carry evidence payloads.  
The UI must show supporting chunks under the answer.

## Food understanding pipeline

Create these components:

- `MealInputParser`
- `FoodNormalizer`
- `PortionEstimator`
- `NutritionLookupService`
- `FoodExplanationService`

The AI model must not be the source of truth for calories when structured data exists.

Required response structure for food analysis:

- identified dish name
- confidence band
- estimated portion
- calories
- macro summary
- good points
- cautions
- suggested healthier alternative if relevant

If dish confidence is low, ask a follow-up question instead of hallucinating.

## Streaming UX requirements

Local AI must stream tokens to the UI.

Required UI states:

- model unavailable
- model downloading
- verifying install
- warming up
- generating
- cancelled
- failed

Required interaction controls:

- send
- stop generation
- regenerate
- copy
- inspect evidence
- inspect model source

Expose whether the answer came from:

- local custom model
- Apple on-device model
- remote fallback

## Safety and health constraints

This app is health-adjacent, so outputs must be framed as educational and assistive.

Never allow the model layer to present itself as diagnosing, prescribing, or replacing a clinician.

Build safety checks for:

- emergency symptoms
- severe chest pain
- stroke-like symptoms
- suicidal ideation
- pediatric high-risk advice
- pregnancy-critical advice
- medication dosing
- treatment changes

When high-risk patterns are detected:

1. stop normal generation
2. show a safety-first response
3. recommend urgent clinician or emergency help where appropriate
4. avoid definitive diagnosis

Safety should run both before and after generation:

- pre-generation classifier/rules
- post-generation output filter

## Telemetry and benchmarks

Create a local telemetry layer for QA and benchmarking.

Track per request:

- backend used
- model version
- time to first token
- total latency
- tokens in
- tokens out
- cancellation
- memory warnings
- failure reason

Track per session:

- model load duration
- warmup duration
- peak storage consumed
- document index size

Do not upload sensitive content by default.  
Telemetry content must be disabled or anonymized in production unless explicitly approved.

## Error handling

Handle these failure cases explicitly:

- no supported backend available
- model missing
- model checksum failed
- insufficient storage
- warmup timeout
- runtime init failure
- inference cancellation
- memory pressure
- OCR failure
- retrieval empty
- unsupported file type

Every AI error must map to:

- user-facing message
- retryability flag
- debug context for QA builds

Do not leak raw engine errors directly to end users.

## File structure to generate

Create these files:

- `App/AI/Core/AIBackend.swift`
- `App/AI/Core/AIOrchestrator.swift`
- `App/AI/Core/AIRequest.swift`
- `App/AI/Core/AIResponse.swift`
- `App/AI/Core/GenerationConfig.swift`
- `App/AI/Backends/AppleFoundationBackend.swift`
- `App/AI/Backends/QwenLocalBackend.swift`
- `App/AI/Models/ModelManifest.swift`
- `App/AI/Models/ModelDownloader.swift`
- `App/AI/Models/ModelStore.swift`
- `App/AI/Models/ModelIntegrityValidator.swift`
- `App/AI/Retrieval/DocumentRetriever.swift`
- `App/AI/Retrieval/GroundedAnswerService.swift`
- `App/AI/Safety/HealthSafetyFilter.swift`
- `App/AI/Telemetry/AITelemetry.swift`
- `App/Features/Settings/ModelManagementView.swift`

Also generate docs:

- `MODEL_RUNTIME_PLAN.md`
- `MODEL_PREP_PIPELINE.md`
- `AI_SAFETY_RULES.md`

## Non-goals

Do not:

- train models inside the app
- convert models inside the app
- make nutrition answers purely generative
- make medical document answers ungrounded
- tie views directly to a runtime SDK
- assume internet access
- assume Apple Foundation Models exist on every device

## Implementation order

1. Define AI domain models and protocols.
2. Build orchestrator and backend selection logic.
3. Implement model manifest and download/install pipeline.
4. Implement mock streaming backend for UI wiring.
5. Replace mock backend with real custom local backend.
6. Add Apple backend as optional path.
7. Add OCR and grounded document QA.
8. Add nutrition retrieval and explanation pipeline.
9. Add safety filters.
10. Add telemetry and QA benchmarks.

## Acceptance criteria

The AI integration is complete only when all of the following are true:

- the app can install and verify a local model
- the app can warm the model and stream responses
- the app can cancel a running generation
- document questions are grounded in retrieved evidence
- nutrition answers use structured facts plus AI explanation
- the user can tell which backend answered
- the app remains usable offline after model installation
- high-risk medical prompts trigger safety behavior

## Final instruction to the agent

Treat AI as a product subsystem, not a chat widget.  
Keep the runtime swappable, the facts grounded, the storage private, and the safety rules enforceable in code.

***

## Notes

The key reason for this split design is that Apple’s framework is useful but only on supported iOS 26 Apple Intelligence devices, while your Qwen path needs a separate custom local runtime and a prepared model artifact pipeline. [huggingface](https://huggingface.co/Qwen/Qwen3.5-0.8B)
That is why this file tells your agent to build a backend-agnostic AI subsystem instead of coupling the whole app to one SDK or one model vendor. [apple](https://www.apple.com/in/newsroom/2025/09/apples-foundation-models-framework-unlocks-new-intelligent-app-experiences/)
