import AppKit
import QuartzCore

class TimerDismissIndicator: NSView {
    private let arcLayer = CAShapeLayer()
    private var childView: NSView?
    var arcColor: NSColor = .white {
        didSet { arcLayer.strokeColor = arcColor.cgColor }
    }

    override var isFlipped: Bool { true }

    init(child: NSView) {
        self.childView = child
        super.init(frame: .zero)
        wantsLayer = true

        arcLayer.fillColor = nil
        arcLayer.strokeColor = NSColor.white.cgColor
        arcLayer.lineWidth = 3
        arcLayer.lineCap = .round
        arcLayer.strokeEnd = 0
        layer?.addSublayer(arcLayer)

        child.translatesAutoresizingMaskIntoConstraints = false
        addSubview(child)

        translatesAutoresizingMaskIntoConstraints = false
        // 4px padding around child for the arc
        child.topAnchor.constraint(equalTo: topAnchor, constant: 4).isActive = true
        child.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4).isActive = true
        child.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4).isActive = true
        child.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4).isActive = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        let rect = bounds.insetBy(dx: 2, dy: 2)
        let path = CGMutablePath()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                     radius: min(rect.width, rect.height) / 2,
                     startAngle: -.pi / 2,
                     endAngle: .pi * 3 / 2,
                     clockwise: false)
        arcLayer.path = path
        arcLayer.frame = bounds
    }

    func startAnimation() {
        arcLayer.strokeEnd = 0
        let anim = CABasicAnimation(keyPath: "strokeEnd")
        anim.fromValue = 0
        anim.toValue = 1
        anim.duration = dismissTimerIn
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        arcLayer.add(anim, forKey: "dismiss")
    }

    func stopAnimation() {
        arcLayer.removeAllAnimations()
        arcLayer.strokeEnd = 0
    }
}
