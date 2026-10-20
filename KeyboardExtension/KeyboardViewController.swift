import UIKit

final class KeyboardViewController: UIInputViewController {

    private let suggestions = ["Sociogram", "Genogram", "Ecomap", "Org Chart", "Network Graph"]

    override func viewDidLoad() {
        super.viewDidLoad()

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            stack.heightAnchor.constraint(equalToConstant: 44),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -6)
        ])

        for title in suggestions {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.backgroundColor = .secondarySystemBackground
            button.layer.cornerRadius = 8
            button.addTarget(self, action: #selector(insertSuggestion(_:)), for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
    }

    @objc private func insertSuggestion(_ sender: UIButton) {
        guard let text = sender.title(for: .normal) else { return }
        textDocumentProxy.insertText(text)
    }
}
