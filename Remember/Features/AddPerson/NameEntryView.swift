import SwiftUI
import SwiftData

struct NameEntryView: View {
    @Bindable var viewModel: AddPersonViewModel
    let onContinue: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            VStack(spacing: Spacing.md) {
                Text("What's their name?")
                    .font(.title2)
                    .fontWeight(.semibold)

                TextField("Name", text: $viewModel.name)
                    .font(.title3)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.center)
                    .textContentType(.name)
                    .autocorrectionDisabled()
                    .focused($isFocused)
                    .submitLabel(.continue)
                    .onSubmit {
                        if viewModel.isNameValid {
                            continueToNext()
                        }
                    }

                Rectangle()
                    .fill(Color.accentColor)
                    .frame(height: Sizing.underline)
                    .frame(maxWidth: Sizing.maxInputWidth)
            }
            .padding(.horizontal, Spacing.xxl)

            Spacer()

            PrimaryButton(title: "Continue", isDisabled: !viewModel.isNameValid) {
                continueToNext()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
        .navigationTitle("Add Someone")
        .onAppear {
            isFocused = true
        }
    }

    private func continueToNext() {
        viewModel.createPerson()
        onContinue()
    }
}

#Preview {
    NavigationStack {
        NameEntryView(
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
