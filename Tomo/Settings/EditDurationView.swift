import AppKit

class EditDurationView: NSView {
    private let onChange: (TimeInterval) -> Void
    private let hoursField: NSTextField
    private let minutesField: NSTextField
    private let secondsField: NSTextField
    private let fieldBgColor: NSColor

    init(duration: TimeInterval, fieldBgColor: NSColor = .clear, onChange: @escaping (TimeInterval) -> Void) {
        self.onChange = onChange
        self.fieldBgColor = fieldBgColor
        let total = Int(duration)
        hoursField = NSTextField(string: "\(total / 3600)")
        minutesField = NSTextField(string: "\((total % 3600) / 60)")
        secondsField = NSTextField(string: "\(total % 60)")

        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        stack.topAnchor.constraint(equalTo: topAnchor).isActive = true
        stack.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        stack.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        stack.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true

        stack.addArrangedSubview(makePart("Hours", field: hoursField))
        stack.addArrangedSubview(makePart("Minutes", field: minutesField))
        stack.addArrangedSubview(makePart("Seconds", field: secondsField))
    }

    private func makePart(_ label: String, field: NSTextField) -> NSView {
        let col = NSStackView()
        col.orientation = .vertical
        col.alignment = .leading
        col.spacing = 4

        let lbl = NSTextField(labelWithString: label)
        lbl.font = .systemFont(ofSize: 12, weight: .medium)
        lbl.textColor = labelTextColor
        col.addArrangedSubview(lbl)

        let cell = VerticallyCenteredTextFieldCell(textCell: field.stringValue)
        cell.isEditable = true
        cell.isSelectable = true
        field.cell = cell
        field.isEditable = true
        field.isSelectable = true
        field.font = .systemFont(ofSize: 16)
        field.textColor = .white
        field.drawsBackground = false
        field.isBezeled = false
        field.focusRingType = .none
        field.wantsLayer = true
        field.layer?.backgroundColor = fieldBgColor.cgColor
        field.layer?.cornerRadius = 4
        field.heightAnchor.constraint(equalToConstant: 32).isActive = true
        field.delegate = self
        col.addArrangedSubview(field)
        field.widthAnchor.constraint(equalTo: col.widthAnchor).isActive = true

        return col
    }

    private func computeDuration() {
        let h = Int(hoursField.stringValue) ?? 0
        let m = Int(minutesField.stringValue) ?? 0
        let s = Int(secondsField.stringValue) ?? 0
        onChange(TimeInterval(h * 3600 + m * 60 + s))
    }
}

extension EditDurationView: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        computeDuration()
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        guard let field = obj.object as? NSTextField else { return }
        if field.stringValue.isEmpty {
            field.stringValue = "0"
        }
        computeDuration()
    }
}
