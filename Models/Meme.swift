import Foundation
import SwiftData

@Model
final class Meme {
    @Attribute(.unique) var id: UUID
    var createdAt: Date

    /// File name of the rendered meme image stored on disk.
    var imageFileName: String

    /// Main caption text. For MVP we can treat this as a single block.
    var topText: String
    var bottomText: String

    /// Whether the user has marked this meme as a favorite.
    var isFavorite: Bool

    /// Optional longer description of the scene (from VLM),
    /// useful for future search or filtering.
    var sceneDescription: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        imageFileName: String,
        topText: String,
        bottomText: String,
        isFavorite: Bool = false,
        sceneDescription: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.imageFileName = imageFileName
        self.topText = topText
        self.bottomText = bottomText
        self.isFavorite = isFavorite
        self.sceneDescription = sceneDescription
    }
}
