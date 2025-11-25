import Foundation
import SwiftData

@Model
final class AppSettings {
    // Only ever 1 instance; you can just fetch the first.
    var defaultFontName: String
    var defaultFontSize: Double
    var defaultTextColorHex: String
    var includeWatermark: Bool

    init(
        defaultFontName: String = "Impact",
        defaultFontSize: Double = 40,
        defaultTextColorHex: String = "#FFFFFF",
        includeWatermark: Bool = true
    ) {
        self.defaultFontName = defaultFontName
        self.defaultFontSize = defaultFontSize
        self.defaultTextColorHex = defaultTextColorHex
        self.includeWatermark = includeWatermark
    }
}
