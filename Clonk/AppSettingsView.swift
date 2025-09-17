import SwiftUI

enum AppearanceMode: String, CaseIterable {
	case auto = "auto"
	case light = "light"
	case dark = "dark"

	var displayName: String {
		switch self {
		case .auto: return NSLocalizedString("auto", comment: "Auto appearance mode")
		case .light: return NSLocalizedString("light", comment: "Light appearance mode")
		case .dark: return NSLocalizedString("dark", comment: "Dark appearance mode")
		}
	}
}

struct AppSettingsView: View {
	@AppStorage("showWeekends") private var showWeekends: Bool = true
	@AppStorage("showDateInMenubar") private var showDateInMenubar: Bool = true
	@AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .auto
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

				VStack(alignment: .leading, spacing: 4) {
					Text(NSLocalizedString("appearance", comment: "Appearance setting label"))
						.font(.caption)
						.foregroundColor(.secondary)
						.padding(.horizontal)

					Picker("", selection: $appearanceMode) {
						ForEach(AppearanceMode.allCases, id: \.self) { mode in
							Text(mode.displayName).tag(mode)
						}
					}
					.pickerStyle(.segmented)
					.padding(.horizontal)
					.onChange(of: appearanceMode) {
						AppearanceManager.shared.setAppearance(appearanceMode)
					}
				}
			}
		}
		.frame(width: 250)
		.padding(.vertical, 12)
		.onAppear {
			// Initialize appearance manager with current setting
			AppearanceManager.shared.setAppearance(appearanceMode)
		}
	}
}
