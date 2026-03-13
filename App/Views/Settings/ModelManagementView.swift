import SwiftUI

struct ModelManagementView: View {
    @StateObject private var store = ModelStore()
    @StateObject private var downloader = ModelDownloader()
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Current Backend
                    GlassCard(material: .regularMaterial) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "cpu")
                                    .foregroundStyle(.blue)
                                Text("Active Backend")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                            }
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Gemini 2.5 Flash (Remote)")
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(.medium)
                                    Text("Cloud-based • Requires internet")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    
                    // Apple Intelligence
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "apple.logo")
                                    .foregroundStyle(.primary)
                                Text("Apple Intelligence")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                            }
                            
                            let capability = AppleFoundationBackend().checkCapability()
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(capability.isSupportedOS ? "Supported OS" : "Requires iOS 26+")
                                        .font(.system(.subheadline, design: .rounded))
                                    Text(capability.canUseFoundationModels ? "Available" : "Not available on this device")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: capability.canUseFoundationModels ? "checkmark.circle.fill" : "xmark.circle")
                                    .foregroundStyle(capability.canUseFoundationModels ? .green : .gray)
                            }
                        }
                    }
                    
                    // Qwen Local Model
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
                            Image(systemName: "internaldrive")
                                .foregroundStyle(.secondary)
                            Text("Models are stored locally for privacy")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
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
                                .foregroundStyle(.red)
                                .padding(.top, 8)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("AI Models")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func modelCard(_ manifest: ModelManifest) -> some View {
        GlassCard(material: .regularMaterial) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(.purple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(manifest.displayName)
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                        Text("v\(manifest.version) • \(manifest.quantization.uppercased()) • \(manifest.fileSizeFormatted)")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
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
                        .tint(.blue)
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
                            Text("Download")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        
                    case .downloading:
                        Button {
                            downloader.cancelDownload()
                        } label: {
                            Text("Cancel")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(.red)
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
                                .foregroundStyle(.red)
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
                        .foregroundStyle(.red)
                }
            }
        }
    }
    
    private var stateColor: Color {
        switch store.installState {
        case .ready: return .green
        case .downloading, .verifying, .warmingUp: return .blue
        case .failed: return .red
        case .incompatible: return .gray
        case .notInstalled: return .secondary
        }
    }
}
