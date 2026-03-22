# Perplexity Health + Sonar Integration Instructions

## Objective

Add Perplexity-powered health and nutrition intelligence to the existing native iOS app without breaking current functionality.

The app already has:
- native Swift/Xcode architecture
- Apple Intelligence option
- local model option
- HealthKit integration
- nutrition logging
- document handling
- reminders / timers / calendar flows
- gamified wellness system

This work must preserve those systems and add Perplexity as an additional intelligence layer.

## Product direction

Do not attempt to embed Perplexity Health as if it were a drop-in native SDK.

Instead, implement a Perplexity-powered feature set that mirrors the most useful parts of Perplexity Health:
- context-aware health answers
- Apple Health-aware personalization
- health file understanding
- workout / sleep / steps trend explanations
- nutrition and calorie analysis
- cited web-grounded responses

Use Perplexity Sonar API as the primary developer integration path for these features.

Keep the app’s own HealthKit, file storage, social features, reminders, and scoring systems as first-party app capabilities.

## Source-of-truth boundaries

The app remains the source of truth for:
- user identity
- profile
- social graph
- leaderboard
- wellness score
- HealthKit permissions
- medical file storage
- routine templates
- reminders and local notifications
- Apple Intelligence toggle
- local model runtime

Perplexity becomes an external intelligence service for:
- cited health explanations
- web-grounded nutrition reasoning
- health trend summaries
- evidence-backed Q&A
- image + description calorie reasoning when cloud mode is allowed

## Mandatory architecture

Create a new provider layer under the AI system.

Required providers:
- AppleFoundationBackend
- QwenLocalBackend
- PerplexitySonarBackend

Do not remove or weaken existing local / Apple paths.

The orchestrator must remain backend-agnostic.

Selection logic:
1. Use local or Apple backend for privacy-first default chat if user preference says so.
2. Use PerplexitySonarBackend for tasks that benefit from web grounding, citations, or cloud reasoning.
3. Always show which backend answered.

## New task routing

Add these tasks:
- `perplexityHealthQA`
- `perplexityFoodAnalysis`
- `perplexityTrendSummary`
- `perplexityReportExplain`
- `perplexityCitedNutrition`
- `perplexityMedicalSearch`

Route tasks as follows:

### Use PerplexitySonarBackend for:
- cited health answers
- “what does this mean” style explanations
- trend analysis over HealthKit summaries
- uploaded health-file explanation
- food calories when user sends photo + description
- evidence-backed nutrition guidance
- web-grounded follow-up questions

### Use AppleFoundationBackend for:
- on-device summarization
- private rewrites
- structured extraction
- short assistant chat on supported devices

### Use QwenLocalBackend for:
- offline chat
- private nutrition explanations
- simple local guidance
- fallback when no network or no API key is present

## Official Perplexity capabilities to reflect

Perplexity Health is available to Pro and Max subscribers in the US and can connect Apple Health, medical records, wellness apps, and uploaded files for personalized health answers.

Perplexity Health is for informational use and is not intended to diagnose conditions, recommend specific treatments, provide personalized nutrition therapy, or give emergency medical advice.

Apple Health data in Perplexity is used to personalize answers but is not currently reflected in the Perplexity Health hub dashboard.

Sonar API provides web-grounded AI responses with streaming support and OpenAI-compatible chat completions.

Use these facts to shape product behavior and disclaimers.

## Perplexity integration requirements

### 1. Perplexity API settings flow

Build a secure API-key settings flow for developer testing and later production configuration.

Requirements:
- secure key entry screen
- key validation action
- test query button
- masked display after save
- delete key action
- environment override support for debug builds
- feature flag to disable Perplexity cloud features globally

Create:
- `App/Perplexity/PerplexityConfig.swift`
- `App/Perplexity/PerplexityKeyStore.swift`
- `App/Features/Settings/PerplexitySettingsView.swift`

Store keys securely using iOS secure storage. Never hardcode keys in source.

### 2. Perplexity backend

Create:
- `App/AI/Backends/PerplexitySonarBackend.swift`

Requirements:
- OpenAI-compatible request format
- non-streaming and streaming support
- model selection
- citation parsing
- error mapping
- timeout handling
- retry policy for transient failures
- explicit backend identity for UI

The backend must support:
- text-only prompts
- image + text prompts for food analysis
- health-summary prompts
- document-context prompts
- structured prompt builders

### 3. Prompt builders

Create:
- `PerplexityHealthPromptBuilder`
- `PerplexityNutritionPromptBuilder`
- `PerplexityTrendPromptBuilder`
- `PerplexityFoodVisionPromptBuilder`

Prompt rules:
- always provide concise user context
- separate user data from the actual question
- ask for uncertainty where confidence is low
- ask for cited reasoning
- prohibit diagnosis
- prohibit treatment changes
- prefer “educational guidance” wording
- require short actionable summaries

### 4. HealthKit context bridge

Do not give Perplexity raw unrestricted HealthKit access.

Instead, build a local summarization bridge:
- read approved HealthKit data locally
- summarize into compact structured context
- pass only relevant fields into Perplexity prompts

Create:
- `App/Perplexity/PerplexityHealthContextBridge.swift`

Supported context inputs:
- recent steps
- workout summary
- sleep summary
- heart-rate trend summary if enabled
- weight trend summary if enabled
- hydration and meal logs from app
- wellness score breakdown
- active routine or challenge context

This bridge must be permission-aware and privacy-aware.

### 5. Health-file bridge

Perplexity Health supports uploaded files and medical-record-aware answers. Recreate this in-app by using your own file system and sending only the needed extracted context.

Create:
- `App/Perplexity/PerplexityDocumentBridge.swift`

Flow:
1. user uploads or opens a health document
2. app OCRs and chunks it locally
3. app retrieves the relevant chunks
4. app sends only the relevant excerpt + user question to Perplexity
5. app displays answer + evidence + backend label

Do not send full unrelated medical archives when only one section is needed.

### 6. Food calorie analysis with Perplexity

Add a Perplexity food flow for photo + text prompts.

Create:
- `App/Perplexity/PerplexityFoodAnalysisService.swift`

Flow:
1. user uploads or captures meal photo
2. user adds short meal description
3. app compresses image
4. app sends image + description to PerplexitySonarBackend
5. app receives calorie / macro / caution response
6. app shows citations and confidence wording
7. user confirms before saving to nutrition log or Apple Health

Use Perplexity for:
- cited calorie reasoning
- food clarification questions
- nutrition explanation
- “good / caution” summary

Do not use Perplexity output as unquestioned truth for logging without user review.

### 7. Trend summaries

Create:
- `App/Perplexity/PerplexityTrendInsightsService.swift`

Features:
- compare this week’s sleep vs last week
- summarize last 5 workouts
- identify step trends over 30 days
- create plain-language wellness recap
- explain food / activity patterns

All trend questions must be driven by app-owned data summaries first.

### 8. User-facing backend controls

Add a user-visible model selector with:
- Apple Intelligence
- Local AI
- Perplexity Cloud

Per-feature override examples:
- default chat backend
- food analysis backend
- document explanation backend
- trend insights backend

Add labels:
- Local
- Apple On-Device
- Perplexity Cloud

Never hide the backend source from the user.

### 9. Safety rules

Perplexity Health is informational and not for diagnosis, treatment, emergency advice, or personalized nutrition therapy.

Mirror that in the app.

Add mandatory safeguards:
- diagnosis guardrail
- treatment-change guardrail
- emergency escalation response
- medication caution guardrail
- pediatric caution guardrail
- pregnancy caution guardrail
- eating-disorder-sensitive copy rules

If the user asks high-risk questions:
1. do not generate normal wellness guidance
2. show urgent-care or clinician escalation language
3. do not rank, gamify, or publicly expose that content

### 10. Citations and evidence UX

When Perplexity is the answering backend:
- display citations
- show “Perplexity Cloud” label
- show answer timestamp
- show “informational only” badge on health answers
- preserve the user’s original prompt
- preserve the summarized context that was sent, if safe

Create UI components:
- `CitationPill`
- `BackendBadge`
- `EvidenceSheet`
- `HealthDisclaimerCard`

### 11. Social and gamification boundaries

Do not expose Perplexity-generated health answers directly on public profiles.

Allowed public outputs:
- challenge participation
- routine templates
- streaks
- badges
- chosen meals
- public lifestyle notes

Disallowed public outputs:
- medical-document summaries
- raw biomarker commentary
- abnormal health flags
- diagnosis-adjacent content
- exact protected health details

Perplexity results should stay private unless explicitly transformed into safe public artifacts.

### 12. Reliability and fallback

The app must continue working if:
- API key is missing
- Perplexity quota is exhausted
- network is offline
- request times out
- image upload fails
- Perplexity is disabled

Fallback order:
1. AppleFoundationBackend if available and task is safe locally
2. QwenLocalBackend
3. graceful error message with retry option

### 13. Performance controls

Add:
- image compression before upload
- context truncation
- per-task token budgets
- request debouncing
- cache for repeated food analyses
- cache for repeated trend summaries
- timeout ceilings by feature

### 14. Telemetry

Track:
- backend used
- time to first token
- total latency
- citations count
- prompt size
- image size
- failure category
- fallback triggered
- user-confirmed save rate for food analysis

Do not log raw health content in production telemetry.

## Files to generate

Create these files:

- `App/Perplexity/PerplexityConfig.swift`
- `App/Perplexity/PerplexityKeyStore.swift`
- `App/Perplexity/PerplexityHealthContextBridge.swift`
- `App/Perplexity/PerplexityDocumentBridge.swift`
- `App/Perplexity/PerplexityFoodAnalysisService.swift`
- `App/Perplexity/PerplexityTrendInsightsService.swift`
- `App/AI/Backends/PerplexitySonarBackend.swift`
- `App/AI/Prompts/PerplexityHealthPromptBuilder.swift`
- `App/AI/Prompts/PerplexityNutritionPromptBuilder.swift`
- `App/AI/Prompts/PerplexityTrendPromptBuilder.swift`
- `App/AI/Prompts/PerplexityFoodVisionPromptBuilder.swift`
- `App/Features/Settings/PerplexitySettingsView.swift`
- `App/Features/AI/BackendSelectorView.swift`
- `App/Features/Food/PerplexityFoodReviewView.swift`
- `App/Features/Health/PerplexityInsightCard.swift`
- `App/Features/Common/CitationPill.swift`
- `App/Features/Common/BackendBadge.swift`
- `App/Features/Common/EvidenceSheet.swift`
- `App/Docs/PERPLEXITY_INTEGRATION_PLAN.md`
- `App/Docs/PERPLEXITY_SAFETY_RULES.md`

## Acceptance criteria

The work is complete only when:
- the app still works with Apple Intelligence and local AI
- Perplexity can be enabled or disabled cleanly
- a developer can enter an API key and test it
- food photo + description can be analyzed through Perplexity
- health trend summaries can be generated from app-owned data
- document explanations can be grounded and routed through Perplexity
- citations are visible when Perplexity answers
- high-risk health questions are safety-filtered
- no public profile leaks private health content
- offline fallback still works

## Implementation order

1. Add Perplexity config, key storage, and feature flags.
2. Implement PerplexitySonarBackend with text-only support.
3. Add backend selector UI and debug test screen.
4. Add streaming and citation rendering.
5. Add HealthKit context bridge.
6. Add food image + description flow.
7. Add document bridge.
8. Add trend insights.
9. Add safety and fallback logic.
10. Add QA telemetry and regression tests.

## Final instruction

Do not rebuild the app around Perplexity.

Keep the app architecture stable and treat Perplexity as a powerful optional intelligence provider layered on top of:
- Apple Intelligence
- local AI
- HealthKit
- document processing
- nutrition logging
- reminders
- social wellness systems