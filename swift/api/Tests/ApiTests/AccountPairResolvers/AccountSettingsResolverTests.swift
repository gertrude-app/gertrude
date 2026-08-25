import XCTest
import XExpect

@testable import Api

final class AccountSettingsResolverTests: ApiTestCase, @unchecked Sendable {
  func testGetAccountSettings() async throws {
    let parent = try await self.parent(with: { $0.dailyReviewEmail = true })
    let method = try await self.db.create(Parent.NotificationMethod(
      parentId: parent.id,
      config: .email(email: parent.email.rawValue),
    ))
    let notification = try await self.db.create(Parent.Notification(
      parentId: parent.id,
      methodId: method.id,
      trigger: .unlockRequestSubmitted,
    ))

    let output = try await GetAccountSettings.resolve(in: self.accountContext(parent))

    expect(output.email).toEqual(parent.email.rawValue)
    expect(output.dailyReviewEmail).toBeTrue()
    expect(output.hasMacScreenshotUsers).toBeFalse()
    expect(output.notificationMethods).toHaveCount(1)
    expect(output.notificationMethods[0].id).toEqual(method.id)
    expect(output.notificationMethods[0].config).toEqual(method.config)
    expect(output.notifications).toHaveCount(1)
    expect(output.notifications[0].id).toEqual(notification.id)
    expect(output.notifications[0].methodId).toEqual(method.id)
    expect(output.notifications[0].trigger).toEqual(.unlockRequestSubmitted)
  }
}
