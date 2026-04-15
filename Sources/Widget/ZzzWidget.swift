import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> BedtimeEntry {
        BedtimeEntry(date: Date(), manager: BedtimeManager.shared)
    }

    func getSnapshot(in context: Context, completion: @escaping (BedtimeEntry) -> ()) {
        let entry = BedtimeEntry(date: Date(), manager: BedtimeManager.shared)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let manager = BedtimeManager.shared
        // 小组件每 15 分钟刷新一次设置（倒计时本身是实时变化的，不需要频繁刷新代码）
        let timeline = Timeline(entries: [BedtimeEntry(date: Date(), manager: manager)], policy: .after(Date().addingTimeInterval(900)))
        completion(timeline)
    }
}

struct BedtimeEntry: TimelineEntry {
    let date: Date
    let manager: BedtimeManager
}

struct ZzzWidgetEntryView : View {
    var entry: Provider.Entry
    
    // 我们需要计算目标就寝时间，以便给 Text(style: .timer) 使用
    private var targetDate: Date {
        // 这里简化逻辑，获取当前的 targetDate
        // 注意：小组件运行在独立进程，通过 App Group 读取 UserDefaults
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let baseDate = hour < 8 ? calendar.date(byAdding: .day, value: -1, to: now)! : now
        let comps = calendar.dateComponents([.year, .month, .day, .weekday], from: baseDate)
        
        let isWeekendNight = (comps.weekday == 6 || comps.weekday == 7)
        let tHour = entry.manager.isOverrideActive ? entry.manager.overrideHour : (isWeekendNight ? entry.manager.weekendHour : entry.manager.weekdayHour)
        let tMin = entry.manager.isOverrideActive ? entry.manager.overrideMinute : (isWeekendNight ? entry.manager.weekendMinute : entry.manager.weekdayMinute)
        
        var targetComps = DateComponents()
        targetComps.year = comps.year
        targetComps.month = comps.month
        targetComps.day = comps.day
        targetComps.hour = tHour
        targetComps.minute = tMin
        targetComps.second = 0
        
        var d = calendar.date(from: targetComps) ?? now
        if tHour < 8 { d = calendar.date(byAdding: .day, value: 1, to: d)! }
        return d
    }

    private var isPast: Bool {
        Date() > targetDate
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 14))
                Text("Zzz")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
            }
            .foregroundStyle(isPast ? .red : .secondary)
            
            Spacer()
            
            if isPast {
                Text("已超时")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
            } else {
                Text(targetDate, style: .timer)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(entry.manager.shouldShowRed ? .red : .primary)
            }
            
            Text("距离就寝")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.ultraThinMaterial, for: .widget)
    }
}

@main
struct ZzzWidget: Widget {
    let kind: String = "ZzzWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ZzzWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("就寝倒计时")
        .description("在桌面上实时查看距离睡觉还有多久。")
        .supportedFamilies([.systemSmall])
    }
}
