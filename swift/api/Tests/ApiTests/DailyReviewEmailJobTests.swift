import Dependencies
import Foundation
import XCTest
import XExpect

@testable import Api

final class DailyReviewEmailJobTests: ApiTestCase, @unchecked Sendable {
  func testSendsOnlyAtSendHourInParentTimeZone() {
    expect(self.shouldSend(now: self.at("America/New_York", 8), tz: "America/New_York"))
      .toEqual(true)
    expect(self.shouldSend(now: self.at("America/New_York", 7), tz: "America/New_York"))
      .toEqual(false)
    expect(self.shouldSend(now: self.at("America/New_York", 9), tz: "America/New_York"))
      .toEqual(false)
    expect(self.shouldSend(now: self.at("America/New_York", 20), tz: "America/New_York"))
      .toEqual(false)
  }

  func testSendHourIsEvaluatedInTheParentsZoneNotUtc() {
    // 8am in Tokyo is the middle of the previous evening in New York
    let tokyo8am = self.at("Asia/Tokyo", 8)
    expect(self.shouldSend(now: tokyo8am, tz: "Asia/Tokyo")).toEqual(true)
    expect(self.shouldSend(now: tokyo8am, tz: "America/New_York")).toEqual(false)
  }

  func testDoesNotSendTwiceSameLocalDay() {
    let now = self.at("America/New_York", 8)
    let earlierSameDay = self.at("America/New_York", 0)
    expect(self.shouldSend(now: now, tz: "America/New_York", lastSentAt: earlierSameDay))
      .toEqual(false)
  }

  func testSendsAgainNextDay() {
    let now = self.at("America/New_York", 8, day: 15)
    let yesterday = self.at("America/New_York", 8, day: 14)
    expect(self.shouldSend(now: now, tz: "America/New_York", lastSentAt: yesterday)).toEqual(true)
  }

  func testNilOrInvalidTimeZoneFallsBackToDefault() {
    let defaultZone8am = self.at(DailyReviewEmailJob.defaultTimeZone, 8)
    expect(self.shouldSend(now: defaultZone8am, tz: nil)).toEqual(true)
    expect(self.shouldSend(now: defaultZone8am, tz: "Not/ARealZone")).toEqual(true)
    expect(self.shouldSend(now: self.at(DailyReviewEmailJob.defaultTimeZone, 7), tz: nil))
      .toEqual(false)
  }

  func testJoinChildNames() {
    expect(joinChildNames([])).toEqual("")
    expect(joinChildNames(["Emma"])).toEqual("Emma")
    expect(joinChildNames(["Emma", "Caleb"])).toEqual("Emma and Caleb")
    expect(joinChildNames(["Emma", "Caleb", "Sam"])).toEqual("Emma, Caleb, and Sam")
  }

  func testChildRowHtml() {
    let row = ChildRow(
      name: "Emma",
      activityUrl: "https://ex.com/children/abc/activity",
      newCount: 8,
      backlog: 23,
    )
    expect(row.html.contains("<strong>Emma</strong>")).toEqual(true)
    expect(row.html.contains("8 new screenshots")).toEqual(true)
    expect(row.html.contains("23 awaiting review")).toEqual(true)
    expect(row.html.contains("https://ex.com/children/abc/activity")).toEqual(true)
  }

  func testChildRowHtmlSingularAndNoNew() {
    let one = ChildRow(name: "A", activityUrl: "u", newCount: 1, backlog: 1)
    expect(one.html.contains("1 new screenshot ")).toEqual(true) // singular, trailing space
    expect(one.html.contains("1 new screenshots")).toEqual(false)

    let noNew = ChildRow(name: "B", activityUrl: "u", newCount: 0, backlog: 5)
    expect(noNew.html.contains("new screenshot")).toEqual(false)
    expect(noNew.html.contains("5 awaiting review")).toEqual(true)
  }

  func testChildRowHtmlEscapesName() {
    let row = ChildRow(name: "<b>x</b>", activityUrl: "u", newCount: 1, backlog: 1)
    expect(row.html.contains("&lt;b&gt;x&lt;/b&gt;")).toEqual(true)
  }

  func testNonBetaDigestLinksToLegacyActivity() async throws {
    let (model, childId) = try await self.digest(accountSiteBetaEnabled: false)

    expect(model.reviewUrl).toEqual("https://dashboard.example/children/activity")
    expect(model.manageUrl).toEqual("https://dashboard.example/settings")
    expect(model.childRows.contains(
      "href=\"https://dashboard.example/children/\(childId.lowercased)/activity\"",
    )).toEqual(true)
  }

  func testBetaDigestLinksToAccountActivityAndLegacySettings() async throws {
    let (model, childId) = try await self.digest(accountSiteBetaEnabled: true)

    expect(model.reviewUrl).toEqual("https://account.example/activity")
    expect(model.manageUrl).toEqual("https://dashboard.example/settings")
    expect(model.childRows.contains(
      "href=\"https://account.example/activity/person/\(childId.lowercased)\"",
    )).toEqual(true)
  }

  // MARK: - helpers

  private func digest(
    accountSiteBetaEnabled: Bool,
  ) async throws -> (DailyReviewDigest, Child.Id) {
    let child = try await self.child(withParent: {
      $0.accountSiteBetaEnabled = accountSiteBetaEnabled
    })
    let connectedChild = try await child.withDevice()
    _ = try await self.db.create(Screenshot(
      computerUserId: connectedChild.computerUser.id,
      url: "https://example.com/screenshot.jpg",
      width: 1280,
      height: 720,
      createdAt: .reference,
    ))

    let model = try await withDependencies {
      $0.env.dashboardUrl = "https://dashboard.example/"
      $0.env.accountDashboardUrl = "https://account.example/"
    } operation: {
      try await DailyReviewEmailJob().buildDigest(for: child.parent.model)
    }
    return try (XCTUnwrap(model), child.id)
  }

  private func shouldSend(
    now: Date,
    tz: String?,
    lastSentAt: Date? = nil,
    sendHour: Int = DailyReviewEmailJob.sendHour,
  ) -> Bool {
    shouldSendDailyReview(now: now, timeZoneId: tz, lastSentAt: lastSentAt, sendHour: sendHour)
  }

  private func at(_ tzId: String, _ hour: Int, day: Int = 15) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: tzId)!
    return calendar.date(
      from: DateComponents(year: 2026, month: 6, day: day, hour: hour, minute: 30),
    )!
  }
}
