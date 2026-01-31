import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var statusBar: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create window
        window = TomoWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: defaultWindowHeight),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.appearance = NSAppearance(named: .vibrantLight)
        window.titlebarAppearsTransparent = true
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.title = ""
        window.isReleasedWhenClosed = false

        // Set up status bar
        statusBar = StatusBarController(window)
        AppState.shared.statusBarController = statusBar

        // Set up main view controller
        let timersVC = TimersViewController()
        window.contentViewController = timersVC

        // Initialize app state
        AppState.shared.initialize()

        // Show window
        statusBar?.showWindow()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

// Subclass to allow key status
class TomoWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
