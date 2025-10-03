import Foundation
import Testing

@testable import LibViews

@Test
func testFormatDurationMinutesOnly() {
  #expect(formatShortDuration(0) == "0m")
  #expect(formatShortDuration(30) == "0m")
  #expect(formatShortDuration(60) == "1m")
  #expect(formatShortDuration(150) == "2m")
  #expect(formatShortDuration(2700) == "45m")
  #expect(formatShortDuration(3540) == "59m")
}

@Test
func testFormatDurationHoursAndMinutes() {
  #expect(formatShortDuration(3600) == "1h")
  #expect(formatShortDuration(3660) == "1h 1m")
  #expect(formatShortDuration(3900) == "1h 5m")
  #expect(formatShortDuration(5025) == "1h 23m")
  #expect(formatShortDuration(7200) == "2h")
  #expect(formatShortDuration(7380) == "2h 3m")
}

@Test
func testFormatDurationLargeValues() {
  #expect(formatShortDuration(10800) == "3h")
  #expect(formatShortDuration(14400) == "4h")
  #expect(formatShortDuration(18000) == "5h")
  #expect(formatShortDuration(21900) == "6h 5m")
  #expect(formatShortDuration(36000) == "10h")
  #expect(formatShortDuration(39660) == "11h 1m")
}

@Test
func testFormatDurationEdgeCases() {
  #expect(formatShortDuration(59) == "0m")
  #expect(formatShortDuration(61) == "1m")
  #expect(formatShortDuration(3599) == "59m")
  #expect(formatShortDuration(3601) == "1h")
  #expect(formatShortDuration(3661) == "1h 1m")
}

@Test
func testFormatRelativeDateJustNow() {
  let now = Date()
  let thirtySecondsAgo = now.addingTimeInterval(-30)
  let fiftyNineSecondsAgo = now.addingTimeInterval(-59)

  #expect(formatRelativeDate(now) == "just now")
  #expect(formatRelativeDate(thirtySecondsAgo) == "just now")
  #expect(formatRelativeDate(fiftyNineSecondsAgo) == "just now")
}

@Test
func testFormatRelativeDateMinutes() {
  let now = Date()
  let oneMinuteAgo = now.addingTimeInterval(-60)
  let fiveMinutesAgo = now.addingTimeInterval(-300)
  let fiftyNineMinutesAgo = now.addingTimeInterval(-3540)

  #expect(formatRelativeDate(oneMinuteAgo) == "1m ago")
  #expect(formatRelativeDate(fiveMinutesAgo) == "5m ago")
  #expect(formatRelativeDate(fiftyNineMinutesAgo) == "59m ago")
}

@Test
func testFormatRelativeDateHours() {
  let now = Date()
  let oneHourAgo = now.addingTimeInterval(-3600)
  let threeHoursAgo = now.addingTimeInterval(-10800)
  let twentyThreeHoursAgo = now.addingTimeInterval(-82800)

  #expect(formatRelativeDate(oneHourAgo) == "1h ago")
  #expect(formatRelativeDate(threeHoursAgo) == "3h ago")
  #expect(formatRelativeDate(twentyThreeHoursAgo) == "23h ago")
}

@Test
func testFormatRelativeDateDays() {
  let now = Date()
  let oneDayAgo = now.addingTimeInterval(-86400)
  let fiveDaysAgo = now.addingTimeInterval(-432_000)
  let sixDaysAgo = now.addingTimeInterval(-518_400)

  #expect(formatRelativeDate(oneDayAgo) == "1d ago")
  #expect(formatRelativeDate(fiveDaysAgo) == "5d ago")
  #expect(formatRelativeDate(sixDaysAgo) == "6d ago")
}

@Test
func testFormatRelativeDateOldDates() {
  let calendar = Calendar.current
  let components = DateComponents(year: 2024, month: 8, day: 13, hour: 12, minute: 0)
  let augustDate = calendar.date(from: components)!
  let components2 = DateComponents(year: 2024, month: 12, day: 25, hour: 12, minute: 0)
  let decemberDate = calendar.date(from: components2)!

  #expect(formatRelativeDate(augustDate) == "Aug 13")
  #expect(formatRelativeDate(decemberDate) == "Dec 25")
}

@Test
func testFormatTimeSecondsOnly() {
  #expect(formatPlayerTime(0) == "0:00")
  #expect(formatPlayerTime(5) == "0:05")
  #expect(formatPlayerTime(30) == "0:30")
  #expect(formatPlayerTime(59) == "0:59")
}

@Test
func testFormatTimeMinutesAndSeconds() {
  #expect(formatPlayerTime(60) == "1:00")
  #expect(formatPlayerTime(65) == "1:05")
  #expect(formatPlayerTime(125) == "2:05")
  #expect(formatPlayerTime(599) == "9:59")
  #expect(formatPlayerTime(600) == "10:00")
  #expect(formatPlayerTime(3599) == "59:59")
}

@Test
func testFormatTimeHoursMinutesSeconds() {
  #expect(formatPlayerTime(3600) == "1:00:00")
  #expect(formatPlayerTime(3605) == "1:00:05")
  #expect(formatPlayerTime(3665) == "1:01:05")
  #expect(formatPlayerTime(7265) == "2:01:05")
  #expect(formatPlayerTime(36005) == "10:00:05")
  #expect(formatPlayerTime(359_999) == "99:59:59")
}

@Test
func testFormatRemainingTimeWithValidDuration() {
  #expect(formatRemainingPlayerTime(progress: 0, durationSeconds: 3600) == "-1:00:00")
  #expect(formatRemainingPlayerTime(progress: 30, durationSeconds: 3600) == "-59:30")
  #expect(formatRemainingPlayerTime(progress: 3570, durationSeconds: 3600) == "-0:30")
  #expect(formatRemainingPlayerTime(progress: 3599, durationSeconds: 3600) == "-0:01")
  #expect(formatRemainingPlayerTime(progress: 3600, durationSeconds: 3600) == "-0:00")
}

@Test
func testFormatRemainingTimeWithNilDuration() {
  #expect(formatRemainingPlayerTime(progress: 0, durationSeconds: nil) == "0:00")
  #expect(formatRemainingPlayerTime(progress: 1000, durationSeconds: nil) == "0:00")
  #expect(formatRemainingPlayerTime(progress: 3665, durationSeconds: nil) == "0:00")
}

@Test
func testFormatRemainingTimeEdgeCases() {
  #expect(formatRemainingPlayerTime(progress: -10, durationSeconds: 3600) == "-1:00:00")
  #expect(formatRemainingPlayerTime(progress: 0, durationSeconds: 0) == "0:00")
  #expect(formatRemainingPlayerTime(progress: 0, durationSeconds: -100) == "0:00")
  #expect(formatRemainingPlayerTime(progress: 760, durationSeconds: 2700) == "-32:20")
  #expect(formatRemainingPlayerTime(progress: 4000, durationSeconds: 3600) == "-0:00")
}
