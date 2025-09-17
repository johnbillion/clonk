import SwiftUI
import EventKit

struct CalendarRow: View {
	let calendar: EKCalendar
	let isSelected: Bool
	let onToggle: () -> Void

	var body: some View {
		Button(action: onToggle) {
			HStack(spacing: 12) {
				Toggle("", isOn: .constant(isSelected))
					.labelsHidden()
					.allowsHitTesting(false)

				Circle()
					.fill(Color(cgColor: calendar.cgColor))
					.frame(width: 12, height: 12)

				Text(calendar.title)
					.font(.system(size: 13))
					.foregroundColor(.primary)
					.lineLimit(1)

				Spacer()
			}
			.padding(.horizontal)
			.padding(.vertical, 6)
			.contentShape(Rectangle())
		}
		.buttonStyle(.plain)
		.background(isSelected ? Color.accentColor.opacity(0.05) : Color.clear)
	}
}
