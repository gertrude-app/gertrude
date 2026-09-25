import CustomDump
import Dependencies
import DuetSQL
import XCTest

@testable import Api

final class SecurityEventNotificationTests: ApiTestCase, @unchecked Sendable {
  func testNonBetaParentReceivesLegacyLinks() async throws {
    try await self.assertNotificationLinks(accountSiteBetaEnabled: false)
  }

  func testBetaParentReceivesAccountLinks() async throws {
    try await self.assertNotificationLinks(accountSiteBetaEnabled: true)
  }

  private func assertNotificationLinks(
    accountSiteBetaEnabled: Bool,
  ) async throws {
    let parent = try await self.parent(with: {
      $0.accountSiteBetaEnabled = accountSiteBetaEnabled
    })
    let configs: [Parent.NotificationMethod.Config] = [
      .text(phoneNumber: "1234567890"),
      .ntfy(topic: "test-topic"),
    ]
    for config in configs {
      let method = try await self.db.create(Parent.NotificationMethod(
        parentId: parent.id,
        config: config,
      ))
      try await self.db.create(Parent.Notification(
        parentId: parent.id,
        methodId: method.id,
        trigger: .securityEventsAll,
      ))
    }

    let event = AdminEvent.securityEvent(.init(
      source: .dashboard(event: .keyCreated),
      detail: "key added",
      notificationDestination: .legacyDashboard(baseUrl: "https://legacy.example"),
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
      await AdminNotifier.liveValue.notify(parent.id, event)
    }

    expectNoDifference(self.sent.texts.count, 1)
    expectNoDifference(ntfyLinks.value.count, 1)
    let text = try XCTUnwrap(self.sent.texts.first)
    let smsLink = try XCTUnwrap(text.message.components(separatedBy: "\n\n").last)
    let ntfyLink = try XCTUnwrap(ntfyLinks.value.first)

    if accountSiteBetaEnabled {
      let expectedUrl = "https://account.example/security-events"
      let shortUrls = try await ShortUrl.query()
        .where(.target == expectedUrl)
        .all(in: self.db)
      expectNoDifference(shortUrls.count, 2)
      expectNoDifference(Set(shortUrls.map(\.publicUrl)), Set([smsLink, ntfyLink]))
    } else {
      let expectedUrl = "https://legacy.example/security-events"
      let shortUrls = try await ShortUrl.query()
        .where(.target == expectedUrl)
        .all(in: self.db)
      expectNoDifference(smsLink, ShortUrl.securityEvents)
      expectNoDifference(shortUrls.count, 1)
      expectNoDifference(shortUrls.first?.publicUrl, ntfyLink)
    }
  }
}
