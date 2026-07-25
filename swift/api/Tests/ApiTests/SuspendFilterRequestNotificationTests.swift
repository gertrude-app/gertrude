import Dependencies
import XCTest
import XExpect

@testable import Api

final class SuspendFilterRequestNotificationTests: ApiTestCase, @unchecked Sendable {
  func testNonBetaParentReceivesLegacyDashboardLink() async throws {
    let child = try await self.childWithComputer()
    let event = self.event(for: child)

    await withDependencies {
      $0.env.accountDashboardUrl = "https://account.example/"
    } operation: {
      await AdminNotifier.liveValue.notify(child.parent.id, event)
    }

    expect(self.sent.emails).toHaveCount(1)
    expect(self.sent.emails[0].templateModel["url"]).toEqual(
      "https://dashboard.example/children/\(child.computerUser.id.lowercased)/suspend-filter-requests/\(self.requestId(in: event).lowercased)",
    )
  }

  func testBetaParentReceivesAccountSiteLink() async throws {
    let child = try await self.childWithComputer()
    var parent = child.parent.model
    parent.accountSiteBetaEnabled = true
    try await self.db.update(parent)
    let event = self.event(for: child)

    await withDependencies {
      $0.env.accountDashboardUrl = "https://account.example/"
    } operation: {
      await AdminNotifier.liveValue.notify(parent.id, event)
    }

    expect(self.sent.emails).toHaveCount(1)
    let requestId = self.requestId(in: event)
    expect(self.sent.emails[0].templateModel["url"]).toEqual(
      "https://account.example/requests/suspension/\(requestId.lowercased)",
    )
  }

  func testAccountSiteRoutingDoesNotChangeIOSRequestDestination() async throws {
    let child = try await self.childWithIOSDevice()
    let event = AdminEvent.suspendFilterRequestSubmitted(.init(
      notificationDestination: .legacyDashboard(baseUrl: "https://dashboard.example"),
      childId: child.id,
      childName: child.name,
      duration: 300,
      requestComment: nil,
      context: .iosapp(deviceId: child.device.id, requestId: .init()),
    ))

    expect(event.routingMacSuspensionRequest(toAccountSiteAt: "https://account.example"))
      .toEqual(event)
  }

  private func event(for child: ChildWithComputerEntities) -> AdminEvent {
    .suspendFilterRequestSubmitted(.init(
      notificationDestination: .legacyDashboard(baseUrl: "https://dashboard.example"),
      childId: child.id,
      childName: child.name,
      duration: 300,
      requestComment: nil,
      context: .macapp(computerUserId: child.computerUser.id, requestId: .init()),
    ))
  }

  private func requestId(
    in event: AdminEvent,
  ) -> MacApp.SuspendFilterRequest.Id {
    guard case .suspendFilterRequestSubmitted(let request) = event,
          case .macapp(_, let requestId) = request.context else {
      fatalError("Expected Mac suspension request event")
    }
    return requestId
  }
}
