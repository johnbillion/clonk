import SwiftUI

struct TimezonePanel: View {
	let timezone: TimeZone
	let timezoneIdentifier: String
	let currentTime: Date
	let onTapName: () -> Void
	let onDelete: (() -> Void)?
	let timezoneCount: Int
	@State private var isHovered = false
	@State private var isNameButtonHovered = false
	@State private var showDeleteButton = false
	@State private var hoverTask: Task<Void, Never>?

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

	private var fontSize: CGFloat {
		let baseSize: CGFloat = 15
		return max(baseSize - CGFloat(max(0, timezoneCount - 4)), 10)
	}

	private var nameFontSize: CGFloat {
		return max(fontSize * 0.75, 10)
	}

	var body: some View {
		ZStack {
			VStack(spacing: 2) {
				Button(action: onTapName) {
					Text(timezoneName)
						.font(.system(size: nameFontSize, weight: .medium))
						.foregroundColor(.primary)
						.lineLimit(1)
						.truncationMode(.tail)
						.padding(.horizontal, 4)
						.padding(.vertical, 2)
						.background(isNameButtonHovered ? Color.gray.opacity(0.15) : Color.clear)
						.cornerRadius(4)
				}
				.buttonStyle(PlainButtonStyle())
				.onHover { hovered in
					isNameButtonHovered = hovered
				}

				Text(timeFormatter.string(from: currentTime))
					.font(.system(size: fontSize, weight: .medium))
					.foregroundColor(.primary)
			}
			.frame(maxWidth: .infinity)
			.padding(.vertical, 8)

			// Delete button in top-right corner
			if showDeleteButton && onDelete != nil {
				VStack {
					HStack {
						Spacer()
						Button(action: {
							onDelete?()
						}) {
							Image(systemName: "minus.circle.fill")
								.foregroundColor(.red)
								.background(Color.white)
								.clipShape(Circle())
						}
						.buttonStyle(PlainButtonStyle())
					}
					Spacer()
				}
				.padding(.top, 4)
				.padding(.trailing, 4)
			}

		}
		.onHover { hovered in
			isHovered = hovered

			// Cancel previous task
			hoverTask?.cancel()

			if hovered {
				// Start intent delay
				hoverTask = Task {
					try? await Task.sleep(nanoseconds: 200_000_000) // 0.20 second delay
					if !Task.isCancelled {
						await MainActor.run {
							showDeleteButton = true
						}
					}
				}
			} else {
				// Hide immediately when not hovering
				showDeleteButton = false
			}
		}
	}
}
