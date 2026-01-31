import AppKit

func makeNavButton(systemName: String, tooltip: String, action: @escaping () -> Void) -> NSButton {
    let btn = NSButton()
    btn.translatesAutoresizingMaskIntoConstraints = false
    btn.bezelStyle = .inline
    btn.isBordered = false
    let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
    btn.image = NSImage(systemSymbolName: systemName, accessibilityDescription: tooltip)?.withSymbolConfiguration(config)
    btn.contentTintColor = NSColor(srgbRed: 0x9B/255, green: 0x9B/255, blue: 0x99/255, alpha: 1)
    btn.toolTip = tooltip
    btn.target = nil
    btn.widthAnchor.constraint(equalToConstant: 30).isActive = true
    btn.heightAnchor.constraint(equalToConstant: 30).isActive = true

    // Use a helper target to call the closure
    let helper = ButtonActionHelper(action: action)
    btn.target = helper
    btn.action = #selector(ButtonActionHelper.invoke)
    // Prevent helper from being deallocated
    objc_setAssociatedObject(btn, "actionHelper", helper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

    return btn
}

class ButtonActionHelper: NSObject {
    let action: () -> Void
    init(action: @escaping () -> Void) { self.action = action }
    @objc func invoke() { action() }
}
