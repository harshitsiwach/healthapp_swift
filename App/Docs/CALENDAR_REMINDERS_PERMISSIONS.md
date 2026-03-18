# Calendar and Reminders Permission Keys

To use Apple's EventKit framework, `Info.plist` must contain the following keys depending on the level of access required:

## Calendar
- **NSCalendarsUsageDescription**: Required to read or modify existing events (Full Access).
- **NSCalendarsWriteOnlyAccessUsageDescription**: Required if the app only ever adds new events (Create Only).
- **NSCalendarsFullAccessUsageDescription**: (iOS 17+) Required alongside `NSCalendarsUsageDescription` to be granted full read/write access to the user's calendar.

## Reminders
- **NSRemindersUsageDescription**: Required to read or save items to Apple Reminders.
- **NSRemindersFullAccessUsageDescription**: (iOS 17+) Required alongside the base key for full reminders access.

## Current App Usage
Our app requests:
- **Write-Only Calendar**: For saving new doctor appointments or follow-ups seamlessly.
- **Full Reminders**: To sync medication and hydration habits to the native Reminders app.
- **Full Calendar (Optional)**: If the user wishes to see upcoming health appointments inside the app dashboard.
