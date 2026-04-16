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
    
    private var nearest: (event: CountdownEvent, date: Date)? {
        entry.manager.nearestEvent()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "bed.double.fill")
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
            .foregroundStyle(entry.manager.shouldShowRed ? .red : .secondary)
            
            if let nearest = nearest {
                if Date() > nearest.date {
                    Text("已超时")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                } else {
                    Text(nearest.date, style: .timer)
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(entry.manager.shouldShowRed ? .red : .primary)
                }
            } else {
                Text("--:--")
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            
            Spacer(minLength: 0)
            
            VStack(alignment: .leading, spacing: 3) {
                let sortedEvents = entry.manager.events
                    .filter { $0.isEnabled }
                    .sorted { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
                
                ForEach(sortedEvents.prefix(2)) { event in
                    HStack {
                        Circle()
                            .fill(nearest?.event.id == event.id ? (entry.manager.shouldShowRed ? Color.red : Color.primary) : Color.secondary.opacity(0.3))
                            .frame(width: 4, height: 4)
                        
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
