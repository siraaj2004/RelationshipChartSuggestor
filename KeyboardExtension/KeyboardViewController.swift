import UIKit

/// A keyboard can't see other apps' chats or the screen. It can only see:
///  1. the text in the field you are typing in, and
///  2. the clipboard (needs "Allow Full Access").
/// So the flow is: copy a message (or copy a screenshot), tap "Paste chat", get chart suggestions.
final class KeyboardViewController: UIInputViewController {

    private let statusLabel = UILabel()
    private let pasteButton = UIButton(type: .system)
    private let clearButton = UIButton(type: .system)
    private let stack = UIStackView()
    private let nextKey = UIButton(type: .system)

    private var chatText = ""               // text pasted or scanned from the chat
    private var current: [ChartSuggestion] = []
    private var lastAnalyzed: String?
    private var isScanning = false

    // MARK: - Setup

    override func viewDidLoad() {
        super.viewDidLoad()

        statusLabel.font = .systemFont(ofSize: 12, weight: .medium)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 2

        var paste = UIButton.Configuration.filled()
        paste.title = "Paste chat"
        paste.cornerStyle = .capsule
        pasteButton.configuration = paste
        pasteButton.addTarget(self, action: #selector(pasteTapped), for: .touchUpInside)

        var clear = UIButton.Configuration.plain()
        clear.title = "Clear"
        clearButton.configuration = clear
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)

        let header = UIStackView(arrangedSubviews: [statusLabel, clearButton, pasteButton])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8
        header.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        pasteButton.setContentHuggingPriority(.required, for: .horizontal)
        clearButton.setContentHuggingPriority(.required, for: .horizontal)

        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        nextKey.setTitle("🌐", for: .normal)
        nextKey.titleLabel?.font = .systemFont(ofSize: 22)
        nextKey.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        nextKey.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(header)
        view.addSubview(stack)
        view.addSubview(nextKey)

        let height = view.heightAnchor.constraint(equalToConstant: 270)
        height.priority = .defaultHigh      // lower than the system's own constraint, avoids a conflict log

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            stack.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            nextKey.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            nextKey.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6),
            nextKey.widthAnchor.constraint(equalToConstant: 44),
            nextKey.heightAnchor.constraint(equalToConstant: 44),
            nextKey.topAnchor.constraint(greaterThanOrEqualTo: stack.bottomAnchor, constant: 4),

            height
        ])
        refresh()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }

    override func viewWillLayoutSubviews() {
        nextKey.isHidden = !needsInputModeSwitchKey   // phones with a built-in globe key don't need ours
        super.viewWillLayoutSubviews()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        refresh()
    }

    // MARK: - Analysis

    private func refresh() {
        let typed = [textDocumentProxy.documentContextBeforeInput, textDocumentProxy.documentContextAfterInput]
            .compactMap { $0 }
            .joined(separator: " ")
        let text = (chatText + "\n" + typed).trimmingCharacters(in: .whitespacesAndNewlines)

        guard text != lastAnalyzed else { return }
        lastAnalyzed = text
        render(text)
    }

    private func render(_ text: String) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        current = []

        guard !text.isEmpty else {
            statusLabel.text = "No chat yet"
            showHint("1. In the chat, long-press a message › Copy\n2. Switch to this keyboard and tap Paste chat\n\nTip: copy a screenshot to scan the whole chat.")
            return
        }

        let language = LanguageDetector.detect(text).language
        current = ChartSuggester.suggest(for: text, language: language)

        guard !current.isEmpty else {
            statusLabel.text = "Language: \(language.rawValue)"
            showHint("Not enough text to suggest a chart. Paste a longer part of the chat.")
            return
        }

        statusLabel.text = "Language: \(language.rawValue)"
        for (index, s) in current.prefix(3).enumerated() {
            stack.addArrangedSubview(makeSuggestionButton(s, index: index))
        }
    }

    // MARK: - Paste / scan

    @objc private func pasteTapped() {
        guard hasFullAccess else {
            statusLabel.text = "Turn on Allow Full Access: Settings › General › Keyboard › Keyboards › Chart Keyboard"
            return
        }
        let pb = UIPasteboard.general
        if pb.hasStrings, let s = pb.string, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            setChat(s)
        } else if pb.hasImages, let data = OCRService.clipboardImageData() {
            scan(data)
        } else {
            statusLabel.text = "Clipboard is empty. Copy a message or a screenshot first."
        }
    }

    @objc private func clearTapped() {
        chatText = ""
        lastAnalyzed = nil
        refresh()
    }

    private func setChat(_ text: String) {
        chatText = String(text.suffix(1500))   // the latest messages matter most
        lastAnalyzed = nil
        refresh()
    }

    private func scan(_ data: Data) {
        guard !isScanning else { return }
        isScanning = true
        statusLabel.text = "Reading screenshot…"
        Task { @MainActor in
            defer { isScanning = false }
            do {
                setChat(try await OCRService.extractChatText(from: data))
            } catch {
                statusLabel.text = error.localizedDescription
            }
        }
    }

    // MARK: - Views

    private func makeSuggestionButton(_ s: ChartSuggestion, index: Int) -> UIButton {
        var cfg = UIButton.Configuration.filled()
        cfg.title = "\(s.chart.rawValue) · \(s.chart.purpose)"
        cfg.subtitle = s.reason
        cfg.titleAlignment = .leading
        cfg.baseBackgroundColor = .secondarySystemBackground
        cfg.baseForegroundColor = .label
        cfg.cornerStyle = .large
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { c in
            var c = c
            c.font = .systemFont(ofSize: 15, weight: .semibold)
            return c
        }
        cfg.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { c in
            var c = c
            c.font = .systemFont(ofSize: 12)
            return c
        }
        let b = UIButton(configuration: cfg)
        b.contentHorizontalAlignment = .leading
        b.tag = index
        b.addTarget(self, action: #selector(tapSuggestion(_:)), for: .touchUpInside)
        return b
    }

    private func showHint(_ text: String) {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        stack.addArrangedSubview(label)
    }

    @objc private func tapSuggestion(_ sender: UIButton) {
        guard current.indices.contains(sender.tag) else { return }
        textDocumentProxy.insertText(current[sender.tag].chart.rawValue + " ")
    }
}
