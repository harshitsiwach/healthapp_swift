# Model Runtime Plan

## Overview

The HealthApp AI subsystem uses a backend-agnostic architecture with three runtime paths:

1. **QwenLocalBackend** — Primary local inference using Qwen 3.5 0.8B
2. **AppleFoundationBackend** — Optional acceleration via Apple Foundation Models (iOS 26+)  
3. **GeminiService** — Remote fallback via Google Gemini 2.5 Flash API

## Architecture

```
┌──────────────────────────────────────┐
│         App Features / Views         │
├──────────────────────────────────────┤
│           AIOrchestrator             │
│    (backend selection + safety)      │
├──────────┬───────────┬───────────────┤
│  Qwen    │  Apple    │  Gemini       │
│  Local   │  FM       │  Remote       │
│  Backend │  Backend  │  Backend      │
└──────────┴───────────┴───────────────┘
```

## Backend Selection Priority

1. `QwenLocalBackend` if model installed, verified, and healthy
2. `AppleFoundationBackend` if device capable and feature flag enabled
3. `GeminiService` as remote fallback (always available with API key)

## Qwen Runtime Details

- **Target Model**: Qwen 3.5 0.8B
- **Quantization**: Q4 (balance of quality and size)
- **Engine**: llama.cpp or MLX (wrapped behind `QwenLocalBackend`)
- **Context Window**: 8192 tokens
- **Supported Features**: Prompt submission, token streaming, cancellation, warmup, health checks

### Integration Steps
1. Prepare model artifact (see `MODEL_PREP_PIPELINE.md`)
2. User downloads model via in-app ModelManagementView
3. Verify SHA256 checksum
4. Initialize runtime engine
5. Warm up with short inference pass
6. Begin serving requests through orchestrator

## Apple Foundation Models

- **Availability**: iOS 26+ on Apple Intelligence-capable devices
- **Use Cases**: Summarization, structured extraction, short-form rewriting
- **Capability Detection**: Runtime-based via `AppleModelCapability`
- **Not a hard dependency** — all features work without it

## Gemini Remote

- **Model**: gemini-2.5-flash
- **Use Cases**: Food photo analysis, weekly health reports, meal recommendations
- **Requires**: Active internet connection + API key
- **Rate Limits**: Standard Gemini API limits apply

## Safety Layer

All inference requests pass through `HealthSafetyFilter`:
- Pre-generation: Input scanning for emergency/crisis keywords
- Post-generation: Output scanning for dangerous medical advice
- See `AI_SAFETY_RULES.md` for complete safety rules

## Telemetry

Local-only metrics tracked per request:
- Backend used, model version
- Time to first token, total latency
- Tokens in/out
- Cancellation/failure tracking
- Memory pressure events
