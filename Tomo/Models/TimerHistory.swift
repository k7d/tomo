import Foundation

typealias DateString = String
// history[date][timerId][startMs] = durationSeconds
typealias TimerHistory = [DateString: [TimerId: [Int: Int]]]

extension Date {
    var slashDateString: DateString {
        let f = DateFormatter()
        f.dateFormat = "yyyy/MM/dd"
        return f.string(from: self)
    }
}

extension Dictionary where Key == DateString, Value == [TimerId: [Int: Int]] {
    mutating func upsertRun(configId: TimerId, start: Date, duration: TimeInterval) {
        let date = start.slashDateString
        let currentDuration = Date().timeIntervalSince(start)
        let effectiveDuration = Swift.min(currentDuration, duration)
        let startMs = Int(start.timeIntervalSince1970 * 1000)
        let seconds = Int(effectiveDuration)

        if self[date] == nil { self[date] = [:] }
        if self[date]![configId] == nil { self[date]![configId] = [:] }
        self[date]![configId]![startMs] = seconds
    }

    mutating func merge(other: TimerHistory) {
        for (date, timers) in other {
            if self[date] == nil { self[date] = [:] }
            for (timerId, runs) in timers {
                if self[date]![timerId] == nil { self[date]![timerId] = [:] }
                for (startMs, duration) in runs {
                    self[date]![timerId]![startMs] = duration
                }
            }
        }
    }

    func currentDayDuration(for timerId: TimerId) -> TimeInterval {
        let today = Date().slashDateString
        guard let runs = self[today]?[timerId] else { return 0 }
        return TimeInterval(runs.values.reduce(0, +))
    }
}
