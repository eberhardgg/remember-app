import Foundation

protocol FileServiceProtocol {
    func audioDirectory() -> URL
    func sketchesDirectory() -> URL
    func photosDirectory() -> URL
    func saveAudio(data: Data, for personId: UUID) throws -> String
    func saveSketch(data: Data, for personId: UUID) throws -> String
    func savePhoto(data: Data, for personId: UUID) throws -> String
    func deleteFiles(for person: Person)
}

final class FileService: FileServiceProtocol {
    private let fileManager = FileManager.default

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    func audioDirectory() -> URL {
        let url = documentsDirectory.appendingPathComponent("audio", isDirectory: true)
        ensureDirectoryExists(url)
        return url
    }

    func sketchesDirectory() -> URL {
        let url = documentsDirectory.appendingPathComponent("sketches", isDirectory: true)
        ensureDirectoryExists(url)
        return url
    }

    func photosDirectory() -> URL {
        let url = documentsDirectory.appendingPathComponent("photos", isDirectory: true)
        ensureDirectoryExists(url)
        return url
    }

    func saveAudio(data: Data, for personId: UUID) throws -> String {
        let relativePath = "audio/\(personId.uuidString).m4a"
        let url = documentsDirectory.appendingPathComponent(relativePath)
        ensureDirectoryExists(url.deletingLastPathComponent())
        try data.write(to: url)
        return relativePath
    }

    func saveSketch(data: Data, for personId: UUID) throws -> String {
        let relativePath = "sketches/\(personId.uuidString).png"
        let url = documentsDirectory.appendingPathComponent(relativePath)
        ensureDirectoryExists(url.deletingLastPathComponent())
        try data.write(to: url)
        return relativePath
    }

    func savePhoto(data: Data, for personId: UUID) throws -> String {
        let relativePath = "photos/\(personId.uuidString).jpg"
        let url = documentsDirectory.appendingPathComponent(relativePath)
        ensureDirectoryExists(url.deletingLastPathComponent())
        try data.write(to: url)
        return relativePath
    }

    func deleteFiles(for person: Person) {
        let paths = [
            person.audioNotePath,
            person.sketchImagePath,
            person.photoImagePath
        ].compactMap { $0 }

        for path in paths {
            let url = documentsDirectory.appendingPathComponent(path)
            try? fileManager.removeItem(at: url)
        }
    }

    private func ensureDirectoryExists(_ url: URL) {
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}
