import SwiftUI

struct TimezoneContainer: View {
	@Binding var selectedTimezones: [TimeZone]
	@Binding var timezoneIdentifiers: [String]
	@State private var currentTime = Date()
	@State private var timer: Timer?
	@State private var showingPicker = false
	@State private var selectedPanelIndex = 0
	
	let onTimezoneChanged: () -> Void

	var body: some View {
		HStack(spacing: 0) {
			ForEach(Array(timezoneIdentifiers.enumerated()), id: \.offset) { index, identifier in
				TimezonePanel(
					timezone: selectedTimezones[index], 
					timezoneIdentifier: identifier,
					currentTime: currentTime,
					onTapName: {
						selectedPanelIndex = index
						showingPicker = true
					}
				)

				if index < selectedTimezones.count - 1 {
					Divider()
						.frame(height: 60)
				}
			}
		}
		.frame(height: 60)
		.background(Color.white)
		.onAppear {
			startTimer()
		}
		.onDisappear {
			timer?.invalidate()
		}
		.sheet(isPresented: $showingPicker) {
			TimezonePickerView { selectedTimezone, identifier in
				selectedTimezones[selectedPanelIndex] = selectedTimezone
				timezoneIdentifiers[selectedPanelIndex] = identifier
				onTimezoneChanged()
				showingPicker = false
			}
		}
	}
	
	private func startTimer() {
		timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
			currentTime = Date()
		}
	}
}
