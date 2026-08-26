import Dependencies
import DuetSQL
import Gertie
import XCTest
import XExpect

@testable import Api

final class GetChildResolverTests: ApiTestCase, @unchecked Sendable {
  func testFetchIncludingPendingDevice() async throws {
    let child = try await self.child()

    let pendingCode = uniqueClaimCode()
    let pendingDevice = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    try await self.createClaim(
      .blockerSupervise,
      pendingDevice.id,
      child.id,
      code: pendingCode,
      expiresAt: .distantFuture,
      claimedAt: .reference,
    )
    try await self.db.create(BlockerApp.Supervision(
      deviceId: pendingDevice.id,
      supervisedAt: nil, // <-- pending
    ))

    let completedDevice = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    try await self.createClaim(
      .blockerSupervise,
      completedDevice.id,
      child.id,
      expiresAt: .distantFuture,
      claimedAt: .reference,
    )
    try await self.db.create(BlockerApp.Supervision(
      deviceId: completedDevice.id,
      supervisedAt: .reference, // <-- not pending
    ))

    let output = try await withDependencies {
      $0.websockets.status = { _ in .filterOn }
    } operation: {
      try await GetChild.resolve(with: child.id, in: context(child.parent))
    }

    expect(output.name).toEqual(child.name)
    expect(output.iosDevices.count).toEqual(2)
    expect(output.iosDevices[0].id).toEqual(pendingDevice.id)
    expect(output.iosDevices[0].pendingClaimCode).toEqual(pendingCode)
    expect(output.iosDevices[0].musicConnected).toEqual(false)
    expect(output.iosDevices[1].id).toEqual(completedDevice.id)
    expect(output.iosDevices[1].pendingClaimCode).toBeNil()
    expect(output.iosDevices[1].musicConnected).toEqual(false)
  }

  func testAbandonedSupervisionCodeAfterScreenTimeConnectDoesNotNag() async throws {
    let child = try await self.child()

    let familyConnectedDevice = try await self.db.create(IOSDevice.random {
      $0.childId = child.id // <-- connected, must have been thru post screen-time offer
    })
    // an unclaimed claim code from an abandoned supervision attempt
    try await self.createClaim(
      .blockerSupervise,
      familyConnectedDevice.id,
      expiresAt: .reference - .days(7),
    )
    try await self.db.create(BlockerApp.Supervision(
      deviceId: familyConnectedDevice.id,
      supervisedAt: nil,
    ))

    let output = try await withDependencies {
      $0.websockets.status = { _ in .filterOn }
    } operation: {
      try await GetChild.resolve(with: child.id, in: context(child.parent))
    }

    expect(output.iosDevices.count).toEqual(1)
    expect(output.iosDevices[0].id).toEqual(familyConnectedDevice.id)
    expect(output.iosDevices[0].pendingClaimCode).toBeNil() // <-- so they don't get nagged
    expect(output.iosDevices[0].musicConnected).toEqual(false)
  }

  func testFetchMarksMusicConnectedDevices() async throws {
    let child = try await self.child()
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    let install = try await self.db.create(
      MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"),
    )
    try await self.db.create(MusicApp.Token(installId: install.id))

    let output = try await withDependencies {
      $0.websockets.status = { _ in .filterOn }
    } operation: {
      try await GetChild.resolve(with: child.id, in: context(child.parent))
    }

    expect(output.iosDevices.count).toEqual(1)
    expect(output.iosDevices[0].id).toEqual(device.id)
    expect(output.iosDevices[0].musicConnected).toEqual(true)
  }

  func testIncludesUnrestrictedAppsAndPublicProjection() async throws {
    let child = try await self.child()

    try await self.db.create([
      UnrestrictedMacApp(scope: .bundleId("com.apple.Safari"), childId: child.id),
      UnrestrictedMacApp(scope: .identifiedAppSlug("chess"), childId: child.id),
    ])

    let privateKeychain = try await self.db.create(Keychain(
      parentId: child.parent.model.id,
      name: "private kc",
      isPublic: false,
    ))
    let publicKeychain = try await self.db.create(Keychain(
      parentId: child.parent.model.id,
      name: "public kc",
      isPublic: true,
    ))
    try await self.db.create([
      ChildKeychain(childId: child.id, keychainId: privateKeychain.id),
      ChildKeychain(childId: child.id, keychainId: publicKeychain.id),
    ])
    try await self.db.create([
      Key(
        keychainId: publicKeychain.id,
        key: .skeleton(scope: .bundleId("com.public.app")),
      ),
      Key(
        keychainId: publicKeychain.id,
        key: .domain(domain: "example.com", scope: .webBrowsers),
      ),
      Key(
        keychainId: privateKeychain.id,
        key: .skeleton(scope: .bundleId("com.private.app")),
      ),
    ])

    let output = try await withDependencies {
      $0.websockets.status = { _ in .filterOn }
    } operation: {
      try await GetChild.resolve(with: child.id, in: context(child.parent))
    }

    let unrestrictedScopes = (output.unrestrictedApps ?? []).map(\.scope)
    expect(Set(unrestrictedScopes)).toEqual(
      [.bundleId("com.apple.Safari"), .identifiedAppSlug("chess")],
    )

    expect(output.publicUnrestrictedApps.count).toEqual(1)
    let pub = output.publicUnrestrictedApps[0]
    expect(pub.keychainId).toEqual(publicKeychain.id)
    expect(pub.keychainName).toEqual("public kc")
    expect(pub.scope).toEqual(.bundleId("com.public.app"))
  }
}
