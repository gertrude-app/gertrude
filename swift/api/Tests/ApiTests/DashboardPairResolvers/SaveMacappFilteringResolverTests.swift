import DuetSQL
import Gertie
import PairQL
import XCTest
import XExpect

@testable import Api

final class SaveMacappFilteringResolverTests: ApiTestCase, @unchecked Sendable {
  func testRejectsInvalidDowntimeWindow() async throws {
    let child = try await self.child()
    let invalid: [PlainTimeWindow] = [
      .init(start: .init(hour: 24, minute: 0), end: .init(hour: 7, minute: 0)),
      .init(start: .init(hour: 21, minute: 0), end: .init(hour: 7, minute: 60)),
      .init(start: .init(hour: 9, minute: 0), end: .init(hour: 9, minute: 0)),
    ]
    for window in invalid {
      do {
        _ = try await SaveMacappFiltering.resolve(
          with: .init(child: child, downtime: window),
          in: child.parent.context,
        )
        XCTFail("expected error to be thrown for \(window)")
      } catch let error as PqlError {
        expect(error.type).toEqual(.badRequest)
      }
    }
  }

  func testRejectsInvalidKeychainScheduleWindow() async throws {
    let child = try await self.child()
    var keychain = Keychain.random
    keychain.parentId = child.parent.id
    try await self.db.create(keychain)

    let input = SaveMacappFiltering.Input(child: child, keychains: [.init(
      id: keychain.id,
      schedule: .init(
        mode: .active,
        days: .all,
        window: .init(start: .init(hour: 25, minute: 0), end: .init(hour: 8, minute: 0)),
      ),
    )])
    do {
      _ = try await SaveMacappFiltering.resolve(with: input, in: child.parent.context)
      XCTFail("expected error to be thrown")
    } catch let error as PqlError {
      expect(error.type).toEqual(.badRequest)
    }
  }

  func testRejectsFilteringDisabledWithNoMonitoring() async throws {
    let child = try await self.child(with: { $0.screenshotsEnabled = false })
    var threw = false
    do {
      _ = try await SaveMacappFiltering.resolve(
        with: .init(child: child, filteringDisabled: true),
        in: child.parent.context,
      )
    } catch {
      threw = true
    }
    expect(threw).toEqual(true)
  }

  func testSetsNewKeychainsFromEmpty() async throws {
    let child = try await self.child()
    var keychain = Keychain.random
    keychain.parentId = child.parent.id
    try await self.db.create(keychain)

    _ = try await SaveMacappFiltering.resolve(
      with: .init(child: child, keychains: [.init(id: keychain.id, schedule: nil)]),
      in: child.parent.context,
    )

    let keychainIds = try await ChildKeychain.query()
      .where(.childId == child.id)
      .all(in: self.db)
      .map(\.keychainId)

    expect(keychainIds).toEqual([keychain.id])
    expect(sent.websocketMessages).toEqual([.init(.userUpdated, to: .user(child.id))])
  }

  func testDeletesExistingKeychains() async throws {
    let child = try await self.child()
    var keychain = Keychain.random
    keychain.parentId = child.parent.id
    try await self.db.create(keychain)
    let pivot = try await self.db.create(ChildKeychain(childId: child.id, keychainId: keychain.id))

    _ = try await SaveMacappFiltering.resolve(
      with: .init(child: child, keychains: []),
      in: child.parent.context,
    )

    let keychains = try await ChildKeychain.query()
      .where(.childId == child.id)
      .all(in: self.db)

    expect(keychains.isEmpty).toBeTrue()
    let childKeychain = try? await self.db.find(pivot.id)
    expect(childKeychain).toBeNil()
  }

  func testReplacesExistingKeychains() async throws {
    let child = try await self.child()
    var keychain1 = Keychain.random
    keychain1.parentId = child.parent.id
    var keychain2 = Keychain.random
    keychain2.parentId = child.parent.id
    try await self.db.create([keychain1, keychain2])

    let pivot = try await self.db.create(ChildKeychain(childId: child.id, keychainId: keychain1.id))

    _ = try await SaveMacappFiltering.resolve(
      with: .init(
        child: child,
        keychains: [.init(
          id: keychain2.id,
          schedule: .init(mode: .active, days: .all, window: "04:00-08:00"),
        )],
      ),
      in: child.parent.context,
    )

    let keychainIds = try await ChildKeychain.query()
      .where(.childId == child.id)
      .all(in: self.db)
      .map(\.keychainId)

    expect(keychainIds).toEqual([keychain2.id])
    let retrievedOldPivot = try? await self.db.find(pivot.id)
    expect(retrievedOldPivot).toBeNil()

    let newPivot = try? await ChildKeychain.query()
      .where(.childId == child.id)
      .first(in: self.db)
    expect(newPivot?.schedule)
      .toEqual(.init(mode: .active, days: .all, window: "04:00-08:00"))
  }
}

extension SaveMacappFiltering.Input {
  init(
    child: ChildEntities,
    filteringDisabled: Bool? = nil,
    downtime: PlainTimeWindow? = nil,
    keychains: [PersonKeychain] = [],
    alwaysBlockedGroupIds: [AlwaysBlockedGroup.Id] = [],
    customAlwaysBlockedRules: [ChildCustomBlockRule] = [],
  ) {
    self.init(
      id: child.id,
      filteringDisabled: filteringDisabled ?? child.filteringDisabled,
      downtime: downtime,
      keychains: keychains,
      alwaysBlockedGroupIds: alwaysBlockedGroupIds,
      customAlwaysBlockedRules: customAlwaysBlockedRules,
    )
  }
}
