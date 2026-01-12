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
                VStack(spacing: 12) {
                    Button {
                        onContinue()
                    } label: {
                        Text("Looks good")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        isRefining = true
                    } label: {
                        Label("Add more details", systemImage: "mic.fill")
                            .font(.subheadline)
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
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
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
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Summarizing...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else if let description = synthesizedDescription, !description.isEmpty {
            // Show synthesized description with bold keywords
            highlightedDescription(text: description, keywords: viewModel.keywords)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(4)
        } else if let transcript = viewModel.transcript, !transcript.isEmpty {
            // Fallback to raw transcript with bold keywords
            highlightedDescription(text: transcript, keywords: viewModel.keywords)
                .font(.subheadline)
                .foregroundStyle(.secondary)
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

    // MARK: - Highlighted Description

    private func highlightedDescription(text: String, keywords: [String]) -> Text {
        var result = Text("")
        let lowercasedText = text.lowercased()

        // Find all keyword ranges
        var highlights: [(range: Range<String.Index>, keyword: String)] = []
        for keyword in keywords {
            let lowercasedKeyword = keyword.lowercased()
            var searchStart = lowercasedText.startIndex
            while let range = lowercasedText.range(of: lowercasedKeyword, range: searchStart..<lowercasedText.endIndex) {
                highlights.append((range, keyword))
                searchStart = range.upperBound
            }
        }

        // Sort by start position
        highlights.sort { $0.range.lowerBound < $1.range.lowerBound }

        // Remove overlapping highlights (keep first)
        var filteredHighlights: [(range: Range<String.Index>, keyword: String)] = []
        for highlight in highlights {
            if let last = filteredHighlights.last {
                if highlight.range.lowerBound >= last.range.upperBound {
                    filteredHighlights.append(highlight)
                }
            } else {
                filteredHighlights.append(highlight)
            }
        }

        // Build attributed text
        var currentIndex = text.startIndex
        for highlight in filteredHighlights {
            // Add non-highlighted text before this keyword
            if currentIndex < highlight.range.lowerBound {
                let normalText = String(text[currentIndex..<highlight.range.lowerBound])
                result = result + Text(normalText)
            }
            // Add highlighted keyword (use original case from text)
            let originalKeyword = String(text[highlight.range])
            result = result + Text(originalKeyword).bold()
            currentIndex = highlight.range.upperBound
        }

        // Add remaining text
        if currentIndex < text.endIndex {
            let remainingText = String(text[currentIndex..<text.endIndex])
            result = result + Text(remainingText)
        }

        return result
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
        VStack(spacing: 16) {
            Text("What else do you remember?")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Mic button
            Button {
                Task {
                    if viewModel.isRecording {
                        await viewModel.stopRecordingAndRefine()
                        isRefining = false
                    } else {
                        await viewModel.startRecording()
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(viewModel.isRecording ? Color.red : Color.accentColor)
                        .frame(width: 70, height: 70)
                        .shadow(radius: viewModel.isRecording ? 8 : 4)

                    if viewModel.isRecording {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.white)
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            Button {
                isRefining = false
            } label: {
                Text("Cancel")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.bottom, 24)
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
