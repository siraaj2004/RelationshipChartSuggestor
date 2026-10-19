import SwiftUI

@main
struct RelationshipChartSuggestorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "message.circle.fill")
                .font(.system(size: 55))
                .foregroundColor(.blue)

            Text("Relationship Chart Suggestor")
                .font(.title2)
                .fontWeight(.bold)

            Text("Your app is ready.")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
