import SwiftUI

// MARK: - Hugging Face Model Browser

struct HuggingFaceModelBrowser: View {
    @Environment(\.theme) var colors
    @Environment(\.dismiss) var dismiss
    @StateObject private var store = HuggingFaceStore()
    @State private var searchText = ""
    @State private var selectedCategory: ModelCategory = .all
    
    enum ModelCategory: String, CaseIterable {
        case all = "All"
        case health = "Health"
        case nutrition = "Nutrition"
        case chat = "Chat"
        case code = "Code"
        
        var searchQuery: String {
            switch self {
            case .all: return "gguf"
            case .health: return "health medical gguf"
            case .nutrition: return "nutrition diet food gguf"
            case .chat: return "chat assistant gguf"
            case .code: return "code programming gguf"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                    .padding(.horizontal)
                    .padding(.bottom, DesignSystem.Spacing.sm)
                
                // Category filter
                categoryFilter
                    .padding(.bottom, DesignSystem.Spacing.sm)
                
                // Model list
                if store.isLoading {
                    loadingView
                } else if store.models.isEmpty {
                    emptyView
                } else {
                    modelList
                }
            }
            .background(colors.background.ignoresSafeArea())
            .navigationTitle("Hugging Face Models")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(colors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await store.search(query: currentQuery) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(colors.neonPurple)
                    }
                }
            }
            .task {
                await store.search(query: currentQuery)
            }
        }
    }
    
    private var currentQuery: String {
        if !searchText.isEmpty { return searchText + " gguf" }
        return selectedCategory.searchQuery
    }
    
    private var searchBar: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(colors.textTertiary)
            
            TextField("Search models...", text: $searchText)
                .foregroundStyle(colors.textPrimary)
                .onSubmit {
                    Task { await store.search(query: currentQuery) }
                }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    Task { await store.search(query: currentQuery) }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(colors.textTertiary)
                }
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .fill(colors.backgroundElevated)
                .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .strokeBorder(colors.cardBorder))
        )
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(ModelCategory.allCases, id: \.self) { cat in
                    Button {
                        Haptic.selection()
                        selectedCategory = cat
                        Task { await store.search(query: currentQuery) }
                    } label: {
                        Text(cat.rawValue)
                            .font(DesignSystem.Typography.captionBold)
                            .foregroundStyle(selectedCategory == cat ? .white : colors.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == cat ? colors.neonPurple : colors.backgroundElevated)
                            )
                    }
                    .buttonStyle(.scaleButton)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ProgressView()
                .tint(colors.neonPurple)
            Text("Searching Hugging Face...")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "arrow.down.circle.dotted")
                .font(.system(size: 50))
                .foregroundStyle(colors.textTertiary)
            Text("No models found")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(colors.textPrimary)
            Text("Try a different search or category")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var modelList: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(store.models) { model in
                    ModelCard(model: model, store: store, colors: colors)
                }
            }
            .padding()
        }
    }
}

// MARK: - Model Card

struct ModelCard: View {
    let model: HFModel
    let store: HuggingFaceStore
    let colors: DesignSystem.ThemeColors
    
    @State private var downloadProgress: Double = 0
    @State private var isDownloading = false
    @State private var isInstalled = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.name)
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundStyle(colors.textPrimary)
                        .lineLimit(1)
                    
                    Text(model.author)
                        .font(DesignSystem.Typography.caption2)
                        .foregroundStyle(colors.textSecondary)
                }
                
                Spacer()
                
                // Size badge
                if let sizeMB = model.sizeMB {
                    Text("\(sizeMB)MB")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundStyle(colors.neonPurple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(colors.neonPurple.opacity(0.15)))
                }
            }
            
            // Description
            if let desc = model.description {
                Text(desc)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(colors.textTertiary)
                    .lineLimit(2)
            }
            
            // Tags
            if !model.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(model.tags.prefix(5), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.textSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(colors.backgroundElevated))
                        }
                    }
                }
            }
            
            // Download button / progress
            if isInstalled {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(colors.neonGreen)
                    Text("Installed")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(colors.neonGreen)
                }
            } else if isDownloading {
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(colors.neonPurple.opacity(0.15))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(colors.neonPurple.gradient)
                                .frame(width: geo.size.width * downloadProgress)
                        }
                    }
                    .frame(height: 6)
                    
                    Text("Downloading... \(Int(downloadProgress * 100))%")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundStyle(colors.neonPurple)
                }
            } else {
                Button {
                    Haptic.impact(.light)
                    startDownload()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle")
                        Text("Download")
                    }
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .fill(colors.neonPurple.gradient)
                    )
                }
                .buttonStyle(.scaleButton)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .fill(colors.backgroundCard)
                .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .strokeBorder(colors.cardBorder))
        )
    }
    
    private func startDownload() {
        isDownloading = true
        downloadProgress = 0
        
        Task {
            await store.downloadModel(model) { progress in
                Task { @MainActor in
                    withAnimation(.smooth) {
                        downloadProgress = progress
                    }
                }
            }
            
            await MainActor.run {
                withAnimation(.spring()) {
                    isDownloading = false
                    isInstalled = true
                }
                Haptic.notification(.success)
            }
        }
    }
}

// MARK: - Hugging Face Store

@MainActor
class HuggingFaceStore: ObservableObject {
    @Published var models: [HFModel] = []
    @Published var isLoading = false
    
    private let baseURL = "https://huggingface.co/api/models"
    
    func search(query: String) async {
        isLoading = true
        defer { isLoading = false }
        
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)?search=\(encoded)&limit=20&sort=downloads&direction=-1&full=false") else {
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let results = try JSONDecoder().decode([HFModelAPI].self, from: data)
            
            models = results.compactMap { api in
                // Filter for GGUF models
                guard api.tags?.contains("gguf") == true || 
                      api.id.lowercased().contains("gguf") ||
                      api.id.lowercased().contains("q4") ||
                      api.id.lowercased().contains("q5") ||
                      api.id.lowercased().contains("q8") else { return nil }
                
                let nameParts = api.id.split(separator: "/")
                let name = nameParts.last.map(String.init) ?? api.id
                let author = nameParts.first.map(String.init) ?? "Unknown"
                
                return HFModel(
                    id: api.id,
                    name: name.replacingOccurrences(of: "-", with: " ").capitalized,
                    author: author,
                    description: api.description,
                    tags: api.tags ?? [],
                    sizeMB: estimateSize(from: name),
                    downloadURL: "https://huggingface.co/\(api.id)/resolve/main",
                    downloads: api.downloads ?? 0
                )
            }
            .sorted { ($0.downloads ?? 0) > ($1.downloads ?? 0) }
        } catch {
            print("HuggingFace search error: \(error)")
        }
    }
    
    func downloadModel(_ model: HFModel, progressHandler: @escaping (Double) -> Void) async {
        // Save to app's models directory
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let modelDir = appSupport.appendingPathComponent("Models/HF/\(model.id.replacingOccurrences(of: "/", with: "_"))")
        try? fileManager.createDirectory(at: modelDir, withIntermediateDirectories: true)
        
        // Find GGUF file URL
        guard let urlString = model.downloadURL,
              let url = URL(string: urlString + "/model.gguf") else { return }
        
        do {
            let (tempURL, _) = try await URLSession.shared.download(from: url, delegate: DownloadProgressDelegate(handler: progressHandler))
            let destURL = modelDir.appendingPathComponent("model.gguf")
            try? fileManager.removeItem(at: destURL)
            try fileManager.moveItem(at: tempURL, to: destURL)
            
            // Save manifest
            let manifest = ModelManifest(
                id: "hf_\(model.id.replacingOccurrences(of: "/", with: "_"))",
                displayName: model.name,
                runtime: "llama_cpp",
                version: "1.0.0",
                quantization: "GGUF",
                fileSizeBytes: Int64((model.sizeMB ?? 1500) * 1_000_000),
                checksumSHA256: "",
                supportsVision: false,
                supportsToolCalling: false,
                contextWindow: 8192,
                minIOSVersion: "18.0",
                downloadURL: model.downloadURL ?? "",
                license: "See model page"
            )
            let manifestData = try JSONEncoder().encode(manifest)
            try manifestData.write(to: modelDir.appendingPathComponent("manifest.json"))
        } catch {
            print("Download error: \(error)")
        }
    }
    
    private func estimateSize(from name: String) -> Int {
        let lower = name.lowercased()
        if lower.contains("7b") || lower.contains("8b") { return 4500 }
        if lower.contains("3b") { return 2000 }
        if lower.contains("2b") || lower.contains("1.5b") { return 1500 }
        if lower.contains("1b") || lower.contains("0.5b") { return 800 }
        if lower.contains("q4") { return 1500 }
        if lower.contains("q5") { return 2000 }
        if lower.contains("q8") { return 4000 }
        return 1500
    }
}

// MARK: - Models

struct HFModel: Identifiable {
    let id: String
    let name: String
    let author: String
    let description: String?
    let tags: [String]
    let sizeMB: Int?
    let downloadURL: String?
    let downloads: Int?
}

struct HFModelAPI: Codable {
    let id: String
    let description: String?
    let tags: [String]?
    let downloads: Int?
    let likes: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, description, tags, downloads, likes
    }
}

// MARK: - Download Progress Delegate

class DownloadProgressDelegate: NSObject, URLSessionDownloadDelegate {
    let handler: (Double) -> Void
    
    init(handler: @escaping (Double) -> Void) {
        self.handler = handler
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {}
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        handler(progress)
    }
}
