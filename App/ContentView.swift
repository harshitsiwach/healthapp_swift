import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var profiles: [UserProfile]
    
    var body: some View {
        Group {
            if profiles.isEmpty {
                OnboardingView()
            } else {
                ContentView()
                    .onAppear {
                        updateStreak()
                        requestNotifications()
                    }
            }
        }
    }
    
    private func updateStreak() {
        guard let profile = profiles.first else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let yesterday = formatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        
        if profile.lastOpenedDate == yesterday {
            profile.streakCount += 1
        } else if profile.lastOpenedDate != today {
            profile.streakCount = 1
        }
        
        profile.lastOpenedDate = today
    }
    
    private func requestNotifications() {
        Task {
            try? await NotificationManager.shared.requestAuthorization()
            if let profile = profiles.first {
                NotificationManager.shared.scheduleDailyReminder(at: profile.notificationTime)
            }
        }
    }
}

struct ContentView: View {
    @Query private var profiles: [UserProfile]
    @State private var selectedTab = 0
    @State private var showCamera = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)
                
                ProgressTabView()
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Progress")
                    }
                    .tag(1)
                
                // AI Chat Tab
                AIChatView()
                    .tabItem {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                        Text("Chat")
                    }
                    .tag(2)
                
                HealthTabView()
                    .tabItem {
                        Image(systemName: "heart.text.clipboard")
                        Text("Health")
                    }
                    .tag(3)
                
                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                    .tag(4)
            }
            .tint(.blue)
            
            // Floating Action Button
            Button {
                showCamera = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.blue.gradient)
                        .frame(width: 60, height: 60)
                        .shadow(color: Color.blue.opacity(0.4), radius: 12, x: 0, y: 4)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .offset(y: -24)
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showCamera) {
            FoodLoggingSheet()
        }
    }
}
