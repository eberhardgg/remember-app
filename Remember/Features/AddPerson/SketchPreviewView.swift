import SwiftUI
import SwiftData

struct SketchPreviewView: View {
    @Bindable var viewModel: AddPersonViewModel
    var onAddPhoto: (() -> Void)? = nil
    let onContinue: () -> Void

    @State private var isRefining = false
    @State private var selectedStyle: IllustrationStyle = .current
    @State private var showStylePicker = false
    @State private var synthesizedDescription: String?
    @State private var isGeneratingDescription = false

    private var hasAPIKey: Bool {
        guard let key = UserDefaults.standard.string(forKey: "openai_api_key") else { return false }
        return !key.isEmpty
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Sketch display with style picker overlay
            ZStack(alignment: .bottomTrailing) {
                sketchImage
                    .frame(width: 240, height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 10)

                // Style picker button
                if hasAPIKey {
                    Button {
                        showStylePicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: selectedStyle.icon)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                }
            }

            // Sketch source indicator (for debugging)
            if !viewModel.sketchSource.isEmpty {
                Text(viewModel.sketchSource)
                    .font(.caption2)
                    .foregroundStyle(viewModel.sketchSource.contains("OpenAI") ? .green : .orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
            }

            // Name - large and prominent
            Text(viewModel.name)
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)

            // Synthesized description with bold keywords OR raw transcript
            descriptionView
                .padding(.horizontal, 32)

            Spacer()

            if isRefining {
                // Refine mode - show mic button
                refineView
            } else {
                // Normal mode - show action buttons
                VStack(spacing: Spacing.sm) {
                    PrimaryButton(title: "Looks good") {
                        onContinue()
                    }

                    SecondaryButton(title: "Add more details", icon: "mic.fill") {
                        isRefining = true
                    }

                    if let onAddPhoto = onAddPhoto {
                        Button {
                            onAddPhoto()
                        } label: {
                            Text("Add a photo instead")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
        }
        .navigationTitle("Memory Sketch")
        .overlay {
            if viewModel.isProcessing {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .onAppear {
            generateSynthesizedDescription()
        }
        .sheet(isPresented: $showStylePicker) {
            stylePickerSheet
        }
    }

    // MARK: - Description View

    @ViewBuilder
    private var descriptionView: some View {
        if isGeneratingDescription {
            HStack(spacing: Spacing.xs) {
                ProgressView()
                    .controlSize(.small)
                Text("Summarizing...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else if let description = synthesizedDescription, !description.isEmpty {
            // Show synthesized description with bold keywords
            HighlightedText(text: description, keywords: viewModel.keywords)
                .multilineTextAlignment(.center)
                .lineLimit(4)
        } else if let transcript = viewModel.transcript, !transcript.isEmpty {
            // Fallback to raw transcript with bold keywords
            HighlightedText(text: transcript, keywords: viewModel.keywords)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
    }

    // MARK: - Style Picker Sheet

    private var stylePickerSheet: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(IllustrationStyle.allCases, id: \.self) { style in
                        Button {
                            if style != selectedStyle {
                                selectedStyle = style
                                showStylePicker = false
                                Task {
                                    await regenerateWithStyle(style)
                                }
                            } else {
                                showStylePicker = false
                            }
                        } label: {
                            HStack {
                                Image(systemName: style.icon)
                                    .frame(width: 24)
                                    .foregroundStyle(selectedStyle == style ? Color.accentColor : Color.secondary)
                                Text(style.displayName)
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                if selectedStyle == style {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Choose a style for the illustration")
                } footer: {
                    Text("Changing the style will regenerate the illustration (~$0.04 via OpenAI).")
                }
            }
            .navigationTitle("Illustration Style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showStylePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Generate Synthesized Description

    private func generateSynthesizedDescription() {
        guard let transcript = viewModel.transcript, !transcript.isEmpty else { return }
        guard hasAPIKey else { return }

        isGeneratingDescription = true

        Task {
            let descService = DescriptionService()
            do {
                let edited = try await descService.editDescription(
                    rawTranscript: transcript,
                    keywords: viewModel.keywords,
                    personName: viewModel.name
                )
                await MainActor.run {
                    synthesizedDescription = edited
                    viewModel.synthesizedDescription = edited
                    isGeneratingDescription = false
                }
            } catch {
                print("Failed to synthesize description: \(error)")
                await MainActor.run {
                    isGeneratingDescription = false
                }
            }
        }
    }

    // MARK: - Regenerate With Style

    private func regenerateWithStyle(_ style: IllustrationStyle) async {
        guard viewModel.person != nil else { return }

        // Temporarily set the global style
        let previousStyle = IllustrationStyle.current
        IllustrationStyle.current = style

        await viewModel.regenerateSketch()

        // Restore previous global style
        IllustrationStyle.current = previousStyle
    }

    @ViewBuilder
    private var sketchImage: some View {
        if let path = viewModel.sketchPath {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let url = documentsURL.appendingPathComponent(path)

            if let data = try? Data(contentsOf: url),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                placeholderSketch
            }
        } else {
            placeholderSketch
        }
    }

    private var placeholderSketch: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.secondary.opacity(0.2))
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
            }
    }

    private var refineView: some View {
        VStack(spacing: Spacing.md) {
            Text("What else do you remember?")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            RecordButton(isRecording: viewModel.isRecording, action: {
                Task {
                    if viewModel.isRecording {
                        await viewModel.stopRecordingAndRefine()
                        isRefining = false
                    } else {
                        await viewModel.startRecording()
                    }
                }
            }, size: .compact)

            Button {
                isRefining = false
            } label: {
                Text("Cancel")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.bottom, Spacing.lg)
    }
}

#Preview {
    NavigationStack {
        SketchPreviewView(
            viewModel: AddPersonViewModel(
                modelContext: try! ModelContainer(for: Person.self).mainContext,
                fileService: FileService(),
                audioService: AudioService(fileService: FileService()),
                transcriptService: TranscriptService(),
                sketchService: SketchService(
                    fileService: FileService(),
                    keywordParser: KeywordParser(),
                    renderer: SketchRenderer()
                )
            ),
            onContinue: {}
        )
    }
}
