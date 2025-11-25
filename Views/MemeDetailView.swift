import SwiftUI

struct MemeDetailView: View {
    // We keep track of whichever meme we're currently showing (original or remix)
    @State private var currentMeme: Meme

    @State private var uiImage: UIImage?
    @State private var loadError: String?

    @State private var shareItem: ShareItem?
    @State private var isPresentingRemix = false

    @Environment(\.displayScale) private var displayScale

    struct ShareItem: Identifiable {
        let id = UUID()
        let image: UIImage
    }

    // Custom init so we can seed currentMeme from the meme passed in
    init(meme: Meme) {
        _currentMeme = State(initialValue: meme)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let uiImage {
                GeometryReader { proxy in
                    let size = proxy.size

                    ZStack {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: size.width)
                            .clipped()

                        VStack {
                            MemeTextOverlay(text: currentMeme.topText.uppercased())
                                .frame(maxWidth: .infinity, alignment: .top)
                                .padding(.top, 16)
                                .padding(.horizontal, 20)

                            Spacer()

                            MemeTextOverlay(text: currentMeme.bottomText.uppercased())
                                .frame(maxWidth: .infinity, alignment: .bottom)
                                .padding(.bottom, 16)
                                .padding(.horizontal, 20)
                        }
                        .padding()
                    }
                }
            } else if let loadError {
                Text(loadError)
                    .foregroundStyle(.white)
                    .padding()
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .navigationTitle("Instameme")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Remix button
            ToolbarItem(placement: .topBarTrailing) {
                if uiImage != nil {
                    Button {
                        isPresentingRemix = true
                    } label: {
                        Image(systemName: "wand.and.stars")
                    }
                    .accessibilityLabel("Remix meme")
                }
            }

            // Share button
            ToolbarItem(placement: .topBarTrailing) {
                if uiImage != nil {
                    Button {
                        renderAndShare()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share meme")
                }
            }
        }
        .sheet(item: $shareItem) { item in
            ActivityView(activityItems: [item.image])
        }
        .sheet(isPresented: $isPresentingRemix) {
            if let uiImage {
                MemeRemixView(
                    baseImage: uiImage,
                    originalMeme: currentMeme
                ) { newMeme in
                    // When the remix saves, switch to the new meme
                    currentMeme = newMeme
                    // If you ever allow changing the image too, you could reload here
                    // Task { await loadImage() }
                }
            }
        }
        .task {
            await loadImage()
        }
    }

    // MARK: - Image loading

    @MainActor
    private func loadImage() async {
        if let image = ImageStore.shared.loadMemeImage(fileName: currentMeme.imageFileName) {
            uiImage = image
        } else {
            loadError = "Failed to load meme image."
            print("MemeDetailView load error: image not found or invalid")
        }
    }

    // MARK: - Sharing / Export
    private func renderAndShare() {
        guard let baseImage = uiImage else { return }

        // 🔒 Safety: always cap the size before burning text & sharing
        let exportBase = baseImage.resized(maxDimension: 1080)

        // Burn current meme text into the resized image
        let rendered = exportBase.withMemeText(
            topText: currentMeme.topText,
            bottomText: currentMeme.bottomText
        )

        shareItem = ShareItem(image: rendered)
    }

    // You can keep this if you want for future use, but it's not used for sharing anymore.
    @ViewBuilder
    private func renderMemeView(baseImage: UIImage) -> some View {
        let imageSize = baseImage.size

        ZStack {
            Image(uiImage: baseImage)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .aspectRatio(imageSize, contentMode: .fit)

            VStack {
                MemeTextOverlay(text: currentMeme.topText.uppercased())
                    .frame(maxWidth: .infinity, alignment: .top)
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                Spacer()

                MemeTextOverlay(text: currentMeme.bottomText.uppercased())
                    .frame(maxWidth: .infinity, alignment: .bottom)
                    .padding(.bottom, 16)
                    .padding(.horizontal, 20)
            }
            .padding()
        }
        .frame(width: imageSize.width, height: imageSize.height)
        .background(Color.black)
    }
}

