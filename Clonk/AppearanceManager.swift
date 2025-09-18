import SwiftUI
import AppKit

class AppearanceManager: ObservableObject {
	static let shared = AppearanceManager()

	@Published var colorScheme: ColorScheme? = nil
	private var currentMode: AppearanceMode = .auto

	private init() {
		// Load saved appearance mode on init
		loadSavedAppearance()

		// Listen for system appearance changes
		DistributedNotificationCenter.default.addObserver(
			self,
			selector: #selector(systemAppearanceChanged),
			name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
			object: nil
		)
	}

	func setAppearance(_ mode: AppearanceMode) {
		currentMode = mode
		UserDefaults.standard.set(mode.rawValue, forKey: "appearanceMode")
		applyAppearance(mode)
	}

	private func loadSavedAppearance() {
		let savedMode = UserDefaults.standard.string(forKey: "appearanceMode") ?? AppearanceMode.auto.rawValue
		let mode = AppearanceMode(rawValue: savedMode) ?? .auto
		currentMode = mode
		applyAppearance(mode)
	}

	@objc private func systemAppearanceChanged() {
		// Only update if we're in auto mode
		if currentMode == .auto {
			applyAppearance(.auto)
		}
	}

	private func applyAppearance(_ mode: AppearanceMode) {
		DispatchQueue.main.async {
			switch mode {
			case .auto:
				// When switching to auto, detect current system appearance
				let isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
				self.colorScheme = isDarkMode ? .dark : .light
			case .light:
				self.colorScheme = .light
			case .dark:
				self.colorScheme = .dark
			}
		}
	}
}
