import Foundation

enum TimerState {
    case done, running, paused
}

struct StartedTimer: Codable {
    let configId: TimerId
    let start: Date
    var adjustedDuration: TimeInterval
    var totalDuration: TimeInterval
    var isPaused: Bool

    var remaining: TimeInterval {
        if isPaused {
            return adjustedDuration
        }
        return max(0, adjustedDuration - Date().timeIntervalSince(start))
    }

    var state: TimerState {
        if remaining <= 0 {
            return .done
        } else if isPaused {
            return .paused
        }
        return .running
    }

    var completed: Double {
        guard totalDuration > 0 else { return 0 }
        return (totalDuration - remaining) / totalDuration
    }

    var finish: Date {
        start.addingTimeInterval(adjustedDuration)
    }

    enum CodingKeys: String, CodingKey {
        case configId = "id"
        case start
        case adjustedDuration = "adjusted-duration"
        case totalDuration = "total-duration"
        case isPaused = "paused?"
    }

    init(configId: TimerId, start: Date, adjustedDuration: TimeInterval, totalDuration: TimeInterval, isPaused: Bool) {
        self.configId = configId
        self.start = start
        self.adjustedDuration = adjustedDuration
        self.totalDuration = totalDuration
        self.isPaused = isPaused
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        configId = try c.decode(String.self, forKey: .configId)
        let startString = try c.decode(String.self, forKey: .start)
        start = ISO8601DateFormatter().date(from: startString) ?? Date()
        adjustedDuration = try c.decode(TimeInterval.self, forKey: .adjustedDuration)
        totalDuration = try c.decode(TimeInterval.self, forKey: .totalDuration)
        isPaused = try c.decode(Bool.self, forKey: .isPaused)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(configId, forKey: .configId)
        try c.encode(ISO8601DateFormatter().string(from: start), forKey: .start)
        try c.encode(adjustedDuration, forKey: .adjustedDuration)
        try c.encode(totalDuration, forKey: .totalDuration)
        try c.encode(isPaused, forKey: .isPaused)
    }
}
