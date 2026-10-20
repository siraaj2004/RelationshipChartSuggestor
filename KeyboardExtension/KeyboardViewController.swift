import UIKit

final class KeyboardViewController: UIInputViewController {

    private let languageLabel = UILabel()
    private let stack = UIStackView()
    private var current: [ChartSuggestion] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        languageLabel.font = .systemFont(ofSize: 13, weight: .medium)
        languageLabel.textColor = .secondaryLabel
        languageLabel.text = "Type to get chart suggestions"
        languageLabel.translatesAutoresizingMaskIntoConstraints = false

        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        let nextKey = UIButton(type: .system)
        nextKey.setTitle("🌐", for: .normal)
        nextKey.titleLabel?.font = .systemFont(ofSize: 22)
        nextKey.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        nextKey.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(languageLabel)
        view.addSubview(stack)
        view.addSubview(nextKey)

        NSLayoutConstraint.activate([
            languageLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            languageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            languageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            stack.topAnchor.constraint(equalTo: languageLabel.bottomAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            nextKey.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            nextKey.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            nextKey.topAnchor.constraint(greaterThanOrEqualTo: stack.bottomAnchor, constant: 8),

            view.heightAnchor.constraint(equalToConstant: 260)
        ])
        refresh()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        refresh()
    }

    private func fullText() -> String {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let after = textDocumentProxy.documentContextAfterInput ?? ""
        return before + " " + after
    }

    private func refresh() {
        let text = fullText()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        guard !trimmed.isEmpty else {
            languageLabel.text = "Type to get chart suggestions"
            return
        }

        let language = LanguageDetector.detect(text)
        languageLabel.text = "Detected: \(language.rawValue)"
        current = ChartSuggestor.suggest(for: text)

        for (index, s) in current.prefix(3).enumerated() {
            let b = UIButton(type: .system)
            b.setTitle("\(s.chart.rawValue) - \(s.chart.purpose)", for: .normal)
            b.contentHorizontalAlignment = .leading
            b.backgroundColor = .secondarySystemBackground
            b.layer.cornerRadius = 10
            b.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
            b.tag = index
            b.addTarget(self, action: #selector(tapSuggestion(_:)), for: .touchUpInside)
            stack.addArrangedSubview(b)
        }
    }

    @objc private func tapSuggestion(_ sender: UIButton) {
        guard current.indices.contains(sender.tag) else { return }
        textDocumentProxy.insertText(current[sender.tag].chart.rawValue + " ")
    }
}
