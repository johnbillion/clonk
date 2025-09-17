import Foundation

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

// Test runner
func runAllTests() {
	var passed = 0
	var total = 0

	let tests: [(String, () -> Bool)] = [
		("Time Display Format", testTimeDisplayFormat),
		("Month Year Format", testMonthYearStringFormat),
		("Date String Format", testDateStringFormat)
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
