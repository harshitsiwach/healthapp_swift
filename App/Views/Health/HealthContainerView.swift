import SwiftUI

/// A container view that merges the Weekly Report (Insights) and Apple Health (Raw Data)
struct HealthContainerView: View {
    @Environment(\.theme) var colors
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Picker for switching views
                Picker("Health View", selection: $selectedTab) {
                    Text("Insights").tag(0)
                    Text("Raw Data").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                
                Group {
                    if selectedTab == 0 {
                        HealthTabView()
                    } else {
                        AppleHealthTabView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(selectedTab == 0 ? "Weekly Report" : "Apple Health")
            .navigationBarTitleDisplayMode(.inline)
            .background(colors.background.ignoresSafeArea())
        }
    }
}

#Preview {
    HealthContainerView()
}
