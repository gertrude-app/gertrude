import Gertie
import XCTest
import XExpect

@testable import Api

final class HandleUnlockRequestsTests: ApiTestCase, @unchecked Sendable {
  func testAcceptSingleRequestNewApp() async throws {
    let child = try await self.child().withDevice {
      $0.appVersion = "2.9.0"
    }

    let keychain = try await self.db.create(Keychain(
      parentId: child.parent.id,
      name: "School",
      isPublic: false,
    ))
    try await self.db.create(ChildKeychain(
      childId: child.model.id,
      keychainId: keychain.id,
    ))

    var request = UnlockRequest.mock
    request.computerUserId = child.computerUser.id
    request.status = .pending
    request.hostname = "khanacademy.org"
    try await self.db.create(request)

    let key = Gertie.Key.domain(domain: "khanacademy.org", scope: .webBrowsers)
    let output = try await HandleUnlockRequests.resolve(
      with: .init(
        decisions: [.init(
          unlockRequestId: request.id,
          status: .accepted,
          key: .init(keychainId: keychain.id, key: key, comment: "looks good"),
          responseComment: nil,
        )],
        duplicateRequestIds: [],
      ),
      in: context(child.parent),
    )

    expect(output).toEqual(.success)

    let retrieved = try await self.db.find(request.id)
    expect(retrieved.status).toEqual(.accepted)

    let keys = try await keychain.keys(in: self.db)
    expect(keys).toHaveCount(1)
    expect(keys[0].key).toEqual(key)
    expect(keys[0].comment).toEqual("looks good")

    expect(sent.websocketMessages).toEqual([
      .init(.userUpdated, to: .usersWith(keychain: keychain.id)),
      .init(
        .unlockRequestsHandled(
          ids: [request.id.rawValue],
          accepted: 1,
          rejected: 0,
          targets: ["khanacademy.org"],
        ),
        to: .userDevice(child.computerUser.id),
      ),
    ])
  }

  func testRejectSingleRequestNewApp() async throws {
    let child = try await self.child().withDevice {
      $0.appVersion = "2.9.0"
    }

    var request = UnlockRequest.mock
    request.computerUserId = child.computerUser.id
    request.status = .pending
    request.hostname = "youtube.com"
    try await self.db.create(request)

    let output = try await HandleUnlockRequests.resolve(
      with: .init(
        decisions: [.init(
          unlockRequestId: request.id,
          status: .rejected,
          key: nil,
          responseComment: "not allowed",
        )],
        duplicateRequestIds: [],
      ),
      in: context(child.parent),
    )

    expect(output).toEqual(.success)

    let retrieved = try await self.db.find(request.id)
    expect(retrieved.status).toEqual(.rejected)
    expect(retrieved.responseComment).toEqual("not allowed")

    expect(sent.websocketMessages).toEqual([
      .init(
        .unlockRequestsHandled(
          ids: [request.id.rawValue],
          accepted: 0,
          rejected: 1,
          targets: ["youtube.com"],
        ),
        to: .userDevice(child.computerUser.id),
      ),
    ])
  }

  func testMixedDecisionsNewAppDedupsUserUpdatedPerKeychain() async throws {
    let child = try await self.child().withDevice {
      $0.appVersion = "2.9.0"
    }

    let keychain = try await self.db.create(Keychain(
      parentId: child.parent.id,
      name: "School",
      isPublic: false,
    ))
    try await self.db.create(ChildKeychain(
      childId: child.model.id,
      keychainId: keychain.id,
    ))

    var accept1 = UnlockRequest.mock
    accept1.computerUserId = child.computerUser.id
    accept1.status = .pending
    accept1.hostname = "coolmath.com"
    try await self.db.create(accept1)

    var accept2 = UnlockRequest.mock
    accept2.computerUserId = child.computerUser.id
    accept2.status = .pending
    accept2.hostname = "khanacademy.org"
    try await self.db.create(accept2)

    var reject = UnlockRequest.mock
    reject.computerUserId = child.computerUser.id
    reject.status = .pending
    reject.hostname = "youtube.com"
    try await self.db.create(reject)

    var dupe = UnlockRequest.mock
    dupe.computerUserId = child.computerUser.id
    dupe.status = .pending
    dupe.hostname = "coolmath.com"
    try await self.db.create(dupe)

    let key1 = Gertie.Key.domain(domain: "coolmath.com", scope: .webBrowsers)
    let key2 = Gertie.Key.domain(domain: "khanacademy.org", scope: .webBrowsers)
    let output = try await HandleUnlockRequests.resolve(
      with: .init(
        decisions: [
          .init(
            unlockRequestId: accept1.id,
            status: .accepted,
            key: .init(keychainId: keychain.id, key: key1),
            responseComment: nil,
          ),
          .init(
            unlockRequestId: accept2.id,
            status: .accepted,
            key: .init(keychainId: keychain.id, key: key2),
            responseComment: nil,
          ),
          .init(
            unlockRequestId: reject.id,
            status: .rejected,
            key: nil,
            responseComment: "nope",
          ),
        ],
        duplicateRequestIds: [dupe.id],
      ),
      in: context(child.parent),
    )

    expect(output).toEqual(.success)

    let dupeExists = try? await self.db.find(dupe.id) as UnlockRequest
    expect(dupeExists).toBeNil()

    // only ONE .userUpdated for the keychain despite two accepts to same keychain
    // plus one aggregated .unlockRequestsHandled
    expect(sent.websocketMessages).toHaveCount(2)
    expect(sent.websocketMessages[0]).toEqual(
      .init(.userUpdated, to: .usersWith(keychain: keychain.id)),
    )
    expect(sent.websocketMessages[1]).toEqual(
      .init(
        .unlockRequestsHandled(
          ids: [accept1.id.rawValue, accept2.id.rawValue, reject.id.rawValue],
          accepted: 2,
          rejected: 1,
          targets: ["coolmath.com", "khanacademy.org", "youtube.com"],
        ),
        to: .userDevice(child.computerUser.id),
      ),
    )
  }

  func testOldAppGetIndividualMessages() async throws {
    let child = try await self.child().withDevice {
      $0.appVersion = "2.4.0"
    }

    let keychain = try await self.db.create(Keychain(
      parentId: child.parent.id,
      name: "School",
      isPublic: false,
    ))
    try await self.db.create(ChildKeychain(
      childId: child.model.id,
      keychainId: keychain.id,
    ))

    var accept = UnlockRequest.mock
    accept.computerUserId = child.computerUser.id
    accept.status = .pending
    accept.hostname = "coolmath.com"
    try await self.db.create(accept)

    var reject = UnlockRequest.mock
    reject.computerUserId = child.computerUser.id
    reject.status = .pending
    reject.hostname = "youtube.com"
    try await self.db.create(reject)

    let key = Gertie.Key.domain(domain: "coolmath.com", scope: .webBrowsers)
    let output = try await HandleUnlockRequests.resolve(
      with: .init(
        decisions: [
          .init(
            unlockRequestId: accept.id,
            status: .accepted,
            key: .init(keychainId: keychain.id, key: key),
            responseComment: nil,
          ),
          .init(
            unlockRequestId: reject.id,
            status: .rejected,
            key: nil,
            responseComment: "nope",
          ),
        ],
        duplicateRequestIds: [],
      ),
      in: context(child.parent),
    )

    expect(output).toEqual(.success)

    // old app: deduped .userUpdated + individual .unlockRequestUpdated_v2 per decision
    expect(sent.websocketMessages).toEqual([
      .init(.userUpdated, to: .usersWith(keychain: keychain.id)),
      .init(
        .unlockRequestUpdated_v2(
          id: accept.id.rawValue,
          status: .accepted,
          target: "coolmath.com",
          comment: nil,
        ),
        to: .userDevice(child.computerUser.id),
      ),
      .init(
        .unlockRequestUpdated_v2(
          id: reject.id.rawValue,
          status: .rejected,
          target: "youtube.com",
          comment: "nope",
        ),
        to: .userDevice(child.computerUser.id),
      ),
    ])
  }

  func testAcceptWithExistingIdenticalKeyMergesInsteadOfDuplicating() async throws {
    let child = try await self.child().withDevice {
      $0.appVersion = "2.9.0"
    }

    let keychain = try await self.db.create(Keychain(
      parentId: child.parent.id,
      name: "School",
      isPublic: false,
    ))
    try await self.db.create(ChildKeychain(
      childId: child.model.id,
      keychainId: keychain.id,
    ))

    let key = Gertie.Key.domain(domain: "example.com", scope: .webBrowsers)
    let existing = try await self.db.create(Key(keychainId: keychain.id, key: key))

    var request = UnlockRequest.mock
    request.computerUserId = child.computerUser.id
    request.status = .pending
    request.hostname = "example.com"
    try await self.db.create(request)

    let output = try await HandleUnlockRequests.resolve(
      with: .init(
        decisions: [.init(
          unlockRequestId: request.id,
          status: .accepted,
          key: .init(
            keychainId: keychain.id,
            key: key,
            comment: "updated comment",
            expiration: Date(addingDays: 30),
          ),
          responseComment: nil,
        )],
        duplicateRequestIds: [],
      ),
      in: context(child.parent),
    )

    expect(output).toEqual(.success)

    let keys = try await keychain.keys(in: self.db)
    expect(keys).toHaveCount(1)
    guard let merged = keys.first else { return }
    expect(merged.id).toEqual(existing.id)
    expect(merged.comment).toEqual("updated comment")
    expect(merged.deletedAt).not.toBeNil()
  }
}
