import Dependencies
import DuetSQL
import MacAppRoute
import XCTest
import XExpect

@testable import Api

final class DisableFilterForChildResolverTests: ApiTestCase, @unchecked Sendable {
  func testDisableFilterSetsFilteringDisabledAndEnablesScreenshots() async throws {
    let child = try await self.child(with: {
      $0.filteringDisabled = false
      $0.screenshotsEnabled = false
    }).withDevice()

    let output = try await DisableFilterForChild.resolve(in: context(child))

    expect(output).toEqual(.success)

    let updated = try await self.db.find(child.model.id)
    expect(updated.filteringDisabled).toEqual(true)
    expect(updated.screenshotsEnabled).toEqual(true)

    let events = try await InterestingEvent.query()
      .where(.eventId == "7bb32aa0")
      .where(.computerUserId == child.computerUser.id)
      .all(in: self.db)

    expect(events).toHaveCount(1)
    expect(events.first?.detail).toEqual("filtering disabled during onboarding")

    let securityEvents = try await Api.SecurityEvent.query()
      .where(.computerUserId == child.computerUser.id)
      .all(in: self.db)

    expect(securityEvents).toHaveCount(1)
    expect(securityEvents.first?.event).toEqual("filteringDisabledDuringOnboarding")

    expect(sent.parentNotifications).toEqual([.init(
      parentId: child.parentId,
      event: .securityEvent(.init(
        source: .macApp(childName: child.name, event: .filteringDisabledDuringOnboarding),
        detail: nil,
      )),
    )])
  }

  func testDisableFilterPreservesScreenshotsIfAlreadyEnabled() async throws {
    let child = try await self.child(with: {
      $0.screenshotsEnabled = true
    }).withDevice()

    _ = try await DisableFilterForChild.resolve(in: context(child))

    let updated = try await self.db.find(child.model.id)
    expect(updated.filteringDisabled).toEqual(true)
    expect(updated.screenshotsEnabled).toEqual(true)
  }

  func testDisableFilterRejectedWhenTokenTooOld() async throws {
    let child = try await self.child(with: {
      $0.filteringDisabled = false
    }).withDevice()

    let tooOld = child.token.createdAt.addingTimeInterval(91 * 60)
    do {
      try await withDependencies {
        $0.date = .constant(tooOld)
      } operation: {
        _ = try await DisableFilterForChild.resolve(in: self.context(child))
      }
      XCTFail("expected error to be thrown")
    } catch let error as PqlError {
      expect(error.type).toEqual(.unauthorized)
    }

    let updated = try await self.db.find(child.model.id)
    expect(updated.filteringDisabled).toEqual(false)

    let events = try await InterestingEvent.query()
      .where(.eventId == "61031fd2")
      .all(in: self.db)

    expect(events).toHaveCount(1)
    let detail = try XCTUnwrap(events.first?.detail)
    expect(detail).toContain("suspicious DisableFilterForChild")
  }
}
