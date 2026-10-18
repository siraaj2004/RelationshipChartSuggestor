import SwiftUI
import Charts

// MARK: - Model

enum VariableType: String, CaseIterable, Identifiable {
    case numeric = "Numeric"
    case categorical = "Categorical"
    case time = "Time / Date"
    var id: String { rawValue }
}

struct ChartSuggestion {
    let name: String
    let reason: String
    let icon: String
}

func suggestChart(x: VariableType, y: VariableType) -> ChartSuggestion {
    switch (x, y) {
    case (.numeric, .numeric):
        return .init(name: "Scatter Plot",
                     reason: "Shows correlation between two numeric variables.",
                     icon: "chart.dots.scatter")
    case (.time, .numeric), (.numeric, .time):
        return .init(name: "Line Chart",
                     reason: "Best for showing how a value changes over time.",
                     icon: "chart.xyaxis.line")
    case (.categorical, .numeric), (.numeric, .categorical):
        return .init(name: "Bar Chart",
                     reason: "Compares a numeric value across categories.",
                     icon: "chart.bar")
    case (.categorical, .categorical):
        return .init(name: "Stacked Bar / Heatmap",
                     reason: "Shows how two categories overlap or relate.",
                     icon: "square.grid.3x3")
    case (.time, .categorical), (.categorical, .time):
        return .init(name: "Timeline / Stacked Area",
                     reason: "Shows category changes across time.",
                     icon: "chart.line.uptrend.xyaxis")
    case (.time, .time):
        return .init(name: "Gantt / Timeline",
                     reason: "Shows spans or events between dates.",
                     icon: "calendar")
    }
}

// MARK: - Preview data

struct SamplePoint: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
}

private let samplePoints: [SamplePoint] = (1...12).map {
    SamplePoint(x: Double($0), y: Double($0) * 2 + Double.random(in: -3...3))
}

// MARK: - View

struct ContentView: View {
    @State private var xType: VariableType = .numeric
    @State private var yType: VariableType = .numeric

    private var suggestion: ChartSuggestion { suggestChart(x: xType, y: yType) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Variables") {
                    Picker("X variable", selection: $xType) {
                        ForEach(VariableType.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Y variable", selection: $yType) {
                        ForEach(VariableType.allCases) { Text($0.rawValue).tag($0) }
                    }
                }

                Section("Suggested Chart") {
                    HStack(spacing: 12) {
                        Image(systemName: suggestion.icon)
                            .font(.largeTitle)
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(suggestion.name).font(.headline)
                            Text(suggestion.reason)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Example") {
                    Chart(samplePoints) { p in
                        PointMark(x: .value("X", p.x), y: .value("Y", p.y))
                    }
                    .frame(height: 200)
                }
            }
            .navigationTitle("Chart Suggestor")
        }
    }
}

#Preview {
    ContentView()
}
