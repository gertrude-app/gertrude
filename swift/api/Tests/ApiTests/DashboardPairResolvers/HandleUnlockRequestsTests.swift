import DuetSQL
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

  func testAcceptWithSkeletonKeyForNonPublicKeychainRejected() async throws {
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
    request.hostname = "minecraftservices.com"
    try await self.db.create(request)

    let key = Gertie.Key.skeleton(scope: .identifiedAppSlug("minecraft"))
    try await expectErrorFrom {
      try await HandleUnlockRequests.resolve(
        with: .init(
          decisions: [.init(
            unlockRequestId: request.id,
            status: .accepted,
            key: .init(keychainId: keychain.id, key: key),
            responseComment: nil,
          )],
          duplicateRequestIds: [],
        ),
        in: self.context(child.parent),
      )
    }.toContain("skeleton")

    let keys = try await keychain.keys(in: self.db)
    expect(keys).toHaveCount(0) // no key created
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

  func testGrantAppWritesUnrestrictedMacAppRowNoKey() async throws {
    let child = try await self.child().withDevice {
      $0.appVersion = "2.9.0"
    }

    var req1 = UnlockRequest.mock
    req1.computerUserId = child.computerUser.id
    req1.status = .pending
    req1.hostname = "core.cloud.unity3d.com"
    try await self.db.create(req1)

    var req2 = UnlockRequest.mock
    req2.computerUserId = child.computerUser.id
    req2.status = .pending
    req2.hostname = "download.unity3d.com"
    try await self.db.create(req2)

    let scope = AppScope.Single.identifiedAppSlug("unity-hub")
    let output = try await HandleUnlockRequests.resolve(
      with: .init(
        decisions: [
          .init(unlockRequestId: req1.id, status: .accepted, grantAppScope: scope),
          .init(unlockRequestId: req2.id, status: .accepted, grantAppScope: scope),
        ],
        duplicateRequestIds: [],
      ),
      in: context(child.parent),
    )

    expect(output).toEqual(.success)
    await expect(try self.db.find(req1.id).status).toEqual(.accepted)
    await expect(try self.db.find(req2.id).status).toEqual(.accepted)

    // exactly ONE row despite two decisions for the same app (batch dedup)
    let rows = try await UnrestrictedMacApp.query()
      .where(.childId == child.model.id)
      .all(in: self.db)
    expect(rows).toHaveCount(1)
    expect(rows[0].scope).toEqual(scope)

    // one child-level .userUpdated + one aggregated handled message with both hosts
    expect(sent.websocketMessages).toEqual([
      .init(.userUpdated, to: .user(child.model.id)),
      .init(
        .unlockRequestsHandled(
          ids: [req1.id.rawValue, req2.id.rawValue],
          accepted: 2,
          rejected: 0,
          targets: ["core.cloud.unity3d.com", "download.unity3d.com"],
        ),
        to: .userDevice(child.computerUser.id),
      ),
    ])
  }

  func testGrantAppSkipsExistingRowAndOmitsUserUpdated() async throws {
    let child = try await self.child().withDevice {
      $0.appVersion = "2.9.0"
    }

    let scope = AppScope.Single.identifiedAppSlug("unity-hub")
    try await self.db.create(UnrestrictedMacApp(scope: scope, childId: child.model.id))

    var req = UnlockRequest.mock
    req.computerUserId = child.computerUser.id
    req.status = .pending
    req.hostname = "core.cloud.unity3d.com"
    try await self.db.create(req)

    let output = try await HandleUnlockRequests.resolve(
      with: .init(
        decisions: [.init(unlockRequestId: req.id, status: .accepted, grantAppScope: scope)],
        duplicateRequestIds: [],
      ),
      in: context(child.parent),
    )

    expect(output).toEqual(.success)

    let rows = try await UnrestrictedMacApp.query()
      .where(.childId == child.model.id)
      .all(in: self.db)
    expect(rows).toHaveCount(1) // still just the pre-existing row

    // nothing newly granted → no .userUpdated, only the handled message
    expect(sent.websocketMessages).toEqual([
      .init(
        .unlockRequestsHandled(
          ids: [req.id.rawValue],
          accepted: 1,
          rejected: 0,
          targets: ["core.cloud.unity3d.com"],
        ),
        to: .userDevice(child.computerUser.id),
      ),
    ])
  }
}
