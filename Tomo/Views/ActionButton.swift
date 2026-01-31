import AppKit

let actionButtonBorderRadius: CGFloat = 6
private let bezelHeight: CGFloat = 4
private let bezelPressedHeight: CGFloat = 1

class ActionButton: NSView {

    var onPressed: (() -> Void)?

    var buttonColor: NSColor = grayColor { didSet { needsDisplay = true } }
    var buttonTextColor: NSColor = grayTextColor { didSet { needsDisplay = true } }
    var minHeight: CGFloat = 55
    var pressable: Bool { onPressed != nil }

    // Subview slots
    var leftView: NSView? { didSet { rebuildLayout() } }
    var centerView: NSView? { didSet { rebuildLayout() } }
    var rightView: NSView? { didSet { rebuildLayout() } }

    /// Optional progress (0..1) drawn as dark overlay from left
    var progress: CGFloat = 0 { didSet { needsDisplay = true } }

    private(set) var isHovering = false
    private(set) var isPressed = false
    private var trackingArea: NSTrackingArea?

    private let contentView = NSView()
    private var contentTopConstraint: NSLayoutConstraint?
    private var outerHeightConstraint: NSLayoutConstraint?

    override var isFlipped: Bool { true }

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.wantsLayer = true
        addSubview(contentView)

        contentTopConstraint = contentView.topAnchor.constraint(equalTo: topAnchor, constant: 0)
        contentTopConstraint?.isActive = true
        contentView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -bezelHeight).isActive = true

        outerHeightConstraint = heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight)
        outerHeightConstraint?.isActive = true
    }

    private func rebuildLayout() {
        contentView.removeAllSubviews()

        let stack = NSView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.wantsLayer = true
        contentView.addSubview(stack)

        stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20).isActive = true
        stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true
        stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5).isActive = true
        stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true

        // Left-aligned view
        if let left = leftView {
            left.translatesAutoresizingMaskIntoConstraints = false
            stack.addSubview(left)
            left.leadingAnchor.constraint(equalTo: stack.leadingAnchor).isActive = true
            left.centerYAnchor.constraint(equalTo: stack.centerYAnchor).isActive = true
        }

        // Center view
        if let center = centerView {
            center.translatesAutoresizingMaskIntoConstraints = false
            stack.addSubview(center)
            center.centerXAnchor.constraint(equalTo: stack.centerXAnchor).isActive = true
            center.centerYAnchor.constraint(equalTo: stack.centerYAnchor).isActive = true
        }

        // Right-aligned view
        if let right = rightView {
            right.translatesAutoresizingMaskIntoConstraints = false
            stack.addSubview(right)
            right.trailingAnchor.constraint(equalTo: stack.trailingAnchor).isActive = true
            right.centerYAnchor.constraint(equalTo: stack.centerYAnchor).isActive = true
        }

        // Minimum content height
        let minContentH = minHeight - bezelHeight
        stack.heightAnchor.constraint(greaterThanOrEqualToConstant: minContentH - 10).isActive = true

        needsDisplay = true
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let bounds = self.bounds

        let currentBezel = isPressed ? bezelPressedHeight : bezelHeight
        let topOffset = isPressed ? (bezelHeight - bezelPressedHeight) : 0.0

        // Full outer rect — filled with button color (the bezel peeks out at bottom)
        let outerRect = NSRect(x: 0, y: topOffset, width: bounds.width, height: bounds.height - topOffset)
        let outerPath = NSBezierPath(roundedRect: outerRect, xRadius: actionButtonBorderRadius, yRadius: actionButtonBorderRadius)

        // Fill entire outer shape with button color — this gives the bezel its tint
        buttonColor.setFill()
        outerPath.fill()

        // Darken the bezel area (bottom shadow) by overlaying black
        if pressable {
            ctx.saveGState()
            outerPath.addClip()
            NSColor.black.withAlphaComponent(0.3).setFill()
            let bezelRect = NSRect(x: 0, y: topOffset + outerRect.height - currentBezel, width: bounds.width, height: currentBezel)
            bezelRect.fill()
            ctx.restoreGState()
        }

        // Main button body (above the bezel)
        let bodyRect = NSRect(x: 0, y: topOffset, width: bounds.width, height: outerRect.height - currentBezel)
        let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: actionButtonBorderRadius, yRadius: actionButtonBorderRadius)

        // Fill body with base color (clean, over the darkened bezel area)
        ctx.saveGState()
        buttonColor.setFill()
        bodyPath.fill()
        ctx.restoreGState()

        // Progress bar overlay
        if progress > 0 {
            ctx.saveGState()
            bodyPath.addClip()
            NSColor.black.withAlphaComponent(0.15).setFill()
            NSRect(x: 0, y: topOffset, width: bounds.width * progress, height: bodyRect.height).fill()
            ctx.restoreGState()
        }

        // Gradient overlay (darker at top)
        if pressable {
            ctx.saveGState()
            bodyPath.addClip()
            let topAlpha: CGFloat = isHovering ? 0.20 : 0.15
            let bottomAlpha: CGFloat = isHovering ? 0.05 : 0.0
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                         colors: [CGColor(red: 0, green: 0, blue: 0, alpha: topAlpha),
                                                   CGColor(red: 0, green: 0, blue: 0, alpha: bottomAlpha)] as CFArray,
                                         locations: [0, 1]) {
                ctx.drawLinearGradient(gradient,
                                       start: CGPoint(x: 0, y: topOffset),
                                       end: CGPoint(x: 0, y: topOffset + bodyRect.height),
                                       options: [])
            }
            ctx.restoreGState()
        }

        // Inner shadow (white highlight at top)
        if pressable {
            ctx.saveGState()
            bodyPath.addClip()
            let shadowBounds = bodyRect.insetBy(dx: -2, dy: -2)
            ctx.setShadow(offset: CGSize(width: 0, height: -1), blur: 1, color: NSColor.white.withAlphaComponent(0.3).cgColor)
            let inversePath = CGMutablePath()
            inversePath.addRect(shadowBounds.insetBy(dx: -10, dy: -10))
            inversePath.addRoundedRect(in: bodyRect, cornerWidth: actionButtonBorderRadius, cornerHeight: actionButtonBorderRadius)
            ctx.addPath(inversePath)
            ctx.clip(using: .evenOdd)
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.fill(shadowBounds.insetBy(dx: -10, dy: -10))
            ctx.restoreGState()
        }

        // Update content position
        contentTopConstraint?.constant = topOffset
    }

    // MARK: - Mouse

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let area = trackingArea { removeTrackingArea(area) }
        trackingArea = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self)
        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        guard pressable else { return }
        isHovering = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovering = false
        isPressed = false
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        guard pressable else { return }
        isPressed = true
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let wasPressed = isPressed
        isPressed = false
        needsDisplay = true
        if wasPressed && pressable {
            let loc = convert(event.locationInWindow, from: nil)
            if bounds.contains(loc) {
                onPressed?()
            }
        }
    }
}
