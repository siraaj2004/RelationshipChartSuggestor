import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "message.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Relationship Chart Suggestor")
                .font(.title2)
                .fontWeight(.bold)

            Text("Your custom keyboard project is ready to build.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Text("Next: enable and test the keyboard.")
                .font(.body)
        }
        .padding()
    }
}
