import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var profiles: [UserProfile]
    @State private var shortcutAction: ShortcutAction?
    @State private var showFoodLogging = false
    @State private var showWaterLogging = false
    
    var body: some View {
        Group {
            if profiles.isEmpty {
                OnboardingView()
            } else {
                ContentView(showFoodLogging: $showFoodLogging)
                    .onAppear {
                        updateStreak()
                        requestNotifications()
                        donateShortcuts()
                    }
                    .onContinueUserActivity("com.aihealthappoffline.logMeal") { activity in
                        showFoodLogging = true
                    }
                    .onContinueUserActivity("com.aihealthappoffline.logFood") { activity in
                        shortcutAction = SiriShortcutsManager.handleUserActivity(activity)
                        showFoodLogging = true
                    }
                    .onContinueUserActivity("com.aihealthappoffline.checkCalories") { activity in
                        // Navigate to dashboard (already default)
                        shortcutAction = .checkCalories
                    }
                    .onContinueUserActivity("com.aihealthappoffline.logWater") { activity in
                        showWaterLogging = true
                        shortcutAction = .logWater
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
    
    private func donateShortcuts() {
        SiriShortcutsManager.shared.donateMealLoggingShortcut()
        SiriShortcutsManager.shared.donateCaloriesCheckShortcut()
        SiriShortcutsManager.shared.donateWaterLoggingShortcut()
    }
}

struct ContentView: View {
    @Environment(\.theme) var colors
    @Query private var profiles: [UserProfile]
    @State private var selectedTab = 0
    @State private var showCamera = false
    @Binding var showFoodLogging: Bool
    
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
            .tint(colors.neonBlue)
            .tabViewStyle(.automatic)
            
            // Floating Action Button (FAB)
            VStack {
                Spacer()
                Button {
                    showCamera = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(colors.neonBlue.gradient)
                            .frame(width: 56, height: 56)
                            .shadow(color: colors.neonBlue.opacity(0.5), radius: 12, x: 0, y: 4)
                            .shadow(color: colors.neonBlue.opacity(0.2), radius: 20, x: 0, y: 8)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(FABButtonStyle())
                .offset(y: -4)
            }
            .ignoresSafeArea(.keyboard)
        }
        .sheet(isPresented: $showCamera) {
            FoodLoggingSheet()
        }
        .sheet(isPresented: $showFoodLogging) {
            FoodLoggingSheet()
        }
    }
}
