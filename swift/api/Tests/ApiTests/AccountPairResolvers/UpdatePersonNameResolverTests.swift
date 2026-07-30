import XCTest
import XExpect

@testable import Api

final class UpdatePersonNameResolverTests: ApiTestCase, @unchecked Sendable {
  func testUpdatesTrimmedNameAndNotifiesApps() async throws {
    let person = try await self.child()

    let output = try await UpdatePersonName.resolve(
      with: .init(personId: person.id, name: "  New name  "),
      in: self.accountContext(person.parent),
    )

    let updated = try await self.db.find(person.id)
    expect(output).toEqual(.success)
    expect(updated.name).toEqual("New name")
    expect(sent.websocketMessages).toEqual([
      .init(.userUpdated, to: .user(person.id)),
    ])
  }

  func testDoesNotNotifyWhenTrimmedNameIsUnchanged() async throws {
    let person = try await self.child()

    let output = try await UpdatePersonName.resolve(
      with: .init(personId: person.id, name: "  \(person.model.name)  "),
      in: self.accountContext(person.parent),
    )

    let unchanged = try await self.db.find(person.id)
    expect(output).toEqual(.success)
    expect(unchanged.name).toEqual(person.model.name)
    expect(sent.websocketMessages).toBeEmpty()
  }

  func testRejectsEmptyName() async throws {
    let person = try await self.child()

    try await expectErrorFrom {
      try await UpdatePersonName.resolve(
        with: .init(personId: person.id, name: "   \n  "),
        in: self.accountContext(person.parent),
      )
    }.toContain("Enter a name")

    let unchanged = try await self.db.find(person.id)
    expect(unchanged.name).toEqual(person.model.name)
    expect(sent.websocketMessages).toBeEmpty()
  }

  func testCannotUpdatePersonFromAnotherAccount() async throws {
    let person = try await self.child()
    let otherParent = try await self.parent()

    try await expectErrorFrom {
      try await UpdatePersonName.resolve(
        with: .init(personId: person.id, name: "Not allowed"),
        in: self.accountContext(otherParent),
      )
    }.toContain("notFound")

    let unchanged = try await self.db.find(person.id)
    expect(unchanged.name).toEqual(person.model.name)
    expect(sent.websocketMessages).toBeEmpty()
  }
}
