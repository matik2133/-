import Foundation
import WidgetKit

enum AppGroup {
    static var id: String {
        if let arr = Bundle.main.object(forInfoDictionaryKey: "ALTAppGroups") as? [String], let g = arr.first {
            return g
        }
        return "group.com.example.pary"
    }
    static var defaults: UserDefaults { UserDefaults(suiteName: id) ?? .standard }
}

struct Slot: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var start: Int
    var end: Int
    var days: [Int]
}

func fmt(_ m: Int) -> String { String(format: "%02d:%02d", m / 60, m % 60) }

final class Store: ObservableObject {
    @Published var slots: [Slot] { didSet { save() } }

    init() { slots = Store.load() }

    static func load() -> [Slot] {
        guard let d = AppGroup.defaults.data(forKey: "slots"),
              let s = try? JSONDecoder().decode([Slot].self, from: d) else { return [] }
        return s
    }

    func save() {
        if let d = try? JSONEncoder().encode(slots) {
            AppGroup.defaults.set(d, forKey: "slots")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct Segment {
    let start: Date
    let end: Date
    let title: String
    let isBreak: Bool
}

func upcomingSegments(slots: [Slot], now: Date, days: Int = 3) -> [Segment] {
    let cal = Calendar.current
    let day0 = cal.startOfDay(for: now)
    var result: [Segment] = []
    for d in 0..<days {
        guard let day = cal.date(byAdding: .day, value: d, to: day0) else { continue }
        let wd = cal.component(.weekday, from: day)
        let list = slots.filter { $0.days.contains(wd) && $0.end > $0.start }.sorted { $0.start < $1.start }
        for (i, s) in list.enumerated() {
            let st = day.addingTimeInterval(TimeInterval(s.start * 60))
            let en = day.addingTimeInterval(TimeInterval(s.end * 60))
            result.append(Segment(start: st, end: en, title: s.title, isBreak: false))
            if i + 1 < list.count, list[i + 1].start > s.end {
                let ns = day.addingTimeInterval(TimeInterval(list[i + 1].start * 60))
                result.append(Segment(start: en, end: ns, title: "Перемена", isBreak: true))
            }
        }
    }
    return result.filter { $0.end > now }
}
