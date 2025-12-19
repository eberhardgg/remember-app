import AVFoundation
import Foundation

enum AudioServiceError: LocalizedError {
    case permissionDenied
    case recordingFailed
    case noActiveRecording

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone access is required to record voice descriptions."
        case .recordingFailed:
            return "Failed to start recording. Please try again."
        case .noActiveRecording:
            return "No active recording to stop."
        }
    }
}

protocol AudioServiceProtocol {
    var isRecording: Bool { get }
    func requestPermission() async -> Bool
    func startRecording(for personId: UUID) throws
    func stopRecording() throws -> URL
}

final class AudioService: NSObject, AudioServiceProtocol {
    private var audioRecorder: AVAudioRecorder?
    private var currentRecordingURL: URL?
    private let fileService: FileServiceProtocol

    var isRecording: Bool {
        audioRecorder?.isRecording ?? false
    }

    init(fileService: FileServiceProtocol) {
        self.fileService = fileService
        super.init()
    }

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func startRecording(for personId: UUID) throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default)
        try audioSession.setActive(true)

        let url = fileService.audioDirectory()
            .appendingPathComponent("\(personId.uuidString).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.delegate = self
        currentRecordingURL = url

        guard audioRecorder?.record() == true else {
            throw AudioServiceError.recordingFailed
        }
    }

    func stopRecording() throws -> URL {
        guard let recorder = audioRecorder, let url = currentRecordingURL else {
            throw AudioServiceError.noActiveRecording
        }

        recorder.stop()
        audioRecorder = nil

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false)

        return url
    }
}

extension AudioService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording finished unsuccessfully")
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Recording encode error: \(error)")
        }
    }
}
