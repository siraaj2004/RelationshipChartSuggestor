import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 55))
                .foregroundStyle(.pink)

            Text("Relationship Chart Suggestor")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("Get three reply ideas for your conversation.")
                .multilineTextAlignment(.center)

            Text("Your suggested replies will appear here.")
                .font(.headline)

            Button("Generate Reply Ideas") {
                // Connect your AI reply generator here.
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
        }
        .padding()
    }
}
