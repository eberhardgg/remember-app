import SwiftUI
import SwiftData

struct SketchPreviewView: View {
    @Bindable var viewModel: AddPersonViewModel
    var onAddPhoto: (() -> Void)? = nil
    let onContinue: () -> Void

    @State private var isRefining = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Sketch display
            sketchImage
                .frame(width: 240, height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 10)

            // Show sketch source for debugging
            if !viewModel.sketchSource.isEmpty {
                Text(viewModel.sketchSource)
                    .font(.caption)
                    .foregroundStyle(viewModel.sketchSource.contains("OpenAI") ? .green : .orange)
            }

            // Name - large and prominent
            Text(viewModel.name)
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)

            // Descriptive summary - keywords as tags
            if !viewModel.keywords.isEmpty {
                KeywordTagsView(keywords: viewModel.keywords)
            }

            // Show transcript excerpt if available
            if let transcript = viewModel.transcript, !transcript.isEmpty {
                Text(transcript)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 32)
            }

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
