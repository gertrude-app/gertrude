import XCTest
import XExpect

@testable import Api

final class DecideSuspensionRequestResolverTests: ApiTestCase, @unchecked Sendable {
  func testRejectsRequestAndNotifiesMac() async throws {
    let child = try await self.child().withDevice()
    let request = try await self.db.create(MacApp.SuspendFilterRequest.random {
      $0.computerUserId = child.computerUser.id
      $0.status = .pending
    })

    let output = try await DecideSuspensionRequest.resolve(
      with: .init(
        id: request.id,
        decision: .rejected,
        responseComment: "Not right now",
      ),
      in: self.accountContext(child.parent),
    )

    expect(output).toEqual(.success)

    let updated = try await self.db.find(request.id)
    expect(updated.status).toEqual(.rejected)
    expect(updated.responseComment).toEqual("Not right now")
    expect(sent.websocketMessages).toEqual([
      .init(
        .filterSuspensionRequestDecided_v2(
          id: updated.id.rawValue,
          decision: .rejected,
          comment: "Not right now",
        ),
        to: .userDevice(child.computerUser.id),
      ),
    ])
  }

  func testGrantsRequestWithExtraMonitoringAndNotifiesMac() async throws {
    let child = try await self.child().withDevice()
    let request = try await self.db.create(MacApp.SuspendFilterRequest.random {
      $0.computerUserId = child.computerUser.id
      $0.status = .pending
    })

    let output = try await DecideSuspensionRequest.resolve(
      with: .init(
        id: request.id,
        decision: .accepted(
          durationInSeconds: 600,
          extraMonitoring: "@30+k",
        ),
        responseComment: "Sounds good",
      ),
      in: self.accountContext(child.parent),
    )

    expect(output).toEqual(.success)

    let updated = try await self.db.find(request.id)
    expect(updated.status).toEqual(.accepted)
    expect(updated.duration).toEqual(.init(600))
    expect(updated.extraMonitoring).toEqual("@30+k")
    expect(updated.responseComment).toEqual("Sounds good")
    expect(sent.websocketMessages).toEqual([
      .init(
        .filterSuspensionRequestDecided_v2(
          id: updated.id.rawValue,
          decision: updated.decision!,
          comment: "Sounds good",
        ),
        to: .userDevice(child.computerUser.id),
      ),
    ])
  }

  func testGrantDurationsMustBeBetweenOneMinuteAndSevenDays() async throws {
    let child = try await self.child().withDevice()
    let request = try await self.db.create(MacApp.SuspendFilterRequest.random {
      $0.computerUserId = child.computerUser.id
      $0.status = .pending
    })
    let decide = { (seconds: Int) in
      try await DecideSuspensionRequest.resolve(
        with: .init(
          id: request.id,
          decision: .accepted(durationInSeconds: seconds, extraMonitoring: nil),
          responseComment: nil,
        ),
        in: self.accountContext(child.parent),
      )
    }

    for seconds in [59, 7 * 24 * 60 * 60 + 1] {
      try await expectErrorFrom { try await decide(seconds) }
        .toContain("between 1 minute and 7 days")
    }
    await expect(try decide(7 * 24 * 60 * 60)).toEqual(.success)
    await expect(try self.db.find(request.id).duration.rawValue).toEqual(7 * 24 * 60 * 60)
  }

  func testCannotDecideRequestFromAnotherAccount() async throws {
    let child = try await self.child().withDevice()
    let request = try await self.db.create(MacApp.SuspendFilterRequest.random {
      $0.computerUserId = child.computerUser.id
      $0.status = .pending
    })
    let otherParent = try await self.parent()

    do {
      _ = try await DecideSuspensionRequest.resolve(
        with: .init(id: request.id, decision: .rejected, responseComment: nil),
        in: self.accountContext(otherParent),
      )
      XCTFail("expected request decision to be rejected")
    } catch {}

    let unchanged = try await self.db.find(request.id)
    expect(unchanged.status).toEqual(.pending)
    expect(sent.websocketMessages).toBeEmpty()
  }
}
