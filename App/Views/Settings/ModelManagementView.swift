import SwiftUI

struct ModelManagementView: View {
    @StateObject private var store = ModelStore()
    @StateObject private var downloader = ModelDownloader()
    @ObservedObject private var orchestrator = AIOrchestrator.shared
    
    private var effectiveActiveBackend: AIBackendID {
        if let override = orchestrator.activeBackendOverride {
            return override
        }
        let capability = AppleFoundationBackend().checkCapability()
        return capability.canUseFoundationModels ? .appleFoundation : .geminiRemote
    }
    
    private var activeBackendName: String {
        switch effectiveActiveBackend {
        case .appleFoundation: return "Apple Intelligence"
        case .qwenLocal: return "Qwen Local Model"
        case .geminiRemote: return "Gemini 2.5 Flash"
        }
    }
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Current Backend Status
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Text("Currently:")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text(activeBackendName)
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    
                    // Gemini Remote
                    Button {
                        withAnimation {
                            orchestrator.activeBackendOverride = .geminiRemote
                        }
                    } label: {
                        GlassCard(material: .regularMaterial) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "cloud.fill")
                                        .foregroundStyle(.blue)
                                    Text("Gemini 2.5 Flash (Remote)")
                                        .font(.system(.headline, design: .rounded))
                                        .fontWeight(.bold)
                                }
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Cloud-based • Requires internet")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if effectiveActiveBackend == .geminiRemote {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(effectiveActiveBackend == .geminiRemote ? Color.blue : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Apple Intelligence
                    Button {
                        let capability = AppleFoundationBackend().checkCapability()
                        if capability.canUseFoundationModels {
                            withAnimation {
                                orchestrator.activeBackendOverride = .appleFoundation
                            }
                        }
                    } label: {
                        let capability = AppleFoundationBackend().checkCapability()
                        let isSelected = effectiveActiveBackend == .appleFoundation
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "apple.logo")
                                        .foregroundStyle(.primary)
                                    Text("Apple Intelligence")
                                        .font(.system(.headline, design: .rounded))
                                        .fontWeight(.bold)
                                }
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(capability.isSupportedOS ? "Supported OS" : "Requires iOS 26+")
                                            .font(.system(.subheadline, design: .rounded))
                                        Text(capability.canUseFoundationModels ? "Available locally" : "Not available on this device")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundStyle(capability.canUseFoundationModels ? Color.secondary : Color.red)
                                    }
                                    Spacer()
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                    } else if !capability.canUseFoundationModels {
                                        Image(systemName: "xmark.circle")
                                            .foregroundStyle(.gray)
                                    }
                                }
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!AppleFoundationBackend().checkCapability().canUseFoundationModels)
                    
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
        let isSelected = effectiveActiveBackend == .qwenLocal
        return Button {
            if store.installState == .ready {
                withAnimation {
                    orchestrator.activeBackendOverride = .qwenLocal
                }
            }
        } label: {
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
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        }
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
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .buttonStyle(.plain)
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
