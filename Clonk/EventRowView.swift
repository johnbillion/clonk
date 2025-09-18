import SwiftUI
import EventKit

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
