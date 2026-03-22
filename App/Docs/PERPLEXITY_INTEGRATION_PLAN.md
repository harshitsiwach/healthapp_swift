# Perplexity Integration Plan

## Objective
Integrate Perplexity Sonar API as an advanced cloud reasoning and health insight backend for HealthApp, enabling web-grounded citations and specialized prompt logic.

## Components Implemented
1. **PerplexityConfig & PerplexityKeyStore**: Securely manages the API key locally via Keychain and stores configuration toggles using `@AppStorage`.
2. **PerplexitySonarBackend**: Conforms to the main `AIBackend` protocol. Features OpenAI-compatible completion parsing, Server-Sent Events (SSE) streaming, and automatic fallback capability.
3. **AIOrchestrator Routing**: Natively supports assigning specific tasks (`perplexityTrendSummary`, `perplexityHealthQA`) to Perplexity, while maintaining local-first preference for standard chat.
4. **Context Bridges**: `PerplexityHealthContextBridge` converts private HealthKit data into safe strings. `PerplexityDocumentBridge` manages chunking and excerpt routing to avoid the 127k context limits.
5. **Transparency UI**: Added `CitationPill`, `EvidenceSheet`, and `BackendBadge` to trace exactly how the agent generated its response, enabling trust.

## Testing Strategy
- Ensure local backends (Apple Foundation, Qwen Local) take priority when the user forces them via the `BackendSelectorView`.
- Input a complex nutritional query without the Perplexity key. It should natively fall back to `GeminiService`.
- Input a valid Perplexity key. It should route to `PerplexitySonarBackend`, returning streaming responses with `BackendBadge` visible as "Perplexity - sonar-pro".

## QA Telemetry
Telemetry logging via `AITelemetry` accurately maps the `backendID`, latency, and completion token count directly to the unified analytics pipeline. Any 400 or 500 error from Perplexity registers as a failed model attempt and cascades down the fallback priority.
