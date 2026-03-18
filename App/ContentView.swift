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
                
                // Spacer for FAB
                Color.clear
                    .tabItem {
                        Text("")
                    }
                    .tag(-1)
                
                AIChatView()
                    .tabItem {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                        Text("Chat")
                    }
                    .tag(2)
                
                HealthContainerView()
                    .tabItem {
                        Image(systemName: "heart.text.square.fill")
                        Text("Health")
                    }
                    .tag(3)
            }
            .tint(.blue)
            
            // Floating Action Button (FAB)
            VStack {
                Spacer()
                Button {
                    showCamera = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.blue.gradient)
                            .frame(width: 56, height: 56)
                            .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .offset(y: -4) // Align with tab bar icons
            }
            .ignoresSafeArea(.keyboard)
        }
        .sheet(isPresented: $showCamera) {
            FoodLoggingSheet()
        }
    }
}
