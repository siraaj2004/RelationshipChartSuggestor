import UIKit

final class KeyboardViewController: UIInputViewController {
    private let languageLabel = UILabel()
    private let suggestionStack = UIStackView()
    private let globeButton = UIButton(type: .system)
    private var pastedText: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.heightAnchor.constraint(equalToConstant: 250).isActive = true

        languageLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        languageLabel.textColor = .secondaryLabel
        languageLabel.text = "Type or paste a chat"

        let paste = makeSmallButton(title: "Paste chat", action: #selector(pasteTapped))
        let delete = makeSmallButton(title: "⌫", action: #selector(deleteTapped))
        globeButton.setTitle("🌐", for: .normal)
        globeButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        globeButton.isHidden = !needsInputModeSwitchKey

        let header = UIStackView(arrangedSubviews: [globeButton, languageLabel, UIView(), paste, delete])
        header.axis = .horizontal
        header.spacing = 12
        header.alignment = .center

        suggestionStack.axis = .vertical
        suggestionStack.spacing = 6
        suggestionStack.distribution = .fillEqually

        let root = UIStackView(arrangedSubviews: [header, suggestionStack])
        root.axis = .vertical
        root.spacing = 8
        root.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root)
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])
        refresh()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        refresh()
    }

    private func makeSmallButton(title: String, action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }

    @objc private func pasteTapped() {
        guard hasFullAccess, let s = UIPasteboard.general.string, !s.isEmpty else {
            languageLabel.text = "Enable Allow Full Access, then copy a message"
            return
        }
        pastedText = s
        refresh()
    }

    @objc private func deleteTapped() {
        textDocumentProxy.deleteBackward()
    }

    private func refresh() {
        let typed = (textDocumentProxy.documentContextBeforeInput ?? "")
            + (textDocumentProxy.documentContextAfterInput ?? "")
        let source = typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? (pastedText ?? "") : typed
        guard !source.isEmpty else { return }

        let (lang, suggestions) = ChartSuggester.analyze(source)
        languageLabel.text = "Detected: \(lang.rawValue)"

        suggestionStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for s in suggestions {
            var config = UIButton.Configuration.tinted()
            config.title = s.text
            config.baseForegroundColor = .label
            config.titleAlignment = .leading
            config.titleLineBreakMode = .byTruncatingTail
            config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
            let b = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
                self?.textDocumentProxy.insertText(s.text)
                self?.pastedText = nil
            })
            b.contentHorizontalAlignment = .leading
            suggestionStack.addArrangedSubview(b)
        }
    }
}
