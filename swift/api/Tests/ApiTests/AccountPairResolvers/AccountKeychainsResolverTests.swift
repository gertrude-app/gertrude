import DuetSQL
import Foundation
import Gertie
import XCTest
import XExpect

@testable import Api

final class AccountKeychainsResolverTests: ApiTestCase, @unchecked Sendable {
  func testMapsKeychainLifecycleInputsAndNormalizesMetadata() async throws {
    let parent = try await self.parent()
    let context = self.accountContext(parent)
    let output = try await SaveAccountKeychain.resolve(
      with: .init(keychainId: nil, name: "  School \n", description: "  Class resources  "),
      in: context,
    )

    let created: Keychain = try await self.db.find(output.id)
    expect(created.name).toEqual("School")
    expect(created.description).toEqual("Class resources")
    let updatedOutput = try await SaveAccountKeychain.resolve(
      with: .init(keychainId: output.id, name: " Homework ", description: " \n\t "),
      in: context,
    )

    expect(updatedOutput.id).toEqual(output.id)
    let updated: Keychain = try await self.db.find(updatedOutput.id)
    expect(updated.name).toEqual("Homework")
    expect(updated.description).toBeNil()

    let deletion = try await DeleteAccountKeychain.resolve(
      with: .init(keychainId: output.id),
      in: context,
    )
    expect(deletion).toEqual(.success)
    await expect(try Keychain.query().where(.id == output.id).exists(in: self.db)).toBeFalse()
  }

  func testRejectsBlankKeychainNamesForCreationAndEditing() async throws {
    let parent = try await self.parent()
    let owned = try await parent.withKeychain { keychain, _ in
      keychain.isPublic = false
    }
    let context = self.accountContext(parent)

    for keychainId in [nil, owned.keychain.id] {
      try await expectErrorFrom {
        try await SaveAccountKeychain.resolve(
          with: .init(keychainId: keychainId, name: " \n\t ", description: "Ignored"),
          in: context,
        )
      }.toContain("badRequest")
    }

    let keychains = try await Keychain.query().where(.parentId == parent.id).all(in: self.db)
    expect(keychains.map(\.id)).toEqual([owned.keychain.id])
    expect(keychains.first?.name).toEqual(owned.keychain.name)
  }

  func testRejectsMetadataChangesAndDeletionOfAnotherAccountsKeychain() async throws {
    let parent = try await self.parent()
    let otherParent = try await self.parent()
    let owned = try await otherParent.withKeychain { keychain, _ in
      keychain.isPublic = false
    }
    let context = self.accountContext(parent)

    try await expectErrorFrom {
      try await SaveAccountKeychain.resolve(
        with: .init(keychainId: owned.keychain.id, name: "Changed", description: nil),
        in: context,
      )
    }.toContain("notFound")
    try await expectErrorFrom {
      try await DeleteAccountKeychain.resolve(
        with: .init(keychainId: owned.keychain.id),
        in: context,
      )
    }.toContain("notFound")

    await expect(try self.db.find(owned.keychain.id).name).toEqual(owned.keychain.name)
    await expect(try self.db.find(owned.keychain.id).description)
      .toEqual(owned.keychain.description)
    await expect(try self.db.find(owned.key.id).key).toEqual(owned.key.key)
    expect(sent.websocketMessages).toBeEmpty()
  }

  func testRejectsMetadataChangesAndDeletionOfPublicKeychains() async throws {
    let parent = try await self.parent()
    let owned = try await parent.withKeychain { keychain, _ in
      keychain.isPublic = true
    }
    let context = self.accountContext(parent)

    try await expectErrorFrom {
      try await SaveAccountKeychain.resolve(
        with: .init(keychainId: owned.keychain.id, name: "Changed", description: nil),
        in: context,
      )
    }.toContain("badRequest")
    try await expectErrorFrom {
      try await DeleteAccountKeychain.resolve(
        with: .init(keychainId: owned.keychain.id),
        in: context,
      )
    }.toContain("badRequest")

    await expect(try self.db.find(owned.keychain.id).name).toEqual(owned.keychain.name)
    await expect(try self.db.find(owned.keychain.id).description)
      .toEqual(owned.keychain.description)
    await expect(try self.db.find(owned.key.id).key).toEqual(owned.key.key)
    expect(sent.websocketMessages).toBeEmpty()
  }

  func testDetailsIncludeOnlyAssignedPeopleFromTheOwningAccount() async throws {
    let parent = try await self.parent()
    let keychain = try await self.db.create(Keychain(
      parentId: parent.id,
      name: "Shared",
      isPublic: true,
    ))
    let mabel = try await self.db.create(Child(parentId: parent.id, name: "Mabel"))
    let jude = try await self.db.create(Child(parentId: parent.id, name: "Jude"))
    let other = try await self.child()
    try await self.db.create([
      ChildKeychain(childId: mabel.id, keychainId: keychain.id),
      ChildKeychain(childId: jude.id, keychainId: keychain.id),
      ChildKeychain(childId: other.id, keychainId: keychain.id),
    ])

    let output = try await GetAccountKeychain.resolve(
      with: .init(keychainId: keychain.id),
      in: self.accountContext(parent),
    )

    expect(output.assignedPeople.map(\.name)).toEqual(["Jude", "Mabel"])
    expect(output.assignedPeople.map(\.id)).toEqual([jude.id, mabel.id])
  }

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

  func testMapsLegacyKeychainAndResolvesAppNames() async throws {
    let parent = try await self.parent()
    let keychain = try await self.db.create(Keychain(
      parentId: parent.id,
      name: "School",
      isPublic: true,
      description: "School resources",
      warning: "Includes broad access",
    ))
    let app = try await self.db.create(IdentifiedApp(
      name: "Minecraft",
      slug: "minecraft",
      launchable: true,
    ))
    try await self.db.create([
      AppBundleId(
        identifiedAppId: app.id,
        bundleId: "com.minecraft.primary",
        count: 2,
      ),
      AppBundleId(
        identifiedAppId: app.id,
        bundleId: "AB12CD34EF.com.minecraft.launcher",
        count: 1,
      ),
    ])
    try await self.db.create(CatalogedApp(
      bundleId: "com.minecraft.launcher",
      name: "Minecraft",
      icon: Data([1]),
      iconContentHash: "minecraft-icon",
    ))
    let expiration = Date(timeIntervalSince1970: 1_800_000_000)
    let slugKey = Key(
      keychainId: keychain.id,
      key: .domain(
        domain: .init("api.example.com")!,
        scope: .single(.identifiedAppSlug("minecraft")),
      ),
      comment: "School portal",
      deletedAt: expiration,
    )
    let bundleKey = Key(
      keychainId: keychain.id,
      key: .skeleton(scope: .bundleId(".AB12CD34EF.com.minecraft.launcher")),
    )
    let unknownAppKey = Key(
      keychainId: keychain.id,
      key: .anySubdomain(
        domain: .init("example.com")!,
        scope: .single(.bundleId("com.unknown.app")),
      ),
    )
    try await self.db.create([slugKey, bundleKey, unknownAppKey])

    let output = try await GetAccountKeychain.resolve(
      with: .init(keychainId: keychain.id),
      in: self.accountContext(parent),
    )

    expect(output.id).toEqual(keychain.id)
    expect(output.name).toEqual("School")
    expect(output.description).toEqual("School resources")
    expect(output.warning).toEqual("Includes broad access")
    expect(output.isPublic).toBeTrue()
    expect(output.apps.map(\.name)).toEqual(["Minecraft"])
    expect(output.apps.map(\.slug)).toEqual(["minecraft"])
    expect(output.apps.map(\.bundleId)).toEqual(["com.minecraft.primary"])
    expect(output.apps.map(\.iconHash)).toEqual(["minecraft-icon"])
    expect(Set(output.keys.map(\.key)))
      .toEqual(Set([slugKey.key, bundleKey.key, unknownAppKey.key]))

    let returnedSlugKey = try XCTUnwrap(output.keys.first { $0.id == slugKey.id })
    expect(returnedSlugKey.comment).toEqual("School portal")
    expect(returnedSlugKey.expiration).toEqual(expiration)
    expect(returnedSlugKey.appName).toEqual("Minecraft")
    expect(try XCTUnwrap(output.keys.first { $0.id == bundleKey.id }).appName)
      .toEqual("Minecraft")
    expect(try XCTUnwrap(output.keys.first { $0.id == unknownAppKey.id }).appName)
      .toBeNil()
  }

  func testRejectsKeychainDetailsOwnedByAnotherAccount() async throws {
    let parent = try await self.parent()
    let otherParent = try await self.parent()
    let otherKeychain = try await self.db.create(Keychain(
      parentId: otherParent.id,
      name: "Other Account",
    ))

    try await expectErrorFrom {
      try await GetAccountKeychain.resolve(
        with: .init(keychainId: otherKeychain.id),
        in: self.accountContext(parent),
      )
    }.toContain("notFound")
  }
}
