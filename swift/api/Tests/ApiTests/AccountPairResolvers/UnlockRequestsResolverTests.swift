import CustomDump
import Gertie
import XCTest
import XExpect

@testable import Api

final class UnlockRequestsResolverTests: ApiTestCase, @unchecked Sendable {
  func testSummaryAndPersonDetailReturnOnlyAccountRequests() async throws {
    let child = try await self.child(with: { $0.name = "Jude" }).withDevice()
    let keychain = try await self.db.create(Keychain(
      parentId: child.parent.id,
      name: "School",
    ))
    try await self.db.create(ChildKeychain(
      childId: child.model.id,
      keychainId: keychain.id,
    ))
    let first = try await self.db.create(UnlockRequest(
      computerUserId: child.computerUser.id,
      appBundleId: ".com.apple.Safari",
      url: "https://school.example.com/lesson?token=secret",
      hostname: "school.example.com",
      requestComment: "Homework",
    ))
    let second = try await self.db.create(UnlockRequest(
      computerUserId: child.computerUser.id,
      appBundleId: ".com.apple.Safari",
      ipAddress: "192.0.2.1",
    ))
    let other = try await self.child().withDevice()
    try await self.db.create(UnlockRequest(
      computerUserId: other.computerUser.id,
      appBundleId: ".com.apple.Safari",
      hostname: "other.example.com",
    ))

    let context = self.accountContext(child.parent)
    let summary = try await GetAccountUnlockRequestSummary.resolve(in: context)

    expect(summary.totalCount).toEqual(2)
    expect(summary.people).toHaveCount(1)
    expect(summary.people.first?.id).toEqual(child.model.id)
    expect(summary.people.first?.pendingCount).toEqual(2)
    expect(summary.people.first?.targets)
      .toEqual(["school.example.com", "192.0.2.1"])

    let detail = try await GetPersonUnlockRequests.resolve(
      with: .init(personId: child.model.id),
      in: context,
    )

    expect(detail.requests.map(\.id)).toEqual([first.id, second.id])
    expect(detail.requests.first?.requestComment).toEqual("Homework")
    expect(detail.keychains.map(\.id)).toEqual([keychain.id])
  }

  func testSummaryReturnsAllDistinctTargetsInRequestOrder() async throws {
    let child = try await self.child().withDevice()
    let targets = [
      "school.example.com", "youtube.com", "school.example.com",
      "scratch.mit.edu", "wikipedia.org", "khanacademy.org",
    ]
    for (index, target) in targets.enumerated() {
      var request = UnlockRequest(
        computerUserId: child.computerUser.id,
        appBundleId: ".com.apple.Safari",
        hostname: target,
      )
      request.createdAt = Date(timeIntervalSince1970: 1_700_000_000 + Double(index))
      try await self.db.create(request)
    }

    let output = try await GetAccountUnlockRequestSummary.resolve(
      in: self.accountContext(child.parent),
    )

    expect(output.totalCount).toEqual(6)
    expect(output.people.first?.pendingCount).toEqual(6)
    expect(output.people.first?.targets).toEqual([
      "school.example.com", "youtube.com", "scratch.mit.edu",
      "wikipedia.org", "khanacademy.org",
    ])
  }

  func testSummarySanitizesUrlTargets() async throws {
    let child = try await self.child().withDevice()
    try await self.db.create(UnlockRequest(
      computerUserId: child.computerUser.id,
      appBundleId: ".com.apple.Safari",
      url: "https://person:secret@school.example.com/lesson?token=secret#answers",
    ))

    let output = try await GetAccountUnlockRequestSummary.resolve(
      in: self.accountContext(child.parent),
    )

    expect(output.people.first?.targets)
      .toEqual(["school.example.com/lesson"])
  }

  func testPersonDetailCreatesAndReusesLegacyDefaultKeychain() async throws {
    let child = try await self.child().withDevice()
    try await self.db.create(UnlockRequest(
      computerUserId: child.computerUser.id,
      appBundleId: ".com.apple.Safari",
      hostname: "example.com",
    ))

    let output = try await GetPersonUnlockRequests.resolve(
      with: .init(personId: child.model.id),
      in: self.accountContext(child.parent),
    )

    let keychains = try await child.model.keychains(in: self.db)
    expect(keychains).toHaveCount(1)
    let keychain = try XCTUnwrap(keychains.first)
    expectNoDifference(output.keychains.map(\.id), [keychain.id])
    expectNoDifference(output.keychains.first?.name, "\(child.model.name)'s Keychain")
    expectNoDifference(output.keychains.first?.numKeys, 0)
    await expect(try keychain.keys(in: self.db)).toBeEmpty()

    let refreshed = try await GetPersonUnlockRequests.resolve(
      with: .init(personId: child.model.id),
      in: self.accountContext(child.parent),
    )
    expectNoDifference(refreshed.keychains.map(\.id), [keychain.id])
    await expect(try child.model.keychains(in: self.db)).toHaveCount(1)
  }

  func testInvalidKeyRollsBackEntireUnlockDecisionBatch() async throws {
    let child = try await self.child().withDevice()
    let first = try await self.db.create(UnlockRequest(
      computerUserId: child.computerUser.id,
      appBundleId: ".com.apple.Safari",
      hostname: "school.example.com",
    ))
    let second = try await self.db.create(UnlockRequest(
      computerUserId: child.computerUser.id,
      appBundleId: ".com.apple.Safari",
      hostname: "example.com",
    ))
    let invalidKeys: [(Gertie.Key, String)] = [
      (.domain(domain: "cloudflare-ech.com", scope: .webBrowsers), "cloudflare-ech.com"),
      (.anySubdomain(domain: "cloudflare-ech.com", scope: .webBrowsers), "cloudflare-ech.com"),
      (.domain(domain: "foo.cloudflare-ech.com", scope: .webBrowsers), "cloudflare-ech.com"),
      (.domainRegex(pattern: "(unbalanced", scope: .webBrowsers), "invalid regex pattern"),
      (.domainRegex(pattern: ".*", scope: .webBrowsers), "matches the empty string"),
      (.domainRegex(pattern: ".+", scope: .webBrowsers), "matches arbitrary hostnames"),
    ]

    for (key, error) in invalidKeys {
      try await expectErrorFrom {
        try await DecideUnlockRequests.resolve(
          with: .init(
            personId: child.model.id,
            decisions: [
              .init(
                requestIds: [first.id],
                action: .acceptedKey(
                  keychainId: nil,
                  key: .domain(domain: "school.example.com", scope: .webBrowsers),
                  comment: nil,
                  expiration: nil,
                ),
              ),
              .init(
                requestIds: [second.id],
                action: .acceptedKey(
                  keychainId: nil,
                  key: key,
                  comment: nil,
                  expiration: nil,
                ),
              ),
            ],
            responseComment: nil,
          ),
          in: self.accountContext(child.parent),
        )
      }.toContain(error)

      let firstAfter = try await self.db.find(first.id)
      let secondAfter = try await self.db.find(second.id)
      expectNoDifference(firstAfter.status, .pending)
      expectNoDifference(secondAfter.status, .pending)
      await expect(try child.model.keychains(in: self.db)).toBeEmpty()
      expect(self.sent.websocketMessages).toBeEmpty()
    }
  }

  func testAcceptsValidDomainRegexKey() async throws {
    let child = try await self.child().withDevice()
    let request = try await self.db.create(UnlockRequest(
      computerUserId: child.computerUser.id,
      appBundleId: ".com.apple.Safari",
      hostname: "harvard.edu",
    ))
    let key = Gertie.Key.domainRegex(pattern: "^harvard\\.edu$", scope: .webBrowsers)

    let output = try await DecideUnlockRequests.resolve(
      with: .init(
        personId: child.model.id,
        decisions: [.init(
          requestIds: [request.id],
          action: .acceptedKey(keychainId: nil, key: key, comment: nil, expiration: nil),
        )],
        responseComment: nil,
      ),
      in: self.accountContext(child.parent),
    )

    expectNoDifference(output.handledCount, 1)
    expectNoDifference(output.remainingCount, 0)
    let resolved = try await self.db.find(request.id)
    expectNoDifference(resolved.status, .accepted)
    let keychains = try await child.model.keychains(in: self.db)
    let keychain = try XCTUnwrap(keychains.first)
    let keys = try await keychain.keys(in: self.db)
    expectNoDifference(keys.map(\.key), [key])
  }

  func testAcceptGroupResolvesEveryRequestAndCreatesOneDefaultKey() async throws {
    let child = try await self.child().withDevice {
      $0.appVersion = "2.9.0"
    }
    let first = try await self.db.create(UnlockRequest(
      computerUserId: child.computerUser.id,
      appBundleId: ".com.apple.Safari",
      hostname: "example.com",
    ))
    let second = try await self.db.create(UnlockRequest(
      computerUserId: child.computerUser.id,
      appBundleId: ".com.apple.Safari",
      hostname: "example.com",
    ))
    let key = Gertie.Key.anySubdomain(domain: "example.com", scope: .webBrowsers)

    let output = try await DecideUnlockRequests.resolve(
      with: .init(
        personId: child.model.id,
        decisions: [.init(
          requestIds: [first.id, second.id],
          action: .acceptedKey(
            keychainId: nil,
            key: key,
            comment: "School",
            expiration: nil,
          ),
        )],
        responseComment: nil,
      ),
      in: self.accountContext(child.parent),
    )

    expect(output.handledCount).toEqual(2)
    expect(output.skippedCount).toEqual(0)
    expect(output.remainingCount).toEqual(0)
    await expect(try self.db.find(first.id).status).toEqual(.accepted)
    await expect(try self.db.find(second.id).status).toEqual(.accepted)

    let keychains = try await child.model.keychains(in: self.db)
    expect(keychains).toHaveCount(1)
    let createdKeychain = try XCTUnwrap(keychains.first)
    let keys = try await createdKeychain.keys(in: self.db)
    expect(keys).toHaveCount(1)
    expect(keys.first?.key).toEqual(key)
    expect(keys.first?.comment).toEqual("School")

    expect(sent.websocketMessages).toEqual([
      .init(.userUpdated, to: .usersWith(keychain: createdKeychain.id)),
      .init(
        .unlockRequestsHandled(
          ids: [first.id.rawValue, second.id.rawValue],
          accepted: 2,
          rejected: 0,
          targets: ["example.com", "example.com"],
        ),
        to: .userDevice(child.computerUser.id),
      ),
    ])
  }

  func testStaleAcceptedDecisionDoesNotCreateDefaultKeychain() async throws {
    let child = try await self.child().withDevice()
    let request = try await self.db.create(UnlockRequest(
      computerUserId: child.computerUser.id,
      appBundleId: ".com.apple.Safari",
      hostname: "example.com",
      status: .accepted,
    ))

    let output = try await DecideUnlockRequests.resolve(
      with: .init(
        personId: child.model.id,
        decisions: [.init(
          requestIds: [request.id],
          action: .acceptedKey(
            keychainId: nil,
            key: .domain(domain: "example.com", scope: .webBrowsers),
            comment: nil,
            expiration: nil,
          ),
        )],
        responseComment: nil,
      ),
      in: self.accountContext(child.parent),
    )

    expect(output.handledCount).toEqual(0)
    expect(output.skippedCount).toEqual(1)
    await expect(try child.model.keychains(in: self.db)).toBeEmpty()
  }

  func testRejectSkipsResolvedRequestsAndNotifiesEachOriginatingMac() async throws {
    let child = try await self.child(with: { $0.name = "Jude" })
    let firstDevice = try await child.withDevice { $0.appVersion = "2.9.0" }
    let secondDevice = try await child.withDevice { $0.appVersion = "2.9.0" }
    let first = try await self.db.create(UnlockRequest(
      computerUserId: firstDevice.computerUser.id,
      appBundleId: ".com.apple.Safari",
      hostname: "youtube.com",
    ))
    let second = try await self.db.create(UnlockRequest(
      computerUserId: secondDevice.computerUser.id,
      appBundleId: ".com.apple.Safari",
      hostname: "reddit.com",
    ))
    let resolved = try await self.db.create(UnlockRequest(
      computerUserId: firstDevice.computerUser.id,
      appBundleId: ".com.apple.Safari",
      hostname: "old.example.com",
      status: .accepted,
    ))

    let output = try await DecideUnlockRequests.resolve(
      with: .init(
        personId: child.model.id,
        decisions: [
          .init(requestIds: [first.id, resolved.id], action: .rejected),
          .init(requestIds: [second.id], action: .rejected),
        ],
        responseComment: "Not right now",
      ),
      in: self.accountContext(child.parent),
    )

    expect(output.handledCount).toEqual(2)
    expect(output.skippedCount).toEqual(1)
    expect(output.remainingCount).toEqual(0)
    await expect(try self.db.find(first.id).responseComment).toEqual("Not right now")
    await expect(try self.db.find(second.id).responseComment).toEqual("Not right now")
    expect(sent.websocketMessages).toHaveCount(2)
    expect(sent.websocketMessages.contains {
      $0.matcher == .userDevice(firstDevice.computerUser.id)
    }).toBeTrue()
    expect(sent.websocketMessages.contains {
      $0.matcher == .userDevice(secondDevice.computerUser.id)
    }).toBeTrue()
  }

  func testRejectsUnrestrictedAccessForAnAppThatDidNotMakeTheRequests() async throws {
    let child = try await self.child().withDevice()
    let request = try await self.db.create(UnlockRequest(
      computerUserId: child.computerUser.id,
      appBundleId: "com.example.requested",
      hostname: "example.com",
    ))

    try await expectErrorFrom {
      try await DecideUnlockRequests.resolve(
        with: .init(
          personId: child.model.id,
          decisions: [.init(
            requestIds: [request.id],
            action: .acceptedApp(scope: .bundleId("com.example.other")),
          )],
          responseComment: nil,
        ),
        in: self.accountContext(child.parent),
      )
    }.toContain("badRequest")
  }

  func testRejectsRequestFromAnotherAccountPerson() async throws {
    let child = try await self.child().withDevice()
    let other = try await self.child().withDevice()
    let request = try await self.db.create(UnlockRequest(
      computerUserId: other.computerUser.id,
      appBundleId: ".com.apple.Safari",
      hostname: "example.com",
    ))

    try await expectErrorFrom {
      try await DecideUnlockRequests.resolve(
        with: .init(
          personId: child.model.id,
          decisions: [.init(requestIds: [request.id], action: .rejected)],
          responseComment: nil,
        ),
        in: self.accountContext(child.parent),
      )
    }.toContain("notFound")
  }
}
