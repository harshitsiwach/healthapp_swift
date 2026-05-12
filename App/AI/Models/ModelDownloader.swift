import Foundation

// MARK: - Model Downloader

@MainActor
final class ModelDownloader: ObservableObject {
    @Published var isDownloading = false
    @Published var progress: Double = 0
    @Published var error: String?
    
    private var downloadTask: URLSessionDownloadTask?
    private let fileManager = FileManager.default
    
    func download(manifest: ModelManifest, to store: ModelStore, token: String? = nil) async {
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
            var request = URLRequest(url: url)
            if let token = token, !token.isEmpty {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            let (tempURL, response) = try await URLSession.shared.download(for: request)
            
            // Validate response
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    throw NSError(domain: "ModelDownloader", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Authentication failed (401/403). Please ensure your HuggingFace token is correct and you have accepted the license terms for this model on huggingface.co."])
                } else if httpResponse.statusCode != 200 {
                    throw NSError(domain: "ModelDownloader", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned error \(httpResponse.statusCode)."])
                }
            }
            
            // Check file size (GGUF models should be large, at least several hundred MB)
            let attributes = try fileManager.attributesOfItem(atPath: tempURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            
            if fileSize < 100_000_000 { // Less than 100MB is almost certainly an error page, not a model
                throw NSError(domain: "ModelDownloader", code: 0, userInfo: [NSLocalizedDescriptionKey: "Downloaded file is too small (\(fileSize) bytes). This usually means you haven't accepted the model's license agreement on HuggingFace. Please visit \(manifest.downloadURL) in your browser and accept the terms."])
            }
            
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
