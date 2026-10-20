import UIKit

class KeyboardViewController: UIInputViewController {

    private let defaultCharts = ["Sociogram", "Genogram", "Ecomap", "Org Chart", "Network Graph"]
    private var suggestionButtons: [UIButton] = []
    private let languageLabel = UILabel()

    private var history = ""
    private var lastContext = ""
    private var debounce: Timer?
    private var requestID = 0

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        applyCharts(defaultCharts)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshSuggestions()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        debounce?.invalidate()
        debounce = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { [weak self] _ in
            self?.refreshSuggestions()
        }
    }

    // MARK: - UI

    private func buildUI() {
        let height = view.heightAnchor.constraint(equalToConstant: 170)
        height.priority = .defaultHigh
        height.isActive = true

        languageLabel.font = .systemFont(ofSize: 12, weight: .medium)
        languageLabel.textColor = .secondaryLabel
        languageLabel.text = "Type a message, or copy chat text and tap Scan"
        languageLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(languageLabel)

        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        for _ in 0..<5 {
            let b = UIButton(type: .system)
            b.addTarget(self, action: #selector(chartTapped(_:)), for: .touchUpInside)
            suggestionButtons.append(b)
            stack.addArrangedSubview(b)
        }

        let globe = UIButton(type: .system)
        globe.setImage(UIImage(systemName: "globe"), for: .normal)
        globe.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        globe.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(globe)

        let delete = UIButton(type: .system)
        delete.setImage(UIImage(systemName: "delete.left"), for: .normal)
        delete.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        delete.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(delete)

        let scan = UIButton(type: .system)
        var cfg = UIButton.Configuration.filled()
        cfg.title = "Scan copied chat"
        cfg.cornerStyle = .capsule
        scan.configuration = cfg
        scan.addTarget(self, action: #selector(scanClipboardTapped), for: .touchUpInside)
        scan.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scan)

        NSLayoutConstraint.activate([
            languageLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            languageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            languageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),

            scroll.topAnchor.constraint(equalTo: languageLabel.bottomAnchor, constant: 8),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            scroll.heightAnchor.constraint(equalToConstant: 48),

            stack.topAnchor.constraint(equalTo: scroll.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            stack.heightAnchor.constraint(equalTo: scroll.heightAnchor),

            globe.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            globe.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
            globe.widthAnchor.constraint(equalToConstant: 36),
            globe.heightAnchor.constraint(equalToConstant: 36),

            delete.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            delete.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
            delete.widthAnchor.constraint(equalToConstant: 36),
            delete.heightAnchor.constraint(equalToConstant: 36),

            scan.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scan.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
            scan.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    private func style(_ button: UIButton, title: String, best: Bool) {
        var config: UIButton.Configuration = best ? .filled() : .tinted()
        config.title = title
        config.cornerStyle = .large
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        button.configuration = config
    }

    private func applyCharts(_ charts: [String]) {
        for (i, button) in suggestionButtons.enumerated() where i < charts.count {
            style(button, title: charts[i], best: i == 0)
        }
    }

    // MARK: - Actions

    @objc private func chartTapped(_ sender: UIButton) {
        if let title = sender.configuration?.title {
            textDocumentProxy.insertText(title)
        }
    }

    @objc private func deleteTapped() {
        textDocumentProxy.deleteBackward()
    }

    // MARK: - Suggestions

    private func refreshSuggestions() {
        guard hasFullAccess else {
            languageLabel.text = "Turn on Allow Full Access for smart suggestions"
            return
        }

        let current = (textDocumentProxy.documentContextBeforeInput ?? "")
                    + (textDocumentProxy.documentContextAfterInput ?? "")

        if current.isEmpty && !lastContext.isEmpty {
            history = String((history + " " + lastContext).suffix(600))
        }
        lastContext = current

        let combined = (history + " " + current).trimmingCharacters(in: .whitespacesAndNewlines)
        guard combined.count >= 3 else {
            languageLabel.text = "Type a message, or copy chat text and tap Scan"
            applyCharts(defaultCharts)
            return
        }
        runScan(on: combined)
    }

    @objc private func scanClipboardTapped() {
        guard hasFullAccess else {
            languageLabel.text = "Turn on Allow Full Access first"
            return
        }
        guard let copied = UIPasteboard.general.string,
              !copied.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            languageLabel.text = "Copy some chat text first"
            return
        }
        runScan(on: copied)
    }

    private func runScan(on text: String) {
        languageLabel.text = "Detecting language…"
        requestID += 1
        let myID = requestID

        ChartSuggester.suggest(text: text) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self, myID == self.requestID else { return }
                guard let result = result else {
                    self.languageLabel.text = "Couldn't reach the server"
                    return
                }
                self.languageLabel.text = "Detected: \(result.language)"
                self.applyCharts(result.charts)
            }
        }
    }
}
