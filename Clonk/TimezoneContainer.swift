import SwiftUI

struct ScaleModifier: ViewModifier {
	let x: CGFloat
	let y: CGFloat

	func body(content: Content) -> some View {
		content.scaleEffect(x: x, y: y, anchor: .center)
	}
}

struct TimezoneContainer: View {
	@Binding var selectedTimezones: [TimeZone]
	@Binding var timezoneIdentifiers: [String]
	@State private var currentTime = Date()
	@State private var timer: Timer?
	@State private var showingPicker = false
	@State private var selectedPanelIndex = 0
	@State private var isInserting = false
	@State private var isHovered = false
	@State private var showPlusButton = false
	@State private var isPlusButtonHovered = false
	@State private var hoverTask: Task<Void, Never>?

	let onTimezoneChanged: () -> Void

	var body: some View {
		ZStack {
			HStack(spacing: 0) {
				ForEach(Array(timezoneIdentifiers.enumerated()), id: \.element) { index, identifier in
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
						timezoneCount: timezoneIdentifiers.count
					)
					.transition(.asymmetric(
						insertion: .scale(scale: 0, anchor: .center).combined(with: .move(edge: .leading)),
						removal: AnyTransition.modifier(
							active: ScaleModifier(x: 0, y: 1),
							identity: ScaleModifier(x: 1, y: 1)
						).combined(with: .move(edge: .trailing))
					))

					if index < selectedTimezones.count - 1 {
						Divider()
							.frame(height: 60)
							.transition(.opacity)
					}
				}
			}

			// Plus button overlapping the right-most timezone
			if showPlusButton {
				HStack {
					Spacer()
					Button(action: {
						isInserting = true
						showingPicker = true
					}) {
						Image(systemName: "plus.circle.fill")
							.foregroundColor(Color(NSColor.controlAccentColor))
							.background(Color.white)
							.clipShape(Circle())
							.font(.title2)
							.scaleEffect(isPlusButtonHovered ? 1.1 : 1.0)
					}
					.buttonStyle(PlainButtonStyle())
					.onHover { hovered in
						isPlusButtonHovered = hovered
					}
					.padding(.trailing, 8)
				}
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
		.onHover { hovered in
			isHovered = hovered

			// Cancel previous task
			hoverTask?.cancel()

			if hovered {
				// Start intent delay
				hoverTask = Task {
					try? await Task.sleep(nanoseconds: 200_000_000) // 0.20 second delay
					if !Task.isCancelled {
						await MainActor.run {
							showPlusButton = true
						}
					}
				}
			} else {
				// Hide immediately when not hovering
				showPlusButton = false
			}
		}
		.sheet(isPresented: $showingPicker) {
			TimezonePickerView { selectedTimezone, identifier in
				if isInserting {
					addTimezone(selectedTimezone, identifier: identifier)
				} else {
					withAnimation(.easeInOut(duration: 0.4)) {
						selectedTimezones[selectedPanelIndex] = selectedTimezone
						timezoneIdentifiers[selectedPanelIndex] = identifier
						sortTimezones()
					}
				}
				onTimezoneChanged()
				showingPicker = false
			}
		}
	}


	private func deleteTimezone(at index: Int) {
		withAnimation(.easeInOut(duration: 0.3)) {
			selectedTimezones.remove(at: index)
			timezoneIdentifiers.remove(at: index)
		}
		onTimezoneChanged()
	}

	private func addTimezone(_ timezone: TimeZone, identifier: String) {
		withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
			selectedTimezones.append(timezone)
			timezoneIdentifiers.append(identifier)
			sortTimezones()
		}
	}

	private func sortTimezones() {
		let now = Date()
		let combined = zip(selectedTimezones, timezoneIdentifiers).sorted { timezone1, timezone2 in
			let offset1 = timezone1.0.secondsFromGMT(for: now)
			let offset2 = timezone2.0.secondsFromGMT(for: now)
			return offset1 < offset2
		}

		selectedTimezones = combined.map { $0.0 }
		timezoneIdentifiers = combined.map { $0.1 }
	}

	private func startTimer() {
		timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
			currentTime = Date()
		}
	}
}
