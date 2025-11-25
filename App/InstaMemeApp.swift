import SwiftUI
import SwiftData

@main
struct InstaMemeApp: App {
    var body: some Scene {
        WindowGroup {
            MemeGalleryView()
        }
        .modelContainer(for: [Meme.self, AppSettings.self])
    }
}

