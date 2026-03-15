# HealthKit Permissions Matrix

To comply with Apple's App Store Review Guidelines, the HealthApp requires proper `Info.plist` usage descriptions for each HealthKit data type accessed.

## Summary of Entitlements Required

Enable the **HealthKit** capability in the Xcode target.

## Read Access (`NSHealthShareUsageDescription`)

Must be set in `Info.plist`:
`<key>NSHealthShareUsageDescription</key>`
`<string>HealthApp reads your steps, heart rate, sleep, and weight to provide personalized AI nutrition feedback and contextual health summaries.</string>`

| Identifier | Type | Required For |
| :--- | :--- | :--- |
| `.stepCount` | `HKQuantityType` | Daily dashboard activity summaries |
| `.activeEnergyBurned` | `HKQuantityType` | Adjusting TDEE directly from actual burn |
| `.heartRate` | `HKQuantityType` | Vitals context for AI |
| `.sleepAnalysis` | `HKCategoryType` | Providing sleep-adjusted macro advice |
| `.bodyMass` | `HKQuantityType` | Weight tracking and maintenance feedback |
| `HKWorkoutType` | `HKObjectType` | Contextualizing intense exercise |

## Write Access (`NSHealthUpdateUsageDescription`)

Must be set in `Info.plist`:
`<key>NSHealthUpdateUsageDescription</key>`
`<string>HealthApp writes nutrition data to Apple Health to keep your daily macro and calorie logs synced across all your apps.</string>`

| Identifier | Type | Required For |
| :--- | :--- | :--- |
| `.dietaryEnergyConsumed` | `HKSampleType` | Syncing tracked meal calories |
| `.dietaryCarbohydrates` | `HKSampleType` | Syncing tracked carbs |
| `.dietaryProtein` | `HKSampleType` | Syncing tracked protein |
| `.dietaryFatTotal` | `HKSampleType` | Syncing tracked fat |
