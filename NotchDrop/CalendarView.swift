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
    private var today: Date { Date() }

    private var monthString: String {
        today.formatted(.dateTime.month(.abbreviated))
    }

    private var dateRange: [Date] {
        let range = vm.dashboardLayout == .focus ? (-3...3) : (-3...3)
        return range.compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }
    }

    var body: some View {
        Group {
            if vm.dashboardLayout == .focus {
                focusBody
            } else {
                compactBody
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Focus layout (full-width card)

    var focusBody: some View {
        VStack(spacing: 0) {
            // Month + Year header
            HStack {
                Text(today.formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                // Today's full date
                Text(today.formatted(.dateTime.weekday(.wide)))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            Spacer(minLength: 10)

            // Wide date strip
            HStack(spacing: 0) {
                ForEach(dateRange, id: \.self) { date in
                    let isToday = calendar.isDateInToday(date)
                    VStack(spacing: 4) {
                        Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(isToday ? .white : .white.opacity(0.3))

                        Text(date.formatted(.dateTime.day()))
                            .font(.system(size: 18, weight: isToday ? .bold : .regular, design: .rounded))
                            .foregroundStyle(isToday ? .white : .white.opacity(0.35))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(isToday ? .blue : .clear)
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 10)

            Spacer(minLength: 10)

            // Next event bar
            HStack(spacing: 8) {
                if let event = calendarManager.nextEvent {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(cgColor: event.calendar.cgColor))
                        .frame(width: 3, height: 20)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(event.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                        Text(event.startDate.formatted(.dateTime.hour().minute()))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                } else {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.25))
                    Text("Nothing scheduled today")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.25))
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Compact layout (split/grid sidebar)

    var compactBody: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(monthString)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            VStack(spacing: 10) {
                HStack(spacing: 4) {
                    ForEach(dateRange, id: \.self) { date in
                        let isToday = calendar.isDateInToday(date)
                        VStack(spacing: 1) {
                            if isToday {
                                Text("today")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundStyle(.red)
                            } else {
                                Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                                    .font(.system(size: 7, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                            Text(date.formatted(.dateTime.day()))
                                .font(.system(size: isToday ? 22 : 13, weight: isToday ? .bold : .regular, design: .rounded))
                                .foregroundStyle(isToday ? .blue : .white.opacity(0.4))
                        }
                        .frame(width: isToday ? 34 : 26)
                    }
                }

                HStack(spacing: 5) {
                    if let event = calendarManager.nextEvent {
                        Circle()
                            .fill(Color(cgColor: event.calendar.cgColor))
                            .frame(width: 6, height: 6)
                        Text(event.title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(1)
                    } else {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.3))
                        Text("Nothing for today")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
