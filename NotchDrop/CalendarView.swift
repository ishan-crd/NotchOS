import EventKit
import SwiftUI

class CalendarManager: ObservableObject {
    static let shared = CalendarManager()

    @Published var nextEvent: EKEvent?
    @Published var todayEvents: [EKEvent] = []
    @Published var accessGranted: Bool = false

    private let store = EKEventStore()
    private var timer: Timer?

    private init() {}

    func start() {
        requestAccess()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.fetchEvents()
        }
    }

    private func requestAccess() {
        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents { [weak self] granted, _ in
                DispatchQueue.main.async {
                    self?.accessGranted = granted
                    if granted { self?.fetchEvents() }
                }
            }
        } else {
            store.requestAccess(to: .event) { [weak self] granted, _ in
                DispatchQueue.main.async {
                    self?.accessGranted = granted
                    if granted { self?.fetchEvents() }
                }
            }
        }
    }

    func fetchEvents() {
        guard accessGranted else { return }
        let now = Date()
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
        let predicate = store.predicateForEvents(withStart: now, end: endOfDay, calendars: nil)
        let events = store.events(matching: predicate).sorted { $0.startDate < $1.startDate }
        DispatchQueue.main.async {
            self.nextEvent = events.first
            self.todayEvents = Array(events.prefix(3))
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

    private var focusDateRange: [Date] {
        (-3...3).compactMap { offset in
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

    // MARK: - Focus layout (full-width carousel card)

    var focusBody: some View {
        VStack(spacing: 0) {
            HStack {
                Text(today.formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text(today.formatted(.dateTime.weekday(.wide)))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            Spacer(minLength: 10)

            HStack(spacing: 0) {
                ForEach(focusDateRange, id: \.self) { date in
                    let isToday = calendar.isDateInToday(date)
                    VStack(spacing: 4) {
                        Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(isToday ? .white : .white.opacity(0.3))
                        Text(date.formatted(.dateTime.day()))
                            .font(.system(size: 18, weight: isToday ? .bold : .regular, design: .rounded))
                            .foregroundStyle(isToday ? .white : .white.opacity(0.35))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(isToday ? .blue : .clear))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 10)

            Spacer(minLength: 10)

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

    // MARK: - Compact layout (split/grid — date card + event list)

    var compactBody: some View {
        HStack(spacing: 0) {
            // Left: day block
            VStack(spacing: 2) {
                Text(today.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.red)
                Text(today.formatted(.dateTime.day()))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(monthString)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(width: 56)
            .padding(.trailing, 8)

            // Divider
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(width: 1)
                .padding(.vertical, 8)

            // Right: today's events
            VStack(alignment: .leading, spacing: 0) {
                Text("TODAY")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
                    .tracking(0.5)
                    .padding(.bottom, 6)

                if calendarManager.todayEvents.isEmpty {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("No events")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.2))
                        Spacer()
                    }
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(calendarManager.todayEvents.prefix(2), id: \.eventIdentifier) { event in
                            HStack(spacing: 8) {
                                Text(event.startDate.formatted(.dateTime.hour().minute()))
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.4))
                                    .frame(width: 40, alignment: .trailing)

                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(Color(cgColor: event.calendar.cgColor))
                                    .frame(width: 3, height: 18)

                                Text(event.title)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .lineLimit(1)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(.leading, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
    }
}
