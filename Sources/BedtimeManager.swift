import Foundation
import WidgetKit

struct CountdownEvent: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var emoji: String
    var hour: Int
    var minute: Int
    var repeatDays: Set<Int> // 1 (Sun) to 7 (Sat)
    var isEnabled: Bool
    
    init(id: UUID = UUID(), name: String, emoji: String = "🔔", hour: Int, minute: Int, repeatDays: Set<Int>, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.hour = hour
        self.minute = minute
        self.repeatDays = repeatDays
        self.isEnabled = isEnabled
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, emoji, hour, minute, repeatDays, isEnabled
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        emoji = try container.decodeIfPresent(String.self, forKey: .emoji) ?? "🔔"
        hour = try container.decode(Int.self, forKey: .hour)
        minute = try container.decode(Int.self, forKey: .minute)
        repeatDays = try container.decode(Set<Int>.self, forKey: .repeatDays)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
    }
    
    static func == (lhs: CountdownEvent, rhs: CountdownEvent) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.emoji == rhs.emoji &&
        lhs.hour == rhs.hour &&
        lhs.minute == rhs.minute &&
        lhs.repeatDays == rhs.repeatDays &&
        lhs.isEnabled == rhs.isEnabled
    }
    
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
    private var isPerformingLoad = false

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

    func nearestEvent(relativeTo referenceDate: Date? = nil) -> (event: CountdownEvent, date: Date)? {
        let currentTime = referenceDate ?? self.currentTime
        let calendar = Calendar.current
        
        var candidates: [(event: CountdownEvent, date: Date)] = []
        
        for dayOffset in 0...7 {
            let searchDate = calendar.date(byAdding: .day, value: dayOffset, to: currentTime)!
            let hour = calendar.component(.hour, from: searchDate)
            let min = calendar.component(.minute, from: searchDate)
            
            let isEarlyMorning = hour < 4 || (hour == 4 && min < 30)
            let baseDate = isEarlyMorning ? calendar.date(byAdding: .day, value: -1, to: searchDate)! : searchDate
            let weekday = calendar.component(.weekday, from: baseDate)
            
            let dailyEvents = events.filter { $0.isEnabled && $0.repeatDays.contains(weekday) }
            
            for event in dailyEvents {
                let eventDate = targetDate(for: event, relativeTo: baseDate)
                
                if dayOffset == 0 {
                    if eventDate > currentTime || currentTime.timeIntervalSince(eventDate) < 3600 {
                        candidates.append((event, eventDate))
                    }
                } else if eventDate > currentTime {
                    candidates.append((event, eventDate))
                }
            }
            
            if !candidates.isEmpty && dayOffset > 0 {
                break
            }
        }
        
        return candidates.sorted { $0.date < $1.date }.first
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
        guard r.eventName != nil else { return false }
        if r.isPast { return true }
        return r.hours == 0 && r.minutes < 60
    }

    private init() {
        // 1. 先定义临时的加载变量
        let defaults = UserDefaults(suiteName: "group.space.kev1nweng.zzz")!
        
        let loadedShowSeconds = defaults.bool(forKey: Keys.showSeconds)
        let loadedWarnWhenNear = defaults.object(forKey: Keys.warnWhenNear) == nil ? true : defaults.bool(forKey: Keys.warnWhenNear)
        let loadedIsCompactMode = defaults.bool(forKey: Keys.isCompactMode)
        
        var loadedEvents: [CountdownEvent] = []
        if let data = defaults.data(forKey: Keys.events),
           let decoded = try? JSONDecoder().decode([CountdownEvent].self, from: data) {
            loadedEvents = decoded
        }
        
        // 2. 如果是首次启动（Key 都不存在），准备初始默认值
        if defaults.object(forKey: Keys.events) == nil && loadedEvents.isEmpty {
            loadedEvents = [
                CountdownEvent(name: "就寝", emoji: "🌙", hour: 22, minute: 30, repeatDays: [2,3,4,5,6])
            ]
            // 注意：此时不能调用 save()，因为 self 还没初始化完
            if let data = try? JSONEncoder().encode(loadedEvents) {
                defaults.set(data, forKey: Keys.events)
                defaults.synchronize()
            }
        }
        
        // 3. 正式初始化所有属性（此时不会触发 didSet）
        self.showSeconds = loadedShowSeconds
        self.warnWhenNear = loadedWarnWhenNear
        self.isCompactMode = loadedIsCompactMode
        self.events = loadedEvents
        self.currentTime = Date()
        self.isPerformingLoad = false
        
        // 4. 开启定时器
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.currentTime = Date()
        }
    }

    private func save() {
        if isPerformingLoad { return }
        
        let isExtension = Bundle.main.bundleIdentifier?.contains(".widget") == true
        if isExtension { return }

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
            CountdownEvent(name: "就寝", emoji: "🌙", hour: 22, minute: 30, repeatDays: [2,3,4,5,6])
        ]
        showSeconds = false
        warnWhenNear = true
        isCompactMode = false
    }

    func removeEvent(id: UUID) {
        events.removeAll { $0.id == id }
    }

    func reloadData() {
        isPerformingLoad = true
        defer { isPerformingLoad = false }
        
        userDefaults.synchronize()
        
        let newShowSeconds = userDefaults.bool(forKey: Keys.showSeconds)
        let newWarnWhenNear = userDefaults.object(forKey: Keys.warnWhenNear) == nil ? true : userDefaults.bool(forKey: Keys.warnWhenNear)
        let newIsCompactMode = userDefaults.bool(forKey: Keys.isCompactMode)
        
        if showSeconds != newShowSeconds { self.showSeconds = newShowSeconds }
        if warnWhenNear != newWarnWhenNear { self.warnWhenNear = newWarnWhenNear }
        if isCompactMode != newIsCompactMode { self.isCompactMode = newIsCompactMode }
        
        if let data = userDefaults.data(forKey: Keys.events),
           let decoded = try? JSONDecoder().decode([CountdownEvent].self, from: data) {
            if self.events != decoded {
                self.events = decoded
            }
        }
    }
}
