import SwiftUI

struct AppSettingsView: View {
	@AppStorage("showWeekends") private var showWeekends: Bool = true

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			VStack(alignment: .leading, spacing: 8) {
				Toggle(NSLocalizedString("show_weekends", comment: "Show weekends toggle"), isOn: $showWeekends)
					.padding(.horizontal)
			}
		}
		.frame(width: 250)
		.padding(.vertical, 12)
	}
}
