import CustomDump
import Dependencies
import DuetSQL
import XCTest

@testable import Api

final class UnlockRequestNotificationTests: ApiTestCase, @unchecked Sendable {
  func testParentReceivesAccountFallbackEmail() async throws {
    try await self.assertNotificationLinks(configured: false)
  }

  func testParentReceivesAccountLinksAcrossConfiguredChannels() async throws {
    try await self.assertNotificationLinks(configured: true)
  }

  private func assertNotificationLinks(configured: Bool) async throws {
    let child = try await self.child()
    if configured {
      let configs: [Parent.NotificationMethod.Config] = [
        .email(email: "notifications@example.com"),
        .slack(channelId: "C123", channelName: "Gertrude", token: "test-token"),
        .text(phoneNumber: "1234567890"),
        .ntfy(topic: "test-topic"),
      ]
      for config in configs {
        let method = try await self.db.create(Parent.NotificationMethod(
          parentId: child.parent.id,
          config: config,
        ))
        try await self.db.create(Parent.Notification(
          parentId: child.parent.id,
          methodId: method.id,
          trigger: .unlockRequestSubmitted,
        ))
      }
    }

    let event = AdminEvent.unlockRequestSubmitted(.init(
      notificationDestination: .legacyDashboard(baseUrl: "https://dashboard.example"),
      userId: child.id,
      userName: child.name,
      requestIds: [.init(), .init()],
    ))
    let ntfyLinks = LockIsolated<[String]>([])
    await withDependencies {
      $0.env.accountDashboardUrl = "https://account.example/"
      $0.ntfy.send = { _, _, message, click in
        let link = try XCTUnwrap(click)
        XCTAssertTrue(message.contains(link))
        ntfyLinks.withValue { $0.append(link) }
      }
    } operation: {
      await AdminNotifier.liveValue.notify(child.parent.id, event)
    }

    let expectedUrl = "https://account.example/requests/unlock/\(child.id.lowercased)"
    expectNoDifference(self.sent.emails.count, 1)
    let email = try XCTUnwrap(self.sent.emails.first)
    expectNoDifference(email.templateModel["url"], expectedUrl)
    expectNoDifference(
      email.templateModel["fallbackNotice"],
      configured ? "" : EMAIL_NOTIFICATION_FALLBACK,
    )

    guard configured else {
      expectNoDifference(self.sent.slacks.count, 0)
      expectNoDifference(self.sent.texts.count, 0)
      expectNoDifference(ntfyLinks.value.count, 0)
      return
    }

    expectNoDifference(self.sent.slacks.count, 1)
    let slack = try XCTUnwrap(self.sent.slacks.first)
    XCTAssertTrue(slack.message.text.contains(expectedUrl))
    expectNoDifference(self.sent.texts.count, 1)
    expectNoDifference(ntfyLinks.value.count, 1)
    let text = try XCTUnwrap(self.sent.texts.first)
    let smsLink = try XCTUnwrap(text.message.components(separatedBy: "\n\n").last)
    let ntfyLink = try XCTUnwrap(ntfyLinks.value.first)
    let shortUrls = try await ShortUrl.query()
      .where(.target == expectedUrl)
      .all(in: self.db)
    expectNoDifference(shortUrls.count, 2)
    expectNoDifference(Set(shortUrls.map(\.publicUrl)), Set([smsLink, ntfyLink]))
  }
}
