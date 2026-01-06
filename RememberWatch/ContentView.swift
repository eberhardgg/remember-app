import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @StateObject private var viewModel = WatchViewModel()

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            if let result = viewModel.searchResult {
                // Show search result
                resultView(result)
            } else if viewModel.isProcessing {
                // Processing state
                processingView
            } else if viewModel.isRecording {
                // Recording state
                recordingView
            } else {
                // Ready state
                readyView
            }
        }
        .onAppear {
            viewModel.activateSession()
        }
    }

    // MARK: - Ready State

    private var readyView: some View {
        VStack(spacing: 16) {
            Button {
                viewModel.startRecording()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 80, height: 80)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)

            Text("Tap to speak")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Recording State

    private var recordingView: some View {
        VStack(spacing: 16) {
            Button {
                viewModel.stopRecording()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 80, height: 80)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white)
                        .frame(width: 28, height: 28)
                }
            }
            .buttonStyle(.plain)

            Text("Listening...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Processing State

    private var processingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Thinking...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Result View

    private func resultView(_ result: PersonResult) -> some View {
        VStack(spacing: 8) {
            // Photo or sketch
            if let imageData = result.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.secondary)
                    }
            }

            // Name
            Text(result.name)
                .font(.headline)
                .lineLimit(1)

            // Context/description
            if let context = result.context {
                Text(context)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }

            // Dismiss button
            Button {
                viewModel.clearResult()
            } label: {
                Text("Done")
                    .font(.caption)
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 8)
    }
}

#Preview {
    ContentView()
}
