import SwiftUI
import AppKit

struct ContentView: View {
	@State private var todaysDate = Date()
	@State private var selectedDate = Date()
	@State private var shouldScrollToToday = false
	@State private var isPinned = true
	@State private var isPinHovered = false
	@State private var isTodayHovered = false
	let appDelegate: AppDelegate

	var body: some View {
		VStack(spacing: 0) {
			HStack {
				Text(monthYearString())
					.font(.headline)
					.padding(.horizontal)
				Spacer()
				Button(action: {
					isPinned.toggle()
					appDelegate.setPinned(isPinned)
				}) {
					Image(systemName: isPinned ? "pin.fill" : "pin")
						.foregroundColor(isPinned ? .blue : .secondary)
						.padding(6)
						.background(isPinHovered ? Color.gray.opacity(0.15) : Color.clear)
						.cornerRadius(4)
				}
				.buttonStyle(PlainButtonStyle())
				.onHover { isHovered in
					isPinHovered = isHovered
				}
				.padding(.horizontal)
			}
			.padding(.vertical, 10)
			.background(Color.white)

			InfiniteCalendarView(
				selectedDate: $selectedDate, 
				todaysDate: todaysDate,
				shouldScrollToToday: $shouldScrollToToday
			)
			.frame(width: 480, height: 440)

			Divider()

			HStack {
				Button(action: {
					selectedDate = todaysDate
					shouldScrollToToday = true
				}) {
					Text("Today")
						.foregroundColor(.blue)
						.padding(.horizontal, 8)
						.padding(.vertical, 4)
						.background(isTodayHovered ? Color.gray.opacity(0.15) : Color.clear)
						.cornerRadius(4)
				}
				.buttonStyle(PlainButtonStyle())
				.onHover { isHovered in
					isTodayHovered = isHovered
				}
				.padding(.horizontal)

				Spacer()

				Text(dateString(selectedDate))
					.font(.caption)
					.foregroundColor(.secondary)
					.padding(.horizontal)
			}
			.padding(.vertical, 8)
			.background(Color.white)
		}
		.frame(width: 480)
		.background(Color.white)
	}

	func monthYearString() -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "MMMM yyyy"
		return formatter.string(from: selectedDate)
	}

	func dateString(_ date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		return formatter.string(from: date)
	}
}
