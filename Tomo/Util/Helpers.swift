import AppKit

let windowWidth: CGFloat = 396
let defaultWindowHeight: CGFloat = 190

let grayColor = NSColor(srgbRed: 0x8a/255, green: 0x8e/255, blue: 0x9b/255, alpha: 1)
let grayTextColor = NSColor.white
let bgColor = NSColor(srgbRed: 0x6c/255, green: 0x6e/255, blue: 0x79/255, alpha: 1)
let labelTextColor = NSColor(srgbRed: 0xc4/255, green: 0xc7/255, blue: 0xcf/255, alpha: 1)

func formatDuration(_ seconds: TimeInterval) -> String {
    let total = Int(ceil(max(0, seconds)))
    let h = total / 3600
    let m = (total % 3600) / 60
    let s = total % 60
    if h > 0 {
        return "\(h):\(String(format: "%02d", m)):\(String(format: "%02d", s))"
    }
    return "\(m):\(String(format: "%02d", s))"
}

extension NSView {
    func removeAllSubviews() {
        subviews.forEach { $0.removeFromSuperview() }
    }
}

extension NSColor {
    func withBrightness(multiplier: CGFloat) -> NSColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        let rgb = usingColorSpace(.sRGB) ?? self
        rgb.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return NSColor(hue: h, saturation: s, brightness: min(b * multiplier, 1), alpha: a)
    }

    func lightenBy(_ amount: CGFloat) -> NSColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        let rgb = usingColorSpace(.sRGB) ?? self
        rgb.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return NSColor(hue: h, saturation: s, brightness: min(b + amount, 1), alpha: a)
    }

    var hslLightness: CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        let rgb = usingColorSpace(.sRGB) ?? self
        rgb.getRed(&r, green: &g, blue: &b, alpha: &a)
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        return (maxC + minC) / 2
    }

    func withHSLLightness(_ target: CGFloat) -> NSColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        let rgb = usingColorSpace(.sRGB) ?? self
        rgb.getRed(&r, green: &g, blue: &b, alpha: &a)
        // Simple approximation: scale to target lightness
        let current = hslLightness
        guard current > 0 else { return self }
        let factor = target / current
        return NSColor(srgbRed: min(r * factor, 1), green: min(g * factor, 1), blue: min(b * factor, 1), alpha: a)
    }
}

func loadSVGIcon(named name: String, size: CGFloat = 20, color: NSColor? = nil) -> NSImage? {
    guard let url = Bundle.main.url(forResource: name, withExtension: "svg", subdirectory: "Icons") else { return nil }
    guard let data = try? Data(contentsOf: url),
          let svgString = String(data: data, encoding: .utf8) else { return nil }

    // Simple SVG rendering via NSImage
    let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
        // Use WebKit-free approach: create an attributed string or use the SVG data directly
        return false
    }

    // Fallback: load SVG via NSImage directly (macOS 11+)
    if let nsImage = NSImage(contentsOf: url) {
        let finalImage = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            nsImage.draw(in: rect)
            return true
        }
        if let color = color {
            return finalImage.tintedWith(color)
        }
        return finalImage
    }
    return image
}

extension NSImage {
    func tintedWith(_ color: NSColor) -> NSImage {
        let img = self.copy() as! NSImage
        img.lockFocus()
        color.set()
        let rect = NSRect(origin: .zero, size: img.size)
        rect.fill(using: .sourceIn)
        img.unlockFocus()
        return img
    }
}
