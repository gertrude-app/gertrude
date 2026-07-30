import Foundation
import XCTest
import XExpect

@testable import Api

final class DeletePersonResolverTests: ApiTestCase, @unchecked Sendable {
  func testDeletesOwnedPersonAndNotifiesApps() async throws {
    let person = try await self.child()

    let output = try await DeletePerson.resolve(
      with: .init(personId: person.id),
      in: self.accountContext(person.parent),
    )

    let deleted = try? await self.db.find(person.id)
    expect(output).toEqual(.success)
    expect(deleted).toBeNil()
    expect(sent.websocketMessages).toEqual([
      .init(.userDeleted, to: .user(person.id)),
    ])
  }

  func testCannotDeletePersonFromAnotherAccount() async throws {
    let person = try await self.child()
    let otherParent = try await self.parent()

    try await expectErrorFrom {
      try await DeletePerson.resolve(
        with: .init(personId: person.id),
        in: self.accountContext(otherParent),
      )
    }.toContain("notFound")

    let unchanged = try await self.db.find(person.id)
    expect(unchanged.id).toEqual(person.id)
    expect(sent.websocketMessages).toBeEmpty()
  }

  func testRejectsDeletingPersonWithSupervisedDevice() async throws {
    let person = try await self.child()
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: person.id,
      modelIdentifier: "iPhone16,1",
      iosVersion: "18.5",
    ))
    try await self.db.create(BlockerApp.Supervision(
      deviceId: device.id,
      supervisedAt: Date(),
    ))

    try await expectErrorFrom {
      try await DeletePerson.resolve(
        with: .init(personId: person.id),
        in: self.accountContext(person.parent),
      )
    }.toContain("Supervision must be removed")

    let unchanged = try await self.db.find(person.id)
    expect(unchanged.id).toEqual(person.id)
    expect(sent.websocketMessages).toBeEmpty()
  }
}
