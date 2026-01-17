import SwiftUI
import SwiftData

struct VoiceRambleView: View {
    @Bindable var viewModel: AddPersonViewModel
    let onContinue: () -> Void

    private var hasAPIKey: Bool {
        guard let key = UserDefaults.standard.string(forKey: "openai_api_key") else { return false }
        return !key.isEmpty
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Text("Describe what they looked like, in your own words.")
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)

                Text("Age, hair, glasses, vibe, posture — whatever you remember.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                // Show current illustration style
                if hasAPIKey {
                    HStack(spacing: 4) {
                        Image(systemName: IllustrationStyle.current.icon)
                        Text("\(IllustrationStyle.current.displayName) style")
                    }
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            // Record button
            RecordButton(isRecording: viewModel.isRecording) {
                Task {
                    if viewModel.isRecording {
                        await viewModel.stopRecording()
                    } else {
                        await viewModel.startRecording()
                    }
                }
            }
            .padding(.bottom, Spacing.xl)

            Spacer()

            if viewModel.isProcessing {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Creating sketch...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }

        }
        .navigationTitle("Voice Description")
        // Auto-advance when sketch is ready
        .onChange(of: viewModel.sketchPath) { _, newPath in
            if newPath != nil {
                onContinue()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.error?.localizedDescription ?? "Something went wrong")
        }
    }
}

#Preview {
    NavigationStack {
        VoiceRambleView(
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
