import AppKit

class SettingsViewController: NSViewController {
    private let contentRoot = ContentRootView()
    private var observer: NSObjectProtocol?

    override func loadView() {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = bgColor.cgColor

        // App bar
        let appBar = NSView()
        appBar.translatesAutoresizingMaskIntoConstraints = false
        appBar.wantsLayer = true
        appBar.layer?.backgroundColor = bgColor.cgColor
        container.addSubview(appBar)
        appBar.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        appBar.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        appBar.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        appBar.heightAnchor.constraint(equalToConstant: 52).isActive = true

        // Back button
        let backBtn = makeNavButton(systemName: "chevron.left", tooltip: "Back") { [weak self] in
            self?.view.window?.contentViewController = TimersViewController()
        }
        appBar.addSubview(backBtn)
        backBtn.leadingAnchor.constraint(equalTo: appBar.leadingAnchor, constant: 8).isActive = true
        backBtn.centerYAnchor.constraint(equalTo: appBar.centerYAnchor).isActive = true

        // Title
        let title = NSTextField(labelWithString: "Settings")
        title.font = .systemFont(ofSize: 20, weight: .medium)
        title.textColor = .white
        title.translatesAutoresizingMaskIntoConstraints = false
        appBar.addSubview(title)
        title.centerXAnchor.constraint(equalTo: appBar.centerXAnchor).isActive = true
        title.centerYAnchor.constraint(equalTo: appBar.centerYAnchor).isActive = true

        // Quit button
        let quitBtn = makeNavButton(systemName: "rectangle.portrait.and.arrow.right", tooltip: "Quit") {
            NSApp.terminate(nil)
        }
        appBar.addSubview(quitBtn)
        quitBtn.trailingAnchor.constraint(equalTo: appBar.trailingAnchor, constant: -8).isActive = true
        quitBtn.centerYAnchor.constraint(equalTo: appBar.centerYAnchor).isActive = true

        // Content
        contentRoot.hasAppBar = true
        container.addSubview(contentRoot)
        contentRoot.topAnchor.constraint(equalTo: appBar.bottomAnchor).isActive = true
        contentRoot.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
        contentRoot.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        contentRoot.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true

        self.view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        observer = NotificationCenter.default.addObserver(forName: .appStateChanged, object: nil, queue: .main) { [weak self] _ in
            self?.rebuild()
        }
        rebuild()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        contentRoot.updateWindowHeight()
    }

    deinit {
        if let observer = observer { NotificationCenter.default.removeObserver(observer) }
    }

    private func rebuild() {
        let state = AppState.shared
        var views: [NSView] = []

        for config in state.timerConfigs {
            let btn = makeTimerButton(
                config: config,
                left: makeIconView(systemName: "pencil", color: config.color.textColor),
                center: makeDurationLabel(config.duration, color: config.color.textColor),
                right: makeTimerNameView(config: config, showDayTotal: false),
                onPressed: { [weak self] in
                    let editVC = EditTimerViewController(config: config)
                    self?.view.window?.contentViewController = editVC
                }
            )
            views.append(btn)
            views.append(makeSpacer(20))
        }

        // New timer button
        let newBtn = ActionButton()
        newBtn.leftView = makeIconView(systemName: "plus", color: grayTextColor)
        let newLabel = NSTextField(labelWithString: "New timer")
        newLabel.font = .systemFont(ofSize: 16, weight: .medium)
        newLabel.textColor = grayTextColor
        newBtn.centerView = newLabel
        newBtn.onPressed = { [weak self] in
            let config = state.addNewTimer()
            let editVC = EditTimerViewController(config: config)
            self?.view.window?.contentViewController = editVC
        }
        views.append(newBtn)

        contentRoot.setChildren(views)
    }
}
