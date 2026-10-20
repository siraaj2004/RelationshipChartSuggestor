import Foundation

struct ChartSuggester {
    struct Result {
        let language: String
        let charts: [String]
    }

    static let allCharts = ["Sociogram", "Genogram", "Ecomap", "Org Chart", "Network Graph"]
    private static var cache: [String: Result] = [:]

    static func suggest(text: String, completion: @escaping (Result?) -> Void) {
        let input = String(text.suffix(600)).trimmingCharacters(in: .whitespacesAndNewlines)
        guard input.count >= 3 else { completion(nil); return }
        if let hit = cache[input] { completion(hit); return }

        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            completion(nil); return
        }

        let prompt = """
        Text typed in a chat (may be English, Roman Telugu, Roman Urdu/Dakhni, or mixed):
        \"\"\"\(input)\"\"\"

        1. Detect the language.
        2. Decide which relationship chart best fits what the person is talking about:
        Sociogram (friends/group dynamics), Genogram (family), Ecomap (person's links to school, work, community, support systems), Org Chart (work hierarchy), Network Graph (wide social connections).
        Reply with JSON only, no other text:
        {"language":"<name>","charts":["<best>","<2nd>","<3rd>","<4th>","<5th>"]}
        Use exactly these chart names: Sociogram, Genogram, Ecomap, Org Chart, Network Graph.
        """

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 6
        request.setValue(Secrets.anthropicKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body: [String: Any] = [
            "model": "claude-haiku-5-5",
            "max_tokens": 120,
            "messages": [["role": "user", "content": prompt]]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = root["content"] as? [[String: Any]],
                  let text = content.first?["text"] as? String,
                  let start = text.firstIndex(of: "{"),
                  let end = text.lastIndex(of: "}"),
                  let jsonData = String(text[start...end]).data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
            else { completion(nil); return }

            let language = parsed["language"] as? String ?? "Unknown"
            var charts = (parsed["charts"] as? [String] ?? []).filter { allCharts.contains($0) }
            for c in allCharts where !charts.contains(c) { charts.append(c) }

            let result = Result(language: language, charts: Array(charts.prefix(5)))
            cache[input] = result
            completion(result)
        }.resume()
    }
}
