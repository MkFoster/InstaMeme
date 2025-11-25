import SwiftUI
import SwiftData
import PhotosUI

struct CameraMemeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    @State private var topText: String = ""
    @State private var bottomText: String = ""

    @State private var isSaving = false
    @State private var errorMessage: String?
    
    @State private var isShowingCamera = false
    
    @State private var isSuggesting = false
    @State private var captionSuggestions: [String] = []
    @State private var aiErrorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Image picker / preview
                if let uiImage = selectedImage {
                    ZStack {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Top / bottom text overlays
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
                    .frame(maxHeight: 320)
                } else {
                    VStack(spacing: 16) {
                        Button {
                            isShowingCamera = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                Text("Take Photo")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .background(Color.blue.opacity(0.9))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)

                        Text("or")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        PhotosPicker(
                            selection: $selectedItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            VStack {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 30))
                                    .padding(.bottom, 4)
                                Text("Select from Photos")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }
                    }
                }

                // Caption fields
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Top text", text: $topText)
                        .textFieldStyle(.roundedBorder)

                    TextField("Bottom text", text: $bottomText)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                // AI error message (separate from generic save/load error)
                if let aiErrorMessage {
                    Text(aiErrorMessage)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .padding(.horizontal)
                }

                // AI caption suggestions
                if !captionSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suggestions")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(captionSuggestions, id: \.self) { suggestion in
                                    Button {
                                        // For now, drop suggestion into bottom text
                                        bottomText = suggestion
                                    } label: {
                                        Text(suggestion)
                                            .font(.footnote)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.secondary.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // Suggest Caption button
                Button {
                    Task {
                        await suggestCaptions()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isSuggesting {
                            ProgressView()
                            Text("Generating…")
                        } else {
                            Image(systemName: "sparkles")
                            Text("Suggest Caption")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
                .disabled(selectedImage == nil || isSaving || isSuggesting)

                Spacer()

                // Save Meme button
                Button {
                    Task {
                        await saveMeme()
                    }
                } label: {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Save Meme")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .disabled(selectedImage == nil || (topText.isEmpty && bottomText.isEmpty) || isSaving)
            }
            .padding(.top)
            .navigationTitle("New InstaMeme")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    await loadSelectedImage(from: newItem)
                }
            }
        }
        .sheet(isPresented: $isShowingCamera) {
            CameraCaptureView(image: $selectedImage)
        }
    }

    // MARK: - Helpers
    private func loadSelectedImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    self.selectedImage = image
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load image."
            }
            print("Error loading image: \(error)")
        }
    }

    @MainActor
    private func saveMeme() async {
        guard let image = selectedImage else {
            errorMessage = "Please pick an image."
            return
        }

        isSaving = true
        errorMessage = nil

        let memeId = UUID()

        do {
            // Resize before saving to reduce storage + performance load
            let resized = image.resized(maxDimension: 1080)
            let fileName = try ImageStore.shared.saveMemeImage(resized, id: memeId)

            let meme = Meme(
                id: memeId,
                imageFileName: fileName,
                topText: topText,
                bottomText: bottomText
            )

            context.insert(meme)
            try context.save()

            dismiss()
        } catch {
            print("Failed to save meme: \(error)")
            errorMessage = "Failed to save meme."
        }

        isSaving = false
    }

    @MainActor
    private func suggestCaptions() async {
        guard let image = selectedImage else { return }

        isSuggesting = true
        aiErrorMessage = nil

        do {
            let captions = try await MemeAIService.shared.suggestCaptions(for: image)
            captionSuggestions = captions
        } catch let error as AIServiceError {
            switch error {
            case .invalidImage:
                aiErrorMessage = "Couldn't read the image."
            }
        } catch {
            aiErrorMessage = "Couldn't generate suggestions."
            print("AI caption error: \(error)")
        }

        isSuggesting = false
    }

}

