import Foundation
import Testing

@testable import LibViews

@Test
func `format duration minutes only`() {
  #expect(formatShortDuration(0, lang: .english) == "0m")
  #expect(formatShortDuration(30, lang: .english) == "0m")
  #expect(formatShortDuration(60, lang: .english) == "1m")
  #expect(formatShortDuration(150, lang: .english) == "2m")
  #expect(formatShortDuration(2700, lang: .english) == "45m")
  #expect(formatShortDuration(3540, lang: .english) == "59m")
}

@Test
func `format duration hours and minutes`() {
  #expect(formatShortDuration(3600, lang: .english) == "1h")
  #expect(formatShortDuration(3660, lang: .english) == "1h 1m")
  #expect(formatShortDuration(3900, lang: .english) == "1h 5m")
  #expect(formatShortDuration(5025, lang: .english) == "1h 23m")
  #expect(formatShortDuration(7200, lang: .english) == "2h")
  #expect(formatShortDuration(7380, lang: .english) == "2h 3m")
}

@Test
func `format duration large values`() {
  #expect(formatShortDuration(10800, lang: .english) == "3h")
  #expect(formatShortDuration(14400, lang: .english) == "4h")
  #expect(formatShortDuration(18000, lang: .english) == "5h")
  #expect(formatShortDuration(21900, lang: .english) == "6h 5m")
  #expect(formatShortDuration(36000, lang: .english) == "10h")
  #expect(formatShortDuration(39660, lang: .english) == "11h 1m")
}

@Test
func `format duration edge cases`() {
  #expect(formatShortDuration(59, lang: .english) == "0m")
  #expect(formatShortDuration(61, lang: .english) == "1m")
  #expect(formatShortDuration(3599, lang: .english) == "59m")
  #expect(formatShortDuration(3601, lang: .english) == "1h")
  #expect(formatShortDuration(3661, lang: .english) == "1h 1m")
}

@Test
func `format relative date just now`() {
  let now = Date()
  let thirtySecondsAgo = now.addingTimeInterval(-30)
  let fiftyNineSecondsAgo = now.addingTimeInterval(-59)

  #expect(formatRelativeDate(now, lang: .english) == "just now")
  #expect(formatRelativeDate(thirtySecondsAgo, lang: .english) == "just now")
  #expect(formatRelativeDate(fiftyNineSecondsAgo, lang: .english) == "just now")
}

@Test
func `format relative date minutes`() {
  let now = Date()
  let oneMinuteAgo = now.addingTimeInterval(-60)
  let fiveMinutesAgo = now.addingTimeInterval(-300)
  let fiftyNineMinutesAgo = now.addingTimeInterval(-3540)

  #expect(formatRelativeDate(oneMinuteAgo, lang: .english) == "1m ago")
  #expect(formatRelativeDate(fiveMinutesAgo, lang: .english) == "5m ago")
  #expect(formatRelativeDate(fiftyNineMinutesAgo, lang: .english) == "59m ago")
}

@Test
func `format relative date hours`() {
  let now = Date()
  let oneHourAgo = now.addingTimeInterval(-3600)
  let threeHoursAgo = now.addingTimeInterval(-10800)
  let twentyThreeHoursAgo = now.addingTimeInterval(-82800)

  #expect(formatRelativeDate(oneHourAgo, lang: .english) == "1h ago")
  #expect(formatRelativeDate(threeHoursAgo, lang: .english) == "3h ago")
  #expect(formatRelativeDate(twentyThreeHoursAgo, lang: .english) == "23h ago")
}

@Test
func `format relative date days`() {
  let now = Date()
  let oneDayAgo = now.addingTimeInterval(-86400)
  let fiveDaysAgo = now.addingTimeInterval(-432_000)
  let sixDaysAgo = now.addingTimeInterval(-518_400)

  #expect(formatRelativeDate(oneDayAgo, lang: .english) == "1d ago")
  #expect(formatRelativeDate(fiveDaysAgo, lang: .english) == "5d ago")
  #expect(formatRelativeDate(sixDaysAgo, lang: .english) == "6d ago")
}

@Test
func `format relative date old dates`() {
  let calendar = Calendar.current
  let components = DateComponents(year: 2024, month: 8, day: 13, hour: 12, minute: 0)
  let augustDate = calendar.date(from: components)!
  let components2 = DateComponents(year: 2024, month: 12, day: 25, hour: 12, minute: 0)
  let decemberDate = calendar.date(from: components2)!

  #expect(formatRelativeDate(augustDate, lang: .english) == "Aug 13")
  #expect(formatRelativeDate(decemberDate, lang: .english) == "Dec 25")
}

@Test
func `format relative date spanish`() {
  let now = Date()
  #expect(formatRelativeDate(now, lang: .spanish) == "justo ahora")
  #expect(formatRelativeDate(now.addingTimeInterval(-30), lang: .spanish) == "justo ahora")
  #expect(formatRelativeDate(now.addingTimeInterval(-60), lang: .spanish) == "1 min")
  #expect(formatRelativeDate(now.addingTimeInterval(-300), lang: .spanish) == "5 min")
  #expect(formatRelativeDate(now.addingTimeInterval(-3600), lang: .spanish) == "hace 1h")
  #expect(formatRelativeDate(now.addingTimeInterval(-10800), lang: .spanish) == "hace 3h")
  #expect(formatRelativeDate(now.addingTimeInterval(-86400), lang: .spanish) == "hace 1d")
  #expect(formatRelativeDate(now.addingTimeInterval(-432_000), lang: .spanish) == "hace 5d")
}

@Test
func `format short duration spanish`() {
  #expect(formatShortDuration(0, lang: .spanish) == "0min")
  #expect(formatShortDuration(60, lang: .spanish) == "1min")
  #expect(formatShortDuration(150, lang: .spanish) == "2min")
  #expect(formatShortDuration(3600, lang: .spanish) == "1h")
  #expect(formatShortDuration(3660, lang: .spanish) == "1h 1min")
  #expect(formatShortDuration(7380, lang: .spanish) == "2h 3min")
}

@Test
func `format relative date old dates with locale`() {
  let calendar = Calendar.current
  let components = DateComponents(year: 2024, month: 8, day: 13, hour: 12, minute: 0)
  let augustDate = calendar.date(from: components)!

  let esResult = formatRelativeDate(augustDate, lang: .spanish)
  #expect(esResult.contains("13"))
}

@Test
func `format time seconds only`() {
  #expect(formatPlayerTime(0) == "0:00")
  #expect(formatPlayerTime(5) == "0:05")
  #expect(formatPlayerTime(30) == "0:30")
  #expect(formatPlayerTime(59) == "0:59")
}

@Test
func `format time minutes and seconds`() {
  #expect(formatPlayerTime(60) == "1:00")
  #expect(formatPlayerTime(65) == "1:05")
  #expect(formatPlayerTime(125) == "2:05")
  #expect(formatPlayerTime(599) == "9:59")
  #expect(formatPlayerTime(600) == "10:00")
  #expect(formatPlayerTime(3599) == "59:59")
}

@Test
func `format time hours minutes seconds`() {
  #expect(formatPlayerTime(3600) == "1:00:00")
  #expect(formatPlayerTime(3605) == "1:00:05")
  #expect(formatPlayerTime(3665) == "1:01:05")
  #expect(formatPlayerTime(7265) == "2:01:05")
  #expect(formatPlayerTime(36005) == "10:00:05")
  #expect(formatPlayerTime(359_999) == "99:59:59")
}

@Test
func `format remaining time with valid duration`() {
  #expect(formatRemainingPlayerTime(progress: 0, durationSeconds: 3600) == "-1:00:00")
  #expect(formatRemainingPlayerTime(progress: 30, durationSeconds: 3600) == "-59:30")
  #expect(formatRemainingPlayerTime(progress: 3570, durationSeconds: 3600) == "-0:30")
  #expect(formatRemainingPlayerTime(progress: 3599, durationSeconds: 3600) == "-0:01")
  #expect(formatRemainingPlayerTime(progress: 3600, durationSeconds: 3600) == "-0:00")
}

@Test
func `format remaining time with nil duration`() {
  #expect(formatRemainingPlayerTime(progress: 0, durationSeconds: nil) == "0:00")
  #expect(formatRemainingPlayerTime(progress: 1000, durationSeconds: nil) == "0:00")
  #expect(formatRemainingPlayerTime(progress: 3665, durationSeconds: nil) == "0:00")
}

@Test
func `format remaining time edge cases`() {
  #expect(formatRemainingPlayerTime(progress: -10, durationSeconds: 3600) == "-1:00:00")
  #expect(formatRemainingPlayerTime(progress: 0, durationSeconds: 0) == "0:00")
  #expect(formatRemainingPlayerTime(progress: 0, durationSeconds: -100) == "0:00")
  #expect(formatRemainingPlayerTime(progress: 760, durationSeconds: 2700) == "-32:20")
  #expect(formatRemainingPlayerTime(progress: 4000, durationSeconds: 3600) == "-0:00")
}
