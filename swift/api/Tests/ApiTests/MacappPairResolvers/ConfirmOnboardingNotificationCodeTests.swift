import Dependencies
import DuetSQL
import MacAppRoute
import Vapor
import XCTest
import XExpect

@testable import Api

final class ConfirmOnboardingNotificationCodeTests: ApiTestCase, @unchecked Sendable {
  func testPersistsMethodAndCreatesBothTriggerNotifications() async throws {
    let child = try await self.child().withDevice()
    let uuids = MockUUIDs()

    let createOutput = try await withDependencies {
      $0.uuid = .mock(uuids)
      $0.verificationCode.generate = { 123_456 }
    } operation: {
      try await SendOnboardingNotificationCode.resolve(
        with: .init(phoneNumber: "+15558675309"),
        in: self.context(child),
      )
    }

    let output = try await ConfirmOnboardingNotificationCode.resolve(
      with: .init(methodId: createOutput.methodId, code: 123_456),
      in: self.context(child),
    )

    expect(output).toEqual(.success)

    let method = try await self.db
      .find(Parent.NotificationMethod.self, byId: createOutput.methodId)
    expect(method.parentId).toEqual(child.parent.model.id)
    expect(method.config).toEqual(.text(phoneNumber: "+15558675309"))

    let notifications = try await Parent.Notification.query()
      .where(.parentId == child.parent.model.id)
      .all(in: self.db)
    expect(notifications).toHaveCount(2)
    let triggers = Set(notifications.map(\.trigger))
    expect(triggers == Set([.unlockRequestSubmitted, .suspendFilterRequestSubmitted]))
      .toEqual(true)
    expect(notifications.allSatisfy { $0.methodId == method.id }).toEqual(true)
  }

  func testRejectedWhenCodeIncorrect() async throws {
    let child = try await self.child().withDevice()
    let uuids = MockUUIDs()

    let createOutput = try await withDependencies {
      $0.uuid = .mock(uuids)
      $0.verificationCode.generate = { 111_111 }
    } operation: {
      try await SendOnboardingNotificationCode.resolve(
        with: .init(phoneNumber: "+15558675309"),
        in: self.context(child),
      )
    }

    do {
      _ = try await ConfirmOnboardingNotificationCode.resolve(
        with: .init(methodId: createOutput.methodId, code: 222_222),
        in: self.context(child),
      )
      XCTFail("expected error to be thrown")
    } catch let error as PqlError {
      expect(error.type).toEqual(.unauthorized)
      expect(error.appTag == .incorrectConfirmationCode).toEqual(true)
    }

    let methods = try await Parent.NotificationMethod.query()
      .where(.parentId == child.parent.model.id)
      .all(in: self.db)
    expect(methods).toHaveCount(0)

    let notifications = try await Parent.Notification.query()
      .where(.parentId == child.parent.model.id)
      .all(in: self.db)
    expect(notifications).toHaveCount(0)
  }

  func testRejectedWhenTokenTooOld() async throws {
    let child = try await self.child().withDevice()
    let tooOld = child.token.createdAt.addingTimeInterval(25 * 60 * 60)

    do {
      try await withDependencies {
        $0.date = .constant(tooOld)
      } operation: {
        _ = try await ConfirmOnboardingNotificationCode.resolve(
          with: .init(methodId: UUID(), code: 111_111),
          in: self.context(child),
        )
      }
      XCTFail("expected error to be thrown")
    } catch let error as PqlError {
      expect(error.type).toEqual(.unauthorized)
    }

    let notifications = try await Parent.Notification.query()
      .where(.parentId == child.parent.model.id)
      .all(in: self.db)
    expect(notifications).toHaveCount(0)

    let events = try await InterestingEvent.query()
      .where(.eventId == "dbe2a684")
      .all(in: self.db)
    expect(events).toHaveCount(1)
    let detail = try XCTUnwrap(events.first?.detail)
    expect(detail).toContain("suspicious ConfirmOnboardingNotificationCode")
  }
}
