import SwiftUI

@main
struct ClonkApp: App {
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

	init() {
		// Initialize the CalendarManager singleton on app startup
		_ = CalendarManager.shared
	}

	var body: some Scene {
		Settings {
			EmptyView()
		}
	}
}
