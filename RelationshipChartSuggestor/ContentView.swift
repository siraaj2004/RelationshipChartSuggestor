import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var vm = ChatViewModel()
    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label("Select chat screenshot", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if vm.isLoading { ProgressView("Scanning…").frame(maxWidth: .infinity) }
                    if let err = vm.errorMessage { Text(err).foregroundStyle(.red) }

                    if let img = vm.image {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if !vm.lines.isEmpty {
                        HStack {
                            Label(vm.language.rawValue, systemImage: "globe")
                            Spacer()
                            Text("Intent: \(vm.intent.rawValue)").foregroundStyle(.secondary)
                        }
                        .font(.subheadline)

                        Text("Suggested replies").font(.headline)
                        ForEach(vm.suggestions) { s in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(s.tone).font(.caption).foregroundStyle(.secondary)
                                Text(s.text)
                                Button("Copy") { UIPasteboard.general.string = s.text }
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        DisclosureGroup("Scanned text") {
                            Text(vm.lines.joined(separator: "\n"))
                                .font(.footnote)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Relationship Suggestor")
        }
        .onChange(of: pickerItem) { _, newItem in
            Task { await vm.load(newItem) }
        }
    }
}
