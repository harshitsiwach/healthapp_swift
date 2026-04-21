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
        let docs = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        return docs?.appendingPathComponent("Models/\(id)/model.bin")
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
    
    static let gemma4_default = ModelManifest(
        id: "gemma_4_2b_q4",
        displayName: "Gemma 4 2B",
        runtime: "llama_cpp",
        version: "1.0.0",
        quantization: "q4_K_M",
        fileSizeBytes: 1_500_000_000,
        checksumSHA256: "",
        supportsVision: true,
        supportsToolCalling: false,
        contextWindow: 8192,
        minIOSVersion: "18.0",
        downloadURL: "https://huggingface.co/google/gemma-4-2b-GGUF/resolve/main/gemma-4-2b-q4_K_M.gguf",
        license: "Gemma"
    )
    
    static let medgemma_4b = ModelManifest(
        id: "medgemma_4b_q4",
        displayName: "MedGemma 4B",
        runtime: "llama_cpp",
        version: "1.0.0",
        quantization: "q4_K_M",
        fileSizeBytes: 2_500_000_000,
        checksumSHA256: "",
        supportsVision: false,
        supportsToolCalling: false,
        contextWindow: 8192,
        minIOSVersion: "18.0",
        downloadURL: "https://huggingface.co/google/medgemma-4b-it-GGUF/resolve/main/medgemma-4b-it-q4_K_M.gguf",
        license: "Gemma"
    )
    
    static let medgemma_2b = ModelManifest(
        id: "medgemma_2b_q4",
        displayName: "MedGemma 2B",
        runtime: "llama_cpp",
        version: "1.0.0",
        quantization: "q4_K_M",
        fileSizeBytes: 1_500_000_000,
        checksumSHA256: "",
        supportsVision: false,
        supportsToolCalling: false,
        contextWindow: 8192,
        minIOSVersion: "18.0",
        downloadURL: "https://huggingface.co/google/medgemma-2b-it-GGUF/resolve/main/medgemma-2b-it-q4_K_M.gguf",
        license: "Gemma"
    )
    
    static let allRecommended: [ModelManifest] = [gemma4_default, medgemma_4b, medgemma_2b]

    

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
