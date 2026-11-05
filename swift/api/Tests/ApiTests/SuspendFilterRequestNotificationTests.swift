import Dependencies
import XCTest
import XExpect

@testable import Api

final class SuspendFilterRequestNotificationTests: ApiTestCase, @unchecked Sendable {
  func testParentReceivesAccountSiteLink() async throws {
    let child = try await self.childWithComputer()
    let event = self.event(for: child)

    await withDependencies {
      $0.env.accountDashboardUrl = "https://account.example/"
    } operation: {
      await AdminNotifier.liveValue.notify(child.parent.id, event)
    }

    expect(self.sent.emails).toHaveCount(1)
    expect(self.sent.emails[0].templateModel["url"]).toEqual(
      "https://account.example/requests/suspension/\(self.requestId(in: event).lowercased)",
    )
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
