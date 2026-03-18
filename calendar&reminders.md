Yes — you can integrate Apple’s official calendar, reminders, local notifications, and even Live Activities into a native Swift/Xcode app through EventKit, EventKitUI, UserNotifications, and ActivityKit. [developer.apple](https://developer.apple.com/documentation/eventkit)
Below is a standalone instructions file for your agent focused on those integrations, permission flows, and product-safe feature boundaries. [createwithswift](https://www.createwithswift.com/getting-access-to-the-users-calendar/)

## calendar_reminders.md

Save the following as `calendar_reminders.md`.

# Calendar, Reminders, Timers, and Notifications Integration

## Goal

Integrate Apple’s official calendar, reminders, timer-style alerts, and live status surfaces into the iOS app using first-party Apple frameworks. [developer.apple](https://developer.apple.com/documentation/usernotifications)
Use EventKit and EventKitUI for calendar and reminders, UserNotifications for local alerts, and ActivityKit for Live Activities where they improve the experience. [developer.apple](https://developer.apple.com/documentation/EventKit/accessing-calendar-using-eventkit-and-eventkitui)
Treat every integration as permission-based, user-controlled, and optional. [developer.apple](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter)

## Supported Apple frameworks

Use `EventKit` to create, retrieve, and edit calendar events and reminders. [developer.apple](https://developer.apple.com/documentation/eventkit/creating-events-and-reminders)
Use `EventKitUI` when the product should present Apple’s native event editor or viewer instead of a custom form. [developer.apple](https://developer.apple.com/documentation/EventKit/accessing-calendar-using-eventkit-and-eventkitui)
Use `UNUserNotificationCenter` and the User Notifications framework for local reminder alerts, timer completion alerts, fasting reminders, hydration reminders, and scheduled health prompts. [developer.apple](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app)
Use `ActivityKit` for Live Activities when the app needs a persistent lock-screen or Dynamic Island status surface for an active timer or ongoing health workflow. [developer.apple](https://developer.apple.com/documentation/appclip/offering-live-activities-with-your-app-clip)

## Product features to integrate

### Calendar features

Support “Add to Calendar” for doctor appointments, follow-up visits, lab tests, medication refill dates, nutrition consultations, and custom user-defined wellness events. [developer.apple](https://developer.apple.com/documentation/eventkit)
Support editing and deleting app-created calendar entries when the app has the required event access. [developer.apple](https://developer.apple.com/documentation/eventkit/retrieving-events-and-reminders)
Support write-only calendar access for simple “create event only” flows, because Apple provides a write-only event permission path for apps that do not need to read the user’s full calendar. [createwithswift](https://www.createwithswift.com/getting-access-to-the-users-calendar/)
Support full calendar access only for features that truly require reading or modifying existing calendar entries, such as showing upcoming appointments inside the app. [createwithswift](https://www.createwithswift.com/getting-access-to-the-users-calendar/)

### Reminders features

Support creating reminders for medicines, supplements, hydration, meal logging, fasting windows, exercise, report follow-ups, and custom wellness habits. [developer.apple](https://developer.apple.com/tutorials/app-dev-training/loading-reminders)
Support reading reminders only if the product genuinely needs to display the user’s reminder state or synchronize app tasks with Apple Reminders. [developer.apple](https://developer.apple.com/documentation/eventkit/retrieving-events-and-reminders)
Support editing completion state, due date, and notes for app-linked reminders when permission is granted. [developer.apple](https://developer.apple.com/documentation/eventkit/creating-events-and-reminders)

### Notifications and timers

Support local notifications for medication reminders, hydration reminders, meal reminders, sleep reminders, appointment reminders, and countdown timers. [developer.apple](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/SchedulingandHandlingLocalNotifications.html)
Use `UNTimeIntervalNotificationTrigger` for countdown timers and short-duration reminders, and use `UNCalendarNotificationTrigger` for date-based reminders such as appointments or medicine schedules. [developer.apple](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/SchedulingandHandlingLocalNotifications.html)
Allow the user to stop, snooze, or reschedule reminder-driven notifications from within the app where appropriate. [developer.apple](https://developer.apple.com/documentation/usernotifications)
Use app-local timers for in-session countdowns and pair them with scheduled local notifications so alerts still fire when the app is backgrounded. [developer.apple](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app)

### Live Activities

Support Live Activities for active countdowns such as fasting timers, medicine countdowns, hydration streak windows, workout recovery timers, or “next meal window” timers. [developer.apple](https://developer.apple.com/documentation/ActivityKit/)
Only use Live Activities for time-sensitive and actively relevant flows, because ActivityKit is meant for live, glanceable updates rather than static reminders. [developer.apple](https://developer.apple.com/documentation/appclip/offering-live-activities-with-your-app-clip)
Do not use Live Activities as a replacement for the reminders list or the calendar view. [developer.apple](https://developer.apple.com/documentation/ActivityKit/)

### Siri and suggestion surfaces

Evaluate Siri Event Suggestions for reservation-like or appointment-like events generated by the app, because Apple’s WWDC guidance notes that Siri Event Suggestions can add events to the Calendar inbox without prompting for calendar access.
Treat Siri Event Suggestions as an optional enhancement, not as the main calendar integration path.

## Permission model

Request permissions only when the user triggers a feature that clearly needs them, not during generic onboarding. [createwithswift](https://www.createwithswift.com/getting-access-to-the-users-calendar/)
For calendar access, support both write-only access and full access, and request the minimum level necessary. [createwithswift](https://www.createwithswift.com/getting-access-to-the-users-calendar/)
For reminders access, request reminders permission only when the user enables reminder sync or creates an Apple Reminder from inside the app. [developer.apple](https://developer.apple.com/tutorials/app-dev-training/loading-reminders)
For notifications, request authorization through `UNUserNotificationCenter` before scheduling alerts. [developer.apple](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter)

### Required privacy usage descriptions

Include the relevant privacy usage descriptions for calendar and reminders access in the app configuration, because EventKit access depends on those entries. [createwithswift](https://www.createwithswift.com/getting-access-to-the-users-calendar/)
Use clear user-facing copy that explains what the app will do with calendar data, reminder data, and notifications before showing the system prompt. [developer.apple](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter)

## Architecture requirements

Create separate services instead of coupling these APIs directly to views. [developer.apple](https://developer.apple.com/documentation/eventkit)
Build these modules:

- `CalendarService` for EventKit event creation, retrieval, and update flows. [developer.apple](https://developer.apple.com/documentation/eventkit/creating-events-and-reminders)
- `ReminderService` for Apple Reminders integration through `EKEventStore`. [developer.apple](https://developer.apple.com/tutorials/app-dev-training/loading-reminders)
- `NotificationService` for all local notification scheduling, cancellation, categories, and snooze flows. [developer.apple](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/SchedulingandHandlingLocalNotifications.html)
- `TimerService` for in-app timer state, background resumption, and notification linking. [developer.apple](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app)
- `LiveActivityService` for ActivityKit-based timer and session status surfaces. [developer.apple](https://developer.apple.com/documentation/appclip/offering-live-activities-with-your-app-clip)
- `PermissionsService` for centralized permission checks and request flows for calendar, reminders, and notifications. [developer.apple](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter)

Keep business logic in these services and expose simple app-level actions such as “schedule follow-up,” “create medicine reminder,” or “start fasting timer.” [developer.apple](https://developer.apple.com/documentation/eventkit)
Never let the AI layer write directly to Calendar or Reminders without explicit user confirmation. [createwithswift](https://www.createwithswift.com/getting-access-to-the-users-calendar/)

## Recommended feature flows

### Add appointment to Calendar

User taps “Add to Calendar,” reviews the appointment details, approves the action, and then the app either opens Apple’s event editor with EventKitUI or creates the event directly through EventKit depending on the feature mode. [developer.apple](https://developer.apple.com/documentation/EventKit/accessing-calendar-using-eventkit-and-eventkitui)
If the app only needs to create the event and never read existing events, request write-only event access. [createwithswift](https://www.createwithswift.com/getting-access-to-the-users-calendar/)

### Create Apple Reminder

User taps “Create Reminder,” reviews title, note, due date, and recurrence, grants reminders access if needed, and then the app saves the reminder through `EKEventStore`. [developer.apple](https://developer.apple.com/tutorials/app-dev-training/loading-reminders)
Use this for medicines, supplements, water intake, symptom tracking, post-meal walks, and report follow-ups. [developer.apple](https://developer.apple.com/documentation/eventkit/creating-events-and-reminders)

### Start timer with local alert

User starts a countdown, the app begins a local timer for UI updates, and the app also schedules a local notification so the alert can still fire when the app is backgrounded. [developer.apple](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/SchedulingandHandlingLocalNotifications.html)
If the timer is important and actively running, optionally start a Live Activity so the countdown remains visible on the lock screen or Dynamic Island. [developer.apple](https://developer.apple.com/documentation/ActivityKit/)

### Reminder notifications

Support notification categories for actions like done, snooze, reschedule, and open app when those actions fit the reminder type. [developer.apple](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/SchedulingandHandlingLocalNotifications.html)
Keep notification content short, informative, and user-controlled. [developer.apple](https://developer.apple.com/documentation/usernotifications)

## Features to ship first

Ship these first because they are high-value and relatively low-risk:

- Add doctor appointment to Apple Calendar. [developer.apple](https://developer.apple.com/documentation/eventkit)
- Create medicine and supplement reminders in Apple Reminders. [developer.apple](https://developer.apple.com/tutorials/app-dev-training/loading-reminders)
- Schedule local notifications for hydration, meal timing, fasting windows, and health follow-ups. [developer.apple](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app)
- Add timers for fasting, post-meal walks, supplements, and medicine countdowns. [developer.apple](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app)
- Add Live Activities for active timers only. [developer.apple](https://developer.apple.com/documentation/appclip/offering-live-activities-with-your-app-clip)

## Safety and UX rules

Always ask for user confirmation before creating a calendar event, saving a reminder, or scheduling recurring notifications. [developer.apple](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter)
If permission is denied, keep the feature usable in a manual in-app mode instead of breaking the flow. [developer.apple](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter)
Do not spam users with excessive recurring notifications, and give easy controls to pause or disable reminder categories. [developer.apple](https://developer.apple.com/documentation/usernotifications)

## Non-goals

Do not read the user’s entire calendar unless the feature truly needs it. [createwithswift](https://www.createwithswift.com/getting-access-to-the-users-calendar/)
Do not auto-create reminders or calendar events based only on AI output without explicit user approval. [developer.apple](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter)
Do not use Live Activities for passive or low-value information. [developer.apple](https://developer.apple.com/documentation/ActivityKit/)

## File structure to generate

Ask the agent to create these files:

- `App/System/PermissionsService.swift` [createwithswift](https://www.createwithswift.com/getting-access-to-the-users-calendar/)
- `App/Calendar/CalendarService.swift` [developer.apple](https://developer.apple.com/documentation/eventkit/creating-events-and-reminders)
- `App/Calendar/CalendarEventEditor.swift` [developer.apple](https://developer.apple.com/documentation/EventKit/accessing-calendar-using-eventkit-and-eventkitui)
- `App/Reminders/ReminderService.swift` [developer.apple](https://developer.apple.com/tutorials/app-dev-training/loading-reminders)
- `App/Notifications/NotificationService.swift` [developer.apple](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/SchedulingandHandlingLocalNotifications.html)
- `App/Timers/TimerService.swift` [developer.apple](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app)
- `App/LiveActivities/LiveActivityService.swift` [developer.apple](https://developer.apple.com/documentation/appclip/offering-live-activities-with-your-app-clip)
- `App/Settings/CalendarRemindersPermissionsView.swift` [createwithswift](https://www.createwithswift.com/getting-access-to-the-users-calendar/)
- `App/Docs/CALENDAR_REMINDERS_PERMISSIONS.md` [developer.apple](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter)

## Acceptance criteria

The integration is complete only when the app can request permissions contextually, create Apple Calendar events, create Apple Reminders, schedule local notifications, run timer-based alerts, and optionally surface active timers as Live Activities. [developer.apple](https://developer.apple.com/documentation/ActivityKit/)
The app must also continue working when any of those permissions are denied, using in-app fallback behavior where necessary. [createwithswift](https://www.createwithswift.com/getting-access-to-the-users-calendar/)

## Final instruction to the agent

Build Apple-native productivity integrations as confirmable actions around health workflows: AI can suggest an appointment, reminder, or timer, but native services must create it only after the user approves. [developer.apple](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter)

## Scope note

This file covers the official Apple integrations that fit best for your use case: Calendar, Reminders, local notifications, timers, Live Activities, and optional Siri Event Suggestions. [developer.apple](https://developer.apple.com/documentation/usernotifications)
That gives your app a strong native workflow layer without depending on private APIs or risky system behavior. [developer.apple](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter)