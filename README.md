# Remember

A calm, memory-first iOS app for remembering people's names.

## Concept

Remember helps you reliably recall names using:
- **Active recall** — testing yourself strengthens memory
- **Spaced repetition** — reviewing at optimal intervals
- **Voice-first input** — describe someone to create a memory sketch

Record a short voice "ramble" describing what someone looked like. Remember generates an abstract sketch as a visual anchor, then uses flashcard-style review to train recall.

## Documentation

- [Product Spec](docs/SPEC.md) — Features, flows, and requirements
- [Architecture](docs/ARCHITECTURE.md) — Technical design and structure
- [Patterns](docs/PATTERNS.md) — Code conventions and best practices

## Tech Stack

- SwiftUI
- SwiftData
- Speech framework (on-device STT)
- AVFoundation (audio recording)
- iOS 17+

## Getting Started

### Prerequisites

- Xcode 15+
- iOS 17+ device or simulator

### Setup

1. Open Xcode
2. Create new project: **File → New → Project → App**
3. Configure:
   - Product Name: `Remember`
   - Organization Identifier: your identifier
   - Interface: SwiftUI
   - Language: Swift
   - Storage: SwiftData
4. Replace the generated files with the structure in `Remember/`
5. Build and run

### Project Structure

```
Remember/
├── App/                    # App entry point
├── Features/
│   ├── Home/              # Main list view
│   ├── AddPerson/         # Add person flow
│   ├── Review/            # Flashcard review
│   └── PersonDetail/      # Person detail & edit
├── Services/              # Business logic
├── Models/                # SwiftData models
├── SketchRenderer/        # Avatar generation
├── Shared/                # Reusable components
└── Resources/             # Assets, strings
```

## Privacy

Everything stays on your device. No accounts, no cloud sync, no data collection.

## License

MIT
