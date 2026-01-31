import AppKit

class SoundPickerView: NSView {
    private var selected: Sound
    private let onSelected: (Sound) -> Void

    init(selected: Sound, onSelected: @escaping (Sound) -> Void) {
        self.selected = selected
        self.onSelected = onSelected
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        removeAllSubviews()

        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 4
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        container.topAnchor.constraint(equalTo: topAnchor).isActive = true
        container.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        container.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        container.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true

        let lbl = NSTextField(labelWithString: "Sound")
        lbl.font = .systemFont(ofSize: 12, weight: .medium)
        lbl.textColor = labelTextColor
        container.addArrangedSubview(lbl)

        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 2
        row.translatesAutoresizingMaskIntoConstraints = false

        for sound in Sound.allCases {
            let circle = SoundCircle(sound: sound, isSelected: sound == selected) { [weak self] in
                self?.selected = sound
                self?.onSelected(sound)
                if sound != .none {
                    SoundPlayer.shared.play(sound)
                }
                self?.setup()
            }
            row.addArrangedSubview(circle)
        }
        container.addArrangedSubview(row)
    }
}

private class SoundCircle: NSView {
    let sound: Sound
    var isSelected: Bool
    let onTap: () -> Void
    private var trackingArea: NSTrackingArea?

    init(sound: Sound, isSelected: Bool, onTap: @escaping () -> Void) {
        self.sound = sound
        self.isSelected = isSelected
        self.onTap = onTap
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: 39).isActive = true
        heightAnchor.constraint(equalToConstant: 38).isActive = true
        wantsLayer = true

        // Add SVG icon
        if let icon = loadSVGIcon(named: sound.rawValue, size: 20, color: labelTextColor) {
            let iv = NSImageView(image: icon)
            iv.translatesAutoresizingMaskIntoConstraints = false
            addSubview(iv)
            iv.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            iv.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            iv.widthAnchor.constraint(equalToConstant: 20).isActive = true
            iv.heightAnchor.constraint(equalToConstant: 20).isActive = true
        } else {
            // Fallback: show first letter
            let label = NSTextField(labelWithString: String(sound.rawValue.prefix(1)).uppercased())
            label.font = .systemFont(ofSize: 14, weight: .medium)
            label.textColor = labelTextColor
            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)
            label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        if isSelected {
            let ringRect = bounds.insetBy(dx: 2, dy: 2)
            ctx.setStrokeColor(NSColor(srgbRed: 0x82/255, green: 0xAC/255, blue: 0xFF/255, alpha: 1).cgColor)
            ctx.setLineWidth(2)
            ctx.strokeEllipse(in: ringRect)
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let area = trackingArea { removeTrackingArea(area) }
        trackingArea = NSTrackingArea(rect: bounds, options: [.activeAlways, .cursorUpdate], owner: self)
        addTrackingArea(trackingArea!)
    }

    override func cursorUpdate(with event: NSEvent) {
        NSCursor.pointingHand.set()
    }

    override func mouseDown(with event: NSEvent) {
        onTap()
    }
}
