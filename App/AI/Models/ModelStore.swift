import Foundation

// MARK: - Model Store

@MainActor
final class ModelStore: ObservableObject {
    @Published var installState: ModelInstallState = .notInstalled
    @Published var downloadProgress: Double = 0
    @Published var installedManifest: ModelManifest?
    @Published var availableModels: [ModelManifest] = ModelManifest.allRecommended
    
    
    private let fileManager = FileManager.default
    
    init() {
        checkInstalledModel()
    }
    
    var modelsDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let modelsDir = appSupport.appendingPathComponent("Models")
        try? fileManager.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        return modelsDir
    }
    
    func checkInstalledModel() {
        // Check each known model in the catalog
        for manifest in availableModels {
            if manifest.isInstalled {
                installedManifest = manifest
                installState = .ready
                return
            }
        }
        // No installed model found
        installedManifest = nil
        installState = .notInstalled
    }
    
    func deleteModel(_ manifest: ModelManifest) {
        let modelDir = modelsDirectory.appendingPathComponent(manifest.id)
        try? fileManager.removeItem(at: modelDir)
        installedManifest = nil
        installState = .notInstalled
        downloadProgress = 0
    }
    
    func deleteAllModels() {
        try? fileManager.removeItem(at: modelsDirectory)
        try? fileManager.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        installedManifest = nil
        installState = .notInstalled
        downloadProgress = 0
    }
}
