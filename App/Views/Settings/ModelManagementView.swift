import SwiftUI

struct ModelManagementView: View {
    @Environment(\.theme) var colors
    @StateObject private var orchestrator = AIOrchestrator.shared
    @StateObject private var store = ModelStore()
    
    @AppStorage("selectedAIBackend") private var selectedBackend: String = AIBackendID.gemmaLocal.rawValue
    
    var body: some View {
        ZStack {
            colors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Available Engines")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(colors.textSecondary)
                            .padding(.horizontal, 4)
                        
                        // Gemma 2 (Local)
                        engineRow(
                            id: .gemmaLocal,
                            title: "Gemma 2 2B (Local)",
                            description: "Fully private, high-performance local AI. Works offline.",
                            icon: "cpu.fill",
                            color: colors.neonPurple,
                            isReady: store.installState == .ready
                        )
                        
                        // Apple Intelligence
                        engineRow(
                            id: .appleFoundation,
                            title: "Apple Intelligence",
                            description: "System-level foundation models by Apple. Optimized for iOS.",
                            icon: "apple.logo",
                            color: colors.textPrimary,
                            isReady: AppleFoundationBackend().checkCapability().canUseFoundationModels
                        )
                    }
                    
                    infoSection
                    
                    Spacer(minLength: 50)
                }
                .padding(20)
            }
        }
        .navigationTitle("AI Engine")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedBackend) { _, newValue in
            if let id = AIBackendID(rawValue: newValue) {
                orchestrator.activeBackendOverride = id
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(colors: [colors.neonBlue, colors.neonPurple], startPoint: .top, endPoint: .bottom)
                )
                .padding(.bottom, 8)
            
            Text("Choose your Intelligence")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.black)
            
            Text("Select the primary AI engine for health analysis and chat. Both options run locally on your device.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
    
    private func engineRow(id: AIBackendID, title: String, description: String, icon: String, color: Color, isReady: Bool) -> some View {
        Button {
            if isReady {
                selectedBackend = id.rawValue
                orchestrator.activeBackendOverride = id
                Haptic.selection()
            }
        } label: {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(colors.textPrimary)
                    
                    Text(description)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(colors.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if !isReady {
                    Text("Unavailable")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1), in: Capsule())
                        .foregroundStyle(.red)
                } else {
                    Image(systemName: selectedBackend == id.rawValue ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(selectedBackend == id.rawValue ? colors.neonGreen : colors.textTertiary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colors.backgroundCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(selectedBackend == id.rawValue ? color.opacity(0.5) : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!isReady)
        .opacity(isReady ? 1.0 : 0.6)
    }
    
    private var infoSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(colors.neonGreen)
                Text("On-Device Privacy Guaranteed")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
            }
            .padding(.top, 12)
            
            Text("Your health data and conversations never leave this device. No information is sent to the cloud for processing.")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(colors.backgroundCard.opacity(0.5))
        .cornerRadius(20)
    }
}
