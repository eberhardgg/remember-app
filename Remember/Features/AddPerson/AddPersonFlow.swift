import SwiftUI
import SwiftData

struct AddPersonFlow: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let onComplete: () -> Void

    @State private var viewModel: AddPersonViewModel?
    @State private var currentStep: AddPersonStep = .name

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    stepView(for: currentStep, viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                let fileService = FileService()
                viewModel = AddPersonViewModel(
                    modelContext: modelContext,
                    fileService: fileService,
                    audioService: AudioService(fileService: fileService),
                    transcriptService: TranscriptService(),
                    sketchService: SketchService(
                        fileService: fileService,
                        keywordParser: KeywordParser(),
                        renderer: SketchRenderer()
                    )
                )
            }
        }
        .interactiveDismissDisabled(currentStep != .name)
    }

    @ViewBuilder
    private func stepView(for step: AddPersonStep, viewModel: AddPersonViewModel) -> some View {
        switch step {
        case .name:
            NameEntryView(viewModel: viewModel) {
                currentStep = .ramble
            }
        case .ramble:
            VoiceRambleView(viewModel: viewModel) {
                currentStep = .sketch
            }
        case .sketch:
            SketchPreviewView(viewModel: viewModel, onAddPhoto: {
                currentStep = .photo
            }) {
                currentStep = .context
            }
        case .photo:
            PhotoAttachView(viewModel: viewModel) {
                currentStep = .context
            }
        case .context:
            ContextEntryView(viewModel: viewModel) {
                onComplete()
                dismiss()
            }
        }
    }
}

enum AddPersonStep {
    case name
    case ramble
    case sketch
    case photo
    case context
}

#Preview {
    AddPersonFlow(onComplete: {})
        .modelContainer(for: Person.self, inMemory: true)
}
