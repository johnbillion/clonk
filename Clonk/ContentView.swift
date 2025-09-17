import SwiftUI
import AppKit

struct ContentView: View {
	@State private var todaysDate = Date()
	@State private var selectedDate = Date()
	@State private var shouldScrollToToday = false
	@State private var isPinned = true
	@State private var isPinHovered = false
	@State private var isTodayHovered = false
	@State private var selectedTimezones: [TimeZone] = []
	@State private var timezoneIdentifiers: [String] = []
	@State private var timer: Timer?
	let appDelegate: AppDelegate

	var body: some View {
		VStack(spacing: 0) {
			TimezoneContainer(
				selectedTimezones: $selectedTimezones,
				timezoneIdentifiers: $timezoneIdentifiers,
				onTimezoneChanged: saveTimezones
			)

			Divider()

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
						.foregroundColor(Color(NSColor.controlAccentColor))
						.padding(.horizontal, 8)
						.padding(.vertical, 4)
						.background(isTodayHovered ? Color.gray.opacity(0.15) : Color.clear)
						.cornerRadius(4)
				}
				.buttonStyle(PlainButtonStyle())
				.onHover { isHovered in
					isTodayHovered = isHovered
				}

				Spacer()

				Text(dateString(selectedDate))
					.font(.caption)
					.foregroundColor(.secondary)

				Spacer()

				Button(action: {
					isPinned.toggle()
					appDelegate.setPinned(isPinned)
				}) {
					Image(systemName: isPinned ? "pin.fill" : "pin")
						.foregroundColor(isPinned ? Color(NSColor.controlAccentColor) : .secondary)
						.padding(6)
						.background(isPinHovered ? Color.gray.opacity(0.15) : Color.clear)
						.cornerRadius(4)
				}
				.buttonStyle(PlainButtonStyle())
				.onHover { isHovered in
					isPinHovered = isHovered
				}
			}
			.padding(.horizontal)
			.padding(.vertical, 8)
			.background(Color(NSColor.windowBackgroundColor))
		}
		.frame(width: 480)
		.background(Color(NSColor.windowBackgroundColor))
		.onAppear {
			loadSavedTimezones()
		}
	}

	func dateString(_ date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		return formatter.string(from: date)
	}

	private func defaultTimezoneIdentifiers() -> [String] {
		return [
			"America/Los_Angeles",  // US West Coast
			"America/New_York",     // US East Coast
			"Europe/London",        // London
			"Asia/Singapore"        // Singapore
		]
	}

	private func loadSavedTimezones() {
		timezoneIdentifiers = UserDefaults.standard.stringArray(forKey: "selectedTimezoneIdentifiers") ?? defaultTimezoneIdentifiers()

		selectedTimezones = timezoneIdentifiers.compactMap { TimeZone(identifier: $0) }

		// If no saved timezones, use defaults
		if timezoneIdentifiers.isEmpty {
			timezoneIdentifiers = defaultTimezoneIdentifiers()
			selectedTimezones = timezoneIdentifiers.compactMap { TimeZone(identifier: $0) }
		}
	}

	private func saveTimezones() {
		UserDefaults.standard.set(timezoneIdentifiers, forKey: "selectedTimezoneIdentifiers")
	}
}
