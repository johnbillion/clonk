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
				.frame(width: 10, height: 10)

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


struct EventChipView: View {
	let event: EKEvent
	
	var body: some View {
		HStack(spacing: 6) {
			Circle()
				.fill(Color(cgColor: event.calendar.cgColor))
				.frame(width: 12, height: 12)
				.overlay(
					Circle()
						.stroke(Color(NSColor.controlBackgroundColor), lineWidth: 1)
				)

			Text(event.title)
				.font(.system(size: 12))
				.foregroundColor(.primary)
				.lineLimit(1)
		}
		.padding(.horizontal, 8)
		.padding(.vertical, 4)
		.background(Color.gray.opacity(0.1))
		.cornerRadius(12)
	}
}

struct FlowLayout: Layout {
	var spacing: CGFloat
	
	init(spacing: CGFloat = 8) {
		self.spacing = spacing
	}
	
	func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
		let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
		return layout(sizes: sizes, proposal: proposal).size
	}
	
	func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
		let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
		let positions = layout(sizes: sizes, proposal: proposal).positions
		
		for (index, subview) in subviews.enumerated() {
			subview.place(at: CGPoint(x: bounds.minX + positions[index].x, y: bounds.minY + positions[index].y), proposal: .unspecified)
		}
	}
	
	private func layout(sizes: [CGSize], proposal: ProposedViewSize) -> (size: CGSize, positions: [CGPoint]) {
		let maxWidth = proposal.width ?? .infinity
		var positions: [CGPoint] = []
		var currentRowWidth: CGFloat = 0
		var currentRowHeight: CGFloat = 0
		var totalHeight: CGFloat = 0
		var currentY: CGFloat = 0
		
		for (index, size) in sizes.enumerated() {
			if currentRowWidth + size.width > maxWidth && currentRowWidth > 0 {
				// Start new row
				totalHeight += currentRowHeight + spacing
				currentY += currentRowHeight + spacing
				currentRowWidth = 0
				currentRowHeight = 0
			}
			
			positions.append(CGPoint(x: currentRowWidth, y: currentY))
			currentRowWidth += size.width + (index < sizes.count - 1 ? spacing : 0)
			currentRowHeight = max(currentRowHeight, size.height)
		}
		
		totalHeight += currentRowHeight
		
		return (CGSize(width: min(currentRowWidth, maxWidth), height: totalHeight), positions)
	}
}