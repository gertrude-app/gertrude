import Dependencies
import DuetSQL
import MacAppRoute
import XCTest
import XExpect

@testable import Api

final class SelectPublicKeychainsResolverTests: ApiTestCase, @unchecked Sendable {
  func testSuccessfullyAttachesPublicKeychains() async throws {
    let child = try await self.child().withDevice()
    let otherParent = try await self.parent()

    let keychain1 = try await self.db.create(Keychain(
      parentId: otherParent.model.id,
      name: "Safe Sites",
      isPublic: true,
    ))
    let keychain2 = try await self.db.create(Keychain(
      parentId: otherParent.model.id,
      name: "Educational",
      isPublic: true,
    ))

    let input: [UUID] = [keychain1.id.rawValue, keychain2.id.rawValue]
    let output = try await SelectPublicKeychains.resolve(with: input, in: context(child))

    expect(output).toEqual(.success)

    let childKeychains = try await ChildKeychain.query()
      .where(.childId == child.model.id)
      .all(in: self.db)

    expect(childKeychains).toHaveCount(2)
    let keychainIds = Set(childKeychains.map(\.keychainId))
    expect(keychainIds == Set([keychain1.id, keychain2.id])).toEqual(true)

    let events = try await InterestingEvent.query()
      .where(.eventId == "04f00574")
      .where(.computerUserId == child.computerUser.id)
      .all(in: self.db)

    expect(events).toHaveCount(1)
    let detail = try XCTUnwrap(events.first?.detail)
    expect(detail).toContain("selected 2 public keychain(s) during onboarding")
    expect(detail).toContain(keychain1.id.lowercased)
    expect(detail).toContain(keychain2.id.lowercased)
  }

  func testSkipsAlreadyAttachedKeychains() async throws {
    let child = try await self.child().withDevice()
    let otherParent = try await self.parent()

    let keychain = try await self.db.create(Keychain(
      parentId: otherParent.model.id,
      name: "Safe Sites",
      isPublic: true,
    ))

    try await self.db.create(ChildKeychain(
      childId: child.model.id,
      keychainId: keychain.id,
    ))

    let input: [UUID] = [keychain.id.rawValue]
    let output = try await SelectPublicKeychains.resolve(with: input, in: context(child))

    expect(output).toEqual(.success)

    let childKeychains = try await ChildKeychain.query()
      .where(.childId == child.model.id)
      .all(in: self.db)

    expect(childKeychains).toHaveCount(1)
  }

  func testRejectsNonPublicKeychain() async throws {
    let child = try await self.child().withDevice()

    let privateKeychain = try await self.db.create(Keychain(
      parentId: child.parent.model.id,
      name: "Private",
      isPublic: false,
    ))

    let input: [UUID] = [privateKeychain.id.rawValue]
    do {
      _ = try await SelectPublicKeychains.resolve(with: input, in: context(child))
      XCTFail("expected error to be thrown")
    } catch let error as PqlError {
      expect(error.type).toEqual(.unauthorized)
    }

    let childKeychains = try await ChildKeychain.query()
      .where(.childId == child.model.id)
      .all(in: self.db)

    expect(childKeychains).toHaveCount(0)
  }

  func testRejectedWhenTokenTooOld() async throws {
    let child = try await self.child().withDevice()
    let otherParent = try await self.parent()

    let keychain = try await self.db.create(Keychain(
      parentId: otherParent.model.id,
      name: "Safe Sites",
      isPublic: true,
    ))

    let tooOld = child.token.createdAt.addingTimeInterval(91 * 60)
    do {
      try await withDependencies {
        $0.date = .constant(tooOld)
      } operation: {
        _ = try await SelectPublicKeychains.resolve(
          with: [keychain.id.rawValue],
          in: self.context(child),
        )
      }
      XCTFail("expected error to be thrown")
    } catch let error as PqlError {
      expect(error.type).toEqual(.unauthorized)
    }

    let childKeychains = try await ChildKeychain.query()
      .where(.childId == child.model.id)
      .all(in: self.db)

    expect(childKeychains).toHaveCount(0)

    let events = try await InterestingEvent.query()
      .where(.eventId == "70146cf3")
      .all(in: self.db)

    expect(events).toHaveCount(1)
    let detail = try XCTUnwrap(events.first?.detail)
    expect(detail).toContain("suspicious SelectPublicKeychains")
  }
}
