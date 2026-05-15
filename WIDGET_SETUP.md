# Widget Setup Guide

## Steps to add Widget Extension in Xcode

### 1. Add Widget Extension Target
1. Open `HealthApp.xcodeproj` in Xcode
2. Click on the project name in the left sidebar
3. Click the `+` button at the bottom of the targets list
4. Search for "Widget Extension"
5. Set Product Name: `HealthAppWidget`
6. Set Bundle Identifier: `com.aihealthappoffline.HealthAppWidget`
7. Click Finish
8. When asked to activate the scheme, click "Activate"

### 2. Delete Auto-Generated Files
Xcode creates placeholder files. Delete them:
- `HealthAppWidget.swift` (the auto-generated one)
- `HealthAppWidgetBundle.swift`

Then drag our custom files into the target:
- `HealthAppWidget/HealthWidget.swift`
- `HealthAppWidget/HealthWidgetProvider.swift`
- `HealthAppWidget/HealthWidgetViews.swift`
- `HealthAppWidget/SharedModelContainer.swift`

### 3. Enable App Groups
This allows the app and widget to share SwiftData:

1. Select the **main app target** (HealthApp)
2. Go to "Signing & Capabilities"
3. Click `+ Capability` → search "App Groups"
4. Click `+` to add a new group: `group.com.aihealthappoffline.shared`
5. Make sure the checkbox is checked

6. Now select the **widget target** (HealthAppWidget)
7. Go to "Signing & Capabilities"
8. Click `+ Capability` → search "App Groups"
9. Check the SAME group: `group.com.aihealthappoffline.shared`

### 4. Add SwiftData Models to Widget Target
The widget needs access to `UserProfile` and `DailyLog`:
1. Select these files in Xcode:
   - `App/Models/UserProfile.swift`
   - `App/Models/DailyLog.swift`
2. In the right panel (File Inspector), under "Target Membership"
3. Check BOTH "HealthApp" AND "HealthAppWidget"

### 5. Build & Run
1. Select the "HealthAppWidget" scheme from the scheme picker
2. Run on iPhone 17 Pro simulator
3. Long-press the home screen → tap `+` → search "Daily Health"
4. Add the widget!

## Widget Sizes
- **Small**: Calorie ring with remaining kcal + streak
- **Medium**: Calorie ring + macro breakdown (protein/carbs/fats)
- **Large**: Full dashboard with calorie bar, macro cards, health score

## Data Refresh
The widget refreshes every 30 minutes automatically.
Users can also force-refresh by tapping the widget (opens the app).
