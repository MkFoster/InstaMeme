import Foundation
import UIKit

enum ImageStoreError: Error {
    case cannotCreateDirectory
    case cannotWriteImage
    case cannotLoadImage
}

final class ImageStore {
    static let shared = ImageStore()

    private init() {}

    private var memesDirectoryURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("MemeImages", isDirectory: true)
    }

    private func ensureDirectoryExists() throws {
        let fm = FileManager.default
        if !fm.fileExists(atPath: memesDirectoryURL.path) {
            do {
                try fm.createDirectory(at: memesDirectoryURL, withIntermediateDirectories: true)
            } catch {
                throw ImageStoreError.cannotCreateDirectory
            }
        }
    }

    func saveMemeImage(_ image: UIImage, id: UUID) throws -> String {
        try ensureDirectoryExists()
        let fileName = "\(id.uuidString).png"
        let url = memesDirectoryURL.appendingPathComponent(fileName)

        guard let data = image.pngData() else {
            throw ImageStoreError.cannotWriteImage
        }

        do {
            try data.write(to: url)
        } catch {
            throw ImageStoreError.cannotWriteImage
        }

        return fileName
    }

    /// Load a meme image by file name.
    /// Returns nil if the file doesn't exist or can't be loaded.
    func loadMemeImage(fileName: String) -> UIImage? {
        let url = memesDirectoryURL.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }
}

