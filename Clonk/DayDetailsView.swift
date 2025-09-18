import SwiftUI
import EventKit

struct DayDetailsView: View {
	let date: Date
	let selectedDayPosition: CGPoint
	let gridWidth: CGFloat

	@ObservedObject private var calendarManager = CalendarManager.shared
	private let calendar = Calendar.current

	private var events: [EKEvent] {
		let dayStart = calendar.startOfDay(for: date)
		return calendarManager.events[dayStart] ?? []
	}

	private var allDayEvents: [EKEvent] {
		events.filter { $0.isAllDay }
	}

	private var morningEvents: [EKEvent] {
		events.filter { !$0.isAllDay && calendar.component(.hour, from: $0.startDate) < 12 }
	}

	private var afternoonEvents: [EKEvent] {
		events.filter { !$0.isAllDay && calendar.component(.hour, from: $0.startDate) >= 12 }
	}

	private let dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "EEE d MMM yyyy" // e.g. "Mon 1 Dec 2025"
		return formatter
	}()

	private let timeFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.timeStyle = .short
		return formatter
	}()

	var body: some View {
		VStack(spacing: 0) {
				// Header with date and all-day events
				FlowLayout(spacing: 8) {
					// Date as a chip (no background)
					HStack(spacing: 6) {
						Text(dateFormatter.string(from: date))
							.font(.subheadline)
							.foregroundColor(.primary)
					}
					.padding(.horizontal, 0)
					.padding(.vertical, 4)

					// All day events as chips
					ForEach(allDayEvents, id: \.eventIdentifier) { event in
						EventChipView(event: event)
					}
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(.horizontal, 16)
				.padding(.vertical, 12)
				.background(Color(NSColor.controlBackgroundColor))

				Divider()

				// Content area
				ScrollView {
					VStack(spacing: 0) {
						// Timed events section
						if !morningEvents.isEmpty || !afternoonEvents.isEmpty {
							HStack(alignment: .top, spacing: 0) {
								// Morning events
								VStack(alignment: .leading, spacing: 8) {
									HStack {
										Text("Morning")
											.font(.system(size: 12, weight: .semibold))
											.foregroundColor(.secondary)
										Spacer()
									}
									.padding(.horizontal, 16)
									.padding(.top, 8)

									if morningEvents.isEmpty {
										Text("No events")
											.font(.system(size: 13))
											.foregroundColor(.secondary)
											.padding(.horizontal, 16)
											.padding(.vertical, 8)
									} else {
										ForEach(morningEvents, id: \.eventIdentifier) { event in
											EventRowView(event: event, showTime: true)
										}
									}

									Spacer(minLength: 0)
								}
								.frame(maxWidth: .infinity)

								// Vertical divider
								Rectangle()
									.fill(Color.gray.opacity(0.3))
									.frame(width: 1)
									.padding(.vertical, 8)

								// Afternoon events
								VStack(alignment: .leading, spacing: 8) {
									HStack {
										Text("Afternoon")
											.font(.system(size: 12, weight: .semibold))
											.foregroundColor(.secondary)
										Spacer()
									}
									.padding(.horizontal, 16)
									.padding(.top, 8)

									if afternoonEvents.isEmpty {
										Text("No events")
											.font(.system(size: 13))
											.foregroundColor(.secondary)
											.padding(.horizontal, 16)
											.padding(.vertical, 8)
									} else {
										ForEach(afternoonEvents, id: \.eventIdentifier) { event in
											EventRowView(event: event, showTime: true)
										}
									}

									Spacer(minLength: 0)
								}
								.frame(maxWidth: .infinity)
							}
							.padding(.bottom, 12)
						}

						// Empty state
						if allDayEvents.isEmpty && morningEvents.isEmpty && afternoonEvents.isEmpty {
							VStack(spacing: 8) {
								Text("No events")
									.font(.system(size: 15))
									.foregroundColor(.primary)
								Text("This day has no scheduled events")
									.font(.system(size: 13))
									.foregroundColor(.secondary)
							}
							.padding(.vertical, 32)
						}
					}
				}
			}
		.frame(width: gridWidth)
		.frame(height: 260) // 5 weeks height
		.background(Color(NSColor.controlBackgroundColor))
	}
}
