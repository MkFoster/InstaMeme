import SwiftUI
import SwiftData

struct MemeGalleryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Meme.createdAt, order: .reverse) private var memes: [Meme]
    
    @State private var isPresentingNewMeme = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("InstaMeme")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isPresentingNewMeme = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $isPresentingNewMeme) {
                    CameraMemeView()
                }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if memes.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("No memes yet")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Tap the + button to create your first Instameme.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(memes, id: \.id) { meme in
                    NavigationLink(destination: MemeDetailView(meme: meme)) {
                        HStack(spacing: 12) {
                            let thumbnail = ImageStore.shared.loadMemeImage(fileName: meme.imageFileName)

                            if let uiImage = thumbnail {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .clipped()
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.2))
                                    Image(systemName: "photo")
                                        .foregroundStyle(.secondary)
                                }
                                .frame(width: 60, height: 60)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(meme.topText)
                                    .font(.headline)
                                    .lineLimit(1)

                                Text(meme.bottomText)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)

                                Text(meme.createdAt, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteMemes)
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Actions

    private func deleteMemes(at offsets: IndexSet) {
        for index in offsets {
            let meme = memes[index]
            context.delete(meme)
        }

        do {
            try context.save()
        } catch {
            print("Failed to delete meme(s): \(error)")
        }
    }
}

#Preview {
    do {
        let container = try ModelContainer(for: Meme.self, AppSettings.self)
        let context = container.mainContext

        let sample = Meme(
            imageFileName: "preview.png",
            topText: "When the AI",
            bottomText: "actually runs on-device"
        )
        context.insert(sample)

        return MemeGalleryView()
            .modelContainer(container)
    } catch {
        return Text("Preview failed: \(error.localizedDescription)")
    }
}

