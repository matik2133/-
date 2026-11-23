import WidgetKit
import SwiftUI

struct Entry: TimelineEntry {
    let date: Date
    let current: Segment?
    let next: Segment?
    let hasData: Bool
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry {
        let now = Date()
        return Entry(date: now, current: Segment(start: now.addingTimeInterval(-1800), end: now.addingTimeInterval(3600), title: "Пара", isBreak: false), next: nil, hasData: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let now = Date()
        let slots = Store.load()
        let segs = upcomingSegments(slots: slots, now: now)
        if segs.isEmpty {
            let e = Entry(date: now, current: nil, next: nil, hasData: !slots.isEmpty)
            completion(Timeline(entries: [e], policy: .after(now.addingTimeInterval(6 * 3600))))
            return
        }
        var entries: [Entry] = []
        if segs[0].start > now {
            entries.append(Entry(date: now, current: nil, next: segs[0], hasData: true))
        }
        for (i, s) in segs.prefix(24).enumerated() {
            let next = i + 1 < segs.count ? segs[i + 1] : nil
            entries.append(Entry(date: max(s.start, now), current: s, next: next, hasData: true))
            if let n = next, n.start > s.end {
                entries.append(Entry(date: s.end, current: nil, next: n, hasData: true))
            }
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct EntryView: View {
    let entry: Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let c = entry.current {
                Text(c.title).font(.headline)
                Text(c.isBreak ? "до начала пары" : "до конца").font(.caption).foregroundStyle(.secondary)
                Text(timerInterval: entry.date...c.end, countsDown: true)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ProgressView(timerInterval: c.start...c.end, countsDown: false) { EmptyView() } currentValueLabel: { EmptyView() }
                if let n = entry.next, n.start == c.end {
                    Text("Дальше: \(n.title)").font(.caption).foregroundStyle(.secondary)
                }
            } else if let n = entry.next {
                Text(n.title).font(.headline)
                Text("до начала").font(.caption).foregroundStyle(.secondary)
                Text(timerInterval: entry.date...n.start, countsDown: true)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(entry.hasData ? "Пар больше нет" : "Добавь пары в приложении").font(.headline)
            }
        }
    }
}

@main
struct ParyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ParyWidget", provider: Provider()) { entry in
            EntryView(entry: entry).containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Пары")
        .description("Сколько осталось до конца пары или перемены")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
