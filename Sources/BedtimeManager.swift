import Foundation
import WidgetKit

struct CountdownEvent: Identifiable, Codable {
    var id: UUID
    var name: String
    var hour: Int
    var minute: Int
    var repeatDays: Set<Int> // 1 (Sun) to 7 (Sat)
    var isEnabled: Bool
    
    var timeDate: Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        return Calendar.current.date(from: comps) ?? Date()
    }
}

@Observable
final class BedtimeManager {
    static let shared = BedtimeManager()

    var events: [CountdownEvent] = [] { didSet { save() } }
    var showSeconds: Bool { didSet { save() } }
    var warnWhenNear: Bool { didSet { save() } }
    var isCompactMode: Bool { didSet { save() } }

    var currentTime: Date = Date()
    private var timer: Timer?

    private let userDefaults = UserDefaults(suiteName: "group.space.kev1nweng.zzz")!

    private enum Keys {
        static let events = "events"
        static let showSeconds = "showSeconds"
        static let warnWhenNear = "warnWhenNear"
        static let isCompactMode = "isCompactMode"
        
        static let weekdayHour = "weekdayHour"
        static let weekdayMinute = "weekdayMinute"
        static let weekendHour = "weekendHour"
        static let weekendMinute = "weekendMinute"
    }
    
    private func targetDate(for event: CountdownEvent, relativeTo baseDate: Date) -> Date {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month, .day], from: baseDate)
        comps.hour = event.hour
        comps.minute = event.minute
        comps.second = 0
        
        var date = calendar.date(from: comps) ?? baseDate
        if event.hour < 4 || (event.hour == 4 && event.minute < 30) {
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        return date
    }

    func nearestEvent() -> (event: CountdownEvent, date: Date)? {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: currentTime)
        let currentMin = calendar.component(.minute, from: currentTime)
        
        let isEarlyMorning = currentHour < 4 || (currentHour == 4 && currentMin < 30)
        let baseDate = isEarlyMorning ? calendar.date(byAdding: .day, value: -1, to: currentTime)! : currentTime
        let baseComps = calendar.dateComponents([.weekday], from: baseDate)
        let weekday = baseComps.weekday ?? 1
        
        let activeEvents = events.filter { $0.isEnabled && $0.repeatDays.contains(weekday) }
        if activeEvents.isEmpty { return nil }
        
        let eventDates = activeEvents.map { (event: $0, date: targetDate(for: $0, relativeTo: baseDate)) }
            .sorted { $0.date < $1.date }
        
        let past = eventDates.filter { $0.date <= currentTime }
        let upcoming = eventDates.filter { $0.date > currentTime }
        
        if let lastPast = past.last {
            let timeSinceExpiry = currentTime.timeIntervalSince(lastPast.date)
            if timeSinceExpiry < 3600 {
                if let nextUpcoming = upcoming.first {
                    let timeUntilNext = nextUpcoming.date.timeIntervalSince(currentTime)
                    if timeUntilNext < 1800 {
                        return nextUpcoming
                    }
                }
                return lastPast
            }
        }
        
        if let firstUpcoming = upcoming.first {
            return firstUpcoming
        }
        
        return past.last
    }

    var remainingTime: (hours: Int, minutes: Int, seconds: Int, isPast: Bool, eventName: String?) {
        guard let nearest = nearestEvent() else {
            return (0, 0, 0, false, nil)
        }
        
        let targetTime = nearest.date
        if currentTime > targetTime {
            let overdue = currentTime.timeIntervalSince(targetTime)
            let hours = Int(overdue) / 3600
            let minutes = (Int(overdue) % 3600) / 60
            let seconds = Int(overdue) % 60
            return (hours, minutes, seconds, true, nearest.event.name)
        } else {
            let interval = targetTime.timeIntervalSince(currentTime)
            let hours = Int(interval) / 3600
            let minutes = (Int(interval) % 3600) / 60
            let seconds = Int(interval) % 60
            return (hours, minutes, seconds, false, nearest.event.name)
        }
    }

    var formattedRemainingTime: String {
        let r = remainingTime
        let sign = r.isPast ? "-" : ""
        if isCompactMode {
            if r.hours > 0 { return String(format: "%@%dh", sign, r.hours) }
            else { return String(format: "%@%dm", sign, r.minutes) }
        }
        if showSeconds { return String(format: "%@%dh %02dm %02ds", sign, r.hours, r.minutes, r.seconds) }
        else { return String(format: "%@%dh %02dm", sign, r.hours, r.minutes) }
    }

    var shouldShowRed: Bool {
        guard warnWhenNear else { return false }
        let r = remainingTime
        if r.isPast { return true }
        return r.hours == 0 && r.minutes < 60
    }

    private init() {
        let defaults = UserDefaults(suiteName: "group.space.kev1nweng.zzz")!
        self.showSeconds = defaults.bool(forKey: Keys.showSeconds)
        self.warnWhenNear = defaults.object(forKey: Keys.warnWhenNear) == nil ? true : defaults.bool(forKey: Keys.warnWhenNear)
        self.isCompactMode = defaults.bool(forKey: Keys.isCompactMode)
        
        if let data = defaults.data(forKey: Keys.events),
           let decoded = try? JSONDecoder().decode([CountdownEvent].self, from: data) {
            self.events = decoded
        } else {
            self.events = [
                CountdownEvent(id: UUID(), name: "工作日", hour: 22, minute: 30, repeatDays: [2,3,4,5,6], isEnabled: true),
                CountdownEvent(id: UUID(), name: "周末", hour: 23, minute: 30, repeatDays: [7,1], isEnabled: true)
            ]
            save()
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.currentTime = Date()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(events) {
            userDefaults.set(data, forKey: Keys.events)
        }
        userDefaults.set(showSeconds, forKey: Keys.showSeconds)
        userDefaults.set(warnWhenNear, forKey: Keys.warnWhenNear)
        userDefaults.set(isCompactMode, forKey: Keys.isCompactMode)
        userDefaults.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func resetToDefaults() {
        events = [
            CountdownEvent(id: UUID(), name: "工作日", hour: 22, minute: 30, repeatDays: [2,3,4,5,6], isEnabled: true),
            CountdownEvent(id: UUID(), name: "周末", hour: 23, minute: 30, repeatDays: [7,1], isEnabled: true)
        ]
        showSeconds = false
        warnWhenNear = true
        isCompactMode = false
    }

    func removeEvent(id: UUID) {
        events.removeAll { $0.id == id }
    }
}
