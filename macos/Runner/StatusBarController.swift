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

class StatusItemView {

    let font = NSFont.systemFont(ofSize: 13, weight: NSFont.Weight.regular)
    let icon = NSImage(named: "MenuBarIcon")
    var tintedIcon = NSImage(named: "MenuBarIcon")
    var statusItem: NSStatusItem
    var isHighlighted = false

    // Timer state for native-driven ticking
    var endTime: Date?
    var totalDurationSeconds: Double = 0
    var isPaused = false
    var pausedRemainingSeconds: Double = 0
    var bgColor = NSColor(red: 0x8e/255, green: 0x8e/255, blue: 0x8d/255, alpha: 1)
    var textColor = NSColor(red: 1, green: 1, blue: 1, alpha: 1) {
        didSet {
            tintedIcon = icon?.tinted(with: textColor)
        }
    }

    private var nativeTimer: Timer?

    init() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: calcStatusItemLength(""))
    }

    func setTimer(endTime: Date, totalDurationSeconds: Double, isPaused: Bool, pausedRemainingSeconds: Double, bgColor: NSColor, textColor: NSColor) {
        self.endTime = endTime
        self.totalDurationSeconds = totalDurationSeconds
        self.isPaused = isPaused
        self.pausedRemainingSeconds = pausedRemainingSeconds
        self.bgColor = bgColor
        self.textColor = textColor
        startNativeTimer()
        tick()
    }

    func clearTimer() {
        stopNativeTimer()
        endTime = nil
        totalDurationSeconds = 0
        isPaused = false
        pausedRemainingSeconds = 0
        bgColor = NSColor(red: 0x8e/255, green: 0x8e/255, blue: 0x8d/255, alpha: 1)
        textColor = NSColor(red: 1, green: 1, blue: 1, alpha: 1)
        updateButtonImage(remainingTime: "", completed: 0)
    }

    private func startNativeTimer() {
        stopNativeTimer()
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        nativeTimer = timer
    }

    private func stopNativeTimer() {
        nativeTimer?.invalidate()
        nativeTimer = nil
    }

    private func tick() {
        let remainingSeconds: Double
        if isPaused {
            remainingSeconds = pausedRemainingSeconds
        } else if let endTime = endTime {
            remainingSeconds = max(0, endTime.timeIntervalSinceNow)
        } else {
            remainingSeconds = 0
        }

        let completed: CGFloat = totalDurationSeconds > 0
            ? CGFloat((totalDurationSeconds - remainingSeconds) / totalDurationSeconds)
            : 0

        let totalSeconds = Int(ceil(remainingSeconds))
        let remainingTime: String
        if totalSeconds <= 0 && endTime == nil {
            remainingTime = ""
        } else {
            let h = totalSeconds / 3600
            let m = (totalSeconds % 3600) / 60
            let s = totalSeconds % 60
            if h > 0 {
                remainingTime = "\(h):\(String(format: "%02d", m)):\(String(format: "%02d", s))"
            } else {
                remainingTime = "\(m):\(String(format: "%02d", s))"
            }
        }

        updateButtonImage(remainingTime: remainingTime, completed: completed)

        // Stop ticking when done (not paused and time is up)
        if !isPaused && remainingSeconds <= 0 && endTime != nil {
            stopNativeTimer()
        }
    }

    func updateButtonImage(remainingTime: String, completed: CGFloat) {
        statusItem.length = calcStatusItemLength(remainingTime)
        let width = statusItem.length
        let height = NSStatusBar.system.thickness
        let capturedBgColor = bgColor
        let capturedTextColor = textColor
        let capturedTintedIcon = tintedIcon
        let capturedFont = font
        let capturedCompleted = completed
        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { drawRect in
            let bgRect = drawRect.insetBy(dx: 0, dy: 1.5)
            Self.drawBox(bgRect: bgRect, completed: capturedCompleted, bgColor: capturedBgColor)
            if remainingTime == "" {
                Self.drawIcon(bgRect: bgRect, tintedIcon: capturedTintedIcon)
            } else {
                Self.drawRemainingTime(bgRect: bgRect, remainingTime: remainingTime, font: capturedFont, textColor: capturedTextColor)
            }
            return true
        }
        image.isTemplate = false
        statusItem.button?.image = image
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.appearsDisabled = false
        statusItem.button?.contentTintColor = nil
        statusItem.button?.needsDisplay = true
        statusItem.button?.display()
    }

    static func fillRoundedRect(rect: CGRect, radius: CGFloat, color: NSColor) {
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

    static func drawBox(bgRect: NSRect, completed: CGFloat, bgColor: NSColor) {
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

    static func drawRemainingTime(bgRect: NSRect, remainingTime: String, font: NSFont, textColor: NSColor) {
        let ps = NSMutableParagraphStyle()
        ps.alignment = .center
        ps.lineBreakMode = .byClipping
        remainingTime.draw(
            in: bgRect.offsetBy(dx: 0, dy: -1),
            withAttributes: [
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.paragraphStyle: ps,
                NSAttributedString.Key.foregroundColor: textColor
            ])
    }

    static func drawIcon(bgRect: NSRect, tintedIcon: NSImage?) {
        // Center icon:
        let width = 18.0
        let height = 8.0
        let iconRect = NSMakeRect((bgRect.size.width - width) * 0.5 + bgRect.origin.x, (bgRect.size.height - height) * 0.5 + bgRect.origin.y, width, height).integral
        tintedIcon?.draw(in:iconRect)
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
