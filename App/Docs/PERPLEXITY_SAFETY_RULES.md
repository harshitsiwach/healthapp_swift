# Perplexity Integration Safety Rules

## 1. Data Minimization
- The `PerplexityHealthContextBridge` must never send the user's real name or identifiable credentials to the cloud API.
- Raw HealthKit `HKQuantitySample` arrays are strictly excluded. Only summarized text (e.g., "7-day average steps: 5000") are sent.

## 2. Medical Boundaries
- Every Perplexity-specific prompt (e.g., `PerplexityTrendPromptBuilder`, `PerplexityFoodVisionPromptBuilder`) must explicitly include the instruction: "Do not provide medical diagnosis, or modify prescribed treatment plans."
- General wellness, nutrition, and fitness advice based on web grounding is permitted but must remain strictly educational.
- Responses containing dangerous phrases (diagnoses, dosage changes) will be caught by `HealthSafetyFilter.checkOutput` and surfaced with a caution warning to the user.

## 3. Fallback & Reliability
- The `AIOrchestrator` relies on the `healthCheck()` method of each backend. If the `PerplexitySonarBackend` encounters an API outage (HTTP 500), timeout, or missing API key, the orchestrator gracefully degrades to `GeminiService` or a local backend (`QwenLocalBackend`, `AppleFoundationBackend`).
- The user is kept informed through the `BackendBadge` UI component, ensuring full transparency about which AI provider actually answered their query.
