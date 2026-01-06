import SwiftUI
import SwiftData

struct NameEntryView: View {
    @Bindable var viewModel: AddPersonViewModel
    let onContinue: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
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
                    .frame(height: 2)
                    .frame(maxWidth: 200)
            }
            .padding(.horizontal, 40)

            Spacer()

            Button {
                continueToNext()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isNameValid)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
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
