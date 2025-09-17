import SwiftUI
import EventKit

struct CalendarSettingsView: View {
	@StateObject private var calendarManager = CalendarManager.shared
	@State private var showingPermissionAlert = false

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			if calendarManager.authorizationStatus == .notDetermined {
				VStack(spacing: 12) {
					Text(NSLocalizedString("calendar_access_required", comment: "Calendar access required message"))
						.font(.subheadline)
						.foregroundColor(.secondary)

					Button(NSLocalizedString("grant_access", comment: "Grant access button")) {
						Task {
							await calendarManager.requestAccess()
						}
					}
					.buttonStyle(.borderedProminent)
				}
				.frame(maxWidth: .infinity)
				.padding()
			} else if calendarManager.authorizationStatus == .denied || calendarManager.authorizationStatus == .restricted {
				VStack(spacing: 8) {
					Text(NSLocalizedString("calendar_access_denied", comment: "Calendar access denied message"))
						.font(.subheadline)
						.foregroundColor(.secondary)

					Text(NSLocalizedString("calendar_access_instructions", comment: "Instructions to enable calendar access"))
						.font(.caption)
						.foregroundColor(.secondary)
						.multilineTextAlignment(.center)

					Button(NSLocalizedString("open_system_settings", comment: "Open system settings button")) {
						NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")!)
					}
					.buttonStyle(.bordered)
				}
				.frame(maxWidth: .infinity)
				.padding()
			} else {
				if calendarManager.calendars.isEmpty {
					VStack(spacing: 12) {
						Text(NSLocalizedString("no_calendars_found", comment: "No calendars found message"))
							.font(.subheadline)
							.foregroundColor(.secondary)
							.multilineTextAlignment(.center)

						Text(NSLocalizedString("no_calendars_instructions", comment: "Instructions when no calendars found"))
							.font(.caption)
							.foregroundColor(.secondary)
							.multilineTextAlignment(.center)
					}
					.frame(maxWidth: .infinity)
					.padding()
				} else {
					ScrollView {
						VStack(alignment: .leading, spacing: 4) {
							ForEach(groupedCalendars().sorted(by: { $0.key < $1.key }), id: \.key) { source, calendars in
								Section {
									ForEach(calendars, id: \.calendarIdentifier) { calendar in
										CalendarRow(
											calendar: calendar,
											isSelected: calendarManager.isCalendarSelected(calendar),
											onToggle: {
												calendarManager.toggleCalendar(calendar)
											}
										)
									}
								} header: {
									Text(source)
										.font(.caption)
										.foregroundColor(.secondary)
										.padding(.horizontal)
										.padding(.top, 8)
								}
							}
						}
						.padding(.vertical, 4)
					}
					.frame(maxHeight: 300)
				}
			}
		}
		.frame(width: 300)
		.padding(.vertical, 12)
	}

	private func groupedCalendars() -> [String: [EKCalendar]] {
		Dictionary(grouping: calendarManager.calendars) { calendar in
			calendar.source.title
		}
	}
}
