import SwiftUI
import EventKit

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
