import XCore
import XCTest
import XExpect

@testable import Api

final class KeyResolverTests: ApiTestCase, @unchecked Sendable {
  func prepare() async throws -> (SaveKey.Input, ParentWithKeychainEntities) {
    let parent = try await self.parent().withKeychain()
    let input = SaveKey.Input(
      isNew: true,
      id: .init(),
      keychainId: parent.keychain.id,
      key: .anySubdomain(domain: .init(string: "fixture.com"), scope: .webBrowsers),
      comment: "a comment",
      expiration: nil,
    )
    return (input, parent)
  }

  func testCreateKeyRecord() async throws {
    let (input, admin) = try await prepare()

    let output = try await SaveKey.resolve(with: input, in: admin.context)
    expect(output).toEqual(.success)

    let key = try await self.db.find(input.id)
    expect(key.comment).toEqual(input.comment)
    expect(key.key).toEqual(input.key)
    expect(sent.websocketMessages)
      .toEqual([.init(.userUpdated, to: .usersWith(keychain: admin.keychain.id))])
  }

  func testCreateKeyRecordWithExpiration() async throws {
    var (input, admin) = try await prepare()
    input.expiration = Date(addingDays: 5)

    let output = try await SaveKey.resolve(with: input, in: admin.context)
    expect(output).toEqual(.success)

    let key = try await self.db.find(input.id)
    expect(key.deletedAt).not.toBeNil()
  }

  func testCreateKeyRecordWithUnknownKeychainIdFails() async throws {
    var (input, admin) = try await prepare()
    input.keychainId = .init()

    let output = try? await SaveKey.resolve(with: input, in: admin.context)
    expect(output).toBeNil()
  }

  func testUpdateKeyRecord() async throws {
    var (input, admin) = try await prepare()
    let key = try await self.db.create(Key(keychainId: admin.keychain.id, key: .mock))

    input.isNew = false
    input.id = key.id
    input.comment = "updated comment"
    input.key = .anySubdomain(domain: .init(string: "updated.com"), scope: .unrestricted)

    let output = try await SaveKey.resolve(with: input, in: admin.context)
    expect(output).toEqual(.success)

    let updatedKey = try await self.db.find(key.id)
    expect(updatedKey.comment).toEqual(input.comment)
    expect(updatedKey.key).toEqual(input.key)
    expect(sent.websocketMessages)
      .toEqual([.init(.userUpdated, to: .usersWith(keychain: admin.keychain.id))])
  }

  func testCreateDuplicateKeySilentlyAccepts() async throws {
    let (input, admin) = try await prepare()
    _ = try await SaveKey.resolve(with: input, in: admin.context)

    var dupeInput = input
    dupeInput.id = .init()
    dupeInput.comment = nil
    let output = try await SaveKey.resolve(with: dupeInput, in: admin.context)
    expect(output).toEqual(.success)

    let keys = try await admin.keychain.keys(in: self.db)
    let matching = keys.filter { $0.key == input.key }
    expect(matching.count).toEqual(1)
    expect(matching.first?.comment).toEqual("a comment")
  }

  func testCreateDuplicateKeyUpdatesComment() async throws {
    let (input, admin) = try await prepare()
    _ = try await SaveKey.resolve(with: input, in: admin.context)

    var dupeInput = input
    dupeInput.id = .init()
    dupeInput.comment = "updated comment"
    let output = try await SaveKey.resolve(with: dupeInput, in: admin.context)
    expect(output).toEqual(.success)

    let keys = try await admin.keychain.keys(in: self.db)
    let matching = keys.filter { $0.key == input.key }
    expect(matching.count).toEqual(1)
    expect(matching.first?.comment).toEqual("updated comment")
  }

  func testCreateDuplicateKeyWithFutureExpirationDeduplicates() async throws {
    var (input, admin) = try await prepare()
    input.expiration = Date(addingDays: 5)
    _ = try await SaveKey.resolve(with: input, in: admin.context)

    var dupeInput = input
    dupeInput.id = .init()
    dupeInput.comment = "second try"
    dupeInput.expiration = nil
    let output = try await SaveKey.resolve(with: dupeInput, in: admin.context)
    expect(output).toEqual(.success)

    let keys = try await admin.keychain.keys(in: self.db)
    let matching = keys.filter { $0.key == input.key }
    expect(matching.count).toEqual(1)
    expect(matching.first?.comment).toEqual("second try")
    expect(matching.first?.deletedAt).toBeNil()
  }

  func testEditKeyToDuplicateMergesAndDeletes() async throws {
    let (input, admin) = try await prepare()
    _ = try await SaveKey.resolve(with: input, in: admin.context)
    let secondKey = try await self.db.create(Key(
      keychainId: admin.keychain.id,
      key: .domain(domain: "other.com", scope: .unrestricted),
    ))

    var editInput = input
    editInput.isNew = false
    editInput.id = secondKey.id
    editInput.key = input.key
    editInput.comment = "merged comment"

    let output = try await SaveKey.resolve(with: editInput, in: admin.context)
    expect(output).toEqual(.success)

    let keys = try await admin.keychain.keys(in: self.db)
    let matching = keys.filter { $0.key == input.key }
    expect(matching.count).toEqual(1)
    expect(matching.first?.comment).toEqual("merged comment")
    let others = keys.filter { $0.key == secondKey.key }
    expect(others.count).toEqual(0)
  }

  func testEditKeyToDuplicateClearsComment() async throws {
    let (input, admin) = try await prepare()
    _ = try await SaveKey.resolve(with: input, in: admin.context)
    let secondKey = try await self.db.create(Key(
      keychainId: admin.keychain.id,
      key: .domain(domain: "other.com", scope: .unrestricted),
    ))

    var editInput = input
    editInput.isNew = false
    editInput.id = secondKey.id
    editInput.key = input.key
    editInput.comment = nil

    let output = try await SaveKey.resolve(with: editInput, in: admin.context)
    expect(output).toEqual(.success)

    let keys = try await admin.keychain.keys(in: self.db)
    let matching = keys.filter { $0.key == input.key }
    expect(matching.count).toEqual(1)
    expect(matching.first?.comment).toBeNil()
  }

  func testRejectsSkeletonKeyForNonPublicKeychain() async throws {
    var (input, admin) = try await prepare()
    var keychain = admin.keychain
    keychain.isPublic = false
    try await self.db.update(keychain)
    input.key = .skeleton(scope: .bundleId("com.example.app"))

    try await expectErrorFrom {
      try await SaveKey.resolve(with: input, in: admin.context)
    }.toContain("skeleton")
  }

  func testAcceptsSkeletonKeyForPublicKeychain() async throws {
    var (input, admin) = try await prepare()
    var keychain = admin.keychain
    keychain.isPublic = true
    try await self.db.update(keychain)
    input.key = .skeleton(scope: .bundleId("com.example.app"))

    let output = try await SaveKey.resolve(with: input, in: admin.context)
    expect(output).toEqual(.success)

    let key = try await self.db.find(input.id)
    expect(key.key).toEqual(input.key)
  }

  func testRejectsCloudflareEchKey() async throws {
    var (input, admin) = try await prepare()
    input.key = .anySubdomain(domain: .init(string: "cloudflare-ech.com"), scope: .unrestricted)

    try await expectErrorFrom {
      try await SaveKey.resolve(with: input, in: admin.context)
    }.toContain("cloudflare-ech.com")

    input.key = .domain(domain: .init(string: "foo.cloudflare-ech.com"), scope: .unrestricted)
    try await expectErrorFrom {
      try await SaveKey.resolve(with: input, in: admin.context)
    }.toContain("cloudflare-ech.com")
  }

  func testUpdateKeyRecordWithExpiration() async throws {
    var (input, admin) = try await prepare()
    let key = try await self.db.create(Key(keychainId: admin.keychain.id, key: .mock))

    input.isNew = false
    input.id = key.id
    input.comment = "updated comment"
    input.key = .anySubdomain(domain: .init(string: "updated.com"), scope: .unrestricted)
    input.expiration = Date(addingDays: 5)

    let output = try await SaveKey.resolve(with: input, in: admin.context)
    expect(output).toEqual(.success)

    let updatedKey = try await self.db.find(key.id)
    expect(updatedKey.comment).toEqual(input.comment)
    expect(updatedKey.key).toEqual(input.key)
    expect(updatedKey.deletedAt).not.toBeNil()
  }

  func testRejectsUncompilableDomainRegex() async throws {
    var (input, admin) = try await prepare()
    input.key = .domainRegex(pattern: "(unbalanced", scope: .unrestricted)
    try await expectErrorFrom {
      try await SaveKey.resolve(with: input, in: admin.context)
    }.toContain("invalid regex pattern")
  }

  func testRejectsTooLongDomainRegex() async throws {
    var (input, admin) = try await prepare()
    let pattern = "^" + String(repeating: "a", count: 200) + "\\.edu$"
    input.key = .domainRegex(pattern: .init(pattern), scope: .unrestricted)
    try await expectErrorFrom {
      try await SaveKey.resolve(with: input, in: admin.context)
    }.toContain("too long")
  }

  func testRejectsDomainRegexThatMatchesEmptyString() async throws {
    var (input, admin) = try await prepare()
    for broad in [".*", "^$", "()", ".?"] {
      input.key = .domainRegex(pattern: .init(broad), scope: .unrestricted)
      try await expectErrorFrom {
        try await SaveKey.resolve(with: input, in: admin.context)
      }.toContain("matches the empty string")
    }
  }

  func testRejectsDomainRegexThatMatchesArbitraryHostnames() async throws {
    var (input, admin) = try await prepare()
    input.key = .domainRegex(pattern: ".+", scope: .unrestricted)
    try await expectErrorFrom {
      try await SaveKey.resolve(with: input, in: admin.context)
    }.toContain("matches arbitrary hostnames")
  }

  func testRejectsDomainRegexWithNoLiteralAlphanumeric() async throws {
    var (input, admin) = try await prepare()
    input.key = .domainRegex(pattern: "\\.\\.", scope: .unrestricted)
    try await expectErrorFrom {
      try await SaveKey.resolve(with: input, in: admin.context)
    }.toContain("literal alphanumeric")
  }

  func testAcceptsValidRealRegex() async throws {
    var (input, admin) = try await prepare()
    input.key = .domainRegex(pattern: "^harvard\\.edu$", scope: .unrestricted)
    let output = try await SaveKey.resolve(with: input, in: admin.context)
    expect(output).toEqual(.success)
  }

  func testAcceptsAlternationRegex() async throws {
    var (input, admin) = try await prepare()
    input.key = .domainRegex(pattern: "^(harvard|mit)\\.edu$", scope: .unrestricted)
    let output = try await SaveKey.resolve(with: input, in: admin.context)
    expect(output).toEqual(.success)
  }

  func testAcceptsAnchoredTldRegex() async throws {
    var (input, admin) = try await prepare()
    input.key = .domainRegex(pattern: "^.*\\.edu$", scope: .unrestricted)
    let output = try await SaveKey.resolve(with: input, in: admin.context)
    expect(output).toEqual(.success)
  }
}
