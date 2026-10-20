import SwiftUI

struct ContentView: View {
    @State private var testText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Relationship Chart Suggestor")
                        .font(.largeTitle.bold())

                    Text("Enable the keyboard to get relationship chart suggestions while you type in any app.")
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Setup").font(.headline)
                        Label("Open Settings > General > Keyboard > Keyboards", systemImage: "1.circle.fill")
                        Label("Tap Add New Keyboard and choose Relationship Chart", systemImage: "2.circle.fill")
                        Label("Tap it again and turn on Allow Full Access if needed", systemImage: "3.circle.fill")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Open Settings", systemImage: "gearshape.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Try it here").font(.headline)
                        TextField("Tap, then switch to the new keyboard", text: $testText)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding()
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView()
}
