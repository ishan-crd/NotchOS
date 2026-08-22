//
//  CalendarView.swift
//  NotchOS
//
//  Copyright © 2026 Ishan Gupta. MIT License.
//

import Combine
import EventKit
import SwiftUI

class CalendarManager: ObservableObject {
    static let shared = CalendarManager()

    @Published var nextEvent: EKEvent?
    @Published var todayEvents: [EKEvent] = []
    @Published var todayReminders: [EKReminder] = []
    @Published var accessGranted: Bool = false
    @Published var availableCalendars: [EKCalendar] = []

    /// Empty means "all calendars".
    @PublishedPersist(key: "excludedCalendarIDs", defaultValue: [])
    var excludedCalendarIDs: Set<String>

    @PublishedPersist(key: "showReminders", defaultValue: true)
    var showReminders: Bool

    private let store = EKEventStore()
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        Publishers.Merge(
            $excludedCalendarIDs.removeDuplicates().map { _ in () },
            $showReminders.removeDuplicates().map { _ in () }
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.fetchEvents() }
        .store(in: &cancellables)
    }

    func start() {
        requestAccess()
        NotificationCenter.default.addObserver(
            self, selector: #selector(storeChanged),
            name: .EKEventStoreChanged, object: store
        )
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.fetchEvents()
        }
    }

    @objc private func storeChanged() {
        DispatchQueue.main.async { self.fetchEvents() }
    }

    /// At startup we only *use* access that was already granted; first-time
    /// permission prompts are driven from the onboarding flow so they don't
    /// ambush the user at launch.
    private func requestAccess() {
        let eventStatus = EKEventStore.authorizationStatus(for: .event)
        guard eventStatus != .notDetermined else { return }

        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents { [weak self] granted, _ in
                DispatchQueue.main.async {
                    self?.accessGranted = granted
                    if granted { self?.fetchEvents() }
                }
            }
            if EKEventStore.authorizationStatus(for: .reminder) != .notDetermined {
                store.requestFullAccessToReminders { [weak self] granted, _ in
                    guard granted else { return }
                    DispatchQueue.main.async { self?.fetchEvents() }
                }
            }
        } else {
            store.requestAccess(to: .event) { [weak self] granted, _ in
                DispatchQueue.main.async {
                    self?.accessGranted = granted
                    if granted { self?.fetchEvents() }
                }
            }
            if EKEventStore.authorizationStatus(for: .reminder) != .notDetermined {
                store.requestAccess(to: .reminder) { [weak self] granted, _ in
                    guard granted else { return }
                    DispatchQueue.main.async { self?.fetchEvents() }
                }
            }
        }
    }

    private var selectedCalendars: [EKCalendar]? {
        let all = store.calendars(for: .event)
        DispatchQueue.main.async {
            if self.availableCalendars.map(\.calendarIdentifier) != all.map(\.calendarIdentifier) {
                self.availableCalendars = all
            }
        }
        guard !excludedCalendarIDs.isEmpty else { return nil }
        let selected = all.filter { !excludedCalendarIDs.contains($0.calendarIdentifier) }
        return selected.isEmpty ? nil : selected
    }

    func fetchEvents() {
        guard accessGranted else { return }
        let now = Date()
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
        let predicate = store.predicateForEvents(withStart: now, end: endOfDay, calendars: selectedCalendars)
        let events = store.events(matching: predicate).sorted { $0.startDate < $1.startDate }
        DispatchQueue.main.async {
            self.nextEvent = events.first
            self.todayEvents = Array(events.prefix(3))
        }
        fetchReminders(endOfDay: endOfDay)
    }

    private func fetchReminders(endOfDay: Date) {
        guard showReminders else {
            DispatchQueue.main.async { self.todayReminders = [] }
            return
        }
        let predicate = store.predicateForIncompleteReminders(
            withDueDateStarting: nil, ending: endOfDay, calendars: nil
        )
        store.fetchReminders(matching: predicate) { [weak self] reminders in
            let due = (reminders ?? [])
                .filter { $0.dueDateComponents != nil }
                .sorted { ($0.dueDateComponents?.date ?? .distantPast) < ($1.dueDateComponents?.date ?? .distantPast) }
            DispatchQueue.main.async { self?.todayReminders = Array(due.prefix(3)) }
        }
    }

    /// Marks a reminder complete and refreshes.
    func complete(_ reminder: EKReminder) {
        reminder.isCompleted = true
        try? store.save(reminder, commit: true)
        fetchEvents()
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
                } else if let reminder = calendarManager.todayReminders.first {
                    Image(systemName: "checklist")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(cgColor: reminder.calendar.cgColor))
                    Text(reminder.title ?? "")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
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

    /// A due reminder with a tappable complete button.
    func reminderRow(_ reminder: EKReminder) -> some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(vm.animation) {
                    calendarManager.complete(reminder)
                }
            } label: {
                Image(systemName: "circle")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(cgColor: reminder.calendar.cgColor))
            }
            .buttonStyle(.plain)
            .frame(width: 40, alignment: .trailing)

            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color(cgColor: reminder.calendar.cgColor).opacity(0.6))
                .frame(width: 3, height: 18)

            Text(reminder.title ?? "")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.65))
                .lineLimit(1)
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

                if calendarManager.todayEvents.isEmpty, calendarManager.todayReminders.isEmpty {
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
                    let eventRows = Array(calendarManager.todayEvents.prefix(2))
                    let reminderRows = Array(calendarManager.todayReminders.prefix(max(0, 2 - eventRows.count) + 1))
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(eventRows, id: \.eventIdentifier) { event in
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
                        ForEach(reminderRows.prefix(max(0, 3 - eventRows.count)), id: \.calendarItemIdentifier) { reminder in
                            reminderRow(reminder)
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
