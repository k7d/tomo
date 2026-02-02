import AppKit

class VerticallyCenteredTextFieldCell: NSTextFieldCell {
    private let horizontalPadding: CGFloat = 8

    override func titleRect(forBounds rect: NSRect) -> NSRect {
        let inset = rect.insetBy(dx: horizontalPadding, dy: 0)
        var r = super.titleRect(forBounds: inset)
        let textHeight = cellSize(forBounds: inset).height
        r.origin.y = rect.origin.y + (rect.height - textHeight) / 2
        r.size.height = textHeight
        return r
    }

    override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?) {
        super.edit(withFrame: titleRect(forBounds: rect), in: controlView, editor: textObj, delegate: delegate, event: event)
    }

    override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
        super.select(withFrame: titleRect(forBounds: rect), in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
    }

    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.drawInterior(withFrame: titleRect(forBounds: cellFrame), in: controlView)
    }
}

class AutoSelectTextField: NSTextField {
    var onTextChanged: ((String) -> Void)?

    override class var cellClass: AnyClass? {
        get { VerticallyCenteredTextFieldCell.self }
        set {}
    }

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
