import SwiftUI
import SwiftData

struct ContextEntryView: View {
    @Bindable var viewModel: AddPersonViewModel
    @Query(sort: \PersonCategory.sortOrder) private var categories: [PersonCategory]
    let onComplete: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Text("Where did you meet?")
                    .font(.title2)
                    .fontWeight(.semibold)

                TextField("e.g., Tech conference, Neighbor", text: $viewModel.context)
                    .font(.title3)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.center)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        saveAndComplete()
                    }
                    .onChange(of: viewModel.context) { _, newValue in
                        viewModel.setContext(newValue)
                    }

                Rectangle()
                    .fill(Color.accentColor)
                    .frame(height: 2)
                    .frame(maxWidth: 200)
            }
            .padding(.horizontal, 40)

            // Quick suggestions
            suggestionsView
                .padding(.horizontal, 24)

            // Category picker
            VStack(spacing: 12) {
                Text("Category")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        categoryButton(nil, label: "None", icon: "xmark.circle")
                        ForEach(categories) { category in
                            categoryButton(category, label: category.name, icon: category.systemImageName)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }

            Spacer()

            Button {
                saveAndComplete()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .navigationTitle("Context")
        .onAppear {
            isFocused = true
        }
    }

    private var suggestionsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.recentContexts(), id: \.self) { suggestion in
                    Button {
                        viewModel.context = suggestion
                        viewModel.setContext(suggestion)
                    } label: {
                        Text(suggestion)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func categoryButton(_ category: PersonCategory?, label: String, icon: String) -> some View {
        let isSelected = viewModel.selectedCategory?.id == category?.id
        Button {
            viewModel.selectedCategory = category
        } label: {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func saveAndComplete() {
        Task {
            do {
                try await viewModel.savePerson()
                await MainActor.run {
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    viewModel.error = error
                    viewModel.showError = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ContextEntryView(
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
            onComplete: {}
        )
    }
}
