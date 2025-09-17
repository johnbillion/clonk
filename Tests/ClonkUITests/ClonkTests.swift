import XCTest

final class MenuBarUITests: XCTestCase {
	var app: XCUIApplication!
	
	override func setUpWithError() throws {
		continueAfterFailure = false
		app = XCUIApplication()
		app.launch()
		
		// Give the app time to initialize
		sleep(2)
	}
	
	override func tearDownWithError() throws {
		app.terminate()
	}
	
	func testMenuBarItemExists() throws {
		// Menu bar apps appear in the system menu bar
		// We need to access the menu bar through the system
		let menuBar = XCUIApplication(bundleIdentifier: "com.apple.finder").menuBars.firstMatch
		
		// Look for our time display in the menu bar
		// The exact text will vary, but it should be in HH:mm:ss format
		let timeRegex = try NSRegularExpression(pattern: "^\\d{2}:\\d{2}:\\d{2}$")
		
		var foundTimeDisplay = false
		let menuBarItems = menuBar.menuBarItems
		
		for i in 0..<menuBarItems.count {
			let item = menuBarItems.element(boundBy: i)
			let title = item.title
			
			if timeRegex.firstMatch(in: title, range: NSRange(location: 0, length: title.count)) != nil {
				foundTimeDisplay = true
				break
			}
		}
		
		XCTAssertTrue(foundTimeDisplay, "Time display should be visible in menu bar")
	}
	
	func testMenuBarItemClick() throws {
		let menuBar = XCUIApplication(bundleIdentifier: "com.apple.finder").menuBars.firstMatch
		let timeRegex = try NSRegularExpression(pattern: "^\\d{2}:\\d{2}:\\d{2}$")
		
		var menuBarItem: XCUIElement?
		
		// Find our menu bar item
		for i in 0..<menuBar.menuBarItems.count {
			let item = menuBar.menuBarItems.element(boundBy: i)
			let title = item.title
			
			if timeRegex.firstMatch(in: title, range: NSRange(location: 0, length: title.count)) != nil {
				menuBarItem = item
				break
			}
		}
		
		XCTAssertNotNil(menuBarItem, "Menu bar item should exist")
		
		// Click the menu bar item
		menuBarItem?.click()
		
		// Give time for popover to appear
		sleep(1)
		
		// Look for calendar elements in the popover
		// The popover should contain date picker elements
		let windows = app.windows
		let popovers = app.popovers
		
		// Check if calendar/date picker is visible
		let hasDatePicker = windows.containing(.datePicker, identifier: "").count > 0 ||
						   popovers.containing(.datePicker, identifier: "").count > 0
		
		XCTAssertTrue(hasDatePicker, "Calendar popover should be visible after clicking menu bar item")
	}
	
	func testTodayButtonFunctionality() throws {
		// First open the popover by clicking menu bar item
		testMenuBarItemClick()
		
		// Look for "Today" button
		let todayButton = app.buttons["Today"]
		XCTAssertTrue(todayButton.exists, "Today button should exist in calendar popover")
		
		// Click Today button
		todayButton.click()
		
		// The button click should succeed without error
		// (We can't easily test the date change without more complex setup)
	}
	
	func testPopoverDismissal() throws {
		// Open popover
		testMenuBarItemClick()
		
		// Click elsewhere to dismiss (click on desktop)
		let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1))
		coordinate.click()
		
		// Give time for dismissal
		sleep(1)
		
		// Popover should be dismissed
		let popovers = app.popovers
		XCTAssertEqual(popovers.count, 0, "Popover should be dismissed after clicking outside")
	}
	
	func testCalendarNavigation() throws {
		// Open popover
		testMenuBarItemClick()
		
		// Look for date picker and verify it's interactive
		let datePicker = app.datePickers.firstMatch
		XCTAssertTrue(datePicker.exists, "Date picker should exist")
		XCTAssertTrue(datePicker.isHittable, "Date picker should be interactive")
	}
}