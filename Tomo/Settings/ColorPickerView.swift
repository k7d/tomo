import AppKit

class ColorPickerView: NSView {
    private var selected: ColorName
    private let onSelected: (ColorName) -> Void

    init(selected: ColorName, onSelected: @escaping (ColorName) -> Void) {
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

        let lbl = NSTextField(labelWithString: "Color")
        lbl.font = .systemFont(ofSize: 12, weight: .medium)
        lbl.textColor = labelTextColor
        container.addArrangedSubview(lbl)

        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 2
        row.translatesAutoresizingMaskIntoConstraints = false

        for color in ColorName.allCases {
            let circle = ColorCircle(color: color, isSelected: color == selected) { [weak self] in
                self?.selected = color
                self?.onSelected(color)
                self?.setup()
            }
            row.addArrangedSubview(circle)
        }
        container.addArrangedSubview(row)
    }
}

private class ColorCircle: NSView {
    let colorName: ColorName
    var isSelected: Bool
    let onTap: () -> Void
    private var trackingArea: NSTrackingArea?

    init(color: ColorName, isSelected: Bool, onTap: @escaping () -> Void) {
        self.colorName = color
        self.isSelected = isSelected
        self.onTap = onTap
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: 39).isActive = true
        heightAnchor.constraint(equalToConstant: 38).isActive = true
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let circleRect = bounds.insetBy(dx: 4, dy: 4)

        // Selection ring
        if isSelected {
            let ringRect = bounds.insetBy(dx: 2, dy: 2)
            ctx.setStrokeColor(NSColor(srgbRed: 0x82/255, green: 0xAC/255, blue: 0xFF/255, alpha: 1).cgColor)
            ctx.setLineWidth(2)
            ctx.strokeEllipse(in: ringRect)
        }

        // Gradient fill
        let base = colorName.nsColor
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        (base.usingColorSpace(.sRGB) ?? base).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let darkColor = NSColor(hue: h, saturation: s, brightness: b * 0.7, alpha: 1)
        let lightColor = NSColor(hue: h, saturation: s, brightness: min(b * 1.1, 1), alpha: 1)

        ctx.saveGState()
        ctx.addEllipse(in: circleRect)
        ctx.clip()

        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: [darkColor.cgColor, lightColor.cgColor] as CFArray,
                                     locations: [0, 1]) {
            ctx.drawLinearGradient(gradient,
                                   start: CGPoint(x: circleRect.midX, y: circleRect.minY),
                                   end: CGPoint(x: circleRect.midX, y: circleRect.maxY),
                                   options: [])
        }
        ctx.restoreGState()
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
