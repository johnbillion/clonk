import SwiftUI

struct TimezoneContainer: View {
	@Binding var selectedTimezones: [TimeZone]
	@Binding var timezoneIdentifiers: [String]
	@State private var currentTime = Date()
	@State private var timer: Timer?
	@State private var showingPicker = false
	@State private var selectedPanelIndex = 0
	@State private var isInserting = false

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
						isInserting = false
						showingPicker = true
					},
					onDelete: timezoneIdentifiers.count > 1 ? {
						deleteTimezone(at: index)
					} : nil,
					onAddLeft: {
						selectedPanelIndex = index
						isInserting = true
						showingPicker = true
					},
					onAddRight: {
						selectedPanelIndex = index + 1
						isInserting = true
						showingPicker = true
					},
					isFirst: index == 0,
					isLast: index == timezoneIdentifiers.count - 1
				)

				if index < selectedTimezones.count - 1 {
					Divider()
						.frame(height: 60)
				}
			}

			// If no timezones, show a single add button
			if timezoneIdentifiers.isEmpty {
				Button(action: {
					selectedPanelIndex = 0
					isInserting = true
					showingPicker = true
				}) {
					Image(systemName: "plus.circle")
						.foregroundColor(Color(NSColor.controlAccentColor))
						.font(.title2)
				}
				.buttonStyle(PlainButtonStyle())
				.frame(height: 60)
				.padding(.horizontal, 20)
			}
		}
		.frame(height: 60)
		.background(Color(NSColor.windowBackgroundColor))
		.onAppear {
			startTimer()
		}
		.onDisappear {
			timer?.invalidate()
		}
		.sheet(isPresented: $showingPicker) {
			TimezonePickerView { selectedTimezone, identifier in
				if isInserting {
					insertTimezone(selectedTimezone, identifier: identifier, at: selectedPanelIndex)
				} else {
					selectedTimezones[selectedPanelIndex] = selectedTimezone
					timezoneIdentifiers[selectedPanelIndex] = identifier
				}
				onTimezoneChanged()
				showingPicker = false
			}
		}
	}


	private func deleteTimezone(at index: Int) {
		selectedTimezones.remove(at: index)
		timezoneIdentifiers.remove(at: index)
		onTimezoneChanged()
	}

	private func insertTimezone(_ timezone: TimeZone, identifier: String, at index: Int) {
		selectedTimezones.insert(timezone, at: index)
		timezoneIdentifiers.insert(identifier, at: index)
	}

	private func startTimer() {
		timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
			currentTime = Date()
		}
	}
}
