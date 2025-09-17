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
			self.setPinned(true)
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
		if popover.isShown {
			closePopover()
		} else {
			showPopover()
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
}

class EventMonitor {
	private var monitor: Any?
	private let mask: NSEvent.EventTypeMask
	private let handler: (NSEvent?) -> Void

	public init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
		self.mask = mask
		self.handler = handler
	}

	deinit {
		stop()
	}

	public func start() {
		monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
	}

	public func stop() {
		if monitor != nil {
			NSEvent.removeMonitor(monitor!)
			monitor = nil
		}
	}
}
