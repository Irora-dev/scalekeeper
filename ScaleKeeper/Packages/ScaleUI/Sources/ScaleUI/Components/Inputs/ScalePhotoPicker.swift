import SwiftUI
import PhotosUI

// MARK: - Scale Photo Picker

public struct ScalePhotoPicker: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    let title: String
    @Binding var selectedImage: UIImage?
    var placeholder: String = "Add Photo"
    var isRequired: Bool = false
    var errorMessage: String? = nil

    @State private var showingOptions = false
    @State private var showingCamera = false
    @State private var showingLibrary = false
    @State private var selectedItem: PhotosPickerItem? = nil

    public init(
        _ title: String,
        selectedImage: Binding<UIImage?>,
        placeholder: String = "Add Photo",
        isRequired: Bool = false,
        errorMessage: String? = nil
    ) {
        self.title = title
        self._selectedImage = selectedImage
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.errorMessage = errorMessage
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.xs) {
            // Label
            HStack(spacing: ScaleSpacing.xs) {
                Text(title)
                    .font(Font.scaleSubheadline)
                    .foregroundStyle(themeManager.currentTheme.textSecondary)

                if isRequired {
                    Text("*")
                        .font(Font.scaleSubheadline)
                        .foregroundStyle(Color.scaleError)
                }
            }

            // Photo display/picker
            Button {
                showingOptions = true
                ScaleHaptics.light()
            } label: {
                if let image = selectedImage {
                    // Show selected image
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))

                        // Remove button
                        Button {
                            selectedImage = nil
                            ScaleHaptics.light()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.white)
                                .shadow(radius: 2)
                        }
                        .padding(ScaleSpacing.sm)
                    }
                } else {
                    // Empty state
                    VStack(spacing: ScaleSpacing.sm) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(themeManager.currentTheme.textTertiary)

                        Text(placeholder)
                            .font(Font.scaleBody)
                            .foregroundStyle(themeManager.currentTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(themeManager.currentTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: ScaleRadius.md)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundStyle(borderColor)
                    )
                }
            }
            .confirmationDialog("Select Photo", isPresented: $showingOptions) {
                Button("Take Photo") {
                    showingCamera = true
                }
                Button("Choose from Library") {
                    showingLibrary = true
                }
                if selectedImage != nil {
                    Button("Remove Photo", role: .destructive) {
                        selectedImage = nil
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(image: $selectedImage)
                    .ignoresSafeArea()
            }
            .photosPicker(
                isPresented: $showingLibrary,
                selection: $selectedItem,
                matching: .images
            )
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            selectedImage = image
                            ScaleHaptics.success()
                        }
                    }
                }
            }

            // Error text
            if let error = errorMessage {
                HStack(spacing: ScaleSpacing.xs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text(error)
                        .font(Font.scaleCaption)
                }
                .foregroundStyle(Color.scaleError)
            }
        }
    }

    private var borderColor: Color {
        if errorMessage != nil {
            return Color.scaleError
        } else {
            return themeManager.currentTheme.borderColor
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                ScaleHaptics.success()
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Scale Photo Grid (for multi-select)

public struct ScalePhotoGrid: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    let title: String
    @Binding var selectedImages: [UIImage]
    var maxPhotos: Int = 10
    var columns: Int = 3

    @State private var showingPicker = false
    @State private var selectedItems: [PhotosPickerItem] = []

    public init(
        _ title: String,
        selectedImages: Binding<[UIImage]>,
        maxPhotos: Int = 10,
        columns: Int = 3
    ) {
        self.title = title
        self._selectedImages = selectedImages
        self.maxPhotos = maxPhotos
        self.columns = columns
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: ScaleSpacing.sm), count: columns)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: ScaleSpacing.sm) {
            HStack {
                Text(title)
                    .font(Font.scaleSubheadline)
                    .foregroundStyle(themeManager.currentTheme.textSecondary)

                Spacer()

                Text("\(selectedImages.count)/\(maxPhotos)")
                    .font(Font.scaleCaption)
                    .foregroundStyle(themeManager.currentTheme.textTertiary)
            }

            LazyVGrid(columns: gridColumns, spacing: ScaleSpacing.sm) {
                // Existing photos
                ForEach(selectedImages.indices, id: \.self) { index in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: selectedImages[index])
                            .resizable()
                            .scaledToFill()
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.sm))

                        Button {
                            selectedImages.remove(at: index)
                            ScaleHaptics.light()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.white)
                                .shadow(radius: 2)
                        }
                        .padding(4)
                    }
                }

                // Add button
                if selectedImages.count < maxPhotos {
                    Button {
                        showingPicker = true
                    } label: {
                        VStack(spacing: ScaleSpacing.xs) {
                            Image(systemName: "plus")
                                .font(.system(size: 24))
                            Text("Add")
                                .font(Font.scaleCaption)
                        }
                        .foregroundStyle(themeManager.currentTheme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(themeManager.currentTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.sm))
                        .overlay(
                            RoundedRectangle(cornerRadius: ScaleRadius.sm)
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                .foregroundStyle(themeManager.currentTheme.borderColor)
                        )
                    }
                }
            }
        }
        .photosPicker(
            isPresented: $showingPicker,
            selection: $selectedItems,
            maxSelectionCount: maxPhotos - selectedImages.count,
            matching: .images
        )
        .onChange(of: selectedItems) { _, newItems in
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            if selectedImages.count < maxPhotos {
                                selectedImages.append(image)
                            }
                        }
                    }
                }
                await MainActor.run {
                    selectedItems = []
                    ScaleHaptics.success()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        ScaleBackground()

        ScrollView {
            VStack(spacing: ScaleSpacing.lg) {
                ScalePhotoPicker(
                    "Primary Photo",
                    selectedImage: .constant(nil),
                    placeholder: "Tap to add a photo"
                )

                ScalePhotoGrid(
                    "Additional Photos",
                    selectedImages: .constant([]),
                    maxPhotos: 6
                )
            }
            .padding()
        }
    }
}
