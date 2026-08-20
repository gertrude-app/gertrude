import DuetSQL
import Gertie
import XCTest
import XExpect

@testable import Api

final class AccountKeychainsResolverTests: ApiTestCase, @unchecked Sendable {
  func testReturnsParentOwnedKeychainsWithPeopleAssignmentsAndKeyCounts() async throws {
    let parent = try await self.parent()
    let jude = try await self.db.create(Child(parentId: parent.id, name: "Jude"))
    let mabel = try await self.db.create(Child(parentId: parent.id, name: "Mabel"))
    let school = try await self.db.create(Keychain(
      parentId: parent.id,
      name: "School",
      description: "School sites",
    ))
    let music = try await self.db.create(Keychain(
      parentId: parent.id,
      name: "Music",
      isPublic: true,
    ))
    try await self.db.create([
      Key(
        keychainId: school.id,
        key: .domain(domain: "one.example", scope: .webBrowsers),
      ),
      Key(
        keychainId: school.id,
        key: .domain(domain: "two.example", scope: .webBrowsers),
      ),
    ])
    try await self.db.create(ChildKeychain(childId: jude.id, keychainId: school.id))

    let otherParent = try await self.parent()
    let otherPerson = try await self.db.create(
      Child(parentId: otherParent.id, name: "Someone Else"),
    )
    let otherKeychain = try await self.db.create(Keychain(
      parentId: otherParent.id,
      name: "Other Account",
      isPublic: true,
    ))
    try await self.db.create(ChildKeychain(
      childId: otherPerson.id,
      keychainId: otherKeychain.id,
    ))

    let output = try await GetAccountKeychains.resolve(in: self.accountContext(parent))

    expect(output.people.map(\.name)).toEqual(["Jude", "Mabel"])
    expect(output.keychains.map(\.name)).toEqual(["Music", "School"])
    let returnedSchool = try XCTUnwrap(output.keychains.first { $0.id == school.id })
    expect(returnedSchool.description).toEqual("School sites")
    expect(returnedSchool.isPublic).toBeFalse()
    expect(returnedSchool.numKeys).toEqual(2)
    expect(returnedSchool.assignedPersonIds).toEqual([jude.id])
    let returnedMusic = try XCTUnwrap(output.keychains.first { $0.id == music.id })
    expect(returnedMusic.isPublic).toBeTrue()
    expect(returnedMusic.numKeys).toEqual(0)
    expect(returnedMusic.assignedPersonIds).toBeEmpty()
    expect(output.people.map(\.id).contains(mabel.id)).toBeTrue()
    expect(output.keychains.map(\.id).contains(otherKeychain.id)).toBeFalse()
  }

  func testReturnsEmptyCollectionsForEmptyAccount() async throws {
    let parent = try await self.parent()

    let output = try await GetAccountKeychains.resolve(in: self.accountContext(parent))

    expect(output.keychains).toBeEmpty()
    expect(output.people).toBeEmpty()
  }

  func testSetsAssignmentsIdempotentlyAndNotifiesPersonApps() async throws {
    let person = try await self.child()
    let keychain = try await self.db.create(Keychain(
      parentId: person.parent.id,
      name: "School",
    ))
    let input = SetAccountKeychainAssignment.Input(
      keychainId: keychain.id,
      personId: person.id,
      assigned: true,
    )

    _ = try await SetAccountKeychainAssignment.resolve(
      with: input,
      in: self.accountContext(person.parent),
    )
    _ = try await SetAccountKeychainAssignment.resolve(
      with: input,
      in: self.accountContext(person.parent),
    )

    let assignments = try await ChildKeychain.query()
      .where(.childId == person.id)
      .where(.keychainId == keychain.id)
      .all(in: self.db)
    expect(assignments).toHaveCount(1)
    expect(sent.websocketMessages).toEqual([
      .init(.userUpdated, to: .user(person.id)),
    ])

    let removeInput = SetAccountKeychainAssignment.Input(
      keychainId: keychain.id,
      personId: person.id,
      assigned: false,
    )
    _ = try await SetAccountKeychainAssignment.resolve(
      with: removeInput,
      in: self.accountContext(person.parent),
    )
    _ = try await SetAccountKeychainAssignment.resolve(
      with: removeInput,
      in: self.accountContext(person.parent),
    )

    let remainingAssignments = try await ChildKeychain.query()
      .where(.childId == person.id)
      .where(.keychainId == keychain.id)
      .all(in: self.db)
    expect(remainingAssignments).toBeEmpty()
    expect(sent.websocketMessages).toEqual([
      .init(.userUpdated, to: .user(person.id)),
      .init(.userUpdated, to: .user(person.id)),
    ])
  }

  func testRejectsKeychainOwnedByAnotherAccount() async throws {
    let person = try await self.child()
    let otherParent = try await self.parent()
    let otherKeychain = try await self.db.create(Keychain(
      parentId: otherParent.id,
      name: "Other Account",
    ))

    try await expectErrorFrom {
      try await SetAccountKeychainAssignment.resolve(
        with: .init(
          keychainId: otherKeychain.id,
          personId: person.id,
          assigned: true,
        ),
        in: self.accountContext(person.parent),
      )
    }.toContain("notFound")

    let assignments = try await ChildKeychain.query()
      .where(.childId == person.id)
      .all(in: self.db)
    expect(assignments).toBeEmpty()
  }

  func testRejectsPersonOwnedByAnotherAccount() async throws {
    let person = try await self.child()
    let otherPerson = try await self.child()
    let keychain = try await self.db.create(Keychain(
      parentId: person.parent.id,
      name: "School",
    ))

    try await expectErrorFrom {
      try await SetAccountKeychainAssignment.resolve(
        with: .init(
          keychainId: keychain.id,
          personId: otherPerson.id,
          assigned: true,
        ),
        in: self.accountContext(person.parent),
      )
    }.toContain("notFound")

    let assignments = try await ChildKeychain.query()
      .where(.keychainId == keychain.id)
      .all(in: self.db)
    expect(assignments).toBeEmpty()
  }
}
