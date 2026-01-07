import SwiftUI
import SwiftData

struct VoiceRambleView: View {
    @Bindable var viewModel: AddPersonViewModel
    let onContinue: () -> Void

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
            }
            .padding(.horizontal, 32)

            Spacer()

            // Record button
            recordButton
                .padding(.bottom, 32)

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

            // Skip button for testing
            Button {
                Task {
                    await viewModel.generateSketch()
                }
            } label: {
                Text("Skip (no description)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 16)
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

    private var recordButton: some View {
        Button {
            Task {
                if viewModel.isRecording {
                    await viewModel.stopRecording()
                } else {
                    await viewModel.startRecording()
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(viewModel.isRecording ? Color.red : Color.accentColor)
                    .frame(width: 100, height: 100)
                    .shadow(radius: viewModel.isRecording ? 10 : 5)

                if viewModel.isRecording {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white)
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isRecording)
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
