# Remember - Product Specification (v1)

## Purpose

Remember is a private, calm, memory-first iOS app that helps users reliably remember people's names by combining:

1. **Active recall** - testing yourself strengthens memory
2. **Spaced repetition** - reviewing at optimal intervals
3. **Memory sketches** - abstract avatars generated from voice descriptions

It is explicitly **not** a personal CRM and **not** a face recognition tool.

## Core User Problem

Forgetting names causes embarrassment, anxiety, and social avoidance. Remember reduces anxiety before future encounters by making name recall reliable with minimal ongoing effort.

## Target User (v1)

Socially active adults who regularly meet new people (work, neighborhood, school parents, networking). Seniors are not the initial ICP.

## Non-Goals (v1)

- No face recognition
- No social/network integrations (LinkedIn, Instagram, etc.)
- No email/calendar/contact scraping
- No accounts, no cloud sync, no backend
- No notifications/reminders
- No streaks/gamification
- No analytics dashboards
- No "AI coach" chat UI
- No medical or senior cognitive framing
- No auto-generated mnemonics (cut from v1 - hard to do well)

## Core Concept

The primary way to add a person is by **recording a short voice "ramble"** describing what the person looked like. This serves two purposes:

1. **Encoding benefit** - actively describing someone creates stronger memory traces than passively capturing a photo
2. **Input convenience** - you rarely have photos of strangers you just met

Remember generates a **non-photorealistic avatar/sketch** from extracted keywords that serves as a visual memory anchor. Optionally, the user may later attach a real photo, but this is secondary and never required.

Flashcards use spaced repetition to train recall of the name from the visual anchor.

## Key Design Principles

1. **Calm, non-judgmental tone** - Forgetting is normal
2. **Low friction** - Add a person in under 60 seconds
3. **Active recall** - Show visual first, reveal name second
4. **Invisible spaced repetition** - No decks, no settings, no intervals shown
5. **Privacy-first** - Everything stays on device
6. **Abstract sketches** - Intentionally non-realistic to avoid creepiness
7. **Photos are optional** - Convenience, not the core experience

---

## Primary UX Flows

### Home Screen

- Minimal list of saved people: small sketch/photo thumbnail + name + context tag
- Search/filter icon in header (filters by context)
- Primary CTA: **"Add someone"**
- Secondary CTA: **"Review N cards"** (N = due items count)
- Tapping a person opens Person Detail
- Empty state: short explanation + CTA

### Add Person Flow

#### Screen A: Name Entry
- Field: "What's their name?"
- Button: Continue

#### Screen B: Voice Ramble (Primary Input)
- Full-screen large microphone button
- Primary prompt: "Describe what they looked like, in your own words. Anything that stood out is perfect."
- Secondary helper text: "Age, hair, glasses, vibe, posture — whatever you remember."
- Tap mic to record, tap again to stop
- Typical length: 10–30 seconds
- Button: Continue

#### Screen C: Sketch Preview
- Display generated abstract sketch on clean background
- Text: "This is a memory sketch — you can change it later."
- Primary button: **"Looks good"**
- Secondary button: **"Regenerate"**
- Tertiary link (subtle): "Add a photo instead"

#### Screen D: Context (Optional)
- Prompt: "Where did you meet?"
- Single-line text field with autocomplete from recent contexts
- Suggestions for new users: "Work", "Neighborhood", "Event", "Friend of friend"
- Primary button: **"Done"** (skippable)

#### Screen E: Optional Photo (Secondary Path)
- Options: Take photo / Upload from library
- Copy: "Photos are optional. Sketches work great too."
- If photo added, sketch remains available and can be toggled later

### Person Detail View

Accessible by tapping any person on Home.

- Shows: name, visual (sketch or photo), context tag, created date
- Primary button: **"Quiz me"** (starts 1-card review for this person)
- Secondary button: **"Edit"**

### Review Flow (Flashcards)

#### Session Start
- Default: algorithm-driven queue (due items first, then near-due)
- Alternative: single-person quiz from Person Detail

#### Card Front
- Primary visual (sketch or photo)
- No name visible
- User attempts recall mentally
- Tap anywhere to reveal

#### Card Back
- Name (large)
- Context tag (where you met them)
- Optional: short excerpt from the ramble (1 line, if transcript exists)
- Swipe right: **"Got it"**
- Swipe left: **"Missed it"**

#### Session End
- Simple: "Done" or "Nice work"
- No stats, no streaks

---

## Spaced Repetition Logic (v1)

Hidden SM-2–style scheduling:

**Inputs:** Got it / Missed it

**Per-person state:**
- `last_reviewed_at` (timestamp)
- `next_due_at` (timestamp)
- `ease_factor` (float, default 2.5)
- `interval_days` (int, starts at 1)

**Algorithm:**
- "Got it": interval = interval × ease_factor; ease_factor += 0.1 (max 3.0)
- "Missed it": interval = 1; ease_factor -= 0.2 (min 1.3)
- next_due_at = now + interval_days

**Daily queue:** due items first, then small number of near-due items

---

## Data Model

```
Person
├── id: UUID
├── name: String
├── context: String?              // "Conference", "Neighbor", etc.
├── createdAt: Date
├── audioNotePath: String?        // file path to audio recording
├── transcriptText: String?       // STT result
├── descriptorKeywords: [String]? // extracted from transcript
├── sketchImagePath: String?      // file path to generated sketch
├── photoImagePath: String?       // file path to optional photo
├── preferredVisualType: Enum     // .sketch | .photo
└── reviewState: ReviewState

ReviewState
├── lastReviewedAt: Date?
├── nextDueAt: Date
├── easeFactor: Double            // default 2.5
└── intervalDays: Int             // default 1
```

---

## Privacy and Trust

- **Default:** All data stays on device
- **Photos:** Never uploaded or analyzed remotely
- **No background scanning** of photo library
- **No automatic ingestion** from contacts/calendar
- **Clear language:** "Nothing leaves your phone."
- **Framing:** "memory sketch," not "portrait"
- **Avoid:** Demographic inference language or labels

---

## Sketch Generation (v1 Approach)

**Chosen approach:** Deterministic avatar renderer driven by extracted keywords

**How it works:**
1. Voice ramble → on-device Speech-to-Text → transcript
2. Transcript → keyword extraction (hair color, glasses, age range, etc.)
3. Keywords → deterministic avatar composition (layered SVG or drawn assets)

**Requirements:**
- Output is intentionally abstract/stylized (not photorealistic)
- Slight exaggeration of distinctive features is acceptable
- Fast: target under 2 seconds
- "Regenerate" varies optional stylistic elements while keeping core features
- Future: could add manual correction UI for misextracted features

---

## Open Questions (Deferred)

1. Does voice-first input materially improve recall vs photo-first? (Validate with user testing)
2. Is the sketch good enough to stand on its own? (Test with sketch-only users)
3. Should we add sketch correction UI in v1.1? (Likely yes)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024-12-18 | Initial spec |
| 1.1 | 2024-12-18 | Added: "Review before meeting" flow, context tagging, person detail view. Removed: auto-generated mnemonics. |
