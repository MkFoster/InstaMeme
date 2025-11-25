import SwiftUI
import SwiftData

struct MemeRemixView: View {
    let baseImage: UIImage
    let originalMeme: Meme
    let onSave: (Meme) -> Void   // 👈 callback to detail view

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var topText: String
    @State private var bottomText: String

    @State private var isSaving = false
    @State private var errorMessage: String?

    @State private var isSuggesting = false
    @State private var captionSuggestions: [String] = []
    @State private var aiErrorMessage: String?

    init(baseImage: UIImage, originalMeme: Meme, onSave: @escaping (Meme) -> Void) {
        self.baseImage = baseImage
        self.originalMeme = originalMeme
        self.onSave = onSave
        _topText = State(initialValue: originalMeme.topText)
        _bottomText = State(initialValue: originalMeme.bottomText)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Preview
                ZStack {
                    Image(uiImage: baseImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack {
                        MemeTextOverlay(text: topText.uppercased())
                            .frame(maxWidth: .infinity, alignment: .top)
                            .padding(.top, 12)
                            .padding(.horizontal, 16)

                        Spacer()

                        MemeTextOverlay(text: bottomText.uppercased())
                            .frame(maxWidth: .infinity, alignment: .bottom)
                            .padding(.bottom, 12)
                            .padding(.horizontal, 16)
                    }
                    .padding()
                }
                .padding(.horizontal)

                // Caption fields
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Top text", text: $topText)
                        .textFieldStyle(.roundedBorder)

                    TextField("Bottom text", text: $bottomText)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                // AI suggestions
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        Task { await suggestCaptions() }
                    } label: {
                        if isSuggesting {
                            ProgressView()
                        } else {
                            Label("Suggest Captions", systemImage: "wand.and.stars")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSuggesting)

                    if !captionSuggestions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(captionSuggestions, id: \.self) { caption in
                                    Button {
                                        bottomText = caption
                                    } label: {
                                        Text(caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.blue.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    if let aiErrorMessage {
                        Text(aiErrorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                Spacer()

                Button {
                    Task { await saveMeme() }
                } label: {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Save Remix")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .disabled((topText.isEmpty && bottomText.isEmpty) || isSaving)
            }
            .padding(.top)
            .navigationTitle("Remix Meme")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - AI

    @MainActor
    private func suggestCaptions() async {
        isSuggesting = true
        aiErrorMessage = nil

        do {
            let captions = try await MemeAIService.shared.suggestCaptions(for: baseImage)
            captionSuggestions = captions
        } catch let error as AIServiceError {
            switch error {
            case .invalidImage:
                aiErrorMessage = "Couldn't read the image."
            }
        } catch {
            aiErrorMessage = "Couldn't generate suggestions."
            print("AI caption error (remix): \(error)")
        }

        isSuggesting = false
    }

    // MARK: - Save

    @MainActor
    private func saveMeme() async {
        isSaving = true
        errorMessage = nil

        let memeId = UUID()

        do {
            // Resize and save as a brand new meme image
            let resized = baseImage.resized(maxDimension: 1080)
            let fileName = try ImageStore.shared.saveMemeImage(resized, id: memeId)

            let newMeme = Meme(
                id: memeId,
                imageFileName: fileName,
                topText: topText,
                bottomText: bottomText
            )

            context.insert(newMeme)
            try context.save()

            // Tell the detail view to switch to the new meme
            onSave(newMeme)

            dismiss()
        } catch {
            print("Failed to save remixed meme: \(error)")
            errorMessage = "Failed to save meme."
        }

        isSaving = false
    }
}

