import Foundation

// MARK: - Model Downloader

@MainActor
final class ModelDownloader: ObservableObject {
    @Published var isDownloading = false
    @Published var progress: Double = 0
    @Published var error: String?
    
    private var downloadTask: URLSessionDownloadTask?
    private let fileManager = FileManager.default
    
    func download(manifest: ModelManifest, to store: ModelStore) async {
        guard !manifest.downloadURL.isEmpty,
              let url = URL(string: manifest.downloadURL) else {
            error = "No download URL configured for this model."
            return
        }
        
        isDownloading = true
        progress = 0
        error = nil
        store.installState = .downloading
        
        do {
            let (tempURL, _) = try await URLSession.shared.download(from: url)
            
            // Move to model directory
            let modelDir = store.modelsDirectory.appendingPathComponent(manifest.id)
            try fileManager.createDirectory(at: modelDir, withIntermediateDirectories: true)
            
            let destURL = modelDir.appendingPathComponent("model.bin")
            if fileManager.fileExists(atPath: destURL.path) {
                try fileManager.removeItem(at: destURL)
            }
            try fileManager.moveItem(at: tempURL, to: destURL)
            
            // Save manifest
            store.installState = .verifying
            let manifestData = try JSONEncoder().encode(manifest)
            let manifestURL = modelDir.appendingPathComponent("manifest.json")
            try manifestData.write(to: manifestURL)
            
            // Verify integrity
            let validator = ModelIntegrityValidator()
            let isValid = await validator.validate(manifest: manifest)
            
            if isValid || manifest.checksumSHA256.isEmpty {
                store.installedManifest = manifest
                store.installState = .ready
                store.downloadProgress = 1.0
            } else {
                store.installState = .failed
                error = "Checksum verification failed."
                try? fileManager.removeItem(at: modelDir)
            }
            
        } catch {
            store.installState = .failed
            self.error = error.localizedDescription
        }
        
        isDownloading = false
    }
    
    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        isDownloading = false
        progress = 0
    }
}
