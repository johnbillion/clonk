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
						.foregroundColor(isPinned ? .blue : .secondary)
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
			.background(Color.white)
		}
		.frame(width: 480)
		.background(Color.white)
		.onAppear {
			loadSavedTimezones()
		}
	}

	func dateString(_ date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		return formatter.string(from: date)
	}
	
	private func loadSavedTimezones() {
		timezoneIdentifiers = UserDefaults.standard.stringArray(forKey: "selectedTimezoneIdentifiers") ?? [
			"America/Los_Angeles",
			"UTC", 
			"Europe/London",
			"Asia/Singapore"
		]
		
		selectedTimezones = timezoneIdentifiers.compactMap { TimeZone(identifier: $0) }
		
		// Ensure we always have 4 timezones
		while selectedTimezones.count < 4 && timezoneIdentifiers.count < 4 {
			let defaultTimezones = ["America/Los_Angeles", "UTC", "Europe/London", "Asia/Singapore"]
			for identifier in defaultTimezones {
				if let timezone = TimeZone(identifier: identifier),
				   !timezoneIdentifiers.contains(identifier) {
					selectedTimezones.append(timezone)
					timezoneIdentifiers.append(identifier)
					break
				}
			}
		}
	}
	
	private func saveTimezones() {
		UserDefaults.standard.set(timezoneIdentifiers, forKey: "selectedTimezoneIdentifiers")
	}
}
