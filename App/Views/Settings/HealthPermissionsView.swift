import SwiftUI
import HealthKit

struct HealthPermissionsView: View {
    @Environment(\.theme) var colors
    @StateObject private var authService = HealthAuthorizationService()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.pink.gradient)
                            .padding(.top, 40)
                        
                        Text("Apple Health Sync")
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.heavy)
                        
                        Text("Connect HealthApp to Apple Health to get personalized, context-aware AI coaching based on your activity, sleep, and vitals.")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Label("Read Steps & Activity", systemImage: "figure.walk")
                                Label("Read Sleep Data", systemImage: "bed.double.fill")
                                Label("Read Heart Rate", systemImage: "waveform.path.ecg")
                                Label("Write Nutrition Data", systemImage: "fork.knife")
                            }
                            .font(.system(.headline, design: .rounded))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Spacer(minLength: 40)
                        
                        Button {
                            Task {
                                try? await authService.requestBasicAuthorization()
                                dismiss()
                            }
                        } label: {
                            Text("Connect Health")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(colors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    Group {
                                        if #available(iOS 26, *) {
                                            Capsule()
                                                .fill(Color.clear)
                                                .glassEffect(.regular.tint(.pink).interactive(), in: .capsule)
                                        } else {
                                            Capsule()
                                                .fill(Color.pink.gradient)
                                        }
                                    }
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                }
            }
            .navigationTitle("HealthKit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
