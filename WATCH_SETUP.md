# Apple Watch Setup Guide

## Steps to add Watch App Target in Xcode

### 1. Add Watch App Target
1. Open `HealthApp.xcodeproj` in Xcode
2. Click on the project name in the left sidebar
3. Click the `+` button at the bottom of the targets list
4. Search for "watchOS" → "App"
5. Set Product Name: `HealthAppWatch`
6. Set Interface: SwiftUI
7. Click Finish

### 2. Add Source Files
Drag these files into the HealthAppWatch target:
- `HealthAppWatch/WatchMainView.swift`

### 3. Enable App Groups (for data sharing)
1. Select the **main app target** (HealthApp)
2. Go to "Signing & Capabilities"
3. Enable App Groups: `group.com.aihealthappoffline.shared`

4. Select the **watch target** (HealthAppWatch)
5. Enable the SAME App Groups: `group.com.aihealthappoffline.shared`

### 4. Add SwiftData Models to Watch Target
Select these files and add Watch target membership:
- `App/Models/UserProfile.swift`
- `App/Models/DailyLog.swift`

### 5. Features on Apple Watch
- **Calorie Ring**: See remaining calories on your wrist
- **Macro Chips**: Quick view of protein/carbs/fats
- **Quick Food Log**: Common Indian foods (Roti, Rice, Dal, Egg, etc.)
- **Water Tracker**: Tap to log glasses of water
- **Streak Badge**: Your daily streak count

### 6. Complications (optional)
Add complications to show:
- Calories remaining
- Protein intake
- Water glasses count
- Streak days

### Note
The Watch app uses the same shared SwiftData container via App Groups,
so data syncs automatically with the iPhone app.
