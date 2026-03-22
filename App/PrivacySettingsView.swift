import SwiftUI
import SwiftData

struct PrivacySettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settings: [PrivacySettings]
    
    var current: PrivacySettings {
        if let first = settings.first {
            return first
        }
        let new = PrivacySettings()
        context.insert(new)
        return new
    }
    
    var body: some View {
        Form {
            Section(header: Text("Profile Visibility"), footer: Text("Controls who can see your gamification stats, level, and streaks. Raw medical data is never shared.")) {
                Picker("Account Privacy", selection: Bindable(current).visibility) {
                    Text("Private").tag("private")
                    Text("Friends Only").tag("friends")
                    Text("Public").tag("public")
                }
                .pickerStyle(.menu)
            }
            
            Section(header: Text("Social Features")) {
                Toggle("Participate in Leaderboards", isOn: Bindable(current).participateInLeaderboards)
                Toggle("Show Badges on Profile", isOn: Bindable(current).showBadges)
                Toggle("Share Routine Templates", isOn: Bindable(current).shareRoutines)
            }
            
            Section(header: Text("Data Protection")) {
                Label("Health app data is never shared publicly.", systemImage: "lock.shield.fill")
                    .foregroundStyle(.green)
                    .font(.footnote)
            }
        }
        .navigationTitle("Social Privacy")
        .onChange(of: current.visibility) { _ in
            try? context.save()
        }
        .onChange(of: current.participateInLeaderboards) { _ in
            try? context.save()
        }
        .onChange(of: current.showBadges) { _ in
            try? context.save()
        }
        .onChange(of: current.shareRoutines) { _ in
            try? context.save()
        }
    }
}
