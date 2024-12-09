import AppKit

func calcStatusItemLength(_ text: String) -> CGFloat {
    return max(CGFloat(text.count-1) * 8.0 + 14, 46);
}

extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let image = self.copy() as! NSImage
        image.lockFocus()
        color.set()
        let imageRect = NSRect(origin: .zero, size: image.size)
        imageRect.fill(using: .sourceIn)
        image.unlockFocus()
        return image
    }
}

class StatusItemView: NSView {
    
    let font = NSFont.systemFont(ofSize: 13, weight: NSFont.Weight.regular)
    let icon = NSImage(named: "MenuBarIcon")
    var tintedIcon = NSImage(named: "MenuBarIcon")
    var statusItem: NSStatusItem
    var isHighlighted = false {
        didSet {
            setNeedsDisplay(bounds)
        }
    }
    var remainingTime = "" {
        didSet {
            statusItem.length = calcStatusItemLength(remainingTime)
            var frame = self.frame
            frame.size.width = statusItem.length
            self.frame = frame
            setNeedsDisplay(bounds)
        }
    }
    var bgColor = NSColor(red: 0x8e/255, green: 0x8e/255, blue: 0x8d/255, alpha: 1) {
        didSet {
            setNeedsDisplay(bounds)
        }
    }
    var textColor = NSColor(red: 1, green: 1, blue: 1, alpha: 1) {
        didSet {
            tintedIcon = icon?.tinted(with: textColor)
            setNeedsDisplay(bounds)
        }
    }
    var completed: CGFloat = 0.0 {
        didSet {
            setNeedsDisplay(bounds)
        }
    }
    
    init() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: calcStatusItemLength(remainingTime))
        super.init(frame: NSMakeRect(0, 0, statusItem.length, NSStatusBar.system.thickness))
        statusItem.button?.addSubview(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func fillRoundedRect(rect: CGRect, radius: CGFloat, color: NSColor) {
        let context = NSGraphicsContext.current!.cgContext

        let path = CGMutablePath()
        path.move( to: CGPoint(x:  rect.midX, y:rect.minY ))
        path.addArc( tangent1End: CGPoint(x: rect.maxX, y: rect.minY ),
                     tangent2End: CGPoint(x: rect.maxX, y: rect.maxY), radius: radius)
        path.addArc( tangent1End: CGPoint(x: rect.maxX, y: rect.maxY ),
                     tangent2End: CGPoint(x: rect.minX, y: rect.maxY), radius: radius)
        path.addArc( tangent1End: CGPoint(x: rect.minX, y: rect.maxY ),
                     tangent2End: CGPoint(x: rect.minX, y: rect.minY), radius: radius)
        path.addArc( tangent1End: CGPoint(x: rect.minX, y: rect.minY ),
                     tangent2End: CGPoint(x: rect.maxX, y: rect.minY), radius: radius)
        path.closeSubpath()
        
        // draw bg color
        context.setFillColor(color.cgColor)
        context.addPath(path)
        context.drawPath(using: .fill)
        
        // draw gradient overlay
        context.addPath(path)
        context.clip()
        if let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [CGColor(red: 0, green: 0, blue: 0, alpha: 0.15), CGColor(red: 0, green: 0, blue: 0, alpha: 0)] as CFArray,
            locations: [0.0, 1.0]
        ) {
            context.drawLinearGradient(gradient, start: CGPoint(x: rect.minX, y: rect.minY ), end: CGPoint(x: rect.minX, y: rect.maxY ), options: [])
        }
        
    }
    
    func drawBox(bgRect: NSRect) {
        // draw main bg
        fillRoundedRect(rect: bgRect, radius: 3, color: bgColor)
        
        // draw progress
        let context = NSGraphicsContext.current!.cgContext
        context.saveGState()
        var clipRect = bgRect
        clipRect.size.width = floor(bgRect.size.width * completed)
        context.clip(to: clipRect)
        fillRoundedRect(rect: bgRect, radius: 3, color: NSColor(red: 0, green: 0, blue: 0, alpha: 0.3))
        context.restoreGState()
    }
    
    func drawRemainingTime(bgRect: NSRect) {
        let ps = NSMutableParagraphStyle()
        ps.alignment = .center
        ps.lineBreakMode = .byClipping
        remainingTime.draw(
            in: bgRect.insetBy(dx: 0, dy: 0),
            withAttributes: [
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.paragraphStyle: ps,
                NSAttributedString.Key.foregroundColor: textColor
            ])
    }
    
    func drawIcon(bgRect: NSRect) {
        // Center icon:
        let width = 18.0
        let height = 8.0
        let iconRect = NSMakeRect((bgRect.size.width - width) * 0.5 + bgRect.origin.x, (bgRect.size.height - height) * 0.5 + bgRect.origin.y, width, height).integral
        tintedIcon?.draw(in:iconRect)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        let bgRect = bounds.insetBy(dx: 0, dy: 1.5)
        drawBox(bgRect: bgRect)
        // draw time
        if remainingTime == "" {
            drawIcon(bgRect: bgRect)
        } else {
            drawRemainingTime(bgRect: bgRect)
        }
    }
}


class StatusBarController: NSObject, NSWindowDelegate {
    var window: NSWindow
    let statusItemView = StatusItemView()
    var globalEventMonitor: Any?
    var localEventMonitor: Any?
    
    init(_ window: NSWindow) {
        self.window = window
        super.init()
        self.window.delegate = self
        if let statusBarButton = statusItemView.statusItem.button {
            statusBarButton.action = #selector(toggleWindow(sender:))
            statusBarButton.target = self
        }
    }
    
    func calcStatusItemLength(_ text: String) -> CGFloat {
        return max(CGFloat(text.count-1) * 8.0 + 14, 46);
    }
    
    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        statusItemView.isHighlighted = false
        return true
    }
    
    @objc func toggleWindow(sender: AnyObject) {
        if window.isVisible {
            hideWindow()
        }
        else {
            showWindow()
        }
    }
    
    func showWindow() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size
        let xPosition = screenFrame.origin.x + (screenFrame.width - windowSize.width) / 2
        let yPosition = screenFrame.origin.y + screenFrame.height * 0.75
        
        window.setFrameTopLeftPoint(NSPoint(x: xPosition, y: yPosition))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Set up global event monitor to detect clicks outside the window
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let self = self, self.window.isVisible {
                self.hideWindow()
            }
        }
    }
    
    func hideWindow() {
        statusItemView.isHighlighted = false
        window.orderOut(nil)
        
        // Remove the global event monitor when hiding the popover
        if let globalEventMonitor = globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
            self.globalEventMonitor = nil
        }
        
        // Remove the local event monitor when hiding the popover
        if let localEventMonitor = localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
            self.localEventMonitor = nil
        }
    }
    
    // MARK: - NSWindowDelegate
    
    func windowDidBecomeKey(_ notification: Notification) {
        // Set up local event monitor for key events
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // 53 is the key code for Esc
                self?.hideWindow()
                return nil // Consume the event
            }
            return event
        }
    }
}
