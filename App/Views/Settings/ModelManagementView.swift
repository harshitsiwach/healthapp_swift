import SwiftUI

struct ModelManagementView: View {
    @Environment(\.theme) var colors
    @StateObject private var store = ModelStore()
    @StateObject private var downloader = ModelDownloader()
    
    var body: some View {
        ZStack {
            colors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Gemma 4 On-Device Header
                    GlassCard(material: .regularMaterial) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .foregroundStyle(colors.neonPurple)
                                Text("Gemma 4 (On-Device)")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                            }
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Fully Private, Fully Offline")
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(.medium)
                                    Text("All AI runs locally on your device. No internet required.")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(colors.textSecondary)
                                }
                                Spacer()
                                Image(systemName: store.installState == .ready ? "checkmark.circle.fill" : "arrow.down.circle")
                                    .foregroundStyle(store.installState == .ready ? colors.neonGreen : colors.neonBlue)
                            }
                        }
                    }
                    
                    // Apple Intelligence (Optional)
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "apple.logo")
                                    .foregroundStyle(colors.textPrimary)
                                Text("Apple Intelligence")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                Spacer()
                                Text("Optional")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(colors.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(colors.textSecondary.opacity(0.1), in: Capsule())
                            }
                            
                            let capability = AppleFoundationBackend().checkCapability()
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(capability.isSupportedOS ? "Supported OS" : "Requires iOS 26+")
                                        .font(.system(.subheadline, design: .rounded))
                                    Text(capability.canUseFoundationModels ? "Available" : "Not available on this device")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(colors.textSecondary)
                                }
                                Spacer()
                                Image(systemName: capability.canUseFoundationModels ? "checkmark.circle.fill" : "xmark.circle")
                                    .foregroundStyle(capability.canUseFoundationModels ? colors.neonGreen : colors.textTertiary)
                            }
                        }
                    }
                    
                    // Local Models
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Local Models")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                        
                        ForEach(store.availableModels) { model in
                            modelCard(model)
                        }
                    }
                    
                    // Storage Info
                    GlassCard(padding: 12) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundStyle(colors.neonGreen)
                            Text("Your data never leaves your device")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(colors.textSecondary)
                        }
                    }
                    
                    // Delete All
                    if store.installedManifest != nil {
                        Button {
                            store.deleteAllModels()
                        } label: {
                            Text("Delete All Models")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(colors.neonRed)
                                .padding(.top, 8)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("AI Engine")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func modelCard(_ manifest: ModelManifest) -> some View {
        GlassCard(material: .regularMaterial) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "cpu")
                        .foregroundStyle(colors.neonPurple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(manifest.displayName)
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                        Text("v\(manifest.version) • \(manifest.quantization.uppercased()) • \(manifest.fileSizeFormatted)")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(colors.textSecondary)
                    }
                    Spacer()
                }
                
                // State indicator
                HStack {
                    Image(systemName: store.installState.iconName)
                        .foregroundStyle(stateColor)
                    Text(store.installState.displayText)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundStyle(stateColor)
                    Spacer()
                }
                
                // Download progress
                if store.installState == .downloading {
                    ProgressView(value: store.downloadProgress)
                        .tint(.purple)
                }
                
                // Action buttons
                HStack {
                    switch store.installState {
                    case .notInstalled, .failed:
                        Button {
                            Task {
                                await downloader.download(manifest: manifest, to: store)
                            }
                        } label: {
                            Text("Download Gemma 4")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(colors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.purple.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        
                    case .downloading:
                        Button {
                            downloader.cancelDownload()
                        } label: {
                            Text("Cancel")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(colors.neonRed)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        
                    case .ready:
                        Button {
                            store.deleteModel(manifest)
                        } label: {
                            Text("Delete Model")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(colors.neonRed)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        
                    default:
                        EmptyView()
                    }
                }
                
                if let error = downloader.error {
                    Text(error)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(colors.neonRed)
                }
            }
        }
    }
    
    private var stateColor: Color {
        switch store.installState {
        case .ready: return colors.neonGreen
        case .downloading, .verifying, .warmingUp: return colors.neonPurple
        case .failed: return colors.neonRed
        case .incompatible: return colors.textTertiary
        case .notInstalled: return colors.textSecondary
        }
    }
}
