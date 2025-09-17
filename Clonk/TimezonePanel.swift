import SwiftUI

struct TimezonePanel: View {
	let timezone: TimeZone
	let timezoneIdentifier: String
	let currentTime: Date
	let onTapName: () -> Void
	let onDelete: (() -> Void)?
	let onAddLeft: (() -> Void)?
	let onAddRight: (() -> Void)?
	let isFirst: Bool
	let isLast: Bool
	@State private var isHovered = false
	@State private var isNameButtonHovered = false
	@State private var showDeleteButton = false
	@State private var showAddButtons = false
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

	var body: some View {
		ZStack {
			VStack(spacing: 2) {
				Button(action: onTapName) {
					Text(timezoneName)
						.font(.caption)
						.foregroundColor(.secondary)
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
					.font(.system(size: 14, weight: .medium))
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

			// Plus buttons
			if showAddButtons {
				HStack {
					// Left add button
					if let onAddLeft = onAddLeft {
						HStack {
							Button(action: onAddLeft) {
								Image(systemName: "plus.circle.fill")
									.foregroundColor(Color(NSColor.controlAccentColor))
									.background(Color.white)
									.clipShape(Circle())
									.font(.system(size: 14))
							}
							.buttonStyle(PlainButtonStyle())
							.offset(x: isFirst ? 3 : -9) // Inboard if first, over separator otherwise

							Spacer()
						}
					}

					Spacer()

					// Right add button
					if let onAddRight = onAddRight {
						HStack {
							Spacer()

							Button(action: onAddRight) {
								Image(systemName: "plus.circle.fill")
									.foregroundColor(Color(NSColor.controlAccentColor))
									.background(Color.white)
									.clipShape(Circle())
									.font(.system(size: 14))
							}
							.buttonStyle(PlainButtonStyle())
							.offset(x: isLast ? -3 : 9) // Inboard if last, over separator otherwise
						}
					}
				}
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
							showAddButtons = true
						}
					}
				}
			} else {
				// Hide immediately when not hovering
				showDeleteButton = false
				showAddButtons = false
			}
		}
	}
}
