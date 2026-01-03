import SwiftUI
import SwiftData
import PhotosUI
import ScaleCore
import ScaleUI

// MARK: - Photo Gallery View

struct PhotoGalleryView: View {
    let animalID: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var animal: Animal?
    @State private var photos: [AnimalPhoto] = []
    @State private var selectedPhoto: AnimalPhoto?
    @State private var showingAddPhoto = false
    @State private var isLoading = true

    private let columns = [
        GridItem(.flexible(), spacing: ScaleSpacing.xs),
        GridItem(.flexible(), spacing: ScaleSpacing.xs),
        GridItem(.flexible(), spacing: ScaleSpacing.xs)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                if isLoading {
                    ScaleLoadingState(message: "Loading photos...")
                } else if photos.isEmpty {
                    ScaleEmptyState.noPhotos {
                        showingAddPhoto = true
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: ScaleSpacing.xs) {
                            ForEach(photos) { photo in
                                PhotoThumbnail(photo: photo)
                                    .onTapGesture {
                                        selectedPhoto = photo
                                    }
                            }
                        }
                        .padding(ScaleSpacing.md)
                    }
                }
            }
            .navigationTitle("Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddPhoto = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(ThemeManager.shared.currentTheme.primaryAccent)
                    }
                }
            }
            .onAppear {
                loadPhotos()
            }
            .sheet(isPresented: $showingAddPhoto) {
                AddPhotoView(animalID: animalID) {
                    loadPhotos()
                }
            }
            .fullScreenCover(item: $selectedPhoto) { photo in
                PhotoDetailView(photo: photo, allPhotos: photos) {
                    loadPhotos()
                }
            }
        }
    }

    private func loadPhotos() {
        isLoading = true

        let predicate = #Predicate<Animal> { $0.id == animalID }
        let descriptor = FetchDescriptor<Animal>(predicate: predicate)

        if let fetchedAnimal = try? modelContext.fetch(descriptor).first {
            animal = fetchedAnimal
            photos = (fetchedAnimal.photos ?? []).sorted { $0.capturedAt > $1.capturedAt }
        }

        isLoading = false
    }
}

// MARK: - Photo Thumbnail

struct PhotoThumbnail: View {
    let photo: AnimalPhoto
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        Group {
            if let imageData = photo.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.cardBackground)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundStyle(themeManager.currentTheme.textTertiary)
                    )
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.sm))
    }
}

// MARK: - Photo Detail View

struct PhotoDetailView: View {
    let photo: AnimalPhoto
    let allPhotos: [AnimalPhoto]
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var currentIndex: Int = 0
    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                TabView(selection: $currentIndex) {
                    ForEach(Array(allPhotos.enumerated()), id: \.element.id) { index, photo in
                        PhotoFullScreen(photo: photo)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Photo", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(.white)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                if let index = allPhotos.firstIndex(where: { $0.id == photo.id }) {
                    currentIndex = index
                }
            }
            .alert("Delete Photo?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteCurrentPhoto()
                }
            } message: {
                Text("This photo will be permanently deleted.")
            }
        }
    }

    private func deleteCurrentPhoto() {
        guard currentIndex < allPhotos.count else { return }
        let photoToDelete = allPhotos[currentIndex]

        modelContext.delete(photoToDelete)

        do {
            try modelContext.save()
            ScaleHaptics.success()
            onDelete()
            dismiss()
        } catch {
            ScaleToastManager.shared.error("Failed to delete photo")
        }
    }
}

// MARK: - Photo Full Screen

struct PhotoFullScreen: View {
    let photo: AnimalPhoto
    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            if let imageData = photo.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale < 1 {
                                    withAnimation {
                                        scale = 1
                                        lastScale = 1
                                    }
                                }
                            }
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                Rectangle()
                    .fill(Color.cardBackground)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 48))
                            .foregroundStyle(themeManager.currentTheme.textTertiary)
                    )
            }
        }
    }
}

// MARK: - Add Photo View

struct AddPhotoView: View {
    let animalID: UUID
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    private let dataService = DataService.shared

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var caption: String = ""
    @State private var capturedDate: Date = Date()
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                ScrollView {
                    VStack(spacing: ScaleSpacing.lg) {
                        // Photo picker
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            if let selectedImageData,
                               let uiImage = UIImage(data: selectedImageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 250)
                                    .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.lg))
                                    .overlay(
                                        VStack {
                                            Spacer()
                                            HStack {
                                                Spacer()
                                                Image(systemName: "pencil.circle.fill")
                                                    .font(.system(size: 32))
                                                    .foregroundStyle(Color.white)
                                                    .shadow(radius: 4)
                                                    .padding(ScaleSpacing.md)
                                            }
                                        }
                                    )
                            } else {
                                VStack(spacing: ScaleSpacing.md) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 48))
                                        .foregroundStyle(ThemeManager.shared.currentTheme.primaryAccent)

                                    Text("Tap to Select Photo")
                                        .font(.scaleHeadline)
                                        .foregroundStyle(Color.scaleTextPrimary)

                                    Text("Choose from your photo library")
                                        .font(.scaleCaption)
                                        .foregroundStyle(themeManager.currentTheme.textTertiary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .background(Color.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: ScaleRadius.lg))
                                .overlay(
                                    RoundedRectangle(cornerRadius: ScaleRadius.lg)
                                        .stroke(themeManager.currentTheme.borderColor, style: StrokeStyle(lineWidth: 2, dash: [8]))
                                )
                            }
                        }
                        .onChange(of: selectedItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                }
                            }
                        }

                        // Caption
                        ScaleTextField(
                            "Caption",
                            text: $caption,
                            placeholder: "Add a caption (optional)",
                            icon: "text.bubble.fill"
                        )

                        // Date
                        ScaleDatePicker(
                            "Photo Date",
                            date: $capturedDate,
                            helpText: "When was this photo taken?"
                        )

                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, ScaleSpacing.md)
                    .padding(.top, ScaleSpacing.md)
                }
            }
            .navigationTitle("Add Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePhoto()
                    }
                    .font(.headline)
                    .foregroundStyle(selectedImageData != nil ? themeManager.currentTheme.primaryAccent : themeManager.currentTheme.textDisabled)
                    .disabled(selectedImageData == nil || isSaving)
                }
            }
            .scaleToastContainer()
        }
    }

    private func savePhoto() {
        guard let imageData = selectedImageData else { return }

        isSaving = true

        // Fetch the animal using DataService
        guard let animal = try? dataService.fetchAnimal(byID: animalID) else {
            ScaleToastManager.shared.error("Could not find animal")
            isSaving = false
            return
        }

        // Compress image if needed
        let compressedData: Data
        if let uiImage = UIImage(data: imageData) {
            compressedData = uiImage.jpegData(compressionQuality: 0.8) ?? imageData
        } else {
            compressedData = imageData
        }

        // Create photo record
        let photo = AnimalPhoto(imageData: compressedData, capturedAt: capturedDate)

        if !caption.isEmpty {
            photo.caption = caption
        }

        // Set as primary if this is the first photo
        let isFirstPhoto = animal.photos?.isEmpty ?? true
        if isFirstPhoto {
            photo.isPrimary = true
        }

        // Set both sides of the relationship
        photo.animal = animal
        if animal.photos == nil {
            animal.photos = [photo]
        } else {
            animal.photos?.append(photo)
        }

        // Insert photo into context
        dataService.insert(photo)

        do {
            try dataService.save()
            ScaleToastManager.shared.success("Photo saved!")
            ScaleHaptics.success()
            onSave()
            dismiss()
        } catch {
            ScaleToastManager.shared.error("Failed to save photo: \(error.localizedDescription)")
            isSaving = false
        }
    }
}

// MARK: - Previews

#Preview("Photo Gallery") {
    PhotoGalleryView(animalID: UUID())
        .modelContainer(for: [Animal.self, AnimalPhoto.self], inMemory: true)
}

#Preview("Add Photo") {
    AddPhotoView(animalID: UUID()) {}
        .modelContainer(for: [Animal.self, AnimalPhoto.self], inMemory: true)
}
