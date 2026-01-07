import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var showAPIKey: Bool = false
    @State private var showSaveConfirmation: Bool = false
    @State private var testResult: String = ""
    @State private var isTesting: Bool = false

    private let apiKeyKey = "openai_api_key"

    private var hasAPIKey: Bool {
        guard let key = UserDefaults.standard.string(forKey: apiKeyKey) else { return false }
        return !key.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("OpenAI API Key")
                            .font(.headline)

                        Text("Required for generating courtroom-style sketches. Your key is stored locally on this device.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Group {
                                if showAPIKey {
                                    TextField("sk-...", text: $apiKey)
                                        .textContentType(.password)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                } else {
                                    SecureField("sk-...", text: $apiKey)
                                        .textContentType(.password)
                                }
                            }
                            .font(.system(.body, design: .monospaced))

                            Button {
                                showAPIKey.toggle()
                            } label: {
                                Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                } footer: {
                    Link("Get an API key from OpenAI →",
                         destination: URL(string: "https://platform.openai.com/api-keys")!)
                        .font(.caption)
                }

                Section {
                    if let storedKey = UserDefaults.standard.string(forKey: apiKeyKey), !storedKey.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("API Key Configured")
                                    .foregroundStyle(.green)
                            }
                            Text("Key: \(storedKey.prefix(7))... (\(storedKey.count) chars)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.orange)
                            Text("No API Key - Using Local Sketches")
                                .foregroundStyle(.orange)
                        }
                    }

                    Button {
                        saveAPIKey()
                    } label: {
                        HStack {
                            Text("Save API Key")
                            Spacer()
                            if showSaveConfirmation {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .disabled(apiKey.isEmpty || apiKey.starts(with: "•"))

                    if hasAPIKey {
                        Button {
                            Task {
                                await testAPIKey()
                            }
                        } label: {
                            HStack {
                                Text("Test API Key")
                                Spacer()
                                if isTesting {
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(isTesting)

                        if !testResult.isEmpty {
                            Text(testResult)
                                .font(.caption)
                                .foregroundStyle(testResult.contains("Success") ? .green : .red)
                        }

                        Button(role: .destructive) {
                            clearAPIKey()
                        } label: {
                            Text("Remove API Key")
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Privacy", systemImage: "lock.shield")
                            .font(.headline)

                        Text("Your API key is stored only on this device. Voice descriptions are sent to OpenAI to generate sketches. No data is stored on our servers.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Cost", systemImage: "dollarsign.circle")
                            .font(.headline)

                        Text("Each sketch costs approximately $0.04 USD, billed directly to your OpenAI account.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"))")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                loadCurrentKey()
            }
        }
    }

    private func loadCurrentKey() {
        // Show masked version if key exists
        if hasAPIKey {
            apiKey = "••••••••••••••••••••"
        }
    }

    private func saveAPIKey() {
        guard !apiKey.isEmpty, !apiKey.starts(with: "•") else { return }

        // Trim whitespace and newlines
        let cleanedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(cleanedKey, forKey: apiKeyKey)

        showSaveConfirmation = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSaveConfirmation = false
        }
    }

    private func clearAPIKey() {
        UserDefaults.standard.removeObject(forKey: apiKeyKey)
        apiKey = ""
        testResult = ""
    }

    private func testAPIKey() async {
        guard let key = UserDefaults.standard.string(forKey: apiKeyKey), !key.isEmpty else {
            testResult = "Error: No API key stored"
            return
        }

        isTesting = true
        testResult = "Testing..."

        // Test with a simple models endpoint
        guard let url = URL(string: "https://api.openai.com/v1/models") else {
            testResult = "Error: Invalid URL"
            isTesting = false
            return
        }

        var request = URLRequest(url: url)
        request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    // Check if dall-e-3 is available
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let models = json["data"] as? [[String: Any]] {
                        let modelIds = models.compactMap { $0["id"] as? String }
                        if modelIds.contains("dall-e-3") {
                            testResult = "✅ Valid key with DALL-E 3 access"
                        } else {
                            testResult = "⚠️ Key valid but DALL-E 3 not found in \(models.count) models"
                        }
                    } else {
                        testResult = "✅ API key is valid"
                    }
                } else if httpResponse.statusCode == 401 {
                    testResult = "❌ Invalid API key (401)"
                } else if httpResponse.statusCode == 429 {
                    testResult = "❌ Rate limited or quota exceeded (429)"
                } else {
                    // Try to get error message
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = json["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        testResult = "❌ \(message)"
                    } else {
                        testResult = "❌ HTTP \(httpResponse.statusCode)"
                    }
                }
            }
        } catch {
            testResult = "❌ Network: \(error.localizedDescription)"
        }

        isTesting = false
    }
}

#Preview {
    SettingsView()
}
