import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel?
    @State private var showingAddPerson = false
    @State private var showingQuickAdd = false
    @State private var showingReview = false
    @State private var showingSettings = false
    @State private var selectedPerson: Person?
    @State private var searchText = ""

    // Voice search state
    @State private var isRecordingSearch = false
    @State private var isTranscribing = false
    @State private var audioService: AudioService?
    @State private var transcriptService: TranscriptService?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    content(viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Remember")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 16) {
                        // Voice search button
                        Button {
                            Task {
                                await toggleVoiceSearch()
                            }
                        } label: {
                            Image(systemName: isRecordingSearch ? "stop.circle.fill" : "mic.fill")
                                .foregroundStyle(isRecordingSearch ? .red : .primary)
                        }
                        .disabled(isTranscribing)

                        Menu {
                            Button {
                                showingQuickAdd = true
                            } label: {
                                Label("Quick Add", systemImage: "plus")
                            }

                            Button {
                                showingAddPerson = true
                            } label: {
                                Label("Add with Voice", systemImage: "mic.fill")
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search names, descriptions...")
            .onChange(of: searchText) { _, newValue in
                viewModel?.searchText = newValue
                viewModel?.loadPeople()
            }
            .sheet(isPresented: $showingAddPerson) {
                AddPersonFlow(onComplete: {
                    viewModel?.loadPeople()
                })
            }
            .sheet(isPresented: $showingQuickAdd) {
                QuickAddView(onComplete: {
                    viewModel?.loadPeople()
                })
            }
            .sheet(isPresented: $showingReview) {
                if let viewModel = viewModel {
                    ReviewSessionView(reviewService: viewModel.reviewService)
                }
            }
            .sheet(item: $selectedPerson) { person in
                PersonDetailView(person: person, onUpdate: {
                    viewModel?.loadPeople()
                })
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .onAppear {
            if viewModel == nil {
                let fileService = FileService()
                let personService = PersonService(modelContext: modelContext, fileService: fileService)
                let reviewService = ReviewService(modelContext: modelContext)
                viewModel = HomeViewModel(personService: personService, reviewService: reviewService)
                viewModel?.loadPeople()

                // Initialize voice search services
                audioService = AudioService(fileService: fileService)
                let transcriptSvc = TranscriptService()
                transcriptService = transcriptSvc

                // Initialize Watch connectivity
                let sketchService = SketchService(
                    fileService: fileService,
                    keywordParser: KeywordParser(),
                    renderer: SketchRenderer()
                )
                WatchConnectivityService.shared.configure(
                    modelContext: modelContext,
                    transcriptService: transcriptSvc,
                    personService: personService,
                    fileService: fileService,
                    sketchService: sketchService
                )
            }
        }
    }

    @ViewBuilder
    private func content(viewModel: HomeViewModel) -> some View {
        if viewModel.people.isEmpty && searchText.isEmpty {
            emptyState
        } else {
            List {
                if viewModel.dueCount > 0 {
                    reviewButton(dueCount: viewModel.dueCount)
                }

                ForEach(viewModel.people) { person in
                    PersonRowView(person: person)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedPerson = person
                        }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let person = viewModel.people[index]
                        viewModel.deletePerson(person)
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private var emptyState: some View {
        EmptyStateView {
            showingAddPerson = true
        }
    }

    private func reviewButton(dueCount: Int) -> some View {
        Button {
            showingReview = true
        } label: {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(.tint)
                Text("Review \(dueCount) \(dueCount == 1 ? "card" : "cards")")
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.accentColor.opacity(0.1))
    }

    // MARK: - Voice Search

    private func toggleVoiceSearch() async {
        guard let audioService = audioService else { return }

        if isRecordingSearch {
            // Stop recording and transcribe
            do {
                let url = try audioService.stopRecording()
                isRecordingSearch = false
                isTranscribing = true

                // Transcribe the audio
                if let transcriptService = transcriptService {
                    let hasPermission = await transcriptService.requestPermission()
                    if hasPermission {
                        let text = try await transcriptService.transcribe(audioURL: url)
                        searchText = text
                    }
                }
            } catch {
                print("Voice search error: \(error)")
            }
            isTranscribing = false
        } else {
            // Start recording
            let hasPermission = await audioService.requestPermission()
            guard hasPermission else { return }

            do {
                try audioService.startRecording(for: UUID())
                isRecordingSearch = true
            } catch {
                print("Voice search recording error: \(error)")
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Person.self, inMemory: true)
}
