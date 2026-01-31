import Foundation

class CloudSyncManager {
    static let shared = CloudSyncManager()
    private let store = NSUbiquitousKeyValueStore.default
    private var observer: NSObjectProtocol?

    func start() {
        // Listen for remote changes
        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main
        ) { [weak self] notification in
            self?.handleRemoteChange(notification)
        }
        store.synchronize()
    }

    func syncTimerConfigs(_ configs: [TimerConfig]) {
        guard let data = try? JSONEncoder().encode(configs) else { return }
        store.set(data, forKey: "timerConfigs")
        store.synchronize()
    }

    func syncLastAction(_ action: StartedTimer?) {
        if let action = action, let data = try? JSONEncoder().encode(action) {
            store.set(data, forKey: "lastAction")
        } else {
            store.removeObject(forKey: "lastAction")
        }
        store.synchronize()
    }

    private func handleRemoteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else { return }

        if reason == NSUbiquitousKeyValueStoreServerChange || reason == NSUbiquitousKeyValueStoreInitialSyncChange {
            // Merge remote configs
            if let data = store.data(forKey: "timerConfigs"),
               let configs = try? JSONDecoder().decode([TimerConfig].self, from: data) {
                AppState.shared.timerConfigs = configs
            }
            AppState.shared.notifyListeners()
        }
    }
}
