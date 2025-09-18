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
	@State private var selectedDayForDetails: Date?
	@State private var shouldScrollToSelectedDay = false

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
			headerView
			calendarScrollView
		}
	}
	
	private var headerView: some View {
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
	}
	
	private var calendarScrollView: some View {
		ScrollViewReader { proxy in
			ScrollView(showsIndicators: false) {
				LazyVStack(spacing: 0) {
					ForEach(Array(weekGroups.enumerated()), id: \.offset) { weekIndex, week in
						weekRowView(for: week, weekIndex: weekIndex, proxy: proxy)
							.id("week-\(weekIndex)")
						
						detailsViewIfNeeded(for: week, weekIndex: weekIndex)
					}
				}
				.padding(.horizontal, 0)
			}
			.animation(.easeInOut(duration: 0.3), value: showWeekends)
			.animation(.easeInOut(duration: 0.3), value: selectedDayForDetails)
			.onAppear {
				generateInitialDates()
				scrollToSelectedDate(proxy: proxy)
				calendarManager.loadEventsForMonth(containing: selectedDate)
			}
			.onReceive(calendarManager.objectWillChange) { _ in
				// When calendar manager changes, just clear our local tracking
			}
			.onChange(of: selectedDate) {
				if shouldScrollToSelected {
					scrollToSelectedDate(proxy: proxy)
					shouldScrollToSelected = false
				}
			}
			.onChange(of: shouldScrollToToday) {
				print("DEBUG: onChange shouldScrollToToday: \(shouldScrollToToday)")
				if shouldScrollToToday {
					print("DEBUG: Calling scrollToTodaysDate...")
					scrollToTodaysDate(proxy: proxy)
					shouldScrollToToday = false
					print("DEBUG: Reset shouldScrollToToday to false")
				}
			}
			.onChange(of: shouldScrollToSelectedDay) {
				if shouldScrollToSelectedDay {
					scrollToSelectedDate(proxy: proxy)
					shouldScrollToSelectedDay = false
				}
			}
		}
	}
	
	@ViewBuilder
	private func detailsViewIfNeeded(for week: [Date], weekIndex: Int) -> some View {
		if let detailsDate = selectedDayForDetails,
		   week.contains(where: { calendar.isDate($0, inSameDayAs: detailsDate) }) {
			GeometryReader { geometry in
				DayDetailsView(
					date: detailsDate,
					selectedDayPosition: CGPoint(x: calculateDayPosition(for: detailsDate, in: geometry), y: 0),
					gridWidth: geometry.size.width
				)
				.padding(.horizontal, 0)
			}
			.frame(height: 260)
			.transition(.opacity.combined(with: .move(edge: .top)))
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
	
	private var weekGroups: [[Date]] {
		let dates = filteredVisibleDates
		let daysPerWeek = showWeekends ? 7 : 5
		var weeks: [[Date]] = []
		
		for i in stride(from: 0, to: dates.count, by: daysPerWeek) {
			let endIndex = min(i + daysPerWeek, dates.count)
			let week = Array(dates[i..<endIndex])
			if week.count == daysPerWeek {
				weeks.append(week)
			}
		}
		
		return weeks
	}
	
	@ViewBuilder
	private func weekRowView(for week: [Date], weekIndex: Int, proxy: ScrollViewProxy) -> some View {
		HStack(spacing: 0) {
			ForEach(week, id: \.self) { date in
				CalendarDayView(
					date: date,
					isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
					isToday: calendar.isDate(date, inSameDayAs: todaysDate),
					onTap: {
						handleDayTap(date: date, proxy: proxy)
					},
					isAlternateMonth: isAlternateMonth(date),
					hasDetailsOpen: selectedDayForDetails != nil && calendar.isDate(date, inSameDayAs: selectedDayForDetails!)
				)
				.id(date)
				.onAppear {
					let totalDaysBeforeThisWeek = weekIndex * (showWeekends ? 7 : 5)
					if totalDaysBeforeThisWeek >= filteredVisibleDates.count - 180 && !isLoadingMore {
						loadMoreWeeks()
					}
					checkAndLoadEventsForMonth(date)
				}
			}
		}
	}
	
	@ViewBuilder
	private func detailsOverlay(for detailsDate: Date, proxy: ScrollViewProxy) -> some View {
		// Simple test - just show a colored rectangle to confirm overlay is working
		Color.blue.opacity(0.3)
			.frame(width: 300, height: 200)
			.overlay(
				Text("Details for \(detailsDate.formatted())")
					.foregroundColor(.white)
			)
			.offset(y: 100) // Position it below the header
			.onAppear {
				print("DEBUG: Details overlay appearing for date: \(detailsDate)")
			}
	}
	
	private func calculateDayPosition(for date: Date, in geometry: GeometryProxy) -> CGFloat {
		// Find which day of the week this date is
		let dayOfWeek = (calendar.component(.weekday, from: date) + 5) % 7 // Convert to Monday=0 format
		let adjustedDayOfWeek = showWeekends ? dayOfWeek : min(dayOfWeek, 4) // Limit to weekdays if needed
		
		let dayWidth = geometry.size.width / CGFloat(showWeekends ? 7 : 5)
		return CGFloat(adjustedDayOfWeek) * dayWidth + dayWidth / 2
	}
	
	private func calculateWeekRowPosition(for date: Date, in geometry: GeometryProxy) -> CGFloat {
		// Find which week row contains this date
		let daysPerWeek = showWeekends ? 7 : 5
		
		// Find the index of this date in filteredVisibleDates
		if let dateIndex = filteredVisibleDates.firstIndex(where: { calendar.isDate($0, inSameDayAs: date) }) {
			let weekIndex = dateIndex / daysPerWeek
			return CGFloat(weekIndex) * 52 // 52 is the day height
		}
		
		return 0
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
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			let scrollTarget = calculateScrollTargetForToday(for: selectedDate)
			print("DEBUG: scrollToSelectedDate - selectedDate: \(selectedDate)")
			print("DEBUG: scrollToSelectedDate - scrollTarget: \(scrollTarget)")
			
			withAnimation(.easeInOut(duration: 0.3)) {
				proxy.scrollTo(scrollTarget, anchor: .top)
			}
		})
	}
	
	private func scrollToTodaysDate(proxy: ScrollViewProxy) {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			let scrollTarget = calculateScrollTargetForToday(for: todaysDate)
			print("DEBUG: scrollToTodaysDate - todaysDate: \(todaysDate)")
			print("DEBUG: scrollToTodaysDate - scrollTarget: \(scrollTarget)")
			
			withAnimation(.easeInOut(duration: 0.3)) {
				proxy.scrollTo(scrollTarget, anchor: .top)
			}
		})
	}
	
	private func calculateScrollTargetForToday(for date: Date) -> String {
		// Find which week contains this date and scroll to 1 week before (second row)
		for (weekIndex, week) in weekGroups.enumerated() {
			if week.contains(where: { calendar.isDate($0, inSameDayAs: date) }) {
				let targetWeekIndex = max(0, weekIndex - 1)
				let scrollTarget = "week-\(targetWeekIndex)"
				print("DEBUG: calculateScrollTargetForToday - found date in week \(weekIndex), scrolling to week-\(targetWeekIndex)")
				return scrollTarget
			}
		}
		
		// Fallback to first week
		print("DEBUG: calculateScrollTargetForToday - date not found, scrolling to week-0")
		return "week-0"
	}
	
	private func calculateScrollTargetForDetails(for date: Date) -> String {
		// Find which week contains this date and scroll to that week (top row)
		for (weekIndex, week) in weekGroups.enumerated() {
			if week.contains(where: { calendar.isDate($0, inSameDayAs: date) }) {
				let scrollTarget = "week-\(weekIndex)"
				print("DEBUG: calculateScrollTargetForDetails - found date in week \(weekIndex), scrolling to week-\(weekIndex)")
				return scrollTarget
			}
		}
		
		// Fallback to first week
		print("DEBUG: calculateScrollTargetForDetails - date not found, scrolling to week-0")
		return "week-0"
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
	
	private func handleDayTap(date: Date, proxy: ScrollViewProxy) {
		print("DEBUG: handleDayTap called for date: \(date)")
		print("DEBUG: Current selectedDayForDetails: \(String(describing: selectedDayForDetails))")
		selectedDate = date
		shouldScrollToSelected = calendar.isDate(date, inSameDayAs: todaysDate)
		
		// Toggle details view for the same day
		if let currentDetailsDate = selectedDayForDetails,
		   calendar.isDate(date, inSameDayAs: currentDetailsDate) {
			print("DEBUG: Closing details (was showing \(currentDetailsDate))")
			selectedDayForDetails = nil
		} else {
			print("DEBUG: Opening details for \(date)")
			
			selectedDayForDetails = date
			print("DEBUG: Updated selectedDayForDetails to: \(date)")
			
			// Calculate scroll target AFTER updating selectedDayForDetails
			let scrollTarget = calculateScrollTargetForDetails(for: date)
			print("DEBUG: Calculated scroll target: \(scrollTarget)")
			
			// Delay scroll slightly to let UI update
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
				print("DEBUG: Scrolling for details to: \(scrollTarget)")
				withAnimation(.easeInOut(duration: 0.3)) {
					proxy.scrollTo(scrollTarget, anchor: .top)
				}
			}
		}
		print("DEBUG: Final selectedDayForDetails: \(String(describing: selectedDayForDetails))")
	}
}

