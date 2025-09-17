import SwiftUI

struct TimezonePickerView: View {
	let onSelection: (TimeZone, String) -> Void
	@State private var searchText = ""
	@State private var filteredTimezones: [(TimeZone, String)] = []

	private var allTimezones: [(TimeZone, String)] {
		let now = Date()
		var allIdentifiers = TimeZone.knownTimeZoneIdentifiers

		// Add GMT (which represents UTC) to the beginning if not present
		if !allIdentifiers.contains("GMT") {
			allIdentifiers.insert("GMT", at: 0)
		}

		let allTimezones = allIdentifiers
			.compactMap { identifier -> (TimeZone, String)? in
				guard let timezone = TimeZone(identifier: identifier) else {
					return nil
				}
				let displayName = friendlyName(for: timezone)
				return (timezone, displayName)
			}
			.sorted { timezone1, timezone2 in
				let offset1 = timezone1.0.secondsFromGMT(for: now)
				let offset2 = timezone2.0.secondsFromGMT(for: now)
				if offset1 == offset2 {
					return timezone1.1 < timezone2.1 // Sort by name if same offset
				}
				return offset1 < offset2
			}

		return allTimezones
	}

	private func updateFilteredTimezones() {
		if searchText.isEmpty {
			filteredTimezones = allTimezones
		} else {
			filteredTimezones = allTimezones.filter {
				$0.1.localizedCaseInsensitiveContains(searchText) ||
				$0.0.identifier.localizedCaseInsensitiveContains(searchText)
			}
		}
	}

	private func friendlyName(for timezone: TimeZone) -> String {
		// Special case for GMT - display as UTC
		if timezone.identifier == "GMT" {
			return "UTC"
		}

		// Use the system localized name or format the identifier
		if let localizedName = timezone.localizedName(for: .generic, locale: .current) {
			let components = timezone.identifier.components(separatedBy: "/")
			if components.count >= 2 {
				let city = components.last?.replacingOccurrences(of: "_", with: " ") ?? ""
				return "\(city) (\(localizedName))"
			}
			return localizedName
		}

		// Fallback: format the identifier nicely
		let components = timezone.identifier.components(separatedBy: "/")
		if let city = components.last {
			return city.replacingOccurrences(of: "_", with: " ")
		}

		return timezone.identifier
	}

	var body: some View {
		VStack {
			Text("Select Timezone")
				.font(.headline)
				.padding(.top)

			TextField("Search timezones...", text: $searchText)
				.textFieldStyle(RoundedBorderTextFieldStyle())
				.padding(.horizontal)
				.onChange(of: searchText) {
					updateFilteredTimezones()
				}

			List(filteredTimezones, id: \.0.identifier) { timezone, displayName in
				Button(action: {
					// Pass both the timezone and its original identifier
					onSelection(timezone, timezone.identifier)
				}) {
					HStack {
						Text(displayName)
							.foregroundColor(.primary)
							.multilineTextAlignment(.leading)
						Spacer()
						Text(currentTimeString(for: timezone))
							.font(.caption)
							.foregroundColor(.secondary)
					}
					.frame(maxWidth: .infinity, alignment: .leading)
					.contentShape(Rectangle())
				}
				.buttonStyle(PlainButtonStyle())
			}
		}
		.frame(width: 400, height: 500)
		.onAppear {
			updateFilteredTimezones()
		}
	}

	private func currentTimeString(for timezone: TimeZone) -> String {
		let formatter = DateFormatter()
		formatter.timeZone = timezone
		formatter.timeStyle = .short
		return formatter.string(from: Date())
	}
}
