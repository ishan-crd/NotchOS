import EventKit
import SwiftUI

class CalendarManager: ObservableObject {
    static let shared = CalendarManager()

    @Published var nextEvent: EKEvent?
    @Published var accessGranted: Bool = false

    private let store = EKEventStore()
    private var timer: Timer?

    private init() {}

    func start() {
        requestAccess()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.fetchNextEvent()
        }
    }

    private func requestAccess() {
        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents { [weak self] granted, _ in
                DispatchQueue.main.async {
                    self?.accessGranted = granted
                    if granted { self?.fetchNextEvent() }
                }
            }
        } else {
            store.requestAccess(to: .event) { [weak self] granted, _ in
                DispatchQueue.main.async {
                    self?.accessGranted = granted
                    if granted { self?.fetchNextEvent() }
                }
            }
        }
    }

    func fetchNextEvent() {
        guard accessGranted else { return }
        let now = Date()
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
        let predicate = store.predicateForEvents(withStart: now, end: endOfDay, calendars: nil)
        let events = store.events(matching: predicate).sorted { $0.startDate < $1.startDate }
        DispatchQueue.main.async {
            self.nextEvent = events.first
        }
    }
}

struct CalendarView: View {
    @StateObject var vm: NotchViewModel
    @ObservedObject private var calendarManager = CalendarManager.shared

    private let calendar = Calendar.current
    private let today = Date()

    private var monthString: String {
        today.formatted(.dateTime.month(.abbreviated))
    }

    private var dateRange: [Date] {
        // Show 3 days before and 3 days after today
        (-3...3).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Month label
            Text(monthString)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 55, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                // Date strip
                HStack(spacing: 6) {
                    ForEach(dateRange, id: \.self) { date in
                        let isToday = calendar.isDateInToday(date)
                        VStack(spacing: 2) {
                            Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(isToday ? .blue : .white.opacity(0.4))
                            Text(date.formatted(.dateTime.day()))
                                .font(.system(size: 14, weight: isToday ? .bold : .regular, design: .rounded))
                                .foregroundStyle(isToday ? .blue : .white.opacity(0.6))
                        }
                        .frame(width: 28)
                    }
                }

                // Next event
                HStack(spacing: 6) {
                    if let event = calendarManager.nextEvent {
                        Circle()
                            .fill(Color(cgColor: event.calendar.cgColor))
                            .frame(width: 6, height: 6)
                        Text(event.title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                    } else {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.3))
                        Text("Nothing for today")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxHeight: .infinity)
    }
}
