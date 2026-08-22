import Foundation
import Gertie
import XCTest
import XExpect

@testable import Api

final class AccountKeyResolverTests: ApiTestCase, @unchecked Sendable {
  func testCreatesUpdatesAndDeletesKey() async throws {
    let parent = try await self.parent()
    let keychain = try await self.db.create(Keychain(
      parentId: parent.id,
      name: "School",
    ))
    let context = self.accountContext(parent)

    _ = try await SaveAccountKey.resolve(
      with: .init(
        keychainId: keychain.id,
        keyId: nil,
        key: .anySubdomain(domain: "example.com", scope: .webBrowsers),
        comment: "School site",
        expiration: nil,
      ),
      in: context,
    )

    var keys = try await keychain.keys(in: self.db)
    expect(keys).toHaveCount(1)
    let key = try XCTUnwrap(keys.first)
    expect(key.comment).toEqual("School site")
    expect(key.key).toEqual(.anySubdomain(domain: "example.com", scope: .webBrowsers))

    let expiration = Date(timeIntervalSince1970: 1_900_000_000)
    _ = try await SaveAccountKey.resolve(
      with: .init(
        keychainId: keychain.id,
        keyId: key.id,
        key: .domain(domain: "school.example.com", scope: .unrestricted),
        comment: "Updated",
        expiration: expiration,
      ),
      in: context,
    )

    let updated: Api.Key = try await self.db.find(key.id)
    expect(updated.comment).toEqual("Updated")
    expect(updated.key).toEqual(Gertie.Key.domain(
      domain: "school.example.com",
      scope: .unrestricted,
    ))
    expect(updated.deletedAt).toEqual(expiration)

    _ = try await DeleteAccountKey.resolve(
      with: .init(keychainId: keychain.id, keyId: key.id),
      in: context,
    )

    keys = try await keychain.keys(in: self.db)
    expect(keys).toBeEmpty()
    expect(sent.websocketMessages).toEqual([
      .init(.userUpdated, to: .usersWith(keychain: keychain.id)),
      .init(.userUpdated, to: .usersWith(keychain: keychain.id)),
      .init(.userUpdated, to: .usersWith(keychain: keychain.id)),
    ])
  }

  func testRejectsKeyFromAnotherKeychain() async throws {
    let parent = try await self.parent()
    let keychain = try await self.db.create(Keychain(
      parentId: parent.id,
      name: "School",
    ))
    let otherKeychain = try await self.db.create(Keychain(
      parentId: parent.id,
      name: "Other",
    ))
    let otherKey = try await self.db.create(Key(
      keychainId: otherKeychain.id,
      key: .mock,
    ))

    try await expectErrorFrom {
      try await SaveAccountKey.resolve(
        with: .init(
          keychainId: keychain.id,
          keyId: otherKey.id,
          key: .domain(domain: "example.com", scope: .webBrowsers),
          comment: nil,
          expiration: nil,
        ),
        in: self.accountContext(parent),
      )
    }.toContain("notFound")

    try await expectErrorFrom {
      try await DeleteAccountKey.resolve(
        with: .init(keychainId: keychain.id, keyId: otherKey.id),
        in: self.accountContext(parent),
      )
    }.toContain("notFound")
  }

  func testRejectsKeychainOwnedByAnotherAccount() async throws {
    let parent = try await self.parent()
    let otherParent = try await self.parent()
    let keychain = try await self.db.create(Keychain(
      parentId: otherParent.id,
      name: "Other Account",
    ))
    let key = try await self.db.create(Key(
      keychainId: keychain.id,
      key: .mock,
    ))

    try await expectErrorFrom {
      try await SaveAccountKey.resolve(
        with: .init(
          keychainId: keychain.id,
          keyId: nil,
          key: .domain(domain: "example.com", scope: .webBrowsers),
          comment: nil,
          expiration: nil,
        ),
        in: self.accountContext(parent),
      )
    }.toContain("notFound")

    try await expectErrorFrom {
      try await DeleteAccountKey.resolve(
        with: .init(keychainId: keychain.id, keyId: key.id),
        in: self.accountContext(parent),
      )
    }.toContain("notFound")
  }

  func testRejectsEditsToPublicAndLegacyKeys() async throws {
    let parent = try await self.parent()
    let publicKeychain = try await self.db.create(Keychain(
      parentId: parent.id,
      name: "Public",
      isPublic: true,
    ))
    let privateKeychain = try await self.db.create(Keychain(
      parentId: parent.id,
      name: "Private",
    ))
    let publicKey = try await self.db.create(Key(
      keychainId: publicKeychain.id,
      key: .mock,
    ))
    let context = self.accountContext(parent)

    try await expectErrorFrom {
      try await SaveAccountKey.resolve(
        with: .init(
          keychainId: publicKeychain.id,
          keyId: nil,
          key: .domain(domain: "example.com", scope: .webBrowsers),
          comment: nil,
          expiration: nil,
        ),
        in: context,
      )
    }.toContain("Public keychains")

    try await expectErrorFrom {
      try await DeleteAccountKey.resolve(
        with: .init(keychainId: publicKeychain.id, keyId: publicKey.id),
        in: context,
      )
    }.toContain("Public keychains")

    try await expectErrorFrom {
      try await SaveAccountKey.resolve(
        with: .init(
          keychainId: privateKeychain.id,
          keyId: nil,
          key: .skeleton(scope: .bundleId("com.example.app")),
          comment: nil,
          expiration: nil,
        ),
        in: context,
      )
    }.toContain("Mac Apps")
  }
}
