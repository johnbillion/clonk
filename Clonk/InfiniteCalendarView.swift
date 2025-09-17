import SwiftUI

struct InfiniteCalendarView: View {
	@Binding var selectedDate: Date
	let todaysDate: Date
	@Binding var shouldScrollToToday: Bool
	@State private var visibleDates: [Date] = []
	@State private var isLoadingMore = false
	@State private var shouldScrollToSelected = false

	private let calendar = Calendar.current
	private let dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "d"
		return formatter
	}()

	var body: some View {
		VStack(spacing: 0) {
			HStack(spacing: 0) {
				ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
					Text(day)
						.font(.system(size: 12, weight: .medium))
						.foregroundColor(.secondary)
						.frame(maxWidth: .infinity)
						.frame(height: 24)
				}
			}
			.background(Color.gray.opacity(0.1))

			ScrollViewReader { proxy in
				ScrollView(showsIndicators: false) {
					LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
					ForEach(Array(visibleDates.enumerated()), id: \.element) { index, date in
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
							if index >= visibleDates.count - 180 && !isLoadingMore {
								loadMoreWeeks()
							}
						}
					}
				}
				.padding(.horizontal, 0)
			}
			.onAppear {
				generateInitialDates()
				scrollToSelectedDate(proxy: proxy)
			}
			.onChange(of: selectedDate) { _ in
				if shouldScrollToSelected {
					scrollToSelectedDate(proxy: proxy)
					shouldScrollToSelected = false
				}
			}
			.onChange(of: shouldScrollToToday) { _ in
				if shouldScrollToToday {
					scrollToSelectedDate(proxy: proxy)
					shouldScrollToToday = false
				}
			}
			}
		}
	}

	private func generateInitialDates() {
		let startDate = calendar.date(byAdding: .month, value: -12, to: Date()) ?? Date()
		let endDate = calendar.date(byAdding: .month, value: 12, to: Date()) ?? Date()

		var dates: [Date] = []
		var currentDate = startOfWeek(for: startDate)
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
			let oneWeekBefore = calendar.date(byAdding: .day, value: -7, to: targetDate) ?? targetDate
			if let scrollToDate = visibleDates.first(where: { calendar.isDate($0, inSameDayAs: oneWeekBefore) }) {
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
}

struct CalendarDayView: View {
	let date: Date
	let isSelected: Bool
	let isToday: Bool
	let onTap: () -> Void
	let isAlternateMonth: Bool

	private let calendar = Calendar.current
	private let dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "d"
		return formatter
	}()

	private let monthFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "MMM"
		return formatter
	}()

	var body: some View {
		Button(action: onTap) {
			VStack(spacing: 2) {
				Text(displayText)
					.font(.system(size: 14, weight: isSelected ? .semibold : (calendar.component(.day, from: date) == 1 ? .semibold : .regular)))
					.foregroundColor(textColor)
					.multilineTextAlignment(.trailing)
					.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
					.padding(.top, 7)
					.padding(.trailing, 10)
			}
			.frame(height: 52)
			.frame(maxWidth: .infinity)
			.background(backgroundColor)
			.overlay(
				Rectangle()
					.stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
			)
		}
		.buttonStyle(PlainButtonStyle())
	}

	private var textColor: Color {
		if isSelected {
			return .white
		} else if isToday {
			return .blue
		} else {
			return .primary
		}
	}

	private var backgroundColor: Color {
		if isSelected {
			return .blue
		} else if isWeekend {
			return Color.gray.opacity(0.1)
		} else if isAlternateMonth {
			return Color.gray.opacity(0.05)
		} else {
			return Color.clear
		}
	}

	private var isWeekend: Bool {
		let weekday = calendar.component(.weekday, from: date)
		return weekday == 1 || weekday == 7
	}

	private var displayText: String {
		let day = calendar.component(.day, from: date)
		let month = calendar.component(.month, from: date)

		if day == 1 {
			if month == 1 {
				let year = calendar.component(.year, from: date)
				return "\(day) Jan \(year)"
			} else {
				return "\(day) \(monthFormatter.string(from: date))"
			}
		} else {
			return "\(day)"
		}
	}

}
