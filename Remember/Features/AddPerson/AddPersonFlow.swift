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
                    if currentStep != .rehearsal {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .onAppear {
            // Always create a fresh ViewModel when the flow appears
            // This ensures clean state for each new person
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
            currentStep = .name
        }
        .interactiveDismissDisabled(currentStep != .name && currentStep != .rehearsal)
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
                // Skip context if already extracted from transcript
                if !viewModel.context.isEmpty {
                    Task {
                        try? await viewModel.savePerson()
                        await MainActor.run {
                            currentStep = .rehearsal
                        }
                    }
                } else {
                    currentStep = .context
                }
            }
        case .photo:
            PhotoAttachView(viewModel: viewModel) {
                // Skip context if already extracted from transcript
                if !viewModel.context.isEmpty {
                    Task {
                        try? await viewModel.savePerson()
                        await MainActor.run {
                            currentStep = .rehearsal
                        }
                    }
                } else {
                    currentStep = .context
                }
            }
        case .context:
            ContextEntryView(viewModel: viewModel) {
                currentStep = .rehearsal
            }
        case .rehearsal:
            if let person = viewModel.person {
                RehearsalPromptView(person: person) {
                    onComplete()
                    dismiss()
                }
            } else {
                // Fallback if person not available
                EmptyView()
                    .onAppear {
                        onComplete()
                        dismiss()
                    }
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
    case rehearsal
}

#Preview {
    AddPersonFlow(onComplete: {})
        .modelContainer(for: Person.self, inMemory: true)
}
