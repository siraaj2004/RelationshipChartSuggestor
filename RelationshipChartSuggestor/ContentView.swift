import SwiftUI

struct ContentView: View {
    @State private var testText = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Relationship Chart Suggestor")
                        .font(.largeTitle.bold())

                    Text("Enable the keyboard in 4 steps:")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        StepRow(number: 1, text: "Open Settings → General → Keyboard → Keyboards")
                        StepRow(number: 2, text: "Tap Add New Keyboard…")
                        StepRow(number: 3, text: "Choose Relationship Chart Suggestor under Third-Party Keyboards")
                        StepRow(number: 4, text: "In any text field, hold the 🌐 key and select this keyboard")
                    }

                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Open Settings")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    Divider()

                    Text("Test the keyboard here:")
                        .font(.headline)

                    TextField("Tap here and switch keyboards…", text: $testText)
                        .textFieldStyle(.roundedBorder)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
}

struct StepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Color.blue))
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
