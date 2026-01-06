import Foundation
import WatchConnectivity
import AVFoundation
import Combine

struct PersonResult: Codable {
    let name: String
    let context: String?
    let imageData: Data?
    let message: String? // For confirmations like "Saved John"
}

@MainActor
class WatchViewModel: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var searchResult: PersonResult?
    @Published var errorMessage: String?

    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var session: WCSession?

    override init() {
        super.init()
    }

    func activateSession() {
        guard WCSession.isSupported() else { return }
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    // MARK: - Recording

    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)

            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioURL = documentsPath.appendingPathComponent("watch_recording.m4a")
            recordingURL = audioURL

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.record()
            isRecording = true
        } catch {
            errorMessage = "Couldn't start recording"
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        isProcessing = true

        guard let url = recordingURL,
              let audioData = try? Data(contentsOf: url) else {
            isProcessing = false
            errorMessage = "Couldn't read recording"
            return
        }

        sendToPhone(audioData: audioData)
    }

    // MARK: - Phone Communication

    private func sendToPhone(audioData: Data) {
        guard let session = session, session.isReachable else {
            isProcessing = false
            errorMessage = "iPhone not reachable"
            return
        }

        let message: [String: Any] = [
            "type": "voiceCommand",
            "audio": audioData
        ]

        session.sendMessage(message, replyHandler: { [weak self] response in
            Task { @MainActor in
                self?.handleResponse(response)
            }
        }, errorHandler: { [weak self] error in
            Task { @MainActor in
                self?.isProcessing = false
                self?.errorMessage = "Failed to reach iPhone"
            }
        })
    }

    private func handleResponse(_ response: [String: Any]) {
        isProcessing = false

        if let resultData = response["result"] as? Data,
           let result = try? JSONDecoder().decode(PersonResult.self, from: resultData) {
            searchResult = result
        } else if let error = response["error"] as? String {
            errorMessage = error
        }
    }

    func clearResult() {
        searchResult = nil
        errorMessage = nil
    }
}

// MARK: - WCSessionDelegate

extension WatchViewModel: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Session activated
    }
}
