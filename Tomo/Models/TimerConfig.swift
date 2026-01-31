import AppKit

typealias TimerId = String

enum ColorName: String, CaseIterable, Codable {
    case color1, color2, color3, color4, color5, color6, color7, color8

    var rgb: (CGFloat, CGFloat, CGFloat) {
        switch self {
        case .color1: return (0x35/255.0, 0xa2/255.0, 0x1e/255.0)
        case .color2: return (0x00/255.0, 0x9f/255.0, 0x81/255.0)
        case .color3: return (0x00/255.0, 0x8f/255.0, 0xf8/255.0)
        case .color4: return (0xab/255.0, 0x6c/255.0, 0xfe/255.0)
        case .color5: return (0xe1/255.0, 0x4a/255.0, 0xdf/255.0)
        case .color6: return (0xff/255.0, 0x49/255.0, 0x53/255.0)
        case .color7: return (0xff/255.0, 0x64/255.0, 0x2d/255.0)
        case .color8: return (0xd8/255.0, 0x79/255.0, 0x00/255.0)
        }
    }

    var nsColor: NSColor {
        let (r, g, b) = rgb
        return NSColor(srgbRed: r, green: g, blue: b, alpha: 1)
    }

    var textColor: NSColor {
        return .white
    }

    /// Darkened color for status bar (multiply by 0.8)
    var statusBarColor: NSColor {
        let (r, g, b) = rgb
        return NSColor(srgbRed: r * 0.8, green: g * 0.8, blue: b * 0.8, alpha: 1)
    }
}

enum Sound: String, CaseIterable, Codable {
    case none, bowl, bell, ring, whistle, bird, cheer, yeah
}

struct TimerConfig: Codable {
    let id: TimerId
    var color: ColorName
    var sound: Sound
    var name: String
    var duration: TimeInterval // seconds
    var startNextId: TimerId?

    var plusDuration: TimeInterval { 5 * 60 } // 5 minutes

    static func defaultConfigs() -> [TimerConfig] {
        [
            TimerConfig(id: "focus", color: .color1, sound: .bowl, name: "Focus", duration: 25 * 60, startNextId: "break"),
            TimerConfig(id: "break", color: .color3, sound: .bird, name: "Break", duration: 5 * 60),
        ]
    }
}
