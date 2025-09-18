import SwiftUI
import EventKit

struct CalendarDayView: View {
	let date: Date
	let isSelected: Bool
	let isToday: Bool
	let onTap: () -> Void
	let isAlternateMonth: Bool

	@ObservedObject private var calendarManager = CalendarManager.shared
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
					.frame(maxWidth: .infinity, alignment: .topTrailing)
					.padding(.top, 7)
					.padding(.trailing, 10)

				if !events.isEmpty {
					HStack(spacing: 2) {
						Spacer()
						ForEach(Array(events.prefix(3)), id: \.eventIdentifier) { event in
							Circle()
								.fill(Color(cgColor: event.calendar.cgColor))
								.frame(width: 4, height: 4)
						}
						if events.count > 3 {
							Text("+\(events.count - 3)")
								.font(.system(size: 9))
								.foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
						}
					}
					.padding(.bottom, 6)
					.padding(.trailing, 10)
				}

				Spacer(minLength: 0)
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
			return Color(NSColor.controlAccentColor)
		} else {
			return .primary
		}
	}

	private var backgroundColor: Color {
		if isSelected {
			return Color(NSColor.controlAccentColor)
		} else if isWeekend {
			return Color.gray.opacity(0.01)
		} else if isAlternateMonth {
			return Color.gray.opacity(0.0005)
		} else {
			return Color(NSColor.controlBackgroundColor)
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
				return "Jan \(day) \(year)"
			} else {
				return "\(monthFormatter.string(from: date)) \(day)"
			}
		} else {
			return "\(day)"
		}
	}

	private var events: [EKEvent] {
		let dayStart = calendar.startOfDay(for: date)
		return calendarManager.events[dayStart] ?? []
	}

}
