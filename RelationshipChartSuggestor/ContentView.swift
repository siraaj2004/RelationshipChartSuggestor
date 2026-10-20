import SwiftUI
import PhotosUI
import Vision

struct ContentView: View {
    @State private var chat = ""
    @State private var photo: PhotosPickerItem?
    @State private var copiedID: UUID?

    private var language: ChatLanguage { LanguageDetector.detect(chat) }
    private var suggestions: [ChartSuggestion] { ChartSuggester.suggest(for: chat, language: language) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Paste their message, or scan a chat screenshot")
                        .font(.subheadline).foregroundStyle(.secondary)

                    TextEditor(text: $chat)
                        .frame(height: 130)
                        .padding(8)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

                    HStack {
                        PhotosPicker(selection: $photo, matching: .images) {
                            Label("Scan screenshot", systemImage: "text.viewfinder")
                        }
                        Spacer()
                        Button("Clear") { chat = "" }
                    }

                    if !chat.isEmpty {
                        Label("Detected: \(language.rawValue)", systemImage: "globe")
                            .font(.headline)

                        ForEach(suggestions) { s in
                            Button {
                                UIPasteboard.general.string = s.text
                                copiedID = s.id
                            } label: {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(s.label).font(.caption).foregroundStyle(.secondary)
                                        Text(s.text).multilineTextAlignment(.leading)
                                    }
                                    Spacer()
                                    Image(systemName: copiedID == s.id ? "checkmark" : "doc.on.doc")
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    GroupBox("Enable the keyboard") {
                        Text("Settings › General › Keyboard › Keyboards › Add New Keyboard › RelationshipChart. Then tap it and turn on Allow Full Access (needed for the Paste button). Use 🌐 to switch keyboards.")
                            .font(.footnote)
                    }
                }
                .padding()
            }
            .navigationTitle("Chat Suggestor")
            .onChange(of: photo) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data)?.cgImage {
                        chat = await recognizeText(in: image)
                    }
                }
            }
        }
    }

    private func recognizeText(in image: CGImage) async -> String {
        await Task.detached {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false   // keeps Roman Urdu/Telugu intact
            try? VNImageRequestHandler(cgImage: image).perform([request])
            let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
            return lines.suffix(8).joined(separator: "\n")   // last few messages
        }.value
    }
}
