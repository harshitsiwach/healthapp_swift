import Foundation

// MARK: - Model Manifest

struct ModelManifest: Codable, Identifiable {
    let id: String
    let displayName: String
    let runtime: String
    let version: String
    let quantization: String
    let fileSizeBytes: Int64
    let checksumSHA256: String
    let supportsVision: Bool
    let supportsToolCalling: Bool
    let contextWindow: Int
    let minIOSVersion: String
    let downloadURL: String
    let license: String
    
    var localPath: URL? {
        // 1. Check for bundled model (Priority 1)
        // Look for model files in the main bundle named after the model ID
        if let bundlePath = Bundle.main.url(forResource: id, withExtension: "gguf") {
            return bundlePath
        }
        
        // 2. Check for downloaded model in Application Support
        let docs = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let downloadedPath = docs?.appendingPathComponent("Models/\(id)/model.bin")
        if let path = downloadedPath, FileManager.default.fileExists(atPath: path.path) {
            return path
        }
        
        return nil
    }
    
    var isInstalled: Bool {
        localPath != nil
    }
    
    var fileSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSizeBytes)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case runtime
        case version
        case quantization
        case fileSizeBytes = "file_size_bytes"
        case checksumSHA256 = "checksum_sha256"
        case supportsVision = "supports_vision"
        case supportsToolCalling = "supports_tool_calling"
        case contextWindow = "context_window"
        case minIOSVersion = "min_ios_version"
        case downloadURL = "download_url"
        case license
    }
    
    static let gemma2_default = ModelManifest(
        id: "gemma-2-2b-it-Q4_K_M",
        displayName: "Gemma 2 2B",
        runtime: "llama_cpp",
        version: "2.0.0",
        quantization: "q4_K_M",
        fileSizeBytes: 1_710_000_000,
        checksumSHA256: "",
        supportsVision: false,
        supportsToolCalling: false,
        contextWindow: 8192,
        minIOSVersion: "18.0",
        downloadURL: "",
        license: "Gemma"
    )
    
    static let allRecommended: [ModelManifest] = [gemma2_default]

    

}

// MARK: - Model Install State

enum ModelInstallState: String {
    case notInstalled
    case downloading
    case verifying
    case ready
    case warmingUp
    case failed
    case incompatible
    
    var displayText: String {
        switch self {
        case .notInstalled: return "Not Installed"
        case .downloading: return "Downloading..."
        case .verifying: return "Verifying..."
        case .ready: return "Ready"
        case .warmingUp: return "Warming Up..."
        case .failed: return "Failed"
        case .incompatible: return "Incompatible"
        }
    }
    
    var iconName: String {
        switch self {
        case .notInstalled: return "arrow.down.circle"
        case .downloading: return "arrow.down.circle.dotted"
        case .verifying: return "checkmark.shield"
        case .ready: return "checkmark.circle.fill"
        case .warmingUp: return "flame"
        case .failed: return "exclamationmark.triangle.fill"
        case .incompatible: return "xmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .ready: return "green"
        case .downloading, .verifying, .warmingUp: return "blue"
        case .failed: return "red"
        case .incompatible: return "gray"
        case .notInstalled: return "secondary"
        }
    }
}
