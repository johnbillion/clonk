import SwiftUI
import EventKit

struct CalendarSettingsView: View {
    @StateObject private var calendarManager = CalendarManager.shared
    @State private var showingPermissionAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calendars")
                .font(.headline)
                .padding(.horizontal)
            
            if calendarManager.authorizationStatus == .notDetermined {
                VStack(spacing: 12) {
                    Text("Calendar access required")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Grant Access") {
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
                    Text("Calendar access denied")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Please enable calendar access in System Settings > Privacy & Security > Calendars")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Open System Settings") {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")!)
                    }
                    .buttonStyle(.bordered)
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
        .frame(width: 300)
        .padding(.vertical, 12)
    }
    
    private func groupedCalendars() -> [String: [EKCalendar]] {
        Dictionary(grouping: calendarManager.calendars) { calendar in
            calendar.source.title
        }
    }
}