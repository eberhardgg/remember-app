import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var showAPIKey: Bool = false
    @State private var showSaveConfirmation: Bool = false

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
                    if hasAPIKey {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("API Key Configured")
                                .foregroundStyle(.green)
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

        UserDefaults.standard.set(apiKey, forKey: apiKeyKey)

        showSaveConfirmation = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSaveConfirmation = false
        }
    }

    private func clearAPIKey() {
        UserDefaults.standard.removeObject(forKey: apiKeyKey)
        apiKey = ""
    }
}

#Preview {
    SettingsView()
}
