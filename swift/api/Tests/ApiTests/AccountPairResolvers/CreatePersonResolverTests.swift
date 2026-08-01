import DuetSQL
import XCTest
import XExpect

@testable import Api

final class CreatePersonResolverTests: ApiTestCase, @unchecked Sendable {
  func testCreatesPersonForAccountWithTrimmedNameAndRelationship() async throws {
    let parent = try await self.parent()

    let output = try await CreatePerson.resolve(
      with: .init(name: "  Jordan  ", relationship: .peer),
      in: self.accountContext(parent),
    )

    let person = try await self.db.find(output.personId)
    expect(output.name).toEqual("Jordan")
    expect(output.relationship).toEqual(.peer)
    expect(person.parentId).toEqual(parent.id)
    expect(person.name).toEqual("Jordan")
    expect(person.relationship).toEqual(.peer)
    expect(person.keyloggingEnabled).toBeTrue()
    expect(person.screenshotsEnabled).toBeTrue()
  }

  func testCreatesSelfManagedPerson() async throws {
    let parent = try await self.parent()

    let output = try await CreatePerson.resolve(
      with: .init(name: "Jordan", relationship: .selfManaged),
      in: self.accountContext(parent),
    )

    let person = try await self.db.find(output.personId)
    expect(person.relationship).toEqual(.selfManaged)
  }

  func testRejectsSecondSelfManagedPersonForAccount() async throws {
    let existing = try await self.child(with: \.relationship, of: .selfManaged)

    try await expectErrorFrom {
      try await CreatePerson.resolve(
        with: .init(name: "Another person", relationship: .selfManaged),
        in: self.accountContext(existing.parent),
      )
    }.toContain("Another protected person")

    let people = try await Child.query()
      .where(.parentId == existing.parent.id)
      .all(in: self.db)
    expect(people.map(\.id)).toEqual([existing.id])
  }

  func testAllowsSelfManagedPersonForDifferentAccount() async throws {
    _ = try await self.child(with: \.relationship, of: .selfManaged)
    let otherParent = try await self.parent()

    let output = try await CreatePerson.resolve(
      with: .init(name: "Other account", relationship: .selfManaged),
      in: self.accountContext(otherParent),
    )

    let person = try await self.db.find(output.personId)
    expect(person.parentId).toEqual(otherParent.id)
    expect(person.relationship).toEqual(.selfManaged)
  }

  func testRejectsEmptyName() async throws {
    let parent = try await self.parent()

    try await expectErrorFrom {
      try await CreatePerson.resolve(
        with: .init(name: "  \n  ", relationship: .child),
        in: self.accountContext(parent),
      )
    }.toContain("Enter a name")

    let people = try await Child.query()
      .where(.parentId == parent.id)
      .all(in: self.db)
    expect(people).toBeEmpty()
  }
}
