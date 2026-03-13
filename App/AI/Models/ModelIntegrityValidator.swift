import Foundation
import CryptoKit

// MARK: - Model Integrity Validator

final class ModelIntegrityValidator {
    
    func validate(manifest: ModelManifest) async -> Bool {
        guard !manifest.checksumSHA256.isEmpty else {
            // No checksum to validate against
            return true
        }
        
        guard let localPath = manifest.localPath,
              FileManager.default.fileExists(atPath: localPath.path) else {
            return false
        }
        
        do {
            let computedHash = try await computeSHA256(for: localPath)
            return computedHash.lowercased() == manifest.checksumSHA256.lowercased()
        } catch {
            return false
        }
    }
    
    private func computeSHA256(for url: URL) async throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { handle.closeFile() }
        
        var hasher = SHA256()
        let bufferSize = 1024 * 1024 // 1 MB
        
        while autoreleasepool(invoking: {
            let data = handle.readData(ofLength: bufferSize)
            guard !data.isEmpty else { return false }
            hasher.update(data: data)
            return true
        }) {}
        
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    func checkVersion(manifest: ModelManifest, against installed: ModelManifest?) -> Bool {
        guard let installed = installed else { return true }
        return manifest.version > installed.version
    }
}
