import Foundation
import Speech

enum TranscriptServiceError: LocalizedError {
    case permissionDenied
    case notAvailable
    case transcriptionFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Speech recognition permission is required."
        case .notAvailable:
            return "Speech recognition is not available on this device."
        case .transcriptionFailed:
            return "Couldn't understand the recording. Try speaking more clearly."
        }
    }
}

protocol TranscriptServiceProtocol {
    func requestPermission() async -> Bool
    func transcribe(audioURL: URL) async throws -> String
}

final class TranscriptService: TranscriptServiceProtocol {
    private let speechRecognizer: SFSpeechRecognizer?

    init(locale: Locale = .current) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
    }

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    func transcribe(audioURL: URL) async throws -> String {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw TranscriptServiceError.notAvailable
        }

        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false

        // Prefer on-device recognition for privacy
        if #available(iOS 13, *) {
            request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        }

        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let result = result, result.isFinal else {
                    return
                }

                let transcript = result.bestTranscription.formattedString
                if transcript.isEmpty {
                    continuation.resume(throwing: TranscriptServiceError.transcriptionFailed)
                } else {
                    continuation.resume(returning: transcript)
                }
            }
        }
    }
}
