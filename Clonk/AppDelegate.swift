import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
	var statusItem: NSStatusItem!
	var popover = NSPopover()
	var eventMonitor: EventMonitor?
	var timer: Timer?
	var isPinned = false

	func applicationDidFinishLaunching(_ notification: Notification) {
		statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

		if let button = statusItem.button {
			updateTimeDisplay()
			button.action = #selector(togglePopover)
			button.sendAction(on: [.leftMouseUp, .rightMouseUp])
		}


		timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
			self.updateTimeDisplay()
		}

		let contentView = ContentView(appDelegate: self)
		popover.contentViewController = NSHostingController(rootView: contentView)
		popover.behavior = .transient
		popover.animates = false

		eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
			if let self = self, self.popover.isShown && !self.isPinned {
				self.closePopover()
			}
		}

		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			self.showPopover()
		}
	}

	func updateTimeDisplay() {
		let formatter = DateFormatter()
		formatter.dateFormat = "HH:mm"
		if let button = statusItem.button {
			button.title = formatter.string(from: Date())
		}
	}

	@objc func togglePopover() {
		guard let event = NSApp.currentEvent else { return }

		if event.type == .rightMouseUp {
			showMenu()
		} else {
			if popover.isShown {
				closePopover()
			} else {
				showPopover()
			}
		}
	}

	func showPopover() {
		if let button = statusItem.button {
			popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
			eventMonitor?.start()
		}
	}

	func closePopover() {
		popover.performClose(nil)
		eventMonitor?.stop()
	}

	public func setPinned(_ pinned: Bool) {
		isPinned = pinned
		popover.behavior = pinned ? .applicationDefined : .transient

		if pinned {
			eventMonitor?.stop()
		} else {
			eventMonitor?.start()
		}
	}

	private func setupMenu() {
		let menu = NSMenu()

		let quitItem = NSMenuItem(title: "Quit Clonk", action: #selector(quitApp), keyEquivalent: "")
		menu.addItem(quitItem)
	}

	private func showMenu() {
		guard let button = statusItem.button else { return }
		let menu = NSMenu()
		menu.appearance = NSAppearance(named: .aqua)

		let quitItem = NSMenuItem(title: "Quit Clonk", action: #selector(quitApp), keyEquivalent: "")
		menu.addItem(quitItem)

		menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
	}


	@objc private func quitApp() {
		NSApplication.shared.terminate(nil)
	}
}

