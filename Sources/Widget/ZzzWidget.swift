import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> BedtimeEntry {
        let manager = BedtimeManager.shared
        manager.reloadData()
        return BedtimeEntry(
            date: Date(),
            events: manager.events,
            showSeconds: manager.showSeconds,
            warnWhenNear: manager.warnWhenNear,
            isCompactMode: manager.isCompactMode
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BedtimeEntry) -> ()) {
        let manager = BedtimeManager.shared
        manager.reloadData()
        let entry = BedtimeEntry(
            date: Date(),
            events: manager.events,
            showSeconds: manager.showSeconds,
            warnWhenNear: manager.warnWhenNear,
            isCompactMode: manager.isCompactMode
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let manager = BedtimeManager.shared
        manager.reloadData()
        
        let currentDate = Date()
        let nextUpdate = currentDate.addingTimeInterval(900)
        let entry = BedtimeEntry(
            date: currentDate,
            events: manager.events,
            showSeconds: manager.showSeconds,
            warnWhenNear: manager.warnWhenNear,
            isCompactMode: manager.isCompactMode
        )
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct BedtimeEntry: TimelineEntry {
    let date: Date
    let events: [CountdownEvent]
    let showSeconds: Bool
    let warnWhenNear: Bool
    let isCompactMode: Bool
}

struct ZzzWidgetEntryView : View {
    var entry: Provider.Entry
    
    private var nearest: (event: CountdownEvent, date: Date)? {
        // Create a temporary manager or logic to find the nearest event
        let manager = BedtimeManager.shared
        // In the widget, the shared instance might not have the right data yet,
        // so we manually override its events for this calculation.
        let originalEvents = manager.events
        manager.events = entry.events
        let result = manager.nearestEvent(relativeTo: entry.date)
        manager.events = originalEvents
        return result
    }
    
    private var shouldShowRed: Bool {
        guard entry.warnWhenNear else { return false }
        guard let nearest = nearest else { return false }
        if entry.date > nearest.date { return true }
        let interval = nearest.date.timeIntervalSince(entry.date)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return hours == 0 && minutes < 60
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(nearest?.event.emoji ?? "🌙")
                    .font(.system(size: 12))
                Text("Zzz")
                    .font(.system(.caption2, design: .rounded))
                    .fontWeight(.bold)
                Spacer()
                if let nearest = nearest {
                    Text(nearest.event.name)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .foregroundStyle(shouldShowRed ? .red : .secondary)

            if let nearest = nearest {
                if entry.date > nearest.date {
                    Text("已超时")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                } else {
                    Text(nearest.date, style: .timer)
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(shouldShowRed ? .red : .primary)
                }
            } else {
                Text("--:--")
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 3) {
                let sortedEvents = entry.events
                    .filter { $0.isEnabled }
                    .sorted { ($0.hour, $0.minute) < ($1.hour, $1.minute) }

                ForEach(sortedEvents.prefix(2)) { event in
                    HStack {
                        Text(event.emoji)
                            .font(.system(size: 8))

                        Text(event.name)
                            .lineLimit(1)
                        Spacer()
                        Text(String(format: "%02d:%02d", event.hour, event.minute))
                            .foregroundStyle(.secondary)
                    }
                    .font(.system(size: 10, weight: nearest?.event.id == event.id ? .medium : .regular))
                }
            }
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
        .description("在桌面上实时查看所有倒计时点。")
        .supportedFamilies([.systemSmall])
    }
}
