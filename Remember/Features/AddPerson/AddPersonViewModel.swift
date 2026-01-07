import Foundation
import SwiftData
import Observation
import UIKit

@Observable
final class AddPersonViewModel {
    private let modelContext: ModelContext
    private let fileService: FileServiceProtocol
    private let audioService: AudioServiceProtocol
    private let transcriptService: TranscriptServiceProtocol
    private let sketchService: SketchServiceProtocol

    // Form state
    var name: String = ""
    var context: String = ""

    // Recording state
    var isRecording: Bool = false
    var hasRecording: Bool = false
    var audioURL: URL?

    // Processing state
    var isProcessing: Bool = false
    var transcript: String?
    var keywords: [String] = []

    // Sketch state
    var sketchPath: String?
    var sketchVariant: Int = 0

    // Photo state
    var photoPath: String?

    // Error handling
    var error: Error?
    var showError: Bool = false

    // Debug info
    var sketchSource: String = ""

    // The person being created
    private(set) var person: Person?

    init(
        modelContext: ModelContext,
        fileService: FileServiceProtocol,
        audioService: AudioServiceProtocol,
        transcriptService: TranscriptServiceProtocol,
        sketchService: SketchServiceProtocol
    ) {
        self.modelContext = modelContext
        self.fileService = fileService
        self.audioService = audioService
        self.transcriptService = transcriptService
        self.sketchService = sketchService
    }

    var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Actions

    func createPerson() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        person = Person(name: trimmedName)
    }

    func startRecording() async {
        guard let person = person else { return }

        let hasPermission = await audioService.requestPermission()
        guard hasPermission else {
            self.error = AudioServiceError.permissionDenied
            self.showError = true
            return
        }

        do {
            try audioService.startRecording(for: person.id)
            isRecording = true
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func stopRecording() async {
        do {
            let url = try audioService.stopRecording()
            audioURL = url
            isRecording = false
            hasRecording = true

            // Start transcription
            await transcribeAudio()
        } catch {
            isRecording = false
            self.error = error
            self.showError = true
        }
    }

    private func transcribeAudio() async {
        guard let url = audioURL else {
            print("[AddPersonVM] No audio URL, generating sketch without transcript")
            await generateSketch()
            return
        }

        isProcessing = true
        print("[AddPersonVM] Starting transcription...")

        let hasPermission = await transcriptService.requestPermission()
        if !hasPermission {
            print("[AddPersonVM] No speech permission, generating sketch without transcript")
            // Still generate a sketch even without transcript
            await generateSketch()
            isProcessing = false
            return
        }

        do {
            let text = try await transcriptService.transcribe(audioURL: url)
            print("[AddPersonVM] Transcription succeeded: \(text.prefix(50))...")
            transcript = text

            // Extract keywords
            let parser = KeywordParser()
            keywords = parser.extractKeywords(from: text)
            print("[AddPersonVM] Extracted keywords: \(keywords)")

            // Generate sketch
            await generateSketch()
        } catch {
            // Transcription failed - continue without it
            print("[AddPersonVM] Transcription failed: \(error)")
            // Still try to generate a default sketch
            await generateSketch()
        }

        isProcessing = false
    }

    func generateSketch() async {
        print("[AddPersonVM] generateSketch called")
        guard let person = person else {
            print("[AddPersonVM] ERROR: person is nil!")
            return
        }
        print("[AddPersonVM] person exists: \(person.name)")

        isProcessing = true

        // Check if OpenAI will be used
        let apiKeyValue = UserDefaults.standard.string(forKey: "openai_api_key")
        let hasAPIKey = apiKeyValue?.isEmpty == false
        let hasTranscript = transcript?.isEmpty == false
        print("[AddPersonVM] hasAPIKey: \(hasAPIKey), hasTranscript: \(hasTranscript)")
        print("[AddPersonVM] API key length: \(apiKeyValue?.count ?? 0)")

        if hasAPIKey && hasTranscript {
            sketchSource = "Using OpenAI DALL-E 3..."
        } else if !hasAPIKey {
            sketchSource = "No API key - using local sketch"
        } else {
            sketchSource = "No transcript - using local sketch"
        }

        do {
            let path = try await sketchService.generateSketch(
                from: transcript,
                keywords: keywords,
                for: person.id
            )
            sketchPath = path
            person.sketchImagePath = path
            person.descriptorKeywords = keywords

            if hasAPIKey && hasTranscript {
                sketchSource = "Generated with OpenAI"
            } else {
                sketchSource = "Generated locally"
            }
        } catch {
            print("[AddPersonVM] Sketch generation error: \(error)")
            sketchSource = "Error: \(error.localizedDescription)"

            // Try local fallback if OpenAI failed
            if hasAPIKey && hasTranscript {
                print("[AddPersonVM] OpenAI failed, trying local fallback...")
                sketchSource = "OpenAI failed, using local sketch"
                do {
                    let fileService = FileService()
                    let localRenderer = SketchRenderer()
                    let keywordParser = KeywordParser()
                    let features = keywordParser.parse(keywords)
                    if let image = localRenderer.render(features: features, variant: 0),
                       let data = image.pngData() {
                        let path = try fileService.saveSketch(data: data, for: person.id)
                        sketchPath = path
                        person.sketchImagePath = path
                        person.descriptorKeywords = keywords
                        sketchSource = "Generated locally (OpenAI failed)"
                    }
                } catch {
                    print("[AddPersonVM] Local fallback also failed: \(error)")
                    self.error = error
                    self.showError = true
                }
            } else {
                self.error = error
                self.showError = true
            }
        }

        isProcessing = false
    }

    func regenerateSketch() async {
        guard let person = person else { return }

        sketchVariant += 1
        isProcessing = true

        do {
            let path = try await sketchService.regenerateSketch(
                from: transcript,
                keywords: keywords,
                for: person.id
            )
            sketchPath = path
            person.sketchImagePath = path
        } catch {
            self.error = error
            self.showError = true
        }

        isProcessing = false
    }

    /// Stop recording and append to existing transcript, then regenerate sketch
    func stopRecordingAndRefine() async {
        guard let person = person else { return }

        do {
            let url = try audioService.stopRecording()
            isRecording = false
            isProcessing = true

            // Transcribe the new audio
            let hasPermission = await transcriptService.requestPermission()
            guard hasPermission else {
                isProcessing = false
                return
            }

            let newText = try await transcriptService.transcribe(audioURL: url)

            // Append to existing transcript
            if let existingTranscript = transcript, !existingTranscript.isEmpty {
                transcript = existingTranscript + " " + newText
            } else {
                transcript = newText
            }

            // Re-extract keywords from combined transcript
            let parser = KeywordParser()
            keywords = parser.extractKeywords(from: transcript ?? "")

            // Regenerate sketch with updated description
            let path = try await sketchService.regenerateSketch(
                from: transcript,
                keywords: keywords,
                for: person.id
            )
            sketchPath = path
            person.sketchImagePath = path
            person.descriptorKeywords = keywords

        } catch {
            self.error = error
            self.showError = true
        }

        isProcessing = false
    }

    func setContext(_ text: String) {
        context = text
        person?.context = text.isEmpty ? nil : text
    }

    func savePhoto(_ image: UIImage) async {
        guard let person = person else { return }

        isProcessing = true

        do {
            // Compress and save as JPEG
            guard let data = image.jpegData(compressionQuality: 0.8) else {
                throw SketchServiceError.saveFailed
            }

            let path = try fileService.savePhoto(data: data, for: person.id)
            photoPath = path
            person.photoImagePath = path
            person.preferredVisualType = .photo
        } catch {
            self.error = error
            self.showError = true
        }

        isProcessing = false
    }

    func savePerson() throws {
        guard let person = person else { return }

        // Save transcript if we have one
        if let transcript = transcript {
            person.transcriptText = transcript
        }

        // Save audio path
        if let audioURL = audioURL {
            person.audioNotePath = "audio/\(person.id.uuidString).m4a"
        }

        modelContext.insert(person)
        try modelContext.save()
    }

    func recentContexts() -> [String] {
        // TODO: Fetch from PersonService
        return ["Work", "Neighborhood", "Event", "Friend of friend"]
    }
}
