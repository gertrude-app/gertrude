import Foundation
import Testing

@testable import LibTCA

@Test
func testFormatDurationMinutesOnly() {
  #expect(formatDuration(0) == "0m")
  #expect(formatDuration(30) == "0m")
  #expect(formatDuration(60) == "1m")
  #expect(formatDuration(150) == "2m")
  #expect(formatDuration(2700) == "45m")
  #expect(formatDuration(3540) == "59m")
}

@Test
func testFormatDurationHoursAndMinutes() {
  #expect(formatDuration(3600) == "1h")
  #expect(formatDuration(3660) == "1h 1m")
  #expect(formatDuration(3900) == "1h 5m")
  #expect(formatDuration(5025) == "1h 23m")
  #expect(formatDuration(7200) == "2h")
  #expect(formatDuration(7380) == "2h 3m")
}

@Test
func testFormatDurationLargeValues() {
  #expect(formatDuration(10800) == "3h")
  #expect(formatDuration(14400) == "4h")
  #expect(formatDuration(18000) == "5h")
  #expect(formatDuration(21900) == "6h 5m")
  #expect(formatDuration(36000) == "10h")
  #expect(formatDuration(39660) == "11h 1m")
}

@Test
func testFormatDurationEdgeCases() {
  #expect(formatDuration(59) == "0m")
  #expect(formatDuration(61) == "1m")
  #expect(formatDuration(3599) == "59m")
  #expect(formatDuration(3601) == "1h")
  #expect(formatDuration(3661) == "1h 1m")
}

@Test
func testFormatRelativeDateJustNow() {
  let now = Date()
  let thirtySecondsAgo = now.addingTimeInterval(-30)
  let fiftyNineSecondsAgo = now.addingTimeInterval(-59)

  #expect(formatRelativeDate(now) == "JUST NOW")
  #expect(formatRelativeDate(thirtySecondsAgo) == "JUST NOW")
  #expect(formatRelativeDate(fiftyNineSecondsAgo) == "JUST NOW")
}

@Test
func testFormatRelativeDateMinutes() {
  let now = Date()
  let oneMinuteAgo = now.addingTimeInterval(-60)
  let fiveMinutesAgo = now.addingTimeInterval(-300)
  let fiftyNineMinutesAgo = now.addingTimeInterval(-3540)

  #expect(formatRelativeDate(oneMinuteAgo) == "1M AGO")
  #expect(formatRelativeDate(fiveMinutesAgo) == "5M AGO")
  #expect(formatRelativeDate(fiftyNineMinutesAgo) == "59M AGO")
}

@Test
func testFormatRelativeDateHours() {
  let now = Date()
  let oneHourAgo = now.addingTimeInterval(-3600)
  let threeHoursAgo = now.addingTimeInterval(-10800)
  let twentyThreeHoursAgo = now.addingTimeInterval(-82800)

  #expect(formatRelativeDate(oneHourAgo) == "1H AGO")
  #expect(formatRelativeDate(threeHoursAgo) == "3H AGO")
  #expect(formatRelativeDate(twentyThreeHoursAgo) == "23H AGO")
}

@Test
func testFormatRelativeDateDays() {
  let now = Date()
  let oneDayAgo = now.addingTimeInterval(-86400)
  let fiveDaysAgo = now.addingTimeInterval(-432_000)
  let sixDaysAgo = now.addingTimeInterval(-518_400)

  #expect(formatRelativeDate(oneDayAgo) == "1D AGO")
  #expect(formatRelativeDate(fiveDaysAgo) == "5D AGO")
  #expect(formatRelativeDate(sixDaysAgo) == "6D AGO")
}

@Test
func testFormatRelativeDateOldDates() {
  let calendar = Calendar.current
  let components = DateComponents(year: 2024, month: 8, day: 13, hour: 12, minute: 0)
  let augustDate = calendar.date(from: components)!
  let components2 = DateComponents(year: 2024, month: 12, day: 25, hour: 12, minute: 0)
  let decemberDate = calendar.date(from: components2)!

  #expect(formatRelativeDate(augustDate) == "AUG 13")
  #expect(formatRelativeDate(decemberDate) == "DEC 25")
}

@Test
func testFormatTimeSecondsOnly() {
  #expect(formatTime(0) == "0:00")
  #expect(formatTime(5) == "0:05")
  #expect(formatTime(30) == "0:30")
  #expect(formatTime(59) == "0:59")
}

@Test
func testFormatTimeMinutesAndSeconds() {
  #expect(formatTime(60) == "1:00")
  #expect(formatTime(65) == "1:05")
  #expect(formatTime(125) == "2:05")
  #expect(formatTime(599) == "9:59")
  #expect(formatTime(600) == "10:00")
  #expect(formatTime(3599) == "59:59")
}

@Test
func testFormatTimeHoursMinutesSeconds() {
  #expect(formatTime(3600) == "1:00:00")
  #expect(formatTime(3605) == "1:00:05")
  #expect(formatTime(3665) == "1:01:05")
  #expect(formatTime(7265) == "2:01:05")
  #expect(formatTime(36005) == "10:00:05")
  #expect(formatTime(359_999) == "99:59:59")
}

@Test
func testFormatRemainingTimeWithValidDuration() {
  #expect(formatRemainingTime(progress: 0, durationSeconds: 3600) == "-1:00:00")
  #expect(formatRemainingTime(progress: 30, durationSeconds: 3600) == "-59:30")
  #expect(formatRemainingTime(progress: 3570, durationSeconds: 3600) == "-0:30")
  #expect(formatRemainingTime(progress: 3599, durationSeconds: 3600) == "-0:01")
  #expect(formatRemainingTime(progress: 3600, durationSeconds: 3600) == "-0:00")
}

@Test
func testFormatRemainingTimeWithNilDuration() {
  #expect(formatRemainingTime(progress: 0, durationSeconds: nil) == "0:00")
  #expect(formatRemainingTime(progress: 1000, durationSeconds: nil) == "0:00")
  #expect(formatRemainingTime(progress: 3665, durationSeconds: nil) == "0:00")
}

@Test
func testFormatRemainingTimeEdgeCases() {
  #expect(formatRemainingTime(progress: -10, durationSeconds: 3600) == "-1:00:00")
  #expect(formatRemainingTime(progress: 0, durationSeconds: 0) == "0:00")
  #expect(formatRemainingTime(progress: 0, durationSeconds: -100) == "0:00")
  #expect(formatRemainingTime(progress: 760, durationSeconds: 2700) == "-32:20")
  #expect(formatRemainingTime(progress: 4000, durationSeconds: 3600) == "-0:00")
}
