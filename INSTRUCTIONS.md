# HealthApp Android — Agent Handoff Document

## Project Overview
Kotlin + Jetpack Compose Android app. Parity with existing iOS HealthApp (SwiftUI).
Location: `~/Desktop/HealthApp_Android/`

## Architecture
- **UI Layer**: Jetpack Compose screens in `ui/screens/`
- **ViewModel Layer**: `viewmodels/` — StateFlow-based, survives config changes
- **Repository Layer**: `repositories/` — single source of truth, abstracts Room
- **Data Layer**: Room database (`data/db/AppDatabase.kt`) + KSP codegen
- **Health Integration**: `health/GoogleFitManager.kt`
- **Application**: `HealthAppApplication.kt` holds singleton `database`

## Database Schema (Room)
- `UserProfile` — profile from onboarding, goals, healthScore, streak
- `DailyLog` — food entries per day (date string yyyy-MM-dd)
- `IndianFoodItem` — 250+ Indian foods seeded at first launch
- `ChatMessage` — AI chat history
- `PeriodEntry`, `WeightEntry`, `SleepEntry`, `Medication`, `FamilyProfile` — tables exist but UI not yet built

## What Is DONE

### 1. Onboarding (4-step)
- File: `ui/screens/onboarding/OnboardingScreen.kt`
- ViewModel: `viewmodels/OnboardingViewModel.kt`
- Flow: Basic Info → Physical Data → Preferences → Goals
- Calculates BMR (Mifflin-St Jeor), TDEE, macro targets
- Saves `UserProfile` to Room
- `MainActivity` checks `repository.hasProfile()` and routes to onboarding if missing

### 2. Dashboard
- File: `ui/screens/DashboardScreen.kt`
- ViewModel: `viewmodels/DashboardViewModel.kt` (requires `Application` context)
- Shows: calories consumed/goal/remaining with animated progress bar
- Macro pills: Protein, Carbs, Fat with % of goal
- Hydration card: tap +250ml (state only, NOT persisted yet)
- Google Fit connect card (if not connected)
- Activity card (if connected): steps, calories burned, distance km
- Health Score card

### 3. Google Fit Integration
- File: `health/GoogleFitManager.kt`
- Reads: steps, calories expended, distance (today only)
- Uses Google Sign-In + Fitness API
- Dashboard shows connect button → launches Google Fit auth intent
- **TODO**: Handle `onActivityResult` in MainActivity for GOOGLE_FIT_REQUEST_CODE (1001)
- **TODO**: Persist hydration to DataStore (currently just in-memory)

### 4. Food Log
- File: `ui/screens/FoodLogScreen.kt`
- ViewModel: `viewmodels/FoodLogViewModel.kt`
- Searchable Indian food database (250+ items)
- Shows today's logged items with calories
- Add/delete entries
- Updates DailyLog in Room

### 5. AI Chat
- File: `ui/screens/ChatScreen.kt`
- ViewModel: `viewmodels/ChatViewModel.kt`
- Offline rule-based AI (no API key needed)
- Handles: food logging, calorie queries, health tips, goal reminders
- Parses "log dal rice" syntax, searches food DB, adds to log
- Persists messages to Room

### 6. Settings
- File: `ui/screens/SettingsScreen.kt`
- Profile display, macro goals, theme toggle (light/dark), clear data

### 7. Navigation
- File: `MainActivity.kt`
- Bottom nav: Dashboard, Food Log, AI Chat, Settings
- Conditionally shows Onboarding first

## What Is NOT Done (Priority Order)

### P0 — Critical
1. **Hydration Persistence** — `DashboardViewModel.addWater()` is in-memory only. Add DataStore or Room field.
2. **Google Fit Result Handling** — `MainActivity` needs `onActivityResult` to handle GOOGLE_FIT_REQUEST_CODE and call `viewModel.checkGoogleFit()`
3. **Navigation from FAB** — Dashboard FAB "Quick Log" does nothing. Wire to food log.
4. **Weight Tracking Screen** — DB table exists, no UI. Add screen with line chart (MPAndroidChart or Compose Canvas).
5. **Sleep Tracking Screen** — DB table exists, no UI. Add card + history list.

### P1 — Important
6. **Weekly Meal Planner** — iOS has this. Create meal plans (veg/non-veg/weight-loss) with grocery list export.
7. **Barcode Scanner** — ML Kit Barcode Scanning. Scan food barcodes, lookup nutrition, add to log.
8. **Medical Report OCR** — ML Kit Text Recognition. Scan lab reports, extract values, store in history.
9. **Notifications/Reminders** — WorkManager or AlarmManager for hydration reminders, meal reminders.
10. **Widgets** — Android Glance for home screen calorie/hydration widget.

### P2 — Nice to Have
11. **Real Local LLM** — llama.cpp Android or ONNX Runtime for offline AI chat (replace rule-based).
12. **Family Profiles** — DB table exists, no UI.
13. **Period Health Tracking** — DB table exists, no UI.
14. **Medical Passport** — Export health data to PDF/share.
15. **Export/Backup** — JSON export of all data.

## Key Files & Their Roles

| File | Role |
|------|------|
| `MainActivity.kt` | Entry point, onboarding routing, bottom nav |
| `ui/screens/DashboardScreen.kt` | Main dashboard |
| `ui/screens/FoodLogScreen.kt` | Food logging |
| `ui/screens/ChatScreen.kt` | AI chat |
| `ui/screens/SettingsScreen.kt` | Settings |
| `ui/screens/onboarding/OnboardingScreen.kt` | 4-step onboarding |
| `viewmodels/DashboardViewModel.kt` | Dashboard state + Google Fit |
| `viewmodels/FoodLogViewModel.kt` | Food log state |
| `viewmodels/ChatViewModel.kt` | Chat state + rule AI |
| `viewmodels/OnboardingViewModel.kt` | Onboarding state + BMR calc |
| `health/GoogleFitManager.kt` | Google Fit API wrapper |
| `repositories/HealthRepository.kt` | Room abstraction |
| `data/db/AppDatabase.kt` | Room database |
| `data/models/*.kt` | All data classes |

## Dependencies to Know
```kotlin
// Already in build.gradle (app level)
implementation("androidx.core:core-ktx:1.15.0")
implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
implementation("androidx.activity:activity-compose:1.10.1")
implementation(platform("androidx.compose:compose-bom:2025.02.00"))
implementation("androidx.compose.ui:ui")
implementation("androidx.compose.material3:material3")
implementation("androidx.navigation:navigation-compose:2.8.9")
implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")

// Room
implementation("androidx.room:room-runtime:2.6.1")
implementation("androidx.room:room-ktx:2.6.1")
ksp("androidx.room:room-compiler:2.6.1")

// Google Fit
implementation("com.google.android.gms:play-services-fitness:21.2.0")
implementation("com.google.android.gms:play-services-auth:21.3.0")

// Charts (NOT added yet — add if building weight/sleep charts)
// implementation("com.github.PhilJay:MPAndroidChart:v3.1.0")

// ML Kit (NOT added yet — add for barcode/OCR)
// implementation("com.google.mlkit:barcode-scanning:17.3.0")
// implementation("com.google.mlkit:text-recognition:16.0.1")
```

## How to Add a New Screen
1. Create `ui/screens/NewScreen.kt` as `@Composable`
2. Create `viewmodels/NewViewModel.kt` extending `ViewModel()`
3. Access DB via `HealthAppApplication.database.*Dao()`
4. Add nav item in `MainActivity.kt` bottom bar + route

## Testing Notes
- Build: `./gradlew app:compileDebugKotlin`
- Full build: `./gradlew app:assembleDebug`
- APK output: `app/build/outputs/apk/debug/app-debug.apk`
- Min SDK: 24 (Android 7.0)
- Target SDK: 35

## Design System
- Primary: `NeonGreen` = `#00E676`
- Secondary: `NeonBlue` = `#00B0FF`
- Accent: `NeonOrange` = `#FF9100`, `NeonPurple` = `#E040FB`
- Background: `BackgroundDark` = `#0A0A0A`, `SurfaceDark` = `#121212`
- Dark mode default, light mode toggle in settings

## Next Agent Should Start With
1. Fix hydration persistence (DataStore)
2. Add `onActivityResult` for Google Fit in MainActivity
3. Build Weight Tracking screen with chart
4. Build Sleep Tracking screen
5. Then pick from P1 list
