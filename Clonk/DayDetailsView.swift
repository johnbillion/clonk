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
		formatter.dateStyle = .full
		return formatter
	}()
	
	private let timeFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.timeStyle = .short
		return formatter
	}()
	
	var body: some View {
		VStack(spacing: 0) {
			// Triangle pointer
			HStack {
				Spacer()
					.frame(width: selectedDayPosition.x - 8)
				Triangle()
					.fill(Color(NSColor.controlBackgroundColor))
					.frame(width: 16, height: 8)
				Spacer()
			}
			
			// Details panel
			VStack(spacing: 0) {
				// Header with date
				HStack {
					Text(dateFormatter.string(from: date))
						.font(.headline)
						.foregroundColor(.primary)
					Spacer()
				}
				.padding(.horizontal, 16)
				.padding(.vertical, 12)
				.background(Color(NSColor.controlBackgroundColor))
				
				Divider()
				
				// Content area
				ScrollView {
					VStack(spacing: 0) {
						// All day events section
						if !allDayEvents.isEmpty {
							VStack(alignment: .leading, spacing: 8) {
								HStack {
									Text("All Day")
										.font(.system(size: 12, weight: .semibold))
										.foregroundColor(.secondary)
									Spacer()
								}
								.padding(.horizontal, 16)
								.padding(.top, 12)
								
								ForEach(allDayEvents, id: \.eventIdentifier) { event in
									EventRowView(event: event, showTime: false)
								}
							}
							
							if !morningEvents.isEmpty || !afternoonEvents.isEmpty {
								Divider()
									.padding(.vertical, 8)
							}
						}
						
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
									
									if morningEvents.isEmpty {
										Text("No events")
											.font(.caption)
											.foregroundStyle(.tertiary)
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
									
									if afternoonEvents.isEmpty {
										Text("No events")
											.font(.caption)
											.foregroundStyle(.tertiary)
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
									.font(.subheadline)
									.foregroundColor(.secondary)
								Text("This day has no scheduled events")
									.font(.caption)
									.foregroundStyle(.tertiary)
							}
							.padding(.vertical, 32)
						}
					}
				}
			}
			.background(Color(NSColor.controlBackgroundColor))
			.cornerRadius(8)
			.shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
		}
		.frame(width: gridWidth)
		.frame(height: 260) // Approximately 5 weeks height (52 * 5)
	}
}

struct EventRowView: View {
	let event: EKEvent
	let showTime: Bool
	
	private let timeFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.timeStyle = .short
		return formatter
	}()
	
	var body: some View {
		HStack(spacing: 8) {
			Circle()
				.fill(Color(cgColor: event.calendar.cgColor))
				.frame(width: 8, height: 8)
			
			VStack(alignment: .leading, spacing: 2) {
				Text(event.title)
					.font(.system(size: 13))
					.foregroundColor(.primary)
					.lineLimit(2)
				
				if showTime {
					Text(timeFormatter.string(from: event.startDate))
						.font(.system(size: 11))
						.foregroundColor(.secondary)
				}
			}
			
			Spacer()
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 4)
	}
}

struct Triangle: Shape {
	func path(in rect: CGRect) -> Path {
		var path = Path()
		path.move(to: CGPoint(x: rect.midX, y: rect.minY))
		path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
		path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
		path.closeSubpath()
		return path
	}
}