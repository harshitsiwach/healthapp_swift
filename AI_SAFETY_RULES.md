# AI Safety Rules

## Core Principle

This app is health-adjacent. All AI outputs must be framed as **educational and assistive**. The model must never present itself as diagnosing, prescribing, or replacing a clinician.

## Emergency Detection

The following topics trigger immediate safety intervention:

### Blocked (Stop generation, show safety message)
- **Emergency symptoms**: chest pain, heart attack, can't breathe, stroke, seizure, unconscious
- **Mental health crisis**: suicidal ideation, self harm, wanting to die

### Cautioned (Show disclaimer, allow response)
- **Medication dosing**: drug dosage, how much medicine
- **Treatment changes**: change/stop medication
- **Pregnancy-critical**: pregnancy-related health decisions
- **Pediatric high-risk**: child/infant medication or treatment

## Safety Response Messages

### Emergency
> ⚠️ If you're experiencing a medical emergency, please call emergency services immediately (112 in India, 911 in US).

### Mental Health Crisis
> 💙 If you're in crisis, please reach out:
> - Vandrevala Foundation: 1860-2662-345 (India)
> - iCall: 9152987821 (India)
> - Crisis Text Line: Text HOME to 741741

### Medication
> 💊 This app cannot provide medication dosage advice. Please consult your doctor or pharmacist.

### Treatment Changes
> ⚕️ Never change your treatment plan without consulting your healthcare provider.

### Pregnancy
> 🤰 Pregnancy-related health decisions should always be discussed with your OB-GYN.

### Pediatric
> 👶 Children's health requires specialized medical guidance. Please consult a pediatrician.

## Output Filtering

Post-generation filter blocks responses containing:
- "you should take [medication]"
- "increase/decrease your dosage"
- "stop taking your medication"
- "you are diagnosed with"
- "this confirms you have"
- "you definitely have"

## General Disclaimer

All AI-generated health content must be accompanied by:
> "This information is for educational purposes only and is not a substitute for professional medical advice, diagnosis, or treatment."

## Evidence Grounding Rules

1. **Medical document Q&A**: Answers must be grounded in retrieved document evidence. No hallucinated medical facts.
2. **Nutrition facts**: Use structured database when available. AI explains, database provides facts.
3. **Health reports**: Based on actual logged data, not generated estimates.

## Implementation

Safety checks run in two phases:
1. **Pre-generation**: `HealthSafetyFilter.checkInput()` — scans user prompt for high-risk patterns
2. **Post-generation**: `HealthSafetyFilter.checkOutput()` — scans AI response for dangerous advice

Both are enforced in the `AIOrchestrator` before any response reaches the UI.
