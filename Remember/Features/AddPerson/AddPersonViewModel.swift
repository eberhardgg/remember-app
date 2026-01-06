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
        guard let url = audioURL else { return }

        isProcessing = true

        let hasPermission = await transcriptService.requestPermission()
        guard hasPermission else {
            isProcessing = false
            // Continue without transcript - not critical
            return
        }

        do {
            let text = try await transcriptService.transcribe(audioURL: url)
            transcript = text

            // Extract keywords
            let parser = KeywordParser()
            keywords = parser.extractKeywords(from: text)

            // Generate sketch
            await generateSketch()
        } catch {
            // Transcription failed - continue without it
            print("Transcription failed: \(error)")
            // Still try to generate a default sketch
            await generateSketch()
        }

        isProcessing = false
    }

    func generateSketch() async {
        guard let person = person else { return }

        isProcessing = true

        do {
            let path = try await sketchService.generateSketch(
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
