import SwiftUI
import PhotosUI

struct PhotoAttachView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: AddPersonViewModel
    let onComplete: () -> Void

    @State private var selectedItem: PhotosPickerItem?
    @State private var showingCamera = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Current visual preview
            currentVisual
                .frame(width: 150, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 5)

            Text("Photos are optional. Sketches work great too.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                // Photo picker
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)

                // Camera button
                Button {
                    showingCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)

                // Skip button
                Button {
                    onComplete()
                } label: {
                    Text("Skip - use sketch")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .navigationTitle("Add Photo")
        .onChange(of: selectedItem) { _, newValue in
            Task {
                await loadPhoto(from: newValue)
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView { image in
                Task {
                    await savePhoto(image)
                }
            }
        }
    }

    @ViewBuilder
    private var currentVisual: some View {
        if let photoPath = viewModel.photoPath,
           let url = fileURL(for: photoPath),
           let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else if let sketchPath = viewModel.sketchPath,
                  let url = fileURL(for: sketchPath),
                  let data = try? Data(contentsOf: url),
                  let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.2))
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)
                }
        }
    }

    private func fileURL(for path: String) -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(path)
    }

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await savePhoto(uiImage)
            }
        } catch {
            print("Failed to load photo: \(error)")
        }
    }

    private func savePhoto(_ image: UIImage) async {
        await viewModel.savePhoto(image)
        onComplete()
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void

        init(onCapture: @escaping (UIImage) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    NavigationStack {
        PhotoAttachView(
            viewModel: AddPersonViewModel(
                modelContext: try! ModelContainer(for: Person.self).mainContext,
                fileService: FileService(),
                audioService: AudioService(fileService: FileService()),
                transcriptService: TranscriptService(),
                sketchService: SketchService(
                    fileService: FileService(),
                    keywordParser: KeywordParser(),
                    renderer: SketchRenderer()
                )
            ),
            onComplete: {}
        )
    }
}
