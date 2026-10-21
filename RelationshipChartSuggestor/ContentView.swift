import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var chat = ""
    @State private var photo: PhotosPickerItem?
    @State private var scanning = false
    @State private var errorText: String?

    var body: some View {
        let language = LanguageDetector.detect(chat).language
        let suggestions = ChartSuggester.suggest(for: chat, language: language)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Paste part of a chat, or scan a chat screenshot from any app.")
                        .font(.subheadline).foregroundStyle(.secondary)

                    TextEditor(text: $chat)
                        .frame(height: 130)
                        .padding(8)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

                    HStack {
                        PhotosPicker(selection: $photo, matching: .images) {
                            Label("Scan screenshot", systemImage: "text.viewfinder")
                        }
                        if scanning { ProgressView().padding(.leading, 6) }
                        Spacer()
                        Button("Clear") { chat = ""; errorText = nil }
                    }

                    if let errorText {
                        Text(errorText).font(.footnote).foregroundStyle(.red)
                    }

                    if !chat.isEmpty {
                        Label("Detected: \(language.rawValue)", systemImage: "globe")
                            .font(.headline)

                        if suggestions.isEmpty {
                            Text("Not enough text to suggest a chart. Add a longer part of the chat.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }

                        ForEach(suggestions) { s in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(s.chart.rawValue).font(.headline)
                                Text(s.chart.purpose).font(.subheadline)
                                Text(s.reason).font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    GroupBox("Use the keyboard in any chat app") {
                        Text("Settings › General › Keyboard › Keyboards › Add New Keyboard › Chart Keyboard. Tap it and turn on Allow Full Access (needed to read the clipboard). In a chat, copy a message or a screenshot, switch with 🌐, then tap Paste chat. Everything is processed on your device and nothing is uploaded.")
                            .font(.footnote)
                    }
                }
                .padding()
            }
            .navigationTitle("Relationship Charts")
            .onChange(of: photo) { item in
                guard let item else { return }
                Task {
                    defer { photo = nil }          // lets you pick the same screenshot again
                    scanning = true
                    errorText = nil
                    defer { scanning = false }
                    do {
                        guard let data = try await item.loadTransferable(type: Data.self) else {
                            throw OCRError.invalidImage
                        }
                        chat = try await OCRService.extractChatText(from: data)
                    } catch {
                        errorText = error.localizedDescription
                    }
                }
            }
        }
    }
}
