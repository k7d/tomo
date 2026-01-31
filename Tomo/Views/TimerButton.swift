import AppKit

/// Convenience factory to create an ActionButton pre-configured for a timer's color
func makeTimerButton(config: TimerConfig, left: NSView? = nil, center: NSView? = nil, right: NSView? = nil, onPressed: (() -> Void)? = nil) -> ActionButton {
    let btn = ActionButton()
    btn.buttonColor = config.color.nsColor
    btn.buttonTextColor = config.color.textColor
    btn.leftView = left
    btn.centerView = center ?? makeDurationLabel(config.duration, color: config.color.textColor)
    btn.rightView = right
    btn.onPressed = onPressed
    return btn
}

func makeDurationLabel(_ seconds: TimeInterval, color: NSColor, fontSize: CGFloat = 35) -> NSTextField {
    let label = NSTextField(labelWithString: "")
    label.attributedStringValue = NSAttributedString(
        string: formatDuration(seconds),
        attributes: [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: color,
            .kern: 1.0,
        ]
    )
    label.isBezeled = false
    label.isEditable = false
    label.drawsBackground = false
    label.alignment = .center
    return label
}

func makeTimerNameView(config: TimerConfig, showDayTotal: Bool = true) -> NSView {
    let stack = NSStackView()
    stack.orientation = .vertical
    stack.alignment = .trailing
    stack.spacing = 2

    let nameLabel = NSTextField(labelWithString: "")
    nameLabel.attributedStringValue = NSAttributedString(
        string: config.name,
        attributes: [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: config.color.textColor,
            .kern: 0.75,
        ]
    )
    nameLabel.isBezeled = false
    nameLabel.isEditable = false
    nameLabel.drawsBackground = false
    stack.addArrangedSubview(nameLabel)

    if showDayTotal {
        let dayTotal = AppState.shared.currentDayDuration(for: config.id)
        let totalLabel = NSTextField(labelWithString: "")
        totalLabel.attributedStringValue = NSAttributedString(
            string: formatDuration(dayTotal),
            attributes: [
                .font: NSFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: config.color.textColor,
                .kern: 0.75,
            ]
        )
        totalLabel.isBezeled = false
        totalLabel.isEditable = false
        totalLabel.drawsBackground = false
        stack.addArrangedSubview(totalLabel)
    }

    return stack
}

func makeIconView(systemName: String, size: CGFloat = 32, color: NSColor = .white) -> NSImageView {
    let config = NSImage.SymbolConfiguration(pointSize: size * 0.6, weight: .regular)
    let image = NSImage(systemSymbolName: systemName, accessibilityDescription: nil)?.withSymbolConfiguration(config)
    let iv = NSImageView(image: image ?? NSImage())
    iv.contentTintColor = color
    iv.translatesAutoresizingMaskIntoConstraints = false
    iv.widthAnchor.constraint(equalToConstant: size).isActive = true
    iv.heightAnchor.constraint(equalToConstant: size).isActive = true
    return iv
}
