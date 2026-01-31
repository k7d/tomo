import AppKit

class AutoSelectTextField: NSTextField {
    var onTextChanged: ((String) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false
        delegate = self
    }

    required init?(coder: NSCoder) { fatalError() }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        // Select all text on focus
        DispatchQueue.main.async {
            if let editor = self.currentEditor() {
                editor.selectAll(nil)
            }
        }
        return result
    }
}

extension AutoSelectTextField: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        onTextChanged?(stringValue)
    }
}
