import SwiftUI

struct TimezonePanel: View {
	let timezone: TimeZone
	let timezoneIdentifier: String
	let currentTime: Date
	let onTapName: () -> Void
	@State private var isHovered = false
	
	private var timeFormatter: DateFormatter {
		let formatter = DateFormatter()
		formatter.timeZone = timezone
		formatter.timeStyle = .short
		return formatter
	}

	private var timezoneName: String {
		// Use the original identifier we saved, not the timezone's reported identifier
		let identifier = timezoneIdentifier

		// Special case for UTC
		if identifier == "UTC" {
			return "UTC"
		}

		// Extract city name from timezone identifier (e.g., "Europe/Rome" -> "Rome")
		let components = identifier.components(separatedBy: "/")
		if components.count >= 2, let city = components.last {
			// Replace underscores with spaces (e.g., "Los_Angeles" -> "Los Angeles")
			return city.replacingOccurrences(of: "_", with: " ")
		}

		// Fallback to identifier
		return identifier
	}

	var body: some View {
		VStack(spacing: 2) {
			Button(action: onTapName) {
				Text(timezoneName)
					.font(.caption)
					.foregroundColor(.secondary)
					.padding(.horizontal, 4)
					.padding(.vertical, 2)
					.background(isHovered ? Color.gray.opacity(0.15) : Color.clear)
					.cornerRadius(4)
			}
			.buttonStyle(PlainButtonStyle())
			.onHover { hovered in
				isHovered = hovered
			}
			
			Text(timeFormatter.string(from: currentTime))
				.font(.system(size: 14, weight: .medium))
				.foregroundColor(.primary)
		}
		.frame(maxWidth: .infinity)
		.padding(.vertical, 8)
	}
}
