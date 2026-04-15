import Foundation

@Observable
final class BedtimeManager {
    static let shared = BedtimeManager()

    var weekdayHour: Int { didSet { save() } }
    var weekdayMinute: Int { didSet { save() } }
    
    var weekendHour: Int { didSet { save() } }
    var weekendMinute: Int { didSet { save() } }
    
    var overrideHour: Int { didSet { save() } }
    var overrideMinute: Int { didSet { save() } }
    var isOverrideActive: Bool { didSet { save() } }

    var showSeconds: Bool { didSet { save() } }
    var warnWhenNear: Bool { didSet { save() } }

    var currentTime: Date = Date()
    private var timer: Timer?

    private let userDefaults = UserDefaults.standard

    private enum Keys {
        static let weekdayHour = "weekdayHour"
        static let weekdayMinute = "weekdayMinute"
        static let weekendHour = "weekendHour"
        static let weekendMinute = "weekendMinute"
        static let overrideHour = "overrideHour"
        static let overrideMinute = "overrideMinute"
        static let isOverrideActive = "isOverrideActive"
        static let showSeconds = "showSeconds"
        static let warnWhenNear = "warnWhenNear"
    }
    
    // SwiftUI Date proxies
    private func dateFrom(hour: Int, minute: Int) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? Date()
    }
    
    private func extractTime(from date: Date) -> (hour: Int, minute: Int) {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0, comps.minute ?? 0)
    }

    var weekdayDate: Date {
        get { dateFrom(hour: weekdayHour, minute: weekdayMinute) }
        set { let t = extractTime(from: newValue); weekdayHour = t.hour; weekdayMinute = t.minute }
    }
    
    var weekendDate: Date {
        get { dateFrom(hour: weekendHour, minute: weekendMinute) }
        set { let t = extractTime(from: newValue); weekendHour = t.hour; weekendMinute = t.minute }
    }
    
    var overrideDate: Date {
        get { dateFrom(hour: overrideHour, minute: overrideMinute) }
        set { let t = extractTime(from: newValue); overrideHour = t.hour; overrideMinute = t.minute }
    }

    var remainingTime: (hours: Int, minutes: Int, seconds: Int, isPast: Bool) {
        let calendar = Calendar.current
        
        // 1. 确定逻辑基准日 (Base Date)
        // 如果现在是凌晨 8 点前，逻辑上属于前一个作息周期
        let currentHour = calendar.component(.hour, from: currentTime)
        let baseDate = currentHour < 8 
            ? calendar.date(byAdding: .day, value: -1, to: currentTime)! 
            : currentTime
        
        let baseComps = calendar.dateComponents([.year, .month, .day, .weekday], from: baseDate)
        
        // 2. 根据基准日判定使用工作日还是周末设置 (周五、周六晚上算周末)
        let isWeekendNight = (baseComps.weekday == 6 || baseComps.weekday == 7)
        
        let targetHour: Int
        let targetMinute: Int
        if isOverrideActive {
            targetHour = overrideHour
            targetMinute = overrideMinute
        } else {
            targetHour = isWeekendNight ? weekendHour : weekdayHour
            targetMinute = isWeekendNight ? weekendMinute : weekdayMinute
        }
        
        // 3. 计算目标绝对时间
        var targetComps = DateComponents()
        targetComps.year = baseComps.year
        targetComps.month = baseComps.month
        targetComps.day = baseComps.day
        targetComps.hour = targetHour
        targetComps.minute = targetMinute
        targetComps.second = 0
        
        var targetDate = calendar.date(from: targetComps) ?? currentTime
        
        // 如果目标睡觉时间设置在凌晨 (0-7点)，它实际上是逻辑基准日的第二天凌晨
        if targetHour < 8 {
            targetDate = calendar.date(byAdding: .day, value: 1, to: targetDate)!
        }
        
        // 4. 计算与当前时间的差值
        if currentTime > targetDate {
            let overdue = currentTime.timeIntervalSince(targetDate)
            let hours = Int(overdue) / 3600
            let minutes = (Int(overdue) % 3600) / 60
            let seconds = Int(overdue) % 60
            return (hours, minutes, seconds, true)
        } else {
            let interval = targetDate.timeIntervalSince(currentTime)
            let hours = Int(interval) / 3600
            let minutes = (Int(interval) % 3600) / 60
            let seconds = Int(interval) % 60
            return (hours, minutes, seconds, false)
        }
    }

    var formattedRemainingTime: String {
        let r = remainingTime
        let sign = r.isPast ? "-" : ""
        if showSeconds {
            return String(format: "%@%dh %02dm %02ds", sign, r.hours, r.minutes, r.seconds)
        } else {
            return String(format: "%@%dh %02dm", sign, r.hours, r.minutes)
        }
    }

    var shouldShowRed: Bool {
        guard warnWhenNear else { return false }
        let r = remainingTime
        if r.isPast { return true }
        return r.hours == 0 && r.minutes < 60
    }

    private init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Keys.weekdayHour) == nil {
            defaults.set(22, forKey: Keys.weekdayHour)
            defaults.set(30, forKey: Keys.weekdayMinute)
            defaults.set(23, forKey: Keys.weekendHour)
            defaults.set(30, forKey: Keys.weekendMinute)
            defaults.set(22, forKey: Keys.overrideHour)
            defaults.set(0, forKey: Keys.overrideMinute)
            defaults.set(false, forKey: Keys.isOverrideActive)
            defaults.set(false, forKey: Keys.showSeconds)
            defaults.set(true, forKey: Keys.warnWhenNear)
        }

        self.weekdayHour = defaults.integer(forKey: Keys.weekdayHour)
        self.weekdayMinute = defaults.integer(forKey: Keys.weekdayMinute)
        self.weekendHour = defaults.integer(forKey: Keys.weekendHour)
        self.weekendMinute = defaults.integer(forKey: Keys.weekendMinute)
        self.overrideHour = defaults.integer(forKey: Keys.overrideHour)
        self.overrideMinute = defaults.integer(forKey: Keys.overrideMinute)
        self.isOverrideActive = defaults.bool(forKey: Keys.isOverrideActive)
        self.showSeconds = defaults.bool(forKey: Keys.showSeconds)
        self.warnWhenNear = defaults.bool(forKey: Keys.warnWhenNear)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.currentTime = Date()
        }
    }

    private func save() {
        userDefaults.set(weekdayHour, forKey: Keys.weekdayHour)
        userDefaults.set(weekdayMinute, forKey: Keys.weekdayMinute)
        userDefaults.set(weekendHour, forKey: Keys.weekendHour)
        userDefaults.set(weekendMinute, forKey: Keys.weekendMinute)
        userDefaults.set(overrideHour, forKey: Keys.overrideHour)
        userDefaults.set(overrideMinute, forKey: Keys.overrideMinute)
        userDefaults.set(isOverrideActive, forKey: Keys.isOverrideActive)
        userDefaults.set(showSeconds, forKey: Keys.showSeconds)
        userDefaults.set(warnWhenNear, forKey: Keys.warnWhenNear)
    }

    func resetToDefaults() {
        weekdayHour = 22
        weekdayMinute = 30
        weekendHour = 23
        weekendMinute = 30
        overrideHour = 22
        overrideMinute = 0
        isOverrideActive = false
        showSeconds = false
        warnWhenNear = true
    }
}
