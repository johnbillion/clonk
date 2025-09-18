import SwiftUI

struct InfiniteCalendarView: View {
	@Binding var selectedDate: Date
	let todaysDate: Date
	@Binding var shouldScrollToToday: Bool
	@State private var visibleDates: [Date] = []
	@State private var isLoadingMore = false
	@State private var shouldScrollToSelected = false
	@State private var loadedMonths: Set<String> = []
	@StateObject private var calendarManager = CalendarManager.shared
	@AppStorage("showWeekends") private var showWeekends: Bool = true

	private let calendar: Calendar = {
		var cal = Calendar.current
		cal.locale = Locale.autoupdatingCurrent
		return cal
	}()

	private let dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "d"
		return formatter
	}()

	private var weekdaySymbols: [String] {
		let symbols = calendar.shortStandaloneWeekdaySymbols
		// Calendar.current.firstWeekday tells us which day starts the week (1=Sunday, 2=Monday)
		// But we always want Monday first for our grid
		// weekdaySymbols array is always indexed as [Sunday, Monday, Tuesday, ...]
		// regardless of locale, per Apple documentation

		if showWeekends {
			// Start with Monday (index 1) through Saturday (index 6), then Sunday (index 0)
			var reordered: [String] = []
			for i in 1...6 {
				reordered.append(symbols[i])
			}
			reordered.append(symbols[0]) // Add Sunday at the end
			return reordered
		} else {
			// Only weekdays: Monday through Friday
			var weekdays: [String] = []
			for i in 1...5 {
				weekdays.append(symbols[i])
			}
			return weekdays
		}
	}

	var body: some View {
		VStack(spacing: 0) {
			HStack(spacing: 0) {
				ForEach(weekdaySymbols, id: \.self) { day in
					Text(day)
						.font(.system(size: 12, weight: .medium))
						.foregroundColor(.secondary)
						.frame(maxWidth: .infinity)
						.frame(height: 24)
				}
			}
			.background(Color(NSColor.controlBackgroundColor))
			.animation(.easeInOut(duration: 0.3), value: showWeekends)

			ScrollViewReader { proxy in
				ScrollView(showsIndicators: false) {
					LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: showWeekends ? 7 : 5), spacing: 0) {
					ForEach(Array(filteredVisibleDates.enumerated()), id: \.element) { index, date in
						CalendarDayView(
							date: date,
							isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
							isToday: calendar.isDate(date, inSameDayAs: todaysDate),
							onTap: {
								selectedDate = date
								shouldScrollToSelected = calendar.isDate(date, inSameDayAs: todaysDate)
							},
							isAlternateMonth: isAlternateMonth(date)
						)
						.onAppear {
							if index >= filteredVisibleDates.count - 180 && !isLoadingMore {
								loadMoreWeeks()
							}
							checkAndLoadEventsForMonth(date)
						}
					}
				}
				.padding(.horizontal, 0)
				.animation(.easeInOut(duration: 0.3), value: showWeekends)
			}
			.onAppear {
				generateInitialDates()
				scrollToSelectedDate(proxy: proxy)
				// Load events for the initial visible months
				calendarManager.loadEventsForMonth(containing: selectedDate)
			}
			.onReceive(calendarManager.objectWillChange) { _ in
				// When calendar manager changes, just clear our local tracking
				// The calendar manager will handle reloading
			}
			.onChange(of: selectedDate) {
				if shouldScrollToSelected {
					scrollToSelectedDate(proxy: proxy)
					shouldScrollToSelected = false
				}
			}
			.onChange(of: shouldScrollToToday) {
				if shouldScrollToToday {
					scrollToSelectedDate(proxy: proxy)
					shouldScrollToToday = false
				}
			}
			}
		}
	}

	private var filteredVisibleDates: [Date] {
		if showWeekends {
			return visibleDates
		} else {
			return visibleDates.filter { date in
				let weekday = calendar.component(.weekday, from: date)
				return weekday != 1 && weekday != 7 // Exclude Sunday (1) and Saturday (7)
			}
		}
	}

	private func generateInitialDates() {
		let twelveMonthsAgo = calendar.date(byAdding: .month, value: -12, to: Date()) ?? Date()
		let firstDayOfMonth = calendar.dateInterval(of: .month, for: twelveMonthsAgo)?.start ?? twelveMonthsAgo
		let startDate = startOfWeek(for: firstDayOfMonth)
		let endDate = calendar.date(byAdding: .month, value: 12, to: Date()) ?? Date()

		var dates: [Date] = []
		var currentDate = startDate
		let finalDate = endOfWeek(for: endDate)

		while currentDate <= finalDate {
			dates.append(currentDate)
			currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
		}

		visibleDates = dates
	}

	private func startOfWeek(for date: Date) -> Date {
		let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
		return calendar.date(from: components) ?? date
	}

	private func endOfWeek(for date: Date) -> Date {
		let startOfWeek = startOfWeek(for: date)
		return calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? date
	}

	private func scrollToSelectedDate(proxy: ScrollViewProxy) {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			let targetDate = calendar.startOfDay(for: selectedDate)
			let mondayOfTargetWeek = startOfWeek(for: targetDate)
			let mondayOneWeekBefore = calendar.date(byAdding: .day, value: -7, to: mondayOfTargetWeek) ?? mondayOfTargetWeek

			if let scrollToDate = filteredVisibleDates.first(where: { calendar.isDate($0, inSameDayAs: mondayOneWeekBefore) }) {
				withAnimation(.easeInOut(duration: 0.3)) {
					proxy.scrollTo(scrollToDate, anchor: UnitPoint.top)
				}
			}
		}
	}

	private func isAlternateMonth(_ date: Date) -> Bool {
		let month = calendar.component(.month, from: date)
		return month % 2 == 0
	}

	private func loadMoreWeeks() {
		guard !isLoadingMore else { return }
		isLoadingMore = true

		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			let lastDate = self.visibleDates.last ?? Date()
			let nextDay = self.calendar.date(byAdding: .day, value: 1, to: lastDate) ?? lastDate
			let endDate = self.calendar.date(byAdding: .month, value: 6, to: nextDay) ?? nextDay

			var newDates: [Date] = []
			var currentDate = nextDay

			while currentDate <= endDate {
				var weekDates: [Date] = []
				for _ in 0..<7 {
					if currentDate <= endDate {
						weekDates.append(currentDate)
						currentDate = self.calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
					}
				}
				if !weekDates.isEmpty {
					newDates.append(contentsOf: weekDates)
				}
			}

			self.visibleDates.append(contentsOf: newDates)
			self.isLoadingMore = false
		}
	}

	private func checkAndLoadEventsForMonth(_ date: Date, forceReload: Bool = false) {
		let components = calendar.dateComponents([.year, .month], from: date)
		let monthKey = "\(components.year ?? 0)-\(components.month ?? 0)"

		if forceReload || !loadedMonths.contains(monthKey) {
			if !forceReload {
				loadedMonths.insert(monthKey)
			}
			calendarManager.loadEventsForMonth(containing: date, forceReload: forceReload)
		}
	}
}

