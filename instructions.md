# AI Agent Swift Migration Guide: Smart Health App

## Project Overview
You are tasked with rebuilding a modern, AI-powered Health and Nutrition tracking application entirely from scratch in **Xcode using Swift and SwiftUI**. 

The app features an advanced frosted-glass aesthetic, extensive use of localized on-device SQL storage, interactive push notifications, and deep integration with the Google Gemini API for photo-based calorie tracking, weekly health reports, and meal recommendations tailored to the Indian diet.

**Architecture Target:** MVVM (Model-View-ViewModel) using SwiftUI, SwiftData (or SQLite.swift/CoreData), and `UNUserNotificationCenter` for local notifications.

---

## 1. Core Data Models & Persistence
The app requires local persistence. You must implement a local database (SwiftData is recommended for iOS 17+, else CoreData or SQLite.swift).

### `UserProfile` Model
A single-row table/entity storing the user's settings and baselines.
- `id`: UUID or Int
- `gender`: String (Male, Female, Other)
- `dob`: Date
- `height_cm`: Double
- `weight_kg`: Double
- `workouts_per_week`: Int
- `goal`: String (lose, maintain, gain)
- `dietary_preference`: String (vegetarian, vegan, eggetarian, non-vegetarian)
- `calculated_daily_calories`: Int
- `calculated_daily_carbs`: Int
- `calculated_daily_protein`: Int
- `calculated_daily_fats`: Int
- `health_score`: Int (0-100)
- `streak_count`: Int (Default 1)
- `last_opened_date`: Date/String (used to calculate streaks)
- `notification_time`: String (HH:mm)

### `DailyLogs` Model
Stores meals and daily goal completions.
- `id`: UUID or Auto-increment Int
- `date`: Date/String (YYYY-MM-DD)
- `food_name`: String (Optional, if null it's just a proxy row for goal completion)
- `estimated_calories`: Int
- `protein_g`: Double
- `carbs_g`: Double
- `fat_g`: Double
- `goal_completed`: Bool/Int (Yes/No answer to daily push notification)
- `image_uri`: String (Local file path for the camera capture)

---

## 2. Onboarding Flow (4 Steps)
If `UserProfile` doesn't exist, launch this flow. Use a standard `NavigationStack`.

1. **Step 1 (Basic):** 
   - Ask for Gender (Chips: Male, Female, Other). 
   - Ask for Workouts per week (Chips: 0 to 7).
2. **Step 2 (Physical Data):**
   - Ask for DOB (Native `DatePicker`, spinning style).
   - Ask for Height (cm) and Weight (kg) using `Picker` wheels.
3. **Step 3 (Preferences):**
   - Calculate BMI in the background and show a "💡 Recommended" badge on the goal.
   - Goal (Cards: Lose Weight, Maintain, Gain Muscle).
   - Dietary Preference (Chips: Vegetarian, Vegan, Eggetarian, Non-Veg).
4. **Step 4 (Results/Calculation):**
   - Show a loading spinner: "Generating Your Plan...".
   - Use the **Mifflin-St Jeor equation** to calculate BMR and TDEE based on workouts. Adjust +/- 500 kcal based on goal.
   - Macros (Indian Diet Adjusted): Lose (40% carb, 35% pro, 25% fat), Maintain/Gain (50% carb, 25% pro, 25% fat).
   - Calculate an initial Health Score (100 minus deductions for bad BMI or 0 workouts).
   - Save all this to the local database.
   - Show the final calculated Calories, Carbs, Protein, and Fats in a beautiful frosted glass UI, along with BMI classification (Underweight, Healthy, Overweight, Obese) and a custom description.

---

## 3. Main Dashboard (Home Tab)
- **Top Bar:** Today's Date formatted nicely, and a "Streak Badge" (fire icon + `streak_count`).
  - *Streak Logic:* On app launch, check `last_opened_date`. If it was yesterday, increment streak. If older, reset to 1.
- **Weekly horizontal calendar:** Show the last 5 days, today, and tomorrow. Selectable. Defaults to Today.
- **Fallback Goal Prompt:** If the user is on Today's date, and the current time is past their `notification_time`, and they haven't answered their daily goal yet (`goal_completed == nil`), show an inline card: "Did you complete your goals today?" with [No] [Yes] buttons. Updates the DB immediately.
- **Main Calorie Card:** A massive clickable card showing remaining calories and a custom `CircularProgress` ring. (navigates to AI Recommendations).
- **Macro Row:** 3 horizontal glass cards for Protein, Carbs, and Fats. Show remaining grams and a mini circular progress ring. 
  - *Dynamic Badges:* Show warnings if over the limit ("+10g over" in red) or if they haven't eaten enough by 3 PM ("⚠️ Low intake" in yellow).
- **Weekly Balances Button:** Navigates to the Weekly Stats view.
- **Recently Logged List:** Shows meals logged for the selected date. Clicking a meal opens a bottom sheet to manually edit its Name, Calories, and Macros.

---

## 4. Floating Action Button & Camera Flow
Implement a custom FAB centered above or on the right of the Tab Bar to launch the Camera sheet.

- **Camera View:** Use `AVFoundation` for a full-screen camera view. 
- **Type Instead:** An option to skip the camera and just type the food description (e.g., "2 roti and dal"). 
- **Gemini AI Integration (CRITICAL):**
  - Prompt: Roleplay as an expert Indian nutritionist. Estimate calories, protein, carbs, and fats.
  - If Image: Pass the base64 jpeg to `gemini-2.5-flash` with a text prompt.
  - If Text: Pass the text to `gemini-2.5-flash`.
  - Parse the JSON response (`food_name`, `estimated_calories`, `protein_g`, `carbs_g`, `fat_g`).
- **Review Step:** Show an editable form pre-filled with the AI's guesses. Let the user adjust numbers before hitting "Save", which writes to `DailyLogs`.

---

## 5. Progress Tab
- **Monthly Calendar:** Use `UICalendarView` or a custom SwiftUI calendar grid.
  - For each day in the month, look at `DailyLogs.goal_completed`.
  - If 1 (Yes): Show a Green dot/background.
  - If 0 (No): Show a Red dot/background.
- **Monthly Score:** Calculate consistency: (Green Days / Days Elapsed in Month) * 10. Display a large score out of 10.

---

## 6. Health Tab (AI Weekly Report)
- Fetches the last 7 days of logs (average calories, protein, carbs, fat, and goal completion rate).
- **Gemini API Call:** Pass these averages to the AI.
  - Ask for: A score (1-10), a 2-sentence summary, an array of warnings (if eating poorly), and an array of `natural_cures` (Indian Ayurvedic remedies like neem, jeera water, etc. based on their deficiencies).
- **UI:** Show "Generating Your Report" while fetching. Then display the Health Score prominently, followed by a yellow glass card for "Health Warnings" and a green glass card for "Natural Remedies".
- Add a "Regenerate Report" button.

---

## 7. AI Meal Ideas (Recommendations View)
Linked from the Dashboard Calorie card.
- **Filters:** A horizontal scroll of chips.
  - Meal Type toggle: `Full Meal` vs `Simple Prep`.
  - Budget toggle: `Low`, `Moderate`, `High`.
- **Gemini API Call:** Send User Goal, Dietary Preference, Remaining Calories, Budget, and Meal Type. 
  - Ask for 5 culturally appropriate Indian meal ideas in JSON format (`name`, `calories`, `protein`, `carbs`, `fat`, `description`).
  - *Debounce* the API calls if the user switches filters rapidly.
- **UI:** Render the meals as cards showing chef hats, descriptions, and pill-shaped macro readouts.

---

## 8. Weekly Stats View
Linked from the Dashboard.
- **Logic:** Calculates rollover pools. For an Indian eating week (starting Sunday or Monday): Total Calories, Carbs, and Fats *roll over* for the week. Protein *resets daily*.
- Show remaining pool left for the week.
- Calculate and display a "Suggested Adjusted Daily Target" to get them back on track for the remaining days of the week.
- **Insights:** Text explanations (e.g., "You had 400kcal extra this week. Consider reducing portion sizes.")

---

## 9. Settings & Push Notifications
- **Notification Time Picker:** Change the daily reminder time using a native Swift `DatePicker` (Time mode).
- **Interactive Push Notifications (`UNUserNotificationCenter`):**
  - Register a custom Notification Category named `goal_check`.
  - Add two `UNNotificationAction` buttons: "Yes, absolutely!" and "Not yet" (Destructive).
  - Schedule a local repeating daily notification at the user's chosen time.
  - Interpret the user's action in `UNUserNotificationCenterDelegate`. Write `goal_completed = 1` or `0` directly to the `DailyLogs` SQLite/SwiftData database in the background.
- **Clear Data (Danger Zone):** An alert to wipe `DailyLogs` and `UserProfile` (preserving streak) and kick the user back to Onboarding.

---

## 10. Design Aesthetics & Styling
The app relies heavily on modern iOS frosted glass:
- **Materials:** Use SwiftUI `Material.ultraThin`, `Material.regular`, `Material.thick` heavily for cards instead of solid colors. 
- **Backgrounds:** The background should be a light gray (`#F0F2F5` in light mode, dark gray in dark mode), with massive, blurred gradient blobs behind the UI. In SwiftUI, use `Circle().fill(Color.purple).blur(radius: 100)` layered underneath the `ScrollView`.
- **Typography:** Use native `SF Pro Rounded` heavily. Use `.fontWeight(.heavy)` or `.black` for numbers and major titles.
- **Micro-interactions:** Add `.animation(.spring())` to buttons, filter chips, and circular progress bars.
- Use **SF Symbols** for all icons (matches the generic icons used in the React Native app).
