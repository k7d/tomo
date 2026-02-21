import Foundation

let dismissTimerIn: TimeInterval = 5
let maxTimerTomos = 10

extension Notification.Name {
    static let appStateChanged = Notification.Name("appStateChanged")
}

class AppState {
    static let shared = AppState()

    var timerConfigs: [TimerConfig] = []
    private var lastAction: StartedTimer?
    private var committedHistory: TimerHistory = [:]
    private var tick: Timer?

    // Status bar controller reference (set by AppDelegate)
    weak var statusBarController: StatusBarController?

    private init() {}

    func initialize() {
        loadFromDefaults()
        restartTicker()
        notifyListeners()
    }

    // MARK: - Config Lookup

    func config(for id: TimerId) -> TimerConfig? {
        timerConfigs.first { $0.id == id }
    }

    // MARK: - Timer Configs CRUD

    func updateTimerConfig(_ config: TimerConfig) {
        if let i = timerConfigs.firstIndex(where: { $0.id == config.id }) {
            timerConfigs[i] = config
        }
        persistTimerConfigs()
        notifyListeners()
    }

    func addNewTimer() -> TimerConfig {
        let id = UUID().uuidString
        let usedColors = Set(timerConfigs.map { $0.color })
        let available = ColorName.allCases.filter { !usedColors.contains($0) }
        let color = available.randomElement() ?? ColorName.allCases.randomElement()!

        let config = TimerConfig(
            id: id, color: color, sound: .bowl,
            name: "Timer \(timerConfigs.count + 1)",
            duration: 10 * 60
        )
        timerConfigs.append(config)
        persistTimerConfigs()
        notifyListeners()
        return config
    }

    func deleteTimer(_ config: TimerConfig) {
        timerConfigs.removeAll { $0.id == config.id }
        persistTimerConfigs()
        notifyListeners()
    }

    // MARK: - Current/Active Timer

    private func getCurrentTimer() -> (StartedTimer?, Bool) {
        guard var timer = lastAction else { return (nil, false) }

        for i in 0..<maxTimerTomos {
            let duration = i == 0 ? timer.adjustedDuration : (config(for: timer.configId)?.duration ?? timer.adjustedDuration)
            let nextStart = timer.start.addingTimeInterval(duration + dismissTimerIn)

            if Date() < nextStart {
                return (timer, true)
            } else {
                // Timer completed — commit to history so chained runs are tracked
                committedHistory.upsertRun(configId: timer.configId, start: timer.start, duration: duration)

                guard let cfg = config(for: timer.configId),
                      let nextId = cfg.startNextId,
                      let nextConfig = config(for: nextId) else {
                    return (timer, false)
                }
                timer = StartedTimer(
                    configId: nextConfig.id,
                    start: nextStart,
                    adjustedDuration: nextConfig.duration,
                    totalDuration: nextConfig.duration,
                    isPaused: false
                )
            }
        }
        return (timer, false)
    }

    func getActiveTimer() -> StartedTimer? {
        let (timer, active) = getCurrentTimer()
        return active ? timer : nil
    }

    func getActiveTimerConfig() -> TimerConfig? {
        guard let timer = getActiveTimer() else { return nil }
        return config(for: timer.configId)
    }

    func getNextTimer(for timer: StartedTimer) -> TimerConfig? {
        guard let cfg = config(for: timer.configId),
              let nextId = cfg.startNextId else { return nil }
        return config(for: nextId)
    }

    // MARK: - Timer Actions

    func startTimer(configId: TimerId) {
        let (current, _) = getCurrentTimer()
        commitToHistory(current)

        guard let cfg = config(for: configId) else { return }
        let isPaused = current?.isPaused ?? false
        let duration = isPaused ? current!.adjustedDuration : cfg.duration
        let totalDuration = isPaused ? current!.totalDuration : duration

        lastAction = StartedTimer(
            configId: configId,
            start: Date(),
            adjustedDuration: duration,
            totalDuration: totalDuration,
            isPaused: false
        )
        persistLastAction()
        restartTicker()
        statusBarController?.hideWindow()
        notifyListeners()
    }

    func stopTimer() {
        guard let timer = getActiveTimer() else { return }
        commitToHistory(timer)
        lastAction = nil
        persistLastAction()
        notifyListeners()
    }

    func pauseTimer() {
        guard let timer = getActiveTimer() else { return }
        commitToHistory(timer)
        let remaining = timer.remaining

        lastAction = StartedTimer(
            configId: timer.configId,
            start: Date(),
            adjustedDuration: remaining,
            totalDuration: timer.totalDuration,
            isPaused: true
        )
        persistLastAction()
        notifyListeners()
    }

    func resumeTimer() {
        guard let timer = getActiveTimer() else { return }
        startTimer(configId: timer.configId)
    }

    func plusTimer() {
        guard let timer = getActiveTimer(),
              let cfg = config(for: timer.configId) else { return }
        commitToHistory(timer)
        let adjusted = timer.remaining + cfg.plusDuration
        let total = timer.totalDuration + cfg.plusDuration

        lastAction = StartedTimer(
            configId: timer.configId,
            start: Date(),
            adjustedDuration: adjusted,
            totalDuration: total,
            isPaused: false
        )
        persistLastAction()
        restartTicker()
        statusBarController?.hideWindow()
        notifyListeners()
    }

    func restartTimer() {
        guard let timer = getActiveTimer() else { return }
        stopTimer()
        startTimer(configId: timer.configId)
    }

    // MARK: - History

    private func commitToHistory(_ timer: StartedTimer?) {
        guard let timer = timer else { return }
        let duration = min(Date().timeIntervalSince(timer.start), timer.adjustedDuration)
        committedHistory.upsertRun(configId: timer.configId, start: timer.start, duration: duration)
    }

    var history: TimerHistory {
        // getCurrentTimer() commits completed chain timers to committedHistory
        let (timer, _) = getCurrentTimer()
        var h = committedHistory
        if let timer = timer {
            let duration = min(Date().timeIntervalSince(timer.start), timer.adjustedDuration)
            h.upsertRun(configId: timer.configId, start: timer.start, duration: duration)
        }
        return h
    }

    func currentDayDuration(for timerId: TimerId) -> TimeInterval {
        history.currentDayDuration(for: timerId)
    }

    // MARK: - Tick

    private func restartTicker() {
        tick?.invalidate()

        var idBefore: TimerId?
        var startBefore: Date?
        var remainingBefore: TimeInterval?
        var stateBefore: TimerState?

        tick = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let timer = self.getActiveTimer()
            let cfg = timer.flatMap { self.config(for: $0.configId) }

            if timer?.configId != idBefore ||
                timer?.start != startBefore ||
                timer?.remaining != remainingBefore ||
                timer?.state != stateBefore {

                self.notifyListeners()

                if timer?.state == .done && stateBefore != .done {
                    self.statusBarController?.showWindow()
                    if let sound = cfg?.sound {
                        SoundPlayer.shared.play(sound)
                    }
                }

                idBefore = timer?.configId
                startBefore = timer?.start
                remainingBefore = timer?.remaining
                stateBefore = timer?.state
            }
        }
        RunLoop.main.add(tick!, forMode: .common)
    }

    // MARK: - Persistence

    private static let isDebug: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()

    static func defaultsKey(_ key: String) -> String {
        isDebug ? "debug_\(key)" : key
    }

    private func persistTimerConfigs() {
        guard let data = try? JSONEncoder().encode(timerConfigs) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey("timerConfigs"))
    }

    private func persistLastAction() {
        if let action = lastAction, let data = try? JSONEncoder().encode(action) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey("lastAction"))
        } else {
            UserDefaults.standard.removeObject(forKey: Self.defaultsKey("lastAction"))
        }
    }

    private func loadFromDefaults() {
        if let data = UserDefaults.standard.data(forKey: Self.defaultsKey("timerConfigs")),
           let configs = try? JSONDecoder().decode([TimerConfig].self, from: data) {
            timerConfigs = configs
        } else {
            timerConfigs = TimerConfig.defaultConfigs()
        }

        if let data = UserDefaults.standard.data(forKey: Self.defaultsKey("lastAction")),
           let action = try? JSONDecoder().decode(StartedTimer.self, from: data) {
            lastAction = action
        }
    }

    // MARK: - Notify

    func notifyListeners() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .appStateChanged, object: nil)
        }
    }
}
