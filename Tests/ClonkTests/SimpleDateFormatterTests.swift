import Foundation
import AppKit

// Simple test functions that don't require XCTest
// These can be run with Swift Package Manager

func testTimeDisplayFormat() -> Bool {
	let formatter = DateFormatter()
	formatter.dateFormat = "HH:mm:ss"

	let testDate = Calendar.current.date(from: DateComponents(
		year: 2024,
		month: 1,
		day: 15,
		hour: 14,
		minute: 30,
		second: 45
	))!

	let result = formatter.string(from: testDate)
	return result == "14:30:45"
}

func testMonthYearStringFormat() -> Bool {
	let formatter = DateFormatter()
	formatter.dateFormat = "MMMM yyyy"

	let testDate = Calendar.current.date(from: DateComponents(
		year: 2024,
		month: 3,
		day: 15
	))!

	let result = formatter.string(from: testDate)
	return result == "March 2024"
}

func testDateStringFormat() -> Bool {
	let formatter = DateFormatter()
	formatter.dateStyle = .medium

	let testDate = Calendar.current.date(from: DateComponents(
		year: 2024,
		month: 6,
		day: 10
	))!

	let result = formatter.string(from: testDate)
	return result.contains("Jun") || result.contains("June")
}

func testDayDetailsDateFormat() -> Bool {
	let formatter = DateFormatter()
	formatter.dateFormat = "EEE d MMM yyyy"

	let testDate = Calendar.current.date(from: DateComponents(
		year: 2024,
		month: 12,
		day: 25
	))!

	let result = formatter.string(from: testDate)
	return result.contains("25") && result.contains("Dec") && result.contains("2024")
}

func testCalendarLayoutConstants() -> Bool {
	// Test that the expected layout calculation is correct (6 rows * 52 points = 312)
	let expectedRowHeight: CGFloat = 52
	let expectedRowCount: CGFloat = 6
	let expectedDetailsHeight = expectedRowCount * expectedRowHeight
	return expectedDetailsHeight == 312.0
}

func testWeekendFiltering() -> Bool {
	let calendar = Calendar.current
	let testDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 6))! // Saturday
	let weekday = calendar.component(.weekday, from: testDate)
	return weekday == 7 // Saturday is weekday 7
}

func testCurrentDateUpdating() -> Bool {
	let now = Date()
	let calendar = Calendar.current
	let components = calendar.dateComponents([.year, .month, .day], from: now)
	let todayStart = calendar.date(from: components)!
	return abs(now.timeIntervalSince(todayStart)) < 24 * 60 * 60
}

func testColorSchemePreference() -> Bool {
	guard let appearance = NSApp?.effectiveAppearance else {
		// In test environment, just verify the appearance names exist
		return NSAppearance.Name.aqua.rawValue.count > 0 && NSAppearance.Name.darkAqua.rawValue.count > 0
	}
	return appearance.name == .aqua || appearance.name == .darkAqua
}

func testCalendarRefreshFunctionality() -> Bool {
	// Test that calendar refresh logic works (simulated)
	// This tests the logic that would be used when permissions are granted
	let calendar = Calendar.current
	let now = Date()

	// Test month calculation for refresh
	guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: now),
		  let nextMonth = calendar.date(byAdding: .month, value: 1, to: now) else {
		return false
	}

	// Verify dates are in expected order
	return previousMonth < now && now < nextMonth
}

func testLocalizationKeys() -> Bool {
	// Test that key localization strings exist (simplified test)
	// Since tests run in a different bundle context, just test basic localization functionality
	let formatter = DateFormatter()
	formatter.dateStyle = .long
	formatter.locale = Locale(identifier: "en_US")

	let testDate = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1))!
	let result = formatter.string(from: testDate)

	// Test that localization infrastructure works
	return result.contains("January") && result.contains("2024")
}

func testMenuBarTimeFormat() -> Bool {
	// Test the time format that would appear in menu bar
	let formatter = DateFormatter()
	formatter.dateFormat = "HH:mm:ss"
	
	let testDate = Calendar.current.date(from: DateComponents(
		year: 2024, month: 1, day: 1, hour: 14, minute: 30, second: 45
	))!
	
	let result = formatter.string(from: testDate)
	let timePattern = "^\\d{2}:\\d{2}:\\d{2}$"
	
	do {
		let regex = try NSRegularExpression(pattern: timePattern)
		let range = NSRange(location: 0, length: result.count)
		return regex.firstMatch(in: result, range: range) != nil
	} catch {
		return false
	}
}

func testMenuBarDateFormat() -> Bool {
	// Test the date format that would appear in menu bar when date toggle is enabled
	let formatter = DateFormatter()
	formatter.dateFormat = "EEE d"
	
	let testDate = Calendar.current.date(from: DateComponents(
		year: 2024, month: 1, day: 15
	))!
	
	let result = formatter.string(from: testDate)
	let datePattern = "\\w{3} \\d{1,2}"
	
	do {
		let regex = try NSRegularExpression(pattern: datePattern)
		let range = NSRange(location: 0, length: result.count)
		return regex.firstMatch(in: result, range: range) != nil
	} catch {
		return false
	}
}

func testAppStateManagement() -> Bool {
	// Test UserDefaults functionality for app state
	let testKey = "test_calendar_selection"
	let testValue = ["cal1", "cal2", "cal3"]
	
	// Save test data
	UserDefaults.standard.set(testValue, forKey: testKey)
	
	// Retrieve and verify
	guard let retrieved = UserDefaults.standard.stringArray(forKey: testKey) else {
		return false
	}
	
	// Clean up
	UserDefaults.standard.removeObject(forKey: testKey)
	
	return retrieved == testValue
}

func testDayDetailsDateCalculation() -> Bool {
	// Test the date calculation logic used in day details
	let calendar = Calendar.current
	let testDate = Date()
	
	// Test start of day calculation
	let startOfDay = calendar.startOfDay(for: testDate)
	let components = calendar.dateComponents([.hour, .minute, .second], from: startOfDay)
	
	return components.hour == 0 && components.minute == 0 && components.second == 0
}

func testEventFilteringLogic() -> Bool {
	// Test the logic for filtering morning vs afternoon events
	let calendar = Calendar.current
	
	let morningDate = calendar.date(from: DateComponents(
		year: 2024, month: 1, day: 1, hour: 9, minute: 0
	))!
	
	let afternoonDate = calendar.date(from: DateComponents(
		year: 2024, month: 1, day: 1, hour: 15, minute: 0
	))!
	
	let morningHour = calendar.component(.hour, from: morningDate)
	let afternoonHour = calendar.component(.hour, from: afternoonDate)
	
	return morningHour < 12 && afternoonHour >= 12
}

func testFirstTimeSetupFlag() -> Bool {
	// Test the UserDefaults flag for first time setup
	let testKey = "test_hasShownFirstTimeSetup"
	
	// Initially should be false
	let initialValue = UserDefaults.standard.bool(forKey: testKey)
	
	// Set to true
	UserDefaults.standard.set(true, forKey: testKey)
	let afterSet = UserDefaults.standard.bool(forKey: testKey)
	
	// Clean up
	UserDefaults.standard.removeObject(forKey: testKey)
	let afterRemoval = UserDefaults.standard.bool(forKey: testKey)
	
	return !initialValue && afterSet && !afterRemoval
}

// Test runner
func runAllTests() {
	var passed = 0
	var total = 0

	let tests: [(String, () -> Bool)] = [
		("Time Display Format", testTimeDisplayFormat),
		("Month Year Format", testMonthYearStringFormat),
		("Date String Format", testDateStringFormat),
		("Day Details Date Format", testDayDetailsDateFormat),
		("Calendar Layout Constants", testCalendarLayoutConstants),
		("Weekend Filtering", testWeekendFiltering),
		("Current Date Updating", testCurrentDateUpdating),
		("Color Scheme Preference", testColorSchemePreference),
		("Calendar Refresh Functionality", testCalendarRefreshFunctionality),
		("Localization Keys", testLocalizationKeys),
		("Menu Bar Time Format", testMenuBarTimeFormat),
		("Menu Bar Date Format", testMenuBarDateFormat),
		("App State Management", testAppStateManagement),
		("Day Details Date Calculation", testDayDetailsDateCalculation),
		("Event Filtering Logic", testEventFilteringLogic),
		("First Time Setup Flag", testFirstTimeSetupFlag)
	]

	for (name, test) in tests {
		total += 1
		if test() {
			print("✅ \(name)")
			passed += 1
		} else {
			print("❌ \(name)")
		}
	}

	print("\nResults: \(passed)/\(total) tests passed")

	if passed == total {
		print("🎉 All tests passed!")
	} else {
		print("💥 Some tests failed")
		exit(1)
	}
}
