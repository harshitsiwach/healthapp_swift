import SwiftUI

/// Settings view allowing the user to manage iOS permissions for Calendar and Reminders
struct CalendarRemindersPermissionsView: View {
    @StateObject private var permissions = PermissionsService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Calendar Access"), footer: Text("Allows HealthApp to automatically schedule appointments or follow-up visits.")) {
                
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("Add to Calendar")
                            .font(.headline)
                        Text(permissions.hasCalendarWriteOnlyAccess ? "Authorized" : "Not Authorized")
                            .font(.caption)
                            .foregroundColor(permissions.hasCalendarWriteOnlyAccess ? .green : .secondary)
                    }
                    Spacer()
                    if !permissions.hasCalendarWriteOnlyAccess {
                        Button("Allow") {
                            Task { try? await permissions.requestCalendarWriteOnlyAccess() }
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    }
                }
            }
            
            Section(header: Text("Reminders Access"), footer: Text("Allows the AI to sync medicine loops, supplements, and hydration reminders to the iOS Reminders app.")) {
                
                HStack {
                    Image(systemName: "list.bullet.rectangle.portrait")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading) {
                        Text("Sync to Reminders")
                            .font(.headline)
                        Text(permissions.hasRemindersAccess ? "Authorized" : "Not Authorized")
                            .font(.caption)
                            .foregroundColor(permissions.hasRemindersAccess ? .green : .secondary)
                    }
                    Spacer()
                    if !permissions.hasRemindersAccess {
                        Button("Allow") {
                            Task { try? await permissions.requestRemindersAccess() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    } else {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    }
                }
            }
            
            Section(header: Text("Push Notifications"), footer: Text("Required for local timers like fasting windows or cooking alarms.")) {
                HStack {
                    Image(systemName: "bell.badge")
                        .foregroundColor(.red)
                    VStack(alignment: .leading) {
                        Text("Alerts & Timers")
                            .font(.headline)
                        Text(permissions.hasNotificationAccess ? "Authorized" : "Not Authorized")
                            .font(.caption)
                            .foregroundColor(permissions.hasNotificationAccess ? .green : .secondary)
                    }
                    Spacer()
                    if !permissions.hasNotificationAccess {
                        Button("Allow") {
                            Task { try? await permissions.requestNotificationAccess() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    } else {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    }
                }
            }
            
            Section {
                Button(action: {
                    permissions.openAppSettings()
                }) {
                    HStack {
                        Spacer()
                        Text("Open iOS Settings")
                            .foregroundColor(.blue)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Integrations")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            permissions.checkCurrentStatus()
        }
    }
}

#Preview {
    NavigationView {
        CalendarRemindersPermissionsView()
    }
}
