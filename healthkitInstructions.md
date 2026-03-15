Yes — the clean way is to integrate with **HealthKit**, not to try to access the Health app’s private internals, and to request only the exact read/write categories your feature needs. [developer.apple](https://developer.apple.com/documentation/xcode/configuring-healthkit-access)
Below is a standalone `healthapp.md` file for your AI agent, focused on low-friction HealthKit features, permission handling, graceful fallbacks, and privacy-safe UX for your nutrition-and-health app. [apple](https://www.apple.com/in/legal/privacy/data/en/health-app/)

## healthapp.md

Save the following as `healthapp.md`.

# Health App Integration Instructions

## Goal

Integrate Apple Health data into the native iOS app through **HealthKit**, so the app can personalize nutrition and wellness guidance using user-approved on-device health data. [developer.apple](https://developer.apple.com/documentation/healthkit)
Do not attempt to directly read the Health app’s private database or UI internals, because third-party apps are expected to use HealthKit authorization and APIs instead. [developer.apple](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data)
Treat all health access as optional, granular, and revocable by the user at any time. [developer.apple](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data)

## Product principles

The app is a nutrition-and-health assistant, so HealthKit should be used to improve personalization, context, and logging rather than to replace clinicians or make diagnoses. [developer.apple](https://developer.apple.com/health-fitness/)
Request the minimum health permissions needed for each feature, because HealthKit authorization is granted per data type rather than as one blanket permission. [developer.apple](https://developer.apple.com/videos/play/wwdc2020/10664/)
All health-derived insights should be computed on device where possible, with clear privacy messaging and graceful behavior when the user declines access. [support.apple](https://support.apple.com/en-in/guide/security/sec88be9900f/web)

## Integrations to build

### 1) Activity context

Read step count, walking/running activity, active energy, and workouts so the app can adapt calorie and meal suggestions to the user’s recent activity level. [developer.apple](https://developer.apple.com/health-fitness/)
Use this for features like “today’s activity-aware meal summary,” “post-workout recovery suggestions,” and “daily movement trend cards,” because those align naturally with a food-and-health product. [bitbakery](https://www.bitbakery.co/blog/how-to-use-apple-healthkit-data-in-an-app)
Do not imply medical conclusions from activity data alone. [developer.apple](https://developer.apple.com/health-fitness/)

### 2) Sleep-aware nutrition

Read sleep-related data so the app can show simple guidance such as “low sleep may affect cravings, appetite regulation, and recovery; keep meals balanced today.” [developer.apple](https://developer.apple.com/health-fitness/)
Use sleep only as a personalization signal for wellness messaging, not as a diagnostic feature. [developer.apple](https://developer.apple.com/health-fitness/)
If sleep access is denied, hide sleep-based insights without affecting the rest of the app. [developer.apple](https://developer.apple.com/documentation/healthkit)

### 3) Heart rate context

Read heart rate and workout-linked heart metrics where appropriate so the app can give better context around exertion, recovery, and wellness trends. [bitbakery](https://www.bitbakery.co/blog/how-to-use-apple-healthkit-data-in-an-app)
Use this for features like “after intense activity, prioritize hydration and recovery nutrition,” not for cardiac diagnosis or alarming claims. [bitbakery](https://www.bitbakery.co/blog/how-to-use-apple-healthkit-data-in-an-app)
Any abnormal-health wording must stay conservative and point the user toward a clinician when risk appears high. [support.apple](https://support.apple.com/en-in/guide/security/sec88be9900f/web)

### 4) Body measurements

Read body weight and similar body-measurement types so the app can improve calorie and nutrition planning over time. [developer.apple](https://developer.apple.com/health-fitness/)
Use these values to personalize targets, progress tracking, and food recommendations only after explicit permission. [developer.apple](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data)
Never shame users, and never make body-composition claims beyond the data actually available. [apple](https://www.apple.com/in/legal/privacy/data/en/health-app/)

### 5) Nutrition logging

Write meal-related nutrition entries back to HealthKit when the user confirms them, so logged food from your app can appear inside the Health app ecosystem. [developer.apple](https://developer.apple.com/documentation/xcode/configuring-healthkit-access)
This is one of the strongest integrations for your product because your app already focuses on meal analysis, calories, and nutrition guidance. [bitbakery](https://www.bitbakery.co/blog/how-to-use-apple-healthkit-data-in-an-app)
Require explicit user confirmation before writing calorie or nutrition data, especially when the meal came from AI estimation rather than manual entry. [developer.apple](https://developer.apple.com/documentation/xcode/configuring-healthkit-access)

### 6) Medical and medication-adjacent features

Evaluate HealthKit medication-related APIs separately, because Apple has introduced medication-focused HealthKit capabilities, but those should be handled with extra caution in a health app. [youtube](https://www.youtube.com/watch?v=CR4Y4dTiV4g)
For v1, prefer read-only context and reminders around user-approved health data instead of medication dosing logic or treatment-change suggestions. [youtube](https://www.youtube.com/watch?v=CR4Y4dTiV4g)
Do not let the AI prescribe, change, or interpret medication regimens as medical instructions.

### 7) Provider-sharing and clinical workflows

Do not build around Health app “Share with Provider” or healthcare-provider workflows as a core app dependency, because those are separate from normal third-party HealthKit access and depend on participating healthcare organizations. [support.apple](https://support.apple.com/en-in/guide/healthregister/apd531bc6215/web)
Treat provider-facing integrations as a later-stage expansion, not a default assumption for all users. [support.apple](https://support.apple.com/en-in/guide/healthregister/apd531bc6215/web)
Keep the core experience fully usable without hospital-linked Health features. [support.apple](https://support.apple.com/en-in/guide/healthregister/apd531bc6215/web)

## Permissions strategy

Add HealthKit capability in the app target and configure the required Health usage descriptions in the app configuration before attempting any health access. [developer.apple](https://developer.apple.com/videos/play/wwdc2020/10664/)
Use both read and write authorization requests only for the specific data types required by a feature, and explain the reason in plain language right before the request is shown. [developer.apple](https://developer.apple.com/videos/play/wwdc2020/10664/)
Never ask for all possible health permissions at onboarding; ask contextually when the user reaches a feature that benefits from the data. [apple](https://www.apple.com/in/legal/privacy/data/en/health-app/)

### Permission flows to implement

- Ask for **activity** access when the user enables activity-aware calorie guidance. [developer.apple](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data)
- Ask for **sleep** access when the user enables sleep-based meal coaching. [bitbakery](https://www.bitbakery.co/blog/how-to-use-apple-healthkit-data-in-an-app)
- Ask for **heart rate** access when the user enables wellness and recovery context features. [developer.apple](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data)
- Ask for **body measurements** access when the user enables weight-aware nutrition planning. [bitbakery](https://www.bitbakery.co/blog/how-to-use-apple-healthkit-data-in-an-app)
- Ask for **nutrition write** access only when the user turns on “Save meals to Apple Health.” [developer.apple](https://developer.apple.com/documentation/xcode/configuring-healthkit-access)

### UX copy requirements

Show a pre-permission screen before the iOS permission prompt with three things: what data will be accessed, why it improves the feature, and that the user can change permissions later. [apple](https://www.apple.com/in/legal/privacy/data/en/health-app/)
If permission is denied, keep the feature available in a reduced mode instead of hard-blocking the app. [developer.apple](https://developer.apple.com/documentation/healthkit)
Provide a settings screen where the user can see which Health integrations are active and what each one does. [developer.apple](https://developer.apple.com/documentation/healthkit)

## Architecture requirements

Create a dedicated HealthKit layer instead of calling HealthKit directly from views. [developer.apple](https://developer.apple.com/documentation/xcode/configuring-healthkit-access)
Use these components:

- `HealthKitManager`
- `HealthAuthorizationService`
- `HealthDataRepository`
- `HealthSyncService`
- `HealthFeatureFlags`
- `HealthInsightsService`

The `HealthKitManager` should handle capability checks, authorization status, reads, writes, and error mapping in one place. [developer.apple](https://developer.apple.com/documentation/healthkit)
The `HealthInsightsService` should transform raw HealthKit data into product-safe summaries for the AI and UI layers. [developer.apple](https://developer.apple.com/health-fitness/)
Never allow the AI layer to query HealthKit directly. [developer.apple](https://developer.apple.com/documentation/healthkit)

## Data types to support first

Prioritize these HealthKit data types for v1 because they match your app’s nutrition and wellness focus and are relatively easy to explain to users. [developer.apple](https://developer.apple.com/health-fitness/)

- Step count. [developer.apple](https://developer.apple.com/health-fitness/)
- Active energy burned. [bitbakery](https://www.bitbakery.co/blog/how-to-use-apple-healthkit-data-in-an-app)
- Workouts. [developer.apple](https://developer.apple.com/health-fitness/)
- Sleep-related data. [bitbakery](https://www.bitbakery.co/blog/how-to-use-apple-healthkit-data-in-an-app)
- Heart rate. [developer.apple](https://developer.apple.com/health-fitness/)
- Weight and related body measurements where appropriate. [bitbakery](https://www.bitbakery.co/blog/how-to-use-apple-healthkit-data-in-an-app)
- Nutrition entries that your app can write after confirmation. [developer.apple](https://developer.apple.com/documentation/xcode/configuring-healthkit-access)

## Features to ship first

### Daily health summary

Show a daily card combining meals logged in your app with steps, sleep, and recent activity so users see one simple “today” view. [developer.apple](https://developer.apple.com/health-fitness/)
Keep this summary descriptive, such as “low sleep + high activity day,” rather than medical or prescriptive. [developer.apple](https://developer.apple.com/health-fitness/)

### Activity-aware meal suggestions

Use workout and activity context to adjust calorie and macro guidance in a simple way, such as emphasizing recovery or hydration after intense exercise. [developer.apple](https://developer.apple.com/health-fitness/)
Always present this as supportive wellness guidance. [developer.apple](https://developer.apple.com/health-fitness/)

### Save to Apple Health

After the user confirms a detected meal, offer “Save to Apple Health” so nutrition logs become part of the user’s broader Apple health record. [developer.apple](https://developer.apple.com/documentation/xcode/configuring-healthkit-access)
This should be opt-in and visible, not automatic. [apple](https://www.apple.com/in/legal/privacy/data/en/health-app/)

### Health-linked goals

Let users create app goals that reference approved HealthKit signals, such as a steps goal, sleep consistency goal, or meal logging streak paired with activity. [bitbakery](https://www.bitbakery.co/blog/how-to-use-apple-healthkit-data-in-an-app)
Keep goals framed around habits and adherence rather than disease outcomes. [developer.apple](https://developer.apple.com/health-fitness/)

### Recovery and wellness nudges

Use recent workout, heart-rate context, and sleep trends to trigger lightweight nudges like “consider a lighter dinner” or “prioritize hydration and protein today.” [developer.apple](https://developer.apple.com/health-fitness/)
These nudges should stay conservative and easy to dismiss. [apple](https://www.apple.com/in/legal/privacy/data/en/health-app/)

## Safety rules

Health-derived features must stay within wellness, logging, summarization, and education boundaries. [developer.apple](https://developer.apple.com/health-fitness/)
Do not infer diagnoses from Apple Health data, do not flag emergencies based on one consumer metric alone, and do not tell users to change medication or treatment. [support.apple](https://support.apple.com/en-in/guide/security/sec88be9900f/web)
When the user asks medical questions, combine HealthKit context with your safety rules and present clinician escalation when appropriate. [support.apple](https://support.apple.com/en-in/guide/security/sec88be9900f/web)

## Privacy rules

Health data is sensitive, so keep it on device by default and avoid unnecessary remote transmission. [themomentum](https://www.themomentum.ai/blog/do-you-need-a-mobile-app-to-access-apple-health-data)
Show clear onboarding text explaining what stays local, what permissions are optional, and how the user can revoke access in the future. [support.apple](https://support.apple.com/en-in/guide/iphone/iph5ede58c3d/ios)
Provide controls to disconnect HealthKit-linked features without deleting the rest of the user’s app data. [developer.apple](https://developer.apple.com/documentation/healthkit)

## Failure handling

If HealthKit is unavailable, permissions are denied, or the device does not support the requested feature, the app must continue working with manual input only. [apple](https://www.apple.com/in/legal/privacy/data/en/health-app/)
All Health-linked screens should have graceful empty states and permission recovery flows. [developer.apple](https://developer.apple.com/documentation/healthkit)
Never show broken cards or blank metrics with no explanation. [apple](https://www.apple.com/in/legal/privacy/data/en/health-app/)

## File structure to generate

Ask the agent to create:

- `App/Health/HealthKitManager.swift`
- `App/Health/HealthAuthorizationService.swift`
- `App/Health/HealthDataRepository.swift`
- `App/Health/HealthInsightsService.swift`
- `App/Health/HealthSyncService.swift`
- `App/Features/Settings/HealthPermissionsView.swift`
- `App/Features/Home/DailyHealthSummaryCard.swift`
- `App/Features/Nutrition/SaveMealToHealthView.swift`
- `App/Docs/HEALTHKIT_PERMISSIONS_MATRIX.md`

## Acceptance criteria

The Health integration is complete only when:  
- the app requests HealthKit permissions contextually and only when needed, [developer.apple](https://developer.apple.com/videos/play/wwdc2020/10664/)
- the app reads approved health signals and uses them to improve wellness and nutrition features, [bitbakery](https://www.bitbakery.co/blog/how-to-use-apple-healthkit-data-in-an-app)
- the app can optionally write confirmed nutrition logs back to HealthKit, [developer.apple](https://developer.apple.com/documentation/xcode/configuring-healthkit-access)
- the app clearly explains what data is used and why, [support.apple](https://support.apple.com/en-in/guide/iphone/iph5ede58c3d/ios)
- the app remains fully usable if the user declines or revokes permissions. [developer.apple](https://developer.apple.com/documentation/healthkit)

## Non-goals

Do not build direct diagnosis features from HealthKit data. [support.apple](https://support.apple.com/en-in/guide/security/sec88be9900f/web)
Do not depend on provider-sharing workflows for the core product. [support.apple](https://support.apple.com/en-in/guide/healthregister/apd531bc6215/web)
Do not request broad health permissions at first launch without a feature-specific reason. [developer.apple](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data)

## Final instruction to the agent

Integrate with **HealthKit** as a privacy-first enhancement layer for nutrition, wellness context, and user-approved health logging, while keeping permissions granular, flows resilient, and medical claims conservative. [support.apple](https://support.apple.com/en-in/guide/security/sec88be9900f/web)

## Recommended v1

For your specific app, I would ship **steps, workouts, sleep, heart rate, weight, and “Save meal to Apple Health”** first, because that gives the highest product value with the clearest user explanation. [developer.apple](https://developer.apple.com/documentation/xcode/configuring-healthkit-access)
I would leave medication-heavy features and provider-sharing flows for later, because they add more safety and workflow complexity than your first release needs. [youtube](https://www.youtube.com/watch?v=CR4Y4dTiV4g)
This gives your agent a clean, realistic HealthKit scope that should fit naturally into the app you are already building.