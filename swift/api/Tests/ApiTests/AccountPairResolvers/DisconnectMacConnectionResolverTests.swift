import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class DisconnectMacConnectionResolverTests: ApiTestCase, @unchecked Sendable {
  func testDisconnectsLastMacWithoutDeletingPersonSettingsOrIOSDevice() async throws {
    let person = try await self.childWithComputer()
    let keychain = try await person.parent.withKeychain()
    let assignment = try await self.db.create(ChildKeychain(
      childId: person.id,
      keychainId: keychain.keychain.id,
    ))
    let iosDevice = try await self.db.create(IOSDevice.mock { $0.childId = person.id })
    let screenshot = try await self.db.create(Screenshot(
      computerUserId: person.computerUser.id,
      url: "https://example.com/screenshot.jpg",
      width: 1280,
      height: 720,
    ))
    let keystrokes = try await self.db.create(KeystrokeLine(
      computerUserId: person.computerUser.id,
      appName: "Safari",
      line: "hello",
    ))
    let unlockRequest = try await self.db.create(UnlockRequest(
      computerUserId: person.computerUser.id,
      appBundleId: "com.apple.Safari",
      hostname: "example.com",
    ))
    let suspensionRequest = try await self.db.create(MacApp.SuspendFilterRequest(
      computerUserId: person.computerUser.id,
      scope: .unrestricted,
    ))

    let output = try await DisconnectMacConnection.resolve(
      with: .init(connectionId: person.computerUser.id),
      in: self.accountContext(person.parent),
    )

    expect(output).toEqual(.success)
    let keptPerson = try await self.db.find(person.id)
    expect(keptPerson.name).toEqual(person.name)
    expect(keptPerson.keyloggingEnabled).toEqual(person.keyloggingEnabled)
    expect(keptPerson.screenshotsEnabled).toEqual(person.screenshotsEnabled)
    expect(keptPerson.screenshotsFrequency).toEqual(person.screenshotsFrequency)
    expect(keptPerson.screenshotsResolution).toEqual(person.screenshotsResolution)
    expect(keptPerson.filteringDisabled).toEqual(person.filteringDisabled)
    expect(keptPerson.downtime).toEqual(person.downtime)
    await expect(try self.db.find(assignment.id).keychainId).toEqual(assignment.keychainId)
    await expect(try self.db.find(iosDevice.id).childId).toEqual(person.id)
    await expect(try ComputerUser.query().byId(person.computerUser.id).exists(in: self.db))
      .toBeFalse()
    await expect(try Computer.query().byId(person.computer.id).exists(in: self.db)).toBeFalse()
    await expect(try MacAppToken.query().byId(person.token.id).exists(in: self.db)).toBeFalse()
    await expect(try Screenshot.query().byId(screenshot.id).exists(in: self.db)).toBeFalse()
    await expect(try KeystrokeLine.query().byId(keystrokes.id).exists(in: self.db)).toBeFalse()
    await expect(try UnlockRequest.query().byId(unlockRequest.id).exists(in: self.db)).toBeFalse()
    await expect(try MacApp.SuspendFilterRequest.query().byId(suspensionRequest.id)
      .exists(in: self.db)).toBeFalse()
    expect(sent.websocketMessages).toEqual([
      .init(.userDeleted, to: .userDevice(person.computerUser.id)),
    ])
    let people = try await GetPeople.resolve(in: self.accountContext(person.parent))
    let remaining = try XCTUnwrap(people.first)
    expect(remaining.id).toEqual(person.id)
    expect(remaining.devices).toHaveCount(1)
    expect(remaining.screenshot).toBeNil()
  }

  func testPreservesOtherLoginsOnSharedMacAndOtherMacs() async throws {
    let person = try await self.child()
    let selected = try await person.withDevice()
    let otherMac = try await person.withDevice()
    let sibling = try await self.db.create(Child(parentId: person.parent.id, name: "Mabel"))
    let otherLogin = try await self.db.create(ComputerUser.random {
      $0.childId = person.id
      $0.computerId = selected.computer.id
      $0.username = "school"
      $0.numericId = 502
    })
    let siblingLogin = try await self.db.create(ComputerUser.random {
      $0.childId = sibling.id
      $0.computerId = selected.computer.id
      $0.numericId = 503
    })
    let otherToken = try await self.db.create(MacAppToken(
      childId: person.id,
      computerUserId: otherLogin.id,
    ))
    let siblingToken = try await self.db.create(MacAppToken(
      childId: sibling.id,
      computerUserId: siblingLogin.id,
    ))
    let screenshot = try await self.db.create(Screenshot(
      computerUserId: otherLogin.id,
      url: "https://example.com/kept.jpg",
      width: 1280,
      height: 720,
    ))

    _ = try await DisconnectMacConnection.resolve(
      with: .init(connectionId: selected.computerUser.id),
      in: self.accountContext(person.parent),
    )

    await expect(try self.db.find(selected.computer.id).parentId).toEqual(person.parent.id)
    for connection in [otherLogin, siblingLogin, otherMac.computerUser] {
      let kept = try await self.db.find(connection.id)
      expect(kept.childId).toEqual(connection.childId)
      expect(kept.computerId).toEqual(connection.computerId)
      expect(kept.username).toEqual(connection.username)
      expect(kept.numericId).toEqual(connection.numericId)
    }
    await expect(try self.db.find(otherToken.id).value).toEqual(otherToken.value)
    await expect(try self.db.find(siblingToken.id).value).toEqual(siblingToken.value)
    await expect(try self.db.find(otherMac.token.id).value).toEqual(otherMac.token.value)
    await expect(try self.db.find(screenshot.id).url).toEqual(screenshot.url)
    expect(sent.websocketMessages).toEqual([
      .init(.userDeleted, to: .userDevice(selected.computerUser.id)),
    ])
    let people = try await withDependencies {
      $0.websockets.status = { _ in .offline }
    } operation: {
      try await GetPeople.resolve(in: self.accountContext(person.parent))
    }
    let remaining = try XCTUnwrap(people.first { $0.id == person.id })
    expect(remaining.devices).toHaveCount(2)
  }

  func testCannotDisconnectAnotherAccountsMac() async throws {
    let person = try await self.childWithComputer()
    let otherParent = try await self.parent()

    try await expectErrorFrom {
      try await DisconnectMacConnection.resolve(
        with: .init(connectionId: person.computerUser.id),
        in: self.accountContext(otherParent),
      )
    }.toContain("notFound")

    await expect(try self.db.find(person.computerUser.id).childId).toEqual(person.id)
    await expect(try self.db.find(person.computer.id).parentId).toEqual(person.parent.id)
    await expect(try self.db.find(person.token.id).value).toEqual(person.token.value)
    expect(sent.websocketMessages).toBeEmpty()
  }

  func testMissingConnectionReturnsNotFound() async throws {
    let parent = try await self.parent()

    try await expectErrorFrom {
      try await DisconnectMacConnection.resolve(
        with: .init(connectionId: .init()),
        in: self.accountContext(parent),
      )
    }.toContain("notFound")

    expect(sent.websocketMessages).toBeEmpty()
  }

  func testWebsocketFailureDoesNotFailCompletedDisconnection() async throws {
    let person = try await self.childWithComputer()

    let output = try await withDependencies {
      $0.websockets.sendEvent = { _ in throw CancellationError() }
    } operation: {
      try await DisconnectMacConnection.resolve(
        with: .init(connectionId: person.computerUser.id),
        in: self.accountContext(person.parent),
      )
    }

    expect(output).toEqual(.success)
    await expect(try ComputerUser.query().byId(person.computerUser.id).exists(in: self.db))
      .toBeFalse()
    await expect(try self.db.find(person.id).name).toEqual(person.name)
  }
}
