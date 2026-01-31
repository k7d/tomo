import AppKit

class TimersViewController: NSViewController {
    private let contentRoot = ContentRootView()
    private var observer: NSObjectProtocol?
    private var dismissIndicator: TimerDismissIndicator?
    private var lastTimerState: TimerState?

    override func loadView() {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = bgColor.cgColor

        contentRoot.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(contentRoot)
        contentRoot.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        contentRoot.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
        contentRoot.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        contentRoot.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true

        // Settings button (bottom-right)
        let settingsBtn = makeNavButton(systemName: "gearshape.fill", tooltip: "Settings") { [weak self] in
            let settingsVC = SettingsViewController()
            self?.view.window?.contentViewController = settingsVC
        }
        container.addSubview(settingsBtn)
        settingsBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8).isActive = true
        settingsBtn.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8).isActive = true

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
        let activeTimer = state.getActiveTimer()
        updateStatusBar(activeTimer)

        var views: [NSView]
        if let timer = activeTimer, let cfg = state.config(for: timer.configId) {
            views = buildActiveTimerViews(timer: timer, config: cfg, state: state)
        } else {
            views = buildStartableTimerViews(state: state)
        }
        contentRoot.setChildren(views)
    }

    // MARK: - Status Bar

    private func updateStatusBar(_ timer: StartedTimer?) {
        guard let statusBar = AppState.shared.statusBarController else { return }
        guard let timer = timer, let cfg = AppState.shared.config(for: timer.configId) else {
            statusBar.statusItemView.clearTimer()
            return
        }
        let endTime = timer.start.addingTimeInterval(timer.adjustedDuration)
        let pausedRemaining = timer.isPaused ? timer.adjustedDuration : 0
        statusBar.statusItemView.setTimer(
            endTime: endTime,
            totalDurationSeconds: timer.totalDuration,
            isPaused: timer.isPaused,
            pausedRemainingSeconds: pausedRemaining,
            bgColor: cfg.color.statusBarColor,
            textColor: cfg.color.textColor
        )
    }

    // MARK: - Active Timer Views

    private func buildActiveTimerViews(timer: StartedTimer, config: TimerConfig, state: AppState) -> [NSView] {
        var views: [NSView] = []

        // Main timer button
        let iconName: String
        switch timer.state {
        case .done: iconName = "checkmark"
        case .running: iconName = "pause.fill"
        case .paused: iconName = "play.fill"
        }

        let icon = makeIconView(systemName: iconName, color: config.color.textColor)

        // Wrap icon with dismiss indicator if done
        let leftView: NSView
        if timer.state == .done {
            let indicator = TimerDismissIndicator(child: icon)
            indicator.arcColor = config.color.textColor
            if lastTimerState != .done {
                DispatchQueue.main.async { indicator.startAnimation() }
            }
            dismissIndicator = indicator
            // Shift left to compensate for padding
            leftView = indicator
        } else {
            dismissIndicator?.stopAnimation()
            dismissIndicator = nil
            leftView = icon
        }
        lastTimerState = timer.state

        let durationLabel = makeDurationLabel(timer.remaining, color: config.color.textColor)
        let nameView = makeTimerNameView(config: config)

        let mainBtn = ActionButton()
        mainBtn.buttonColor = config.color.nsColor
        mainBtn.buttonTextColor = config.color.textColor
        mainBtn.progress = CGFloat(timer.completed)
        mainBtn.leftView = leftView
        mainBtn.centerView = durationLabel
        mainBtn.rightView = nameView
        mainBtn.onPressed = { [weak self] in
            switch timer.state {
            case .running: state.pauseTimer()
            case .paused: state.resumeTimer()
            case .done:
                if let next = state.getNextTimer(for: timer) {
                    state.startTimer(configId: next.id)
                } else {
                    state.stopTimer()
                }
            }
        }
        views.append(mainBtn)
        views.append(makeSpacer(20))

        // Action buttons row: Stop | +5m | Restart
        let row = NSStackView()
        row.orientation = .horizontal
        row.distribution = .fillEqually
        row.spacing = 20
        row.translatesAutoresizingMaskIntoConstraints = false

        let stopBtn = ActionButton()
        stopBtn.buttonColor = config.color.nsColor
        stopBtn.buttonTextColor = config.color.textColor
        stopBtn.centerView = makeIconView(systemName: "stop.fill", color: config.color.textColor)
        stopBtn.minHeight = 45
        stopBtn.onPressed = { state.stopTimer() }
        row.addArrangedSubview(stopBtn)

        let plusBtn = ActionButton()
        plusBtn.buttonColor = config.color.nsColor
        plusBtn.buttonTextColor = config.color.textColor
        let plusLabel = NSTextField(labelWithString: "+\(Int(config.plusDuration / 60))m")
        plusLabel.font = .systemFont(ofSize: 22, weight: .bold)
        plusLabel.textColor = config.color.textColor
        plusLabel.alignment = .center
        plusBtn.centerView = plusLabel
        plusBtn.minHeight = 45
        plusBtn.onPressed = { state.plusTimer() }
        row.addArrangedSubview(plusBtn)

        let restartBtn = ActionButton()
        restartBtn.buttonColor = config.color.nsColor
        restartBtn.buttonTextColor = config.color.textColor
        restartBtn.centerView = makeIconView(systemName: "arrow.counterclockwise", color: config.color.textColor)
        restartBtn.minHeight = 45
        restartBtn.onPressed = { state.restartTimer() }
        row.addArrangedSubview(restartBtn)

        views.append(row)

        // "Will start next" section
        if timer.state == .done, let nextConfig = state.getNextTimer(for: timer) {
            views.append(makeSpacer(20))
            let nextLabel = NSTextField(labelWithString: "Will start next:")
            nextLabel.font = .systemFont(ofSize: 14, weight: .medium)
            nextLabel.textColor = labelTextColor
            nextLabel.alignment = .center
            views.append(nextLabel)
            views.append(makeSpacer(10))

            let nextBtn = makeTimerButton(
                config: nextConfig,
                left: makeIconView(systemName: "arrow.forward", color: nextConfig.color.textColor),
                right: makeTimerNameView(config: nextConfig)
            )
            views.append(nextBtn)
        }

        return views
    }

    // MARK: - Startable Timer Views

    private func buildStartableTimerViews(state: AppState) -> [NSView] {
        var views: [NSView] = []
        for (i, config) in state.timerConfigs.enumerated() {
            let btn = makeTimerButton(
                config: config,
                left: makeIconView(systemName: "play.fill", color: config.color.textColor),
                right: makeTimerNameView(config: config),
                onPressed: { state.startTimer(configId: config.id) }
            )
            views.append(btn)
            if i < state.timerConfigs.count - 1 {
                views.append(makeSpacer(20))
            }
        }
        lastTimerState = nil
        dismissIndicator = nil
        return views
    }
}

func makeSpacer(_ height: CGFloat) -> NSView {
    let v = NSView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.heightAnchor.constraint(equalToConstant: height).isActive = true
    return v
}
