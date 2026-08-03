import XCTest
import XExpect

@testable import Api

final class UpdatePersonBasicDetailsResolverTests: ApiTestCase, @unchecked Sendable {
  func testUpdatesTrimmedNameAndRelationshipAndNotifiesApps() async throws {
    let person = try await self.child()

    let output = try await UpdatePersonBasicDetails.resolve(
      with: .init(personId: person.id, name: "  New name  ", relationship: .peer),
      in: self.accountContext(person.parent),
    )

    let updated = try await self.db.find(person.id)
    expect(output).toEqual(.success)
    expect(updated.name).toEqual("New name")
    expect(updated.relationship).toEqual(.peer)
    expect(sent.websocketMessages).toEqual([
      .init(.userUpdated, to: .user(person.id)),
    ])
  }

  func testUpdatesRelationshipWithoutNotifyingApps() async throws {
    let person = try await self.child()

    let output = try await UpdatePersonBasicDetails.resolve(
      with: .init(
        personId: person.id,
        name: person.model.name,
        relationship: .selfManaged,
      ),
      in: self.accountContext(person.parent),
    )

    let updated = try await self.db.find(person.id)
    expect(output).toEqual(.success)
    expect(updated.name).toEqual(person.model.name)
    expect(updated.relationship).toEqual(.selfManaged)
    expect(sent.websocketMessages).toBeEmpty()
  }

  func testRejectsSelfManagedRelationshipWhenAnotherPersonUsesIt() async throws {
    let person = try await self.child()
    _ = try await self.db.create(Child(
      parentId: person.parent.id,
      name: "Existing self-managed person",
      relationship: .selfManaged,
    ))

    try await expectErrorFrom {
      try await UpdatePersonBasicDetails.resolve(
        with: .init(
          personId: person.id,
          name: "Changed name",
          relationship: .selfManaged,
        ),
        in: self.accountContext(person.parent),
      )
    }.toContain("Another protected person")

    let unchanged = try await self.db.find(person.id)
    expect(unchanged.name).toEqual(person.model.name)
    expect(unchanged.relationship).toEqual(.child)
    expect(sent.websocketMessages).toBeEmpty()
  }

  func testAcceptsUnchangedDetails() async throws {
    let person = try await self.child(with: \.relationship, of: .selfManaged)

    let output = try await UpdatePersonBasicDetails.resolve(
      with: .init(
        personId: person.id,
        name: "  \(person.model.name)  ",
        relationship: .selfManaged,
      ),
      in: self.accountContext(person.parent),
    )

    let unchanged = try await self.db.find(person.id)
    expect(output).toEqual(.success)
    expect(unchanged.name).toEqual(person.model.name)
    expect(unchanged.relationship).toEqual(.selfManaged)
    expect(sent.websocketMessages).toBeEmpty()
  }

  func testRejectsEmptyNameWithoutUpdatingRelationship() async throws {
    let person = try await self.child()

    try await expectErrorFrom {
      try await UpdatePersonBasicDetails.resolve(
        with: .init(personId: person.id, name: "   \n  ", relationship: .peer),
        in: self.accountContext(person.parent),
      )
    }.toContain("Enter a name")

    let unchanged = try await self.db.find(person.id)
    expect(unchanged.name).toEqual(person.model.name)
    expect(unchanged.relationship).toEqual(.child)
    expect(sent.websocketMessages).toBeEmpty()
  }

  func testCannotUpdatePersonFromAnotherAccount() async throws {
    let person = try await self.child()
    let otherParent = try await self.parent()

    try await expectErrorFrom {
      try await UpdatePersonBasicDetails.resolve(
        with: .init(personId: person.id, name: "Not allowed", relationship: .peer),
        in: self.accountContext(otherParent),
      )
    }.toContain("notFound")

    let unchanged = try await self.db.find(person.id)
    expect(unchanged.name).toEqual(person.model.name)
    expect(unchanged.relationship).toEqual(.child)
    expect(sent.websocketMessages).toBeEmpty()
  }
}
