# Remember - iOS Architecture

## Overview

Remember is a native iOS app built with SwiftUI, following a feature-based modular architecture with MVVM pattern. All data stays on-device using SwiftData for persistence and FileManager for binary assets (audio, images).

## Tech Stack

| Layer | Technology |
|-------|------------|
| UI Framework | SwiftUI |
| Architecture | MVVM + Coordinator |
| Persistence | SwiftData (Swift 5.9+) |
| File Storage | FileManager |
| Speech-to-Text | Speech framework (on-device) |
| Audio Recording | AVFoundation |
| Image Generation | Core Graphics + custom avatar renderer |
| Minimum iOS | 17.0 |

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         SwiftUI Views                           │
│  (HomeView, AddPersonFlow, ReviewView, PersonDetailView, etc.)  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                         ViewModels                              │
│    (HomeViewModel, AddPersonViewModel, ReviewViewModel, etc.)   │
│                                                                 │
│  • Owns UI state                                                │
│  • Calls services                                               │
│  • Publishes updates via @Published / @Observable               │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                          Services                               │
├─────────────────┬─────────────────┬─────────────────────────────┤
│ PersonService   │ ReviewService   │ AudioService                │
│                 │                 │                             │
│ • CRUD for      │ • SR algorithm  │ • Record audio              │
│   Person model  │ • Queue logic   │ • Playback                  │
│ • Search/filter │ • Update state  │ • File management           │
├─────────────────┼─────────────────┼─────────────────────────────┤
│ TranscriptService                 │ SketchService               │
│                                   │                             │
│ • On-device STT                   │ • Keyword extraction        │
│ • Transcript cleanup              │ • Avatar generation         │
│                                   │ • Regeneration variants     │
└───────────────────────────────────┴─────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Data Layer                               │
├─────────────────────────────────┬───────────────────────────────┤
│          SwiftData              │        FileManager            │
│                                 │                               │
│  • Person model                 │  • Audio files (.m4a)         │
│  • ReviewState (embedded)       │  • Sketch images (.png)       │
│  • Context history              │  • Photo images (.jpg)        │
│                                 │                               │
│  Location: App's default        │  Location: App's Documents/   │
│  SwiftData container            │  with subdirectories          │
└─────────────────────────────────┴───────────────────────────────┘
```

## Project Structure

```
Remember/
├── App/
│   ├── RememberApp.swift           # @main entry point
│   └── AppState.swift              # Global app state if needed
│
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── HomeViewModel.swift
│   │   ├── PersonRowView.swift
│   │   └── EmptyStateView.swift
│   │
│   ├── AddPerson/
│   │   ├── AddPersonFlow.swift     # Navigation coordinator
│   │   ├── NameEntryView.swift
│   │   ├── VoiceRambleView.swift
│   │   ├── SketchPreviewView.swift
│   │   ├── ContextEntryView.swift
│   │   ├── PhotoAttachView.swift
│   │   └── AddPersonViewModel.swift
│   │
│   ├── Review/
│   │   ├── ReviewSessionView.swift
│   │   ├── FlashcardView.swift
│   │   ├── ReviewCompleteView.swift
│   │   └── ReviewViewModel.swift
│   │
│   └── PersonDetail/
│       ├── PersonDetailView.swift
│       ├── PersonEditView.swift
│       └── PersonDetailViewModel.swift
│
├── Services/
│   ├── PersonService.swift         # CRUD, search, filtering
│   ├── ReviewService.swift         # Spaced repetition logic
│   ├── AudioService.swift          # Recording & playback
│   ├── TranscriptService.swift     # Speech-to-text
│   └── SketchService.swift         # Avatar generation
│
├── Models/
│   ├── Person.swift                # SwiftData model
│   ├── ReviewState.swift           # Embedded in Person
│   └── VisualType.swift            # Enum: .sketch, .photo
│
├── SketchRenderer/
│   ├── SketchRenderer.swift        # Main renderer
│   ├── SketchComponents/
│   │   ├── FaceShape.swift
│   │   ├── HairStyle.swift
│   │   ├── Eyes.swift
│   │   ├── Glasses.swift
│   │   ├── FacialHair.swift
│   │   └── Accessories.swift
│   ├── SketchStyle.swift           # Line weight, colors, etc.
│   └── KeywordParser.swift         # Extract features from transcript
│
├── Shared/
│   ├── Components/
│   │   ├── PrimaryButton.swift
│   │   ├── SecondaryButton.swift
│   │   ├── RecordButton.swift
│   │   └── SketchThumbnail.swift
│   ├── Extensions/
│   │   ├── Date+Extensions.swift
│   │   └── Color+Theme.swift
│   └── Theme/
│       ├── Typography.swift
│       └── Colors.swift
│
├── Resources/
│   ├── Assets.xcassets
│   └── Localizable.strings
│
└── Preview Content/
    └── PreviewData.swift           # Sample data for previews
```

## Data Models

### Person (SwiftData)

```swift
@Model
final class Person {
    var id: UUID
    var name: String
    var context: String?
    var createdAt: Date

    // File paths (relative to Documents/)
    var audioNotePath: String?
    var sketchImagePath: String?
    var photoImagePath: String?

    // Transcript data
    var transcriptText: String?
    var descriptorKeywords: [String]

    // Visual preference
    var preferredVisualType: VisualType

    // Embedded review state
    var lastReviewedAt: Date?
    var nextDueAt: Date
    var easeFactor: Double
    var intervalDays: Int

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.descriptorKeywords = []
        self.preferredVisualType = .sketch
        self.nextDueAt = Date()
        self.easeFactor = 2.5
        self.intervalDays = 1
    }
}
```

### VisualType

```swift
enum VisualType: String, Codable {
    case sketch
    case photo
}
```

## Key Flows

### Add Person Flow

```
┌──────────────┐    ┌───────────────┐    ┌────────────────┐
│  NameEntry   │───▶│  VoiceRamble  │───▶│ SketchPreview  │
│              │    │               │    │                │
│ name: String │    │ • Record      │    │ • Show sketch  │
│              │    │ • STT async   │    │ • Regenerate   │
│              │    │ • Extract kw  │    │ • Add photo    │
└──────────────┘    └───────────────┘    └────────────────┘
                                                  │
                                                  ▼
                                         ┌────────────────┐
                                         │  ContextEntry  │───▶ Save & Done
                                         │                │
                                         │ context: String│
                                         │ (optional)     │
                                         └────────────────┘
```

**Data flow during Add Person:**

1. User enters name → stored in ViewModel
2. User records audio → AudioService saves .m4a to disk
3. TranscriptService transcribes → transcript stored
4. KeywordParser extracts features → descriptorKeywords stored
5. SketchRenderer generates avatar → .png saved to disk
6. User optionally adds context
7. PersonService saves Person to SwiftData

### Review Session Flow

```
┌──────────────┐    ┌───────────────┐    ┌────────────────┐
│ ReviewService│───▶│  CardFront    │───▶│   CardBack     │
│              │    │               │    │                │
│ • Get queue  │    │ • Show sketch │    │ • Reveal name  │
│ • Due first  │    │ • Tap to flip │    │ • Got/Missed   │
│ • Near-due   │    │               │    │ • Update SR    │
└──────────────┘    └───────────────┘    └────────────────┘
                                                  │
                                                  ▼
                                         ┌────────────────┐
                                         │ ReviewComplete │
                                         │                │
                                         │ "Nice work"    │
                                         └────────────────┘
```

### Spaced Repetition Update

```swift
func updateReviewState(for person: Person, gotIt: Bool) {
    person.lastReviewedAt = Date()

    if gotIt {
        person.intervalDays = Int(Double(person.intervalDays) * person.easeFactor)
        person.easeFactor = min(3.0, person.easeFactor + 0.1)
    } else {
        person.intervalDays = 1
        person.easeFactor = max(1.3, person.easeFactor - 0.2)
    }

    person.nextDueAt = Calendar.current.date(
        byAdding: .day,
        value: person.intervalDays,
        to: Date()
    ) ?? Date()
}
```

## File Storage Strategy

```
Documents/
├── audio/
│   ├── {person-id}.m4a
│   └── ...
├── sketches/
│   ├── {person-id}.png
│   └── ...
└── photos/
    ├── {person-id}.jpg
    └── ...
```

- Files named by Person UUID for easy lookup
- Cleanup: when Person deleted, delete associated files
- Audio files kept for potential re-transcription or playback

## Sketch Generation Pipeline

```
┌─────────────┐    ┌──────────────┐    ┌───────────────┐
│ Transcript  │───▶│ KeywordParser│───▶│ SketchRenderer│───▶ PNG
│             │    │              │    │               │
│ "She had    │    │ hairColor:   │    │ Compose       │
│  red curly  │    │   red        │    │ layers:       │
│  hair and   │    │ hairStyle:   │    │ - face        │
│  glasses"   │    │   curly      │    │ - hair        │
│             │    │ glasses:     │    │ - glasses     │
│             │    │   true       │    │ - etc.        │
└─────────────┘    └──────────────┘    └───────────────┘
```

**Keyword categories:**
- Hair: color, style (short, long, curly, straight, bald, etc.)
- Face: shape, age range
- Features: glasses, beard, mustache
- Build: tall, short, stocky, thin
- Distinguishing: specific accessories, notable features

**Regenerate behavior:**
- Keep extracted features constant
- Vary: line style, slight proportions, color saturation
- Provides meaningful variety without losing identity

## Performance Considerations

| Operation | Target | Approach |
|-----------|--------|----------|
| App launch | < 500ms | Lazy load, minimal startup work |
| Add person (total) | < 60s | User-paced, async processing |
| STT transcription | < 5s | On-device, async |
| Sketch generation | < 2s | Pre-rendered components, compositing |
| Review card flip | < 100ms | Image pre-loaded |
| Search/filter | < 100ms | SwiftData queries with indexes |

## Testing Strategy

| Layer | Approach |
|-------|----------|
| Models | Unit tests for SR algorithm, keyword parsing |
| Services | Unit tests with mock data |
| ViewModels | Unit tests with mock services |
| Views | SwiftUI previews with sample data |
| Integration | UI tests for critical flows (add, review) |

## Future Considerations (v2+)

- **iCloud sync**: Optional, explicit opt-in, uses CloudKit
- **Sketch correction UI**: Tap to adjust misextracted features
- **Widget**: Review reminder or "person of the day"
- **Siri integration**: "Quiz me on Sarah"
- **Export/backup**: JSON + files bundle
