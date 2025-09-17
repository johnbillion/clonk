import SwiftUI

struct AppSettingsView: View {
	@AppStorage("showWeekends") private var showWeekends: Bool = true
	@AppStorage("showDateInMenubar") private var showDateInMenubar: Bool = true
	let appDelegate: AppDelegate

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			VStack(alignment: .leading, spacing: 8) {
				Toggle(NSLocalizedString("show_weekends", comment: "Show weekends toggle"), isOn: $showWeekends)
					.padding(.horizontal)
				
				Toggle(NSLocalizedString("show_date_in_menubar", comment: "Show date in menubar toggle"), isOn: $showDateInMenubar)
					.padding(.horizontal)
					.onChange(of: showDateInMenubar) {
						appDelegate.updateTimeDisplay()
					}
			}
		}
		.frame(width: 250)
		.padding(.vertical, 12)
	}
}
