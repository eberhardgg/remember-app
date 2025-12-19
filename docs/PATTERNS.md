# Remember - Design Patterns & Conventions

## Architecture Patterns

### MVVM (Model-View-ViewModel)

We use MVVM with SwiftUI's native observation system.

**View responsibilities:**
- Render UI based on ViewModel state
- Forward user actions to ViewModel
- No business logic

**ViewModel responsibilities:**
- Own and expose UI state via `@Observable`
- Coordinate between Views and Services
- Transform data for display
- Handle user actions

**Model responsibilities:**
- Represent domain data (SwiftData models)
- No UI logic, no business logic

```swift
// Example: HomeViewModel
@Observable
final class HomeViewModel {
    private let personService: PersonService
    private let reviewService: ReviewService

    var people: [Person] = []
    var dueCount: Int = 0
    var searchText: String = ""
    var selectedContext: String?

    init(personService: PersonService, reviewService: ReviewService) {
        self.personService = personService
        self.reviewService = reviewService
    }

    func loadPeople() {
        people = personService.fetchAll(
            searchText: searchText,
            context: selectedContext
        )
        dueCount = reviewService.getDueCount()
    }

    func deletePerson(_ person: Person) {
        personService.delete(person)
        loadPeople()
    }
}
```

### Service Pattern

Services encapsulate business logic and external dependencies. They are:
- Stateless (no UI state)
- Reusable across ViewModels
- Testable via protocol abstraction

```swift
// Protocol for testability
protocol PersonServiceProtocol {
    func fetchAll(searchText: String?, context: String?) -> [Person]
    func save(_ person: Person)
    func delete(_ person: Person)
}

// Concrete implementation
final class PersonService: PersonServiceProtocol {
    private let modelContext: ModelContext
    private let fileService: FileService

    init(modelContext: ModelContext, fileService: FileService) {
        self.modelContext = modelContext
        self.fileService = fileService
    }

    func delete(_ person: Person) {
        // Clean up files first
        fileService.deleteFiles(for: person)
        // Then delete from SwiftData
        modelContext.delete(person)
    }
}
```

### Dependency Injection

Dependencies are injected via initializers. No singletons, no global state.

**At app level:** Create services and pass down

```swift
@main
struct RememberApp: App {
    let container: ModelContainer
    let personService: PersonService
    let reviewService: ReviewService
    // ... other services

    init() {
        let container = try! ModelContainer(for: Person.self)
        self.container = container

        let fileService = FileService()
        self.personService = PersonService(
            modelContext: container.mainContext,
            fileService: fileService
        )
        self.reviewService = ReviewService(
            modelContext: container.mainContext
        )
    }

    var body: some Scene {
        WindowGroup {
            HomeView(
                viewModel: HomeViewModel(
                    personService: personService,
                    reviewService: reviewService
                )
            )
        }
        .modelContainer(container)
    }
}
```

**For testing:** Inject mocks

```swift
final class MockPersonService: PersonServiceProtocol {
    var people: [Person] = []

    func fetchAll(searchText: String?, context: String?) -> [Person] {
        return people
    }
}

func testHomeViewModel() {
    let mockService = MockPersonService()
    mockService.people = [Person(name: "Test")]

    let viewModel = HomeViewModel(
        personService: mockService,
        reviewService: MockReviewService()
    )

    viewModel.loadPeople()
    XCTAssertEqual(viewModel.people.count, 1)
}
```

---

## SwiftUI Patterns

### View Composition

Break complex views into small, focused components.

```swift
// Bad: Monolithic view
struct HomeView: View {
    var body: some View {
        // 200 lines of nested views
    }
}

// Good: Composed views
struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack {
                SearchBar(text: $viewModel.searchText)
                PersonList(people: viewModel.people)
            }
            .toolbar {
                HomeToolbar(dueCount: viewModel.dueCount)
            }
        }
    }
}
```

### State Ownership

State lives in the lowest common ancestor that needs it.

```swift
// View-local state: @State
struct VoiceRambleView: View {
    @State private var isRecording = false  // Only this view needs it
}

// Shared state: ViewModel via @Observable
struct AddPersonFlow: View {
    @State private var viewModel = AddPersonViewModel()

    var body: some View {
        NameEntryView(name: $viewModel.name)
        // viewModel shared across child views
    }
}
```

### Navigation

Use NavigationStack with value-based navigation for type safety.

```swift
enum AddPersonStep: Hashable {
    case name
    case ramble
    case sketch
    case context
    case photo
}

struct AddPersonFlow: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            NameEntryView(onContinue: { path.append(AddPersonStep.ramble) })
                .navigationDestination(for: AddPersonStep.self) { step in
                    switch step {
                    case .ramble: VoiceRambleView(...)
                    case .sketch: SketchPreviewView(...)
                    case .context: ContextEntryView(...)
                    case .photo: PhotoAttachView(...)
                    }
                }
        }
    }
}
```

---

## Error Handling

### Result Type for Failable Operations

```swift
enum RememberError: LocalizedError {
    case audioRecordingFailed
    case transcriptionFailed
    case sketchGenerationFailed
    case fileWriteFailed(path: String)

    var errorDescription: String? {
        switch self {
        case .audioRecordingFailed:
            return "Couldn't record audio. Please check microphone permissions."
        case .transcriptionFailed:
            return "Couldn't understand the recording. Try speaking more clearly."
        case .sketchGenerationFailed:
            return "Couldn't create the sketch. Please try again."
        case .fileWriteFailed(let path):
            return "Couldn't save file to \(path)."
        }
    }
}

// Service returns Result
func transcribe(audioURL: URL) async -> Result<String, RememberError> {
    // ...
}
```

### ViewModel Error State

```swift
@Observable
final class AddPersonViewModel {
    var error: RememberError?
    var showError: Bool = false

    func transcribeAudio() async {
        let result = await transcriptService.transcribe(audioURL: audioURL)
        switch result {
        case .success(let transcript):
            self.transcript = transcript
        case .failure(let error):
            self.error = error
            self.showError = true
        }
    }
}

// View shows alert
struct VoiceRambleView: View {
    @Bindable var viewModel: AddPersonViewModel

    var body: some View {
        // ...
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.error?.localizedDescription ?? "Unknown error")
        }
    }
}
```

---

## Naming Conventions

### Files

| Type | Convention | Example |
|------|------------|---------|
| View | `{Feature}View.swift` | `HomeView.swift` |
| ViewModel | `{Feature}ViewModel.swift` | `HomeViewModel.swift` |
| Service | `{Domain}Service.swift` | `PersonService.swift` |
| Model | `{Entity}.swift` | `Person.swift` |
| Component | `{Description}View.swift` | `RecordButton.swift` |

### Types

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase, noun | `PersonService` |
| Structs | PascalCase, noun | `Person` |
| Enums | PascalCase, noun | `VisualType` |
| Enum cases | camelCase | `.sketch`, `.photo` |
| Protocols | PascalCase, adjective or noun+Protocol | `PersonServiceProtocol` |

### Properties & Methods

| Type | Convention | Example |
|------|------------|---------|
| Properties | camelCase, noun | `dueCount`, `isRecording` |
| Methods | camelCase, verb | `loadPeople()`, `deletePerson(_:)` |
| Boolean props | `is`, `has`, `should` prefix | `isLoading`, `hasPhoto` |
| Async methods | verb, async suffix optional | `transcribe()`, `generateSketch()` |

---

## Code Style

### SwiftUI View Structure

Order within a View struct:
1. Properties (environment, state, bindings)
2. Computed properties
3. `body`
4. Helper methods
5. Subviews (private)

```swift
struct PersonDetailView: View {
    // 1. Properties
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: PersonDetailViewModel
    let person: Person

    // 2. Computed properties
    private var displayImage: Image {
        // ...
    }

    // 3. Body
    var body: some View {
        content
            .navigationTitle(person.name)
            .toolbar { toolbarContent }
    }

    // 4. Helper methods
    private func quizPerson() {
        // ...
    }

    // 5. Subviews
    @ViewBuilder
    private var content: some View {
        // ...
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // ...
    }
}
```

### Async/Await

Use structured concurrency. Avoid callbacks.

```swift
// Good: async/await
func addPerson() async {
    let transcript = await transcriptService.transcribe(audioURL: url)
    let keywords = keywordParser.extract(from: transcript)
    let sketch = await sketchService.generate(from: keywords)
    await personService.save(person)
}

// Avoid: callbacks
func addPerson(completion: @escaping (Result<Person, Error>) -> Void) {
    transcriptService.transcribe(audioURL: url) { result in
        // callback hell
    }
}
```

### Access Control

- Default to `private` for properties and methods
- Use `internal` (implicit) for types
- Use `public` only for framework boundaries (not needed for app)

```swift
final class PersonService {
    private let modelContext: ModelContext  // Private
    private let fileService: FileService    // Private

    func fetchAll() -> [Person] {           // Internal (default)
        // ...
    }

    private func buildPredicate() -> Predicate<Person> {  // Private helper
        // ...
    }
}
```

---

## Testing Conventions

### Test Naming

```swift
func test_loadPeople_withEmptyDatabase_returnsEmptyArray() { }
func test_updateReviewState_withGotIt_increasesInterval() { }
func test_transcribe_withClearAudio_returnsTranscript() { }
```

Pattern: `test_{method}_{condition}_{expectedResult}`

### Arrange-Act-Assert

```swift
func test_updateReviewState_withGotIt_increasesInterval() {
    // Arrange
    let person = Person(name: "Test")
    person.intervalDays = 1
    person.easeFactor = 2.5
    let service = ReviewService(modelContext: mockContext)

    // Act
    service.updateReviewState(for: person, gotIt: true)

    // Assert
    XCTAssertEqual(person.intervalDays, 2)  // 1 * 2.5 rounded
    XCTAssertEqual(person.easeFactor, 2.6)
}
```

### Mock Naming

```swift
final class MockPersonService: PersonServiceProtocol { }
final class MockAudioService: AudioServiceProtocol { }
```

---

## Git Conventions

### Branch Naming

```
feature/add-person-flow
feature/review-session
fix/audio-recording-crash
refactor/sketch-renderer
docs/update-architecture
```

### Commit Messages

```
Add voice ramble recording UI

- Implement RecordButton with animation
- Add AudioService for recording management
- Handle microphone permission request
```

Format:
- First line: imperative, max 50 chars
- Blank line
- Body: what and why, wrapped at 72 chars

---

## Documentation

### Code Comments

Only when **why** isn't obvious. Don't comment **what**.

```swift
// Bad: explains what
// Loop through people and filter by context
for person in people where person.context == selectedContext {

// Good: explains why
// SM-2 algorithm caps ease factor at 3.0 to prevent intervals
// from growing too quickly after a lucky streak
person.easeFactor = min(3.0, person.easeFactor + 0.1)
```

### Public API Documentation

Use Swift doc comments for services and public methods.

```swift
/// Generates an abstract avatar sketch from extracted keywords.
///
/// The sketch is intentionally non-photorealistic to avoid uncanny valley
/// effects and unrealistic user expectations.
///
/// - Parameter keywords: Extracted descriptors (hair color, glasses, etc.)
/// - Returns: URL to the generated PNG file
/// - Throws: `RememberError.sketchGenerationFailed` if rendering fails
func generate(from keywords: [String]) async throws -> URL {
    // ...
}
```
