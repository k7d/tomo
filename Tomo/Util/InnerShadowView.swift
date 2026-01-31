import AppKit

struct ShadowSpec {
    let color: NSColor
    let offset: CGPoint
    let blurRadius: CGFloat
}

class InnerShadowView: NSView {
    var shadows: [ShadowSpec] = []

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let bounds = self.bounds

        // Draw child content via layer or subviews handled by AppKit
        // Inner shadow is drawn on top
        for shadow in shadows {
            context.saveGState()

            // Create shadow path (inverse — fill everything outside the bounds)
            let outer = bounds.insetBy(dx: -shadow.blurRadius * 2, dy: -shadow.blurRadius * 2)
            let path = CGMutablePath()
            path.addRect(outer)
            path.addRect(bounds)

            context.addPath(path)
            context.clip(using: .evenOdd)

            let shadowColor = shadow.color.cgColor
            context.setShadow(offset: CGSize(width: shadow.offset.x, height: -shadow.offset.y),
                              blur: shadow.blurRadius,
                              color: shadowColor)
            context.setFillColor(NSColor.black.cgColor)
            context.addRect(bounds)
            context.fillPath()

            context.restoreGState()
        }
    }
}
