import Cocoa
import FlutterMacOS

let windowWidth = 396.0
let defaultWindowHeight = 190.0

@main
class AppDelegate: FlutterAppDelegate {


    var statusBar: StatusBarController?

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    override func applicationDidFinishLaunching(_ aNotification: Notification) {
        guard let window = mainFlutterWindow else {
            print("mainFlutterWindow is nil")
            return
        }

        window.styleMask = [.titled, .fullSizeContentView]
        window.setContentSize(NSSize(width: windowWidth, height: defaultWindowHeight))
        window.appearance = NSAppearance(named: .vibrantLight)
        window.titlebarAppearsTransparent = true
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.title = "";
        let controller: FlutterViewController = window.contentViewController as! FlutterViewController

        statusBar = StatusBarController.init(mainFlutterWindow!)

        statusBar?.showWindow()

        let channel = FlutterMethodChannel(name: "dev.k7d.tomo/status_bar",
                                           binaryMessenger: controller.engine.binaryMessenger)

        statusBar?.statusItemView.onTimerComplete = {
            channel.invokeMethod("onTimerComplete", arguments: nil)
        }

        channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "setStatusBarTimer":
                if let args = call.arguments as? [String: Any],
                   let endTimeMs = args["endTimeMs"] as? Double,
                   let totalDurationSeconds = args["totalDurationSeconds"] as? Double,
                   let isPaused = args["isPaused"] as? Bool,
                   let pausedRemainingSeconds = args["pausedRemainingSeconds"] as? Double,
                   let bgColor = args["bgColor"] as? Array<Double>,
                   let textColor = args["textColor"] as? Array<Double> {
                    let endTime = Date(timeIntervalSince1970: endTimeMs / 1000.0)
                    self?.statusBar?.statusItemView.setTimer(
                        endTime: endTime,
                        totalDurationSeconds: totalDurationSeconds,
                        isPaused: isPaused,
                        pausedRemainingSeconds: pausedRemainingSeconds,
                        bgColor: NSColor(red: bgColor[0], green: bgColor[1], blue: bgColor[2], alpha: 1),
                        textColor: NSColor(red: textColor[0], green: textColor[1], blue: textColor[2], alpha: 1)
                    )
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                }
                break
            case "clearStatusBarTimer":
                self?.statusBar?.statusItemView.clearTimer()
                result(nil)
                break
            case "setContentHeight":
                if let args = call.arguments as? [String: Any],
                   let height = args["height"] as? Double {
                    let screen = NSScreen.main
                    let maxHeight = screen?.frame.height
                    let limitedHeight = maxHeight != nil ? min(height, maxHeight! * 0.5) : height
                    window.setContentSize(NSSize(width: windowWidth, height: limitedHeight))
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                }
                break
            case "openWindow":
                self?.statusBar?.showWindow()
                break
            case "closeWindow":
                self?.statusBar?.hideWindow()
                break
            default:
                result(FlutterMethodNotImplemented)
            }
        }


        super.applicationDidFinishLaunching(aNotification)
    }
}
