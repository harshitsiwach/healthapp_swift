import SwiftUI

struct PerplexitySettingsView: View {
    @State private var apiKey: String = ""
    @State private var isKeySaved: Bool = false
    @State private var isTesting: Bool = false
    @State private var testResult: String?
    @AppStorage("isPerplexityEnabled") private var isPerplexityEnabled: Bool = true
    
    var body: some View {
        Form {
            Section(header: Text("Perplexity Cloud API"), footer: Text("HealthApp requires an active API key to enable cited health answers and cloud food analysis.")) {
                Toggle("Enable Perplexity Features", isOn: $isPerplexityEnabled)
                
                if isKeySaved {
                    HStack {
                        Text("API Key")
                        Spacer()
                        Text("••••••" + (PerplexityKeyStore.shared.getKey()?.suffix(4) ?? ""))
                            .foregroundStyle(.secondary)
                    }
                    
                    Button(role: .destructive, action: deleteKey) {
                        Text("Remove API Key")
                    }
                } else {
                    SecureField("pplx-...", text: $apiKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    Button("Save Key", action: saveKey)
                        .disabled(apiKey.isEmpty)
                }
            }
            
            if isKeySaved {
                Section(header: Text("Developer Setup")) {
                    Button(action: testConnection) {
                        HStack {
                            Text("Test Connection")
                            Spacer()
                            if isTesting {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isTesting)
                    
                    if let result = testResult {
                        Text(result)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Perplexity Configuration")
        .onAppear(perform: loadState)
    }
    
    private func loadState() {
        isKeySaved = PerplexityKeyStore.shared.hasKey
    }
    
    private func saveKey() {
        do {
            try PerplexityKeyStore.shared.saveKey(apiKey)
            apiKey = ""
            isKeySaved = true
        } catch {
            print("Failed to save key: \(error)")
        }
    }
    
    private func deleteKey() {
        do {
            try PerplexityKeyStore.shared.deleteKey()
            isKeySaved = false
            testResult = nil
        } catch {
            print("Failed to delete key: \(error)")
        }
    }
    
    private func testConnection() {
        guard let key = PerplexityKeyStore.shared.getKey() else { return }
        isTesting = true
        testResult = nil
        
        Task {
            do {
                let url = PerplexityConfig.shared.apiBaseURL
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body: [String: Any] = [
                    "model": PerplexityConfig.shared.defaultChatModel,
                    "messages": [
                        ["role": "user", "content": "Say hello in 2 words."]
                    ],
                    "max_tokens": 10
                ]
                
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                await MainActor.run {
                    self.isTesting = false
                    if httpResponse.statusCode == 200 {
                        self.testResult = "✅ Connection successful! Key is valid."
                    } else {
                        self.testResult = "❌ Error: API returned status \(httpResponse.statusCode). Please check your key."
                        if let errorStr = String(data: data, encoding: .utf8) {
                            print("Perplexity API Error: \(errorStr)")
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.isTesting = false
                    self.testResult = "❌ Connection failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        PerplexitySettingsView()
    }
}
