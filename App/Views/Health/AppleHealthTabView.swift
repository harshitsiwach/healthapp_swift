import SwiftUI

struct AppleHealthTabView: View {
    @StateObject private var insightsService = HealthInsightsService()
    @State private var showingPermissions = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Apple Health")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            
                            Text("Your centralized hub for health data and privacy controls.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        
                        // Summary Card
                        if let summary = insightsService.lastSummary {
                            DailyHealthSummaryCard(summary: summary)
                                .padding(.horizontal)
                        } else {
                            if insightsService.isRefreshing {
                                ProgressView("Fetching Health Data...")
                                    .padding()
                            } else {
                                GlassCard(padding: 20) {
                                    VStack(spacing: 12) {
                                        Image(systemName: "heart.slash")
                                            .font(.largeTitle)
                                            .foregroundStyle(.gray)
                                        Text("No Health Data Found")
                                            .font(.headline)
                                        Text("Make sure you have granted permissions and have logged data in Apple Health.")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Error Message
                        if let error = insightsService.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.horizontal)
                        }
                        
                        // Permissions Button
                        Button {
                            showingPermissions = true
                        } label: {
                            HStack {
                                Image(systemName: "lock.shield")
                                Text("Manage Permissions")
                            }
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                Group {
                                    if #available(iOS 26, *) {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.clear)
                                            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
                                    } else {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.ultraThinMaterial)
                                    }
                                }
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .task {
                await insightsService.refreshSummary()
            }
            .sheet(isPresented: $showingPermissions) {
                HealthPermissionsView()
                    .onDisappear {
                        Task { await insightsService.refreshSummary() }
                    }
            }
        }
    }
}
