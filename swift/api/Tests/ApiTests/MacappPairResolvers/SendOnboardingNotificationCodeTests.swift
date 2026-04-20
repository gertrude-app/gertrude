import Dependencies
import DuetSQL
import MacAppRoute
import XCTest
import XExpect

@testable import Api

final class SendOnboardingNotificationCodeTests: ApiTestCase, @unchecked Sendable {
  func testSendsTextAndStoresPendingMethodWithoutPersisting() async throws {
    let child = try await self.child().withDevice()
    let uuids = MockUUIDs()

    let output = try await withDependencies {
      $0.uuid = .mock(uuids)
      $0.verificationCode.generate = { 654_321 }
    } operation: {
      try await SendOnboardingNotificationCode.resolve(
        with: .init(phoneNumber: "+15558675309"),
        in: self.context(child),
      )
    }

    expect(output.methodId).toEqual(uuids[0])

    expect(sent.texts).toEqual([
      .init(to: "+15558675309", message: "Your verification code is 654321"),
    ])

    let preConfirm = try? await self.db
      .find(Parent.NotificationMethod.self, byId: uuids[0])
    expect(preConfirm).toBeNil()
  }

  func testRejectedWhenTokenTooOld() async throws {
    let child = try await self.child().withDevice()
    let tooOld = child.token.createdAt.addingTimeInterval(25 * 60 * 60)

    do {
      try await withDependencies {
        $0.date = .constant(tooOld)
      } operation: {
        _ = try await SendOnboardingNotificationCode.resolve(
          with: .init(phoneNumber: "+15558675309"),
          in: self.context(child),
        )
      }
      XCTFail("expected error to be thrown")
    } catch let error as PqlError {
      expect(error.type).toEqual(.unauthorized)
    }

    expect(sent.texts).toHaveCount(0)

    let events = try await InterestingEvent.query()
      .where(.eventId == "26d28e89")
      .all(in: self.db)
    expect(events).toHaveCount(1)
    let detail = try XCTUnwrap(events.first?.detail)
    expect(detail).toContain("suspicious SendOnboardingNotificationCode")
  }
}
