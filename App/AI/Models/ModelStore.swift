import Foundation

// MARK: - Model Store

@MainActor
final class ModelStore: ObservableObject {
    @Published var installState: ModelInstallState = .notInstalled
    @Published var downloadProgress: Double = 0
    @Published var installedManifest: ModelManifest?
    @Published var availableModels: [ModelManifest] = [ModelManifest.qwen3_5_default]
    
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
        // Check if any model is installed
        let modelDir = modelsDirectory.appendingPathComponent(ModelManifest.qwen3_5_default.id)
        let modelFile = modelDir.appendingPathComponent("model.bin")
        let manifestFile = modelDir.appendingPathComponent("manifest.json")
        
        if fileManager.fileExists(atPath: modelFile.path) && fileManager.fileExists(atPath: manifestFile.path) {
            if let data = try? Data(contentsOf: manifestFile),
               let manifest = try? JSONDecoder().decode(ModelManifest.self, from: data) {
                installedManifest = manifest
                installState = .ready
            }
        } else {
            installState = .notInstalled
        }
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
