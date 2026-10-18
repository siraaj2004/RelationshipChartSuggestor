import UIKit

final class KeyboardViewController: UIInputViewController {

    private let replies = [
        "Hey, tell me more 😊",
        "I understand what you mean.",
        "Haha, you made me smile ❤️"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildKeyboard()
    }

    private func buildKeyboard() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 10
            ),
            stack.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -10
            ),
            stack.topAnchor.constraint(
                equalTo: view.topAnchor, constant: 10
            ),
            stack.bottomAnchor.constraint(
                equalTo: view.bottomAnchor, constant: -10
            )
        ])

        let title = UILabel()
        title.text = "Relationship Reply Suggestions"
        title.font = .boldSystemFont(ofSize: 15)
        title.textAlignment = .center
        stack.addArrangedSubview(title)

        for reply in replies {
            let button = UIButton(type: .system)
            button.setTitle(reply, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 15)
            button.titleLabel?.numberOfLines = 2
            button.backgroundColor = .secondarySystemBackground
            button.layer.cornerRadius = 9
            button.contentEdgeInsets = UIEdgeInsets(
                top: 12, left: 8, bottom: 12, right: 8
            )
            button.accessibilityIdentifier = reply
            button.addTarget(
                self,
                action: #selector(insertReply(_:)),
                for: .touchUpInside
            )
            stack.addArrangedSubview(button)
        }

        let next = UIButton(type: .system)
        next.setTitle("Next Keyboard 🌐", for: .normal)
        next.addTarget(
            self,
            action: #selector(nextKeyboard),
            for: .touchUpInside
        )
        stack.addArrangedSubview(next)
    }

    @objc private func insertReply(_ sender: UIButton) {
        guard let reply = sender.accessibilityIdentifier else {
            return
        }
        textDocumentProxy.insertText(reply)
    }

    @objc private func nextKeyboard() {
        advanceToNextInputMode()
    }
}
