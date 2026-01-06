import Foundation
import WatchConnectivity
import SwiftData
import UIKit

/// Handles communication with the Apple Watch companion app
@MainActor
final class WatchConnectivityService: NSObject {
    static let shared = WatchConnectivityService()

    private var session: WCSession?
    private var modelContext: ModelContext?
    private var transcriptService: TranscriptServiceProtocol?
    private var personService: PersonService?
    private var fileService: FileServiceProtocol?
    private var sketchService: SketchServiceProtocol?

    private override init() {
        super.init()
    }

    func configure(
        modelContext: ModelContext,
        transcriptService: TranscriptServiceProtocol,
        personService: PersonService,
        fileService: FileServiceProtocol,
        sketchService: SketchServiceProtocol
    ) {
        self.modelContext = modelContext
        self.transcriptService = transcriptService
        self.personService = personService
        self.fileService = fileService
        self.sketchService = sketchService

        guard WCSession.isSupported() else { return }
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    // MARK: - Voice Command Processing

    private func processVoiceCommand(audioData: Data) async -> [String: Any] {
        guard let transcriptService = transcriptService else {
            return ["error": "Service not configured"]
        }

        // Save audio to temp file for transcription
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("watch_audio.m4a")
        do {
            try audioData.write(to: tempURL)
        } catch {
            return ["error": "Failed to process audio"]
        }

        // Transcribe
        let hasPermission = await transcriptService.requestPermission()
        guard hasPermission else {
            return ["error": "Speech permission denied"]
        }

        let transcript: String
        do {
            transcript = try await transcriptService.transcribe(audioURL: tempURL)
        } catch {
            return ["error": "Couldn't understand audio"]
        }

        // Determine intent and execute
        let intent = IntentParser.parse(transcript)

        switch intent {
        case .remember(let name, let description):
            return await handleRemember(name: name, description: description)
        case .search(let query):
            return await handleSearch(query: query)
        case .unknown:
            return ["error": "Try: 'Remember [name]...' or 'Who is...?'"]
        }
    }

    // MARK: - Remember Intent

    private func handleRemember(name: String, description: String?) async -> [String: Any] {
        guard let modelContext = modelContext,
              let sketchService = sketchService else {
            return ["error": "Service not configured"]
        }

        // Create person
        let person = Person(name: name)
        person.transcriptText = description

        // Extract keywords if we have a description
        var keywords: [String] = []
        if let description = description {
            let parser = KeywordParser()
            keywords = parser.extractKeywords(from: description)
            person.descriptorKeywords = keywords
        }

        // Generate sketch
        do {
            let sketchPath = try await sketchService.generateSketch(
                from: description,
                keywords: keywords,
                for: person.id
            )
            person.sketchImagePath = sketchPath
        } catch {
            // Continue without sketch
        }

        // Save
        modelContext.insert(person)
        try? modelContext.save()

        // Build response
        let result = WatchPersonResult(
            name: name,
            context: description,
            imageData: loadImageData(for: person),
            message: "Saved \(name)"
        )

        guard let resultData = try? JSONEncoder().encode(result) else {
            return ["error": "Failed to encode result"]
        }

        return ["result": resultData]
    }

    // MARK: - Search Intent

    private func handleSearch(query: String) async -> [String: Any] {
        guard let personService = personService else {
            return ["error": "Service not configured"]
        }

        // Search for matching people
        let people = personService.fetchAll(searchText: query)

        guard let person = people.first else {
            return ["error": "No one matches '\(query)'"]
        }

        let result = WatchPersonResult(
            name: person.name,
            context: person.context ?? person.transcriptText?.prefix(50).description,
            imageData: loadImageData(for: person),
            message: nil
        )

        guard let resultData = try? JSONEncoder().encode(result) else {
            return ["error": "Failed to encode result"]
        }

        return ["result": resultData]
    }

    // MARK: - Helpers

    private func loadImageData(for person: Person) -> Data? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        // Try photo first
        if let photoPath = person.photoImagePath {
            let url = documentsURL.appendingPathComponent(photoPath)
            if let data = try? Data(contentsOf: url) {
                // Resize for watch
                if let image = UIImage(data: data),
                   let resized = resizeForWatch(image) {
                    return resized.pngData()
                }
                return data
            }
        }

        // Fall back to sketch
        if let sketchPath = person.sketchImagePath {
            let url = documentsURL.appendingPathComponent(sketchPath)
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data),
                   let resized = resizeForWatch(image) {
                    return resized.pngData()
                }
                return data
            }
        }

        return nil
    }

    private func resizeForWatch(_ image: UIImage) -> UIImage? {
        let size = CGSize(width: 160, height: 160)
        UIGraphicsBeginImageContextWithOptions(size, false, 2.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Session activated
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate for switching watches
        session.activate()
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let type = message["type"] as? String, type == "voiceCommand",
              let audioData = message["audio"] as? Data else {
            replyHandler(["error": "Invalid message"])
            return
        }

        Task { @MainActor in
            let response = await self.processVoiceCommand(audioData: audioData)
            replyHandler(response)
        }
    }
}

// MARK: - Result Type

struct WatchPersonResult: Codable {
    let name: String
    let context: String?
    let imageData: Data?
    let message: String?
}
