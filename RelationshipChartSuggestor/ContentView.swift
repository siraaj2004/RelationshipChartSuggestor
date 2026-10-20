import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var pickerItem: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var scannedText = ""
    @State private var result: LanguageResult?
    @State private var suggestions: [ChartSuggestion] = []
    @State private var isScanning = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label("Choose chat screenshot", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if isScanning {
                        HStack { ProgressView(); Text("Scanning...") }
                    }

                    if let errorMessage {
                        Text(errorMessage).foregroundColor(.red)
                    }

                    if let result {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Detected language").font(.headline)
                            Text(result.language.rawValue).font(.title2.bold())
                            Text("Urdu: \(result.urduScore)  Telugu: \(result.teluguScore)  English: \(result.englishScore)")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }

                    if !suggestions.isEmpty {
                        Text("Suggested charts").font(.headline)
                        ForEach(suggestions) { s in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: s.icon)
                                    .font(.title3)
                                    .frame(width: 28)
                                VStack(alignment: .leading) {
                                    Text(s.title).font(.subheadline.bold())
                                    Text(s.reason).font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    if !scannedText.isEmpty {
                        DisclosureGroup("Scanned text") {
                            Text(scannedText)
                                .font(.footnote)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Relationship Chart")
        }
        .task(id: pickerItem) {
            guard let pickerItem else { return }
            await scan(pickerItem)
        }
    }

    private func scan(_ item: PhotosPickerItem) async {
        isScanning = true
        errorMessage = nil
        result = nil
        suggestions = []
        scannedText = ""
        defer { isScanning = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let ui = UIImage(data: data) else {
                errorMessage = "Could not load that image."
                return
            }
            image = ui

            let text = try await OCRService.extractText(from: ui)
            scannedText = text

            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessage = "No text found. Try a clearer, higher-resolution screenshot."
                return
            }

            let detected = LanguageDetector.detect(text)
            result = detected
            suggestions = ChartSuggester.suggest(for: text, language: detected.language)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
