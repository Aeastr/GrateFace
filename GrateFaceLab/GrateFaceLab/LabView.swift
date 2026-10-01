import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct LabView: View {
    @StateObject private var model = LabModel()
    @State private var artworkItem: PhotosPickerItem?
    @State private var isImportingTemplate = false
    @State private var isImportingMask = false

    private var watchFaceType: UTType { UTType(filenameExtension: "watchface") ?? .data }

    var body: some View {
        NavigationStack {
            Form {
                Section("Template · optional") {
                    Button(model.templateName ?? "Choose another Photos face") {
                        isImportingTemplate = true
                    }
                    if model.templateName != nil {
                        Button("Use built-in face") { model.useBuiltInTemplate() }
                    }
                    Text("The built-in face is ready. Choose an export only to explore a different Photos layout or style; the lab replaces its photos and masks.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if let report = model.archiveReport {
                    Section("Inside the face") {
                        if let bundle = report.bundleIdentifier {
                            LabeledContent("Face bundle", value: bundle)
                        }
                        ForEach(report.entries) { entry in
                            LabeledContent(entry.path, value: entry.isDirectory
                                           ? "Folder" : ByteCountFormatter.string(fromByteCount: entry.uncompressedBytes,
                                                                                     countStyle: .file))
                                .font(.footnote)
                        }
                    }
                }
                Section("Artwork") {
                    PhotosPicker(selection: $artworkItem, matching: .images) {
                        Label(model.artwork == nil ? "Choose photo" : "Change photo", systemImage: "photo")
                    }
                    if let artwork = model.artwork {
                        Image(uiImage: artwork)
                            .resizable().scaledToFit().frame(maxHeight: 240)
                            .accessibilityLabel("Selected artwork")
                    }
                }
                Section("Subject mask · optional") {
                    Button(model.mask == nil ? "Choose grayscale PNG" : "Change mask") {
                        isImportingMask = true
                    }
                    Button("Make test mask") { model.makeTestMask() }
                    if let mask = model.mask {
                        Image(uiImage: mask)
                            .resizable().scaledToFit().frame(maxHeight: 160)
                            .accessibilityLabel("Selected foreground mask")
                        Button("Remove mask", role: .destructive) { model.clearMask() }
                    }
                    Text("White passes in front of the clock; black stays behind. The mask must match the artwork's pixel size.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Preview shape") {
                    LabeledContent("Corner reach", value: "\(Int(model.previewCornerRadius))")
                    Slider(value: $model.previewCornerRadius, in: 140...290, step: 2)
                        .accessibilityLabel("Preview corner reach")
                    Text("Adjusts the rounded photo corners in both preview images. The black bezel and gray rim follow the same curve.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Experiment") {
                    Button("Generate face") { model.generate() }
                        .buttonStyle(.borderedProminent)
                    if let url = model.generatedURL {
                        Button("Add to Watch") { Task { await model.addToWatch() } }
                        ShareLink(item: url) { Label("Share face file", systemImage: "square.and.arrow.up") }
                    }
                    Text(model.status).font(.footnote).textSelection(.enabled)
                }
            }
            .navigationTitle("GrateFace Lab")
            .fileImporter(isPresented: $isImportingTemplate, allowedContentTypes: [watchFaceType]) { result in
                switch result {
                case .success(let url): model.importTemplate(url)
                case .failure(let error): model.status = error.localizedDescription
                }
            }
            .fileImporter(isPresented: $isImportingMask, allowedContentTypes: [.png, .image]) { result in
                switch result {
                case .success(let url): model.importMask(url)
                case .failure(let error): model.status = error.localizedDescription
                }
            }
            .onChange(of: artworkItem) { _, item in
                Task { await model.importArtwork(item) }
            }
        }
    }
}
