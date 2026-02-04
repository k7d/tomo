import AppKit

class ContentRootView: NSView {
    let stackView = NSStackView()
    private let scrollView = NSScrollView()

    var hasAppBar = false

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
        translatesAutoresizingMaskIntoConstraints = false

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.autohidesScrollers = true
        addSubview(scrollView)

        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 0
        stackView.edgeInsets = NSEdgeInsets(top: 30, left: 30, bottom: 30, right: 30)

        let clipView = NSClipView()
        clipView.translatesAutoresizingMaskIntoConstraints = false
        clipView.drawsBackground = false
        clipView.documentView = stackView
        scrollView.contentView = clipView

        stackView.topAnchor.constraint(equalTo: clipView.topAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: clipView.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: clipView.trailingAnchor).isActive = true
        stackView.widthAnchor.constraint(equalTo: clipView.widthAnchor).isActive = true
    }

    func setChildren(_ views: [NSView]) {
        stackView.arrangedSubviews.forEach { stackView.removeArrangedSubview($0); $0.removeFromSuperview() }
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview(view)
            // Make buttons/views stretch full width
            view.widthAnchor.constraint(equalTo: stackView.widthAnchor, constant: -60).isActive = true
        }
        stackView.edgeInsets.top = hasAppBar ? 10 : 30

        // After layout, update window height
        DispatchQueue.main.async { [weak self] in
            self?.updateWindowHeight()
        }
    }

    func updateWindowHeight() {
        stackView.layoutSubtreeIfNeeded()
        let contentHeight = stackView.fittingSize.height
        let appBarHeight: CGFloat = hasAppBar ? 52 : 0 // AppBar standard height
        let totalHeight = contentHeight + appBarHeight

        guard let window = self.window else { return }
        let screen = NSScreen.main
        let maxHeight = screen.map { $0.frame.height * 0.8 } ?? 600
        let limitedHeight = min(totalHeight, maxHeight)

        let frame = window.frame
        let newOrigin = NSPoint(x: frame.origin.x, y: frame.origin.y + frame.height - limitedHeight)
        window.setFrame(NSRect(origin: newOrigin, size: NSSize(width: windowWidth, height: limitedHeight)), display: true, animate: false)
    }
}
