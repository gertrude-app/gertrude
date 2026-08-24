import Foundation
import XCTest
import XExpect

@testable import Api

final class GetSecurityEventsMappingTests: XCTestCase {
  func testMapsLegacyFeedEventsToAccountEvents() {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let childEvent = SecurityEventsFeed.FeedEvent.child(.init(
      id: .init(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!),
      childId: .init(UUID(uuidString: "00000000-0000-0000-0000-000000000002")!),
      childName: "Jude",
      deviceId: .init(UUID(uuidString: "00000000-0000-0000-0000-000000000003")!),
      deviceName: "Jude's MacBook",
      event: "Filter suspension granted by admin",
      detail: "for 30 minutes",
      explanation: "The filter was suspended.",
      severity: .recommended,
      createdAt: date,
    ))
    let adminEvent = SecurityEventsFeed.FeedEvent.admin(.init(
      id: .init(UUID(uuidString: "00000000-0000-0000-0000-000000000004")!),
      event: "Successful login",
      detail: "using magic link",
      explanation: "Someone logged in.",
      severity: .all,
      ipAddress: "203.0.113.42",
      createdAt: date,
    ))

    guard case .macApp(let macAppEvent) = GetSecurityEvents.Event(childEvent) else {
      return XCTFail("Expected a Mac app event")
    }
    expect(macAppEvent.personName).toEqual("Jude")
    expect(macAppEvent.title).toEqual("Filter suspension granted by admin")
    expect(macAppEvent.severity).toEqual(.high)

    guard case .account(let accountEvent) = GetSecurityEvents.Event(adminEvent) else {
      return XCTFail("Expected an account event")
    }
    expect(accountEvent.title).toEqual("Successful login")
    expect(accountEvent.severity).toEqual(.low)
    expect(accountEvent.ipAddress).toEqual("203.0.113.42")
  }
}
