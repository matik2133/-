import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        NavigationStack {
            List {
                if store.slots.isEmpty {
                    Text("Добавь первую пару кнопкой +").foregroundStyle(.secondary)
                }
                ForEach($store.slots) { $slot in
                    NavigationLink {
                        SlotEditor(slot: $slot)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(slot.title).font(.headline)
                            Text("\(fmt(slot.start)) – \(fmt(slot.end))")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { store.slots.remove(atOffsets: $0) }
            }
            .navigationTitle("Расписание")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Упорядочить") { store.slots.sort { $0.start < $1.start } }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { add() } label: { Image(systemName: "plus") }
                }
            }
        }
    }

    func add() {
        store.slots.append(Slot(title: "Пара \(store.slots.count + 1)", start: 510, end: 600, days: [2, 3, 4, 5, 6]))
    }
}

func timeBinding(_ m: Binding<Int>) -> Binding<Date> {
    Binding(
        get: { Calendar.current.date(bySettingHour: m.wrappedValue / 60, minute: m.wrappedValue % 60, second: 0, of: Date()) ?? Date() },
        set: {
            let c = Calendar.current.dateComponents([.hour, .minute], from: $0)
            m.wrappedValue = (c.hour ?? 0) * 60 + (c.minute ?? 0)
        }
    )
}

struct SlotEditor: View {
    @Binding var slot: Slot
    let names: [(Int, String)] = [(2, "Пн"), (3, "Вт"), (4, "Ср"), (5, "Чт"), (6, "Пт"), (7, "Сб"), (1, "Вс")]

    var body: some View {
        Form {
            TextField("Название", text: $slot.title)
            DatePicker("Начало", selection: timeBinding($slot.start), displayedComponents: .hourAndMinute)
            DatePicker("Конец", selection: timeBinding($slot.end), displayedComponents: .hourAndMinute)
            Section("Дни недели") {
                ForEach(names, id: \.0) { n in
                    Toggle(n.1, isOn: Binding(
                        get: { slot.days.contains(n.0) },
                        set: { on in
                            if on {
                                if !slot.days.contains(n.0) { slot.days.append(n.0) }
                            } else {
                                slot.days.removeAll { $0 == n.0 }
                            }
                        }
                    ))
                }
            }
        }
        .navigationTitle(slot.title)
    }
}
