import Foundation
import EventKit
import SwiftUI

class CalendarManager: ObservableObject {
	static let shared = CalendarManager()

	private let eventStore = EKEventStore()

	@Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
	@Published var calendars: [EKCalendar] = []
	@Published var selectedCalendarIdentifiers: Set<String> = []
	@Published var events: [Date: [EKEvent]] = [:]
	private var loadedMonths: Set<String> = []
	private var changeDebounceTimer: Timer?

	private init() {
		checkAuthorizationStatus()
		loadSavedCalendarSelection()
		setupEventStoreNotifications()
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
		changeDebounceTimer?.invalidate()
	}

	func checkAuthorizationStatus() {
		authorizationStatus = EKEventStore.authorizationStatus(for: .event)

		if authorizationStatus == .fullAccess || authorizationStatus == .writeOnly {
			loadCalendars()
		}
	}

	func requestAccess() async -> Bool {
		do {
			let granted = try await eventStore.requestFullAccessToEvents()
			await MainActor.run {
				self.authorizationStatus = granted ? .fullAccess : .denied
				if granted {
					self.loadCalendars()
				}
			}
			return granted
		} catch {
			print("Failed to request calendar access: \(error)")
			await MainActor.run {
				self.authorizationStatus = .denied
			}
			return false
		}
	}

	func loadCalendars() {
		calendars = eventStore.calendars(for: .event).sorted { $0.title < $1.title }

		// Only default to all calendars if no selection was saved AND no calendars are currently selected
		let hasSavedSelection = UserDefaults.standard.stringArray(forKey: "selectedCalendarIdentifiers") != nil
		if !hasSavedSelection && selectedCalendarIdentifiers.isEmpty && !calendars.isEmpty {
			// Select all calendars by default only on first run
			selectedCalendarIdentifiers = Set(calendars.compactMap { $0.calendarIdentifier })
			saveCalendarSelection()
		}
	}

	func toggleCalendar(_ calendar: EKCalendar) {
		if selectedCalendarIdentifiers.contains(calendar.calendarIdentifier) {
			selectedCalendarIdentifiers.remove(calendar.calendarIdentifier)
		} else {
			selectedCalendarIdentifiers.insert(calendar.calendarIdentifier)
		}
		saveCalendarSelection()
		reloadAllEvents()
	}

	func reloadAllEvents() {
		// Get all months that were previously loaded
		let monthsToReload = Array(loadedMonths)

		// Clear cache
		events = [:]
		loadedMonths = []

		// Reload all previously loaded months with new calendar selection
		for monthKey in monthsToReload {
			let components = monthKey.split(separator: "-")
			if components.count == 2,
			   let year = Int(components[0]),
			   let month = Int(components[1]) {
				var dateComponents = DateComponents()
				dateComponents.year = year
				dateComponents.month = month
				dateComponents.day = 1
				if let monthDate = Calendar.current.date(from: dateComponents) {
					loadEventsForMonth(containing: monthDate, forceReload: true)
				}
			}
		}

		objectWillChange.send()
	}

	func isCalendarSelected(_ calendar: EKCalendar) -> Bool {
		selectedCalendarIdentifiers.contains(calendar.calendarIdentifier)
	}

	func fetchEvents(for date: Date) -> [EKEvent] {
		guard authorizationStatus == .fullAccess || authorizationStatus == .writeOnly else {
			return []
		}

		let calendar = Calendar.current
		let startOfDay = calendar.startOfDay(for: date)
		guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
			return []
		}

		let selectedCalendars = calendars.filter { selectedCalendarIdentifiers.contains($0.calendarIdentifier) }
		guard !selectedCalendars.isEmpty else { return [] }

		let predicate = eventStore.predicateForEvents(
			withStart: startOfDay,
			end: endOfDay,
			calendars: selectedCalendars
		)

		return eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
	}

	func refreshEvents() {
		objectWillChange.send()
	}

	func loadEventsForMonth(containing date: Date, forceReload: Bool = false) {
		guard authorizationStatus == .fullAccess || authorizationStatus == .writeOnly else {
			return
		}

		let calendar = Calendar.current
		let monthKey = monthKeyForDate(date)

		// Check if we've already loaded this month (unless forcing reload)
		guard forceReload || !loadedMonths.contains(monthKey) else {
			return
		}

		guard let monthRange = calendar.range(of: .day, in: .month, for: date),
			  let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
			  let endOfMonth = calendar.date(byAdding: .day, value: monthRange.count, to: startOfMonth) else {
			return
		}

		let selectedCalendars = calendars.filter { selectedCalendarIdentifiers.contains($0.calendarIdentifier) }

		// Mark as loaded before fetching to prevent duplicate loads
		loadedMonths.insert(monthKey)

		// If no calendars selected, clear events for this month
		guard !selectedCalendars.isEmpty else {
			// Clear events for this month's dates
			let calendar = Calendar.current
			var currentDate = startOfMonth
			while currentDate < endOfMonth {
				let dayStart = calendar.startOfDay(for: currentDate)
				events[dayStart] = []
				currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
			}
			objectWillChange.send()
			return
		}

		let predicate = eventStore.predicateForEvents(
			withStart: startOfMonth,
			end: endOfMonth,
			calendars: selectedCalendars
		)

		let monthEvents = eventStore.events(matching: predicate)

		var eventsByDate: [Date: [EKEvent]] = [:]
		for event in monthEvents {
			let dayStart = calendar.startOfDay(for: event.startDate)
			if eventsByDate[dayStart] != nil {
				eventsByDate[dayStart]?.append(event)
			} else {
				eventsByDate[dayStart] = [event]
			}

			if event.isAllDay || calendar.dateComponents([.day], from: event.startDate, to: event.endDate).day ?? 0 > 0 {
				var currentDate = calendar.date(byAdding: .day, value: 1, to: dayStart)!
				while currentDate < event.endDate && currentDate < endOfMonth {
					if eventsByDate[currentDate] != nil {
						eventsByDate[currentDate]?.append(event)
					} else {
						eventsByDate[currentDate] = [event]
					}
					currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
				}
			}
		}

		for (date, dateEvents) in eventsByDate {
			eventsByDate[date] = dateEvents.sorted { $0.startDate < $1.startDate }
		}

		// Merge with existing events instead of replacing
		for (date, dateEvents) in eventsByDate {
			events[date] = dateEvents
		}

		objectWillChange.send()
	}

	private func monthKeyForDate(_ date: Date) -> String {
		let calendar = Calendar.current
		let components = calendar.dateComponents([.year, .month], from: date)
		return "\(components.year ?? 0)-\(components.month ?? 0)"
	}

	private func loadSavedCalendarSelection() {
		if let saved = UserDefaults.standard.stringArray(forKey: "selectedCalendarIdentifiers") {
			selectedCalendarIdentifiers = Set(saved)
		}
	}

	private func saveCalendarSelection() {
		UserDefaults.standard.set(Array(selectedCalendarIdentifiers), forKey: "selectedCalendarIdentifiers")
	}

	// MARK: - Event Store Change Notifications

	private func setupEventStoreNotifications() {
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(eventStoreChanged),
			name: .EKEventStoreChanged,
			object: eventStore
		)

		// Also listen for app becoming active to refresh stale data
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(appDidBecomeActive),
			name: NSApplication.didBecomeActiveNotification,
			object: nil
		)
	}

	@objc private func eventStoreChanged() {
		// Debounce rapid changes that often come in bursts
		changeDebounceTimer?.invalidate()
		changeDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
			DispatchQueue.main.async {
				self?.handleEventStoreChange()
			}
		}
	}

	@objc private func appDidBecomeActive() {
		// Refresh events when app becomes active in case of external changes
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			self.handleEventStoreChange()
		}
	}

	private func handleEventStoreChange() {
		// Reload calendars in case new ones were added or removed
		loadCalendars()

		// Reload events for all previously loaded months
		let monthsToReload = Array(loadedMonths)
		if !monthsToReload.isEmpty {
			// Clear events cache
			events = [:]
			loadedMonths = []

			// Reload all previously loaded months
			for monthKey in monthsToReload {
				let components = monthKey.split(separator: "-")
				if components.count == 2,
				   let year = Int(components[0]),
				   let month = Int(components[1]) {
					var dateComponents = DateComponents()
					dateComponents.year = year
					dateComponents.month = month
					dateComponents.day = 1
					if let monthDate = Calendar.current.date(from: dateComponents) {
						loadEventsForMonth(containing: monthDate, forceReload: true)
					}
				}
			}

			print(NSLocalizedString("refreshed_events_due_to_change", comment: "Debug message for event refresh"))
		}

		objectWillChange.send()
	}
}
