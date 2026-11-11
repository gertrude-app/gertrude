import DuetSQL
import XCTest
import XExpect

@testable import Api

final class AccountReferralSourceResolverTests: ApiTestCase, @unchecked Sendable {
  func testSavesReferralSourceInTheLegacySurveyFormat() async throws {
    let parent = try await self.parent()

    _ = try await SaveAccountReferralSource.resolve(
      with: .init(source: .communityGroup),
      in: self.accountContext(parent),
    )

    let events = try await InterestingEvent.query()
      .where(.parentId == parent.id)
      .where(.eventId == .string(referralSurveyEventId))
      .all(in: self.db)
    expect(events.map(\.detail)).toEqual(["referral source survey: community_group"])
    expect(events.map(\.context)).toEqual(["account"])
    let slacks = self.sent.slacks.filter { $0.message.channel == "signups" }
    expect(slacks.count).toEqual(1)
    expect(slacks[0].message.text.contains("community_group")).toBeTrue()
  }

  func testOtherSourceIncludesTrimmedText() async throws {
    let parent = try await self.parent()

    _ = try await SaveAccountReferralSource.resolve(
      with: .init(source: .other(text: "  a podcast  ")),
      in: self.accountContext(parent),
    )

    let event = try await InterestingEvent.query()
      .where(.parentId == parent.id)
      .where(.eventId == .string(referralSurveyEventId))
      .first(in: self.db)
    expect(event.detail).toEqual("referral source survey: other — \"a podcast\"")
  }

  func testOtherSourceWithoutTextIsStillRecorded() async throws {
    let parent = try await self.parent()

    _ = try await SaveAccountReferralSource.resolve(
      with: .init(source: .other(text: "   ")),
      in: self.accountContext(parent),
    )

    let event = try await InterestingEvent.query()
      .where(.parentId == parent.id)
      .where(.eventId == .string(referralSurveyEventId))
      .first(in: self.db)
    expect(event.detail).toEqual("referral source survey: other")
  }
}
