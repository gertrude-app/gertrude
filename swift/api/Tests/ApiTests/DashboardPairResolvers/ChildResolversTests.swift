import DuetSQL
import Gertie
import PairQL
import XCTest
import XExpect

@testable import Api

final class ChildResolversTests: ApiTestCase, @unchecked Sendable {
  func testSaveAndDeleteNewChild() async throws {
    let parent = try await self.parent()

    let input = SaveUser.Input(
      id: .init(),
      isNew: true,
      name: "Franny",
      keyloggingEnabled: false, // <-- ignored for new child, we set recommended default
      screenshotsEnabled: false, // <-- ignored for new child, we set recommended default
      screenshotsResolution: 999, // <-- ignored for new child, we set recommended default
      screenshotsFrequency: 888, // <-- ignored for new child, we set recommended default
      showSuspensionActivity: false, // <-- ignored for new child, we set recommended default
      filteringDisabled: false, // <-- honored as-is (no recommended default override)
      downtime: "22:00-06:00",
      keychains: [],
    )

    let output = try await SaveUser.resolve(with: input, in: parent.context)

    let child = try await self.db.find(input.id)
    expect(output).toEqual(.success)
    expect(child.name).toEqual("Franny")
    // vvv--- these are our recommended defaults
    expect(child.keyloggingEnabled).toEqual(true)
    expect(child.screenshotsEnabled).toEqual(true)
    expect(child.screenshotsResolution).toEqual(1000)
    expect(child.screenshotsFrequency).toEqual(180)
    expect(child.showSuspensionActivity).toEqual(true)
    expect(child.filteringDisabled).toEqual(false)
    expect(child.downtime).toEqual("22:00-06:00")

    let keychains = try await child.keychains(in: self.db)
    expect(keychains.isEmpty).toBeTrue()
    expect(sent.websocketMessages).toEqual([.init(.userUpdated, to: .user(child.id))])

    // now delete...
    let deleteOutput = try await DeleteEntity_v2.resolve(
      with: .init(id: child.id.rawValue, type: .child),
      in: parent.context,
    )
    expect(deleteOutput).toEqual(.success)
    let retrieved = try? await self.db.find(child.id)
    expect(retrieved).toBeNil()
    expect(sent.websocketMessages).toEqual([
      .init(.userUpdated, to: .user(child.id)),
      .init(.userDeleted, to: .user(child.id)),
    ])
  }

  func testExistingChildUpdated() async throws {
    let child = try await self.child()

    let output = try await SaveUser.resolve(
      with: SaveUser.Input(
        id: child.id,
        isNew: false,
        name: "New name",
        keyloggingEnabled: false,
        screenshotsEnabled: false,
        screenshotsResolution: 333,
        screenshotsFrequency: 444,
        showSuspensionActivity: true,
        filteringDisabled: false,
        downtime: "22:00-06:00",
        keychains: [],
      ),
      in: child.parent.context,
    )

    let retrieved = try await self.db.find(child.id)
    expect(output).toEqual(.success)
    expect(retrieved.name).toEqual("New name")
    expect(retrieved.keyloggingEnabled).toEqual(false)
    expect(retrieved.screenshotsEnabled).toEqual(false)
    expect(retrieved.screenshotsResolution).toEqual(333)
    expect(retrieved.screenshotsFrequency).toEqual(444)
    expect(retrieved.showSuspensionActivity).toEqual(true)
    expect(retrieved.downtime).toEqual("22:00-06:00")

    expect(sent.websocketMessages).toEqual([.init(.userUpdated, to: .user(child.id))])
  }

  func testEnforcesMinimumScreenshotFrequency() async throws {
    let child = try await self.child()

    let output = try await SaveUser.resolve(
      with: SaveUser.Input(
        id: child.id,
        isNew: false,
        name: "New name",
        keyloggingEnabled: false,
        screenshotsEnabled: false,
        screenshotsResolution: 333,
        screenshotsFrequency: 1, // <-- below minimum of 10
        showSuspensionActivity: true,
        filteringDisabled: false,
        keychains: [],
      ),
      in: child.parent.context,
    )

    let retrieved = try await self.db.find(child.id)
    expect(output).toEqual(.success)
    expect(retrieved.screenshotsFrequency).toEqual(10)
  }

  func testNewChildHonorsFilteringDisabled() async throws {
    let parent = try await self.parent()
    let input = SaveUser.Input.mock(with: {
      $0.filteringDisabled = true
      $0.screenshotsEnabled = true
    })
    _ = try await SaveUser.resolve(with: input, in: parent.context)
    let child = try await self.db.find(input.id)
    expect(child.filteringDisabled).toEqual(true)
  }

  func testRejectsFilteringDisabledWithNoMonitoring() async throws {
    let child = try await self.child()
    var threw = false
    do {
      _ = try await SaveUser.resolve(
        with: .mock(with: {
          $0.id = child.id
          $0.isNew = false
          $0.filteringDisabled = true
          $0.screenshotsEnabled = false
        }),
        in: child.parent.context,
      )
    } catch {
      threw = true
    }
    expect(threw).toEqual(true)
  }

  func testRejectsNewChildWithFilteringDisabledAndNoMonitoring() async throws {
    let parent = try await self.parent()
    var threw = false
    do {
      _ = try await SaveUser.resolve(
        with: .mock(with: {
          $0.filteringDisabled = true
          $0.screenshotsEnabled = false
        }),
        in: parent.context,
      )
    } catch {
      threw = true
    }
    expect(threw).toEqual(true)
  }

  func testRejectsInvalidDowntimeWindow() async throws {
    let parent = try await self.parent()
    let invalid: [PlainTimeWindow] = [
      .init(start: .init(hour: 24, minute: 0), end: .init(hour: 7, minute: 0)),
      .init(start: .init(hour: 21, minute: 0), end: .init(hour: 7, minute: 60)),
      .init(start: .init(hour: 9, minute: 0), end: .init(hour: 9, minute: 0)),
    ]
    for window in invalid {
      do {
        _ = try await SaveUser.resolve(
          with: .mock(with: { $0.downtime = window }),
          in: parent.context,
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

    let input = SaveUser.Input(
      from: child,
      keychains: [.init(
        id: keychain.id,
        schedule: .init(
          mode: .active,
          days: .all,
          window: .init(start: .init(hour: 25, minute: 0), end: .init(hour: 8, minute: 0)),
        ),
      )],
    )
    do {
      _ = try await SaveUser.resolve(with: input, in: child.parent.context)
      XCTFail("expected error to be thrown")
    } catch let error as PqlError {
      expect(error.type).toEqual(.badRequest)
    }
  }

  func testSetsNewKeychainsFromEmpty() async throws {
    let child = try await self.child()
    var keychain = Keychain.random
    keychain.parentId = child.parent.id
    try await self.db.create(keychain)

    let input = SaveUser.Input(from: child, keychains: [.init(id: keychain.id, schedule: nil)])
    _ = try await SaveUser.resolve(with: input, in: child.parent.context)

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

    let input = SaveUser.Input(from: child, keychains: [])
    _ = try await SaveUser.resolve(with: input, in: child.parent.context)

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

    let input = SaveUser.Input(
      from: child,
      keychains: [.init(
        id: keychain2.id,
        schedule: .init(mode: .active, days: .all, window: "04:00-08:00"),
      )],
    )
    _ = try await SaveUser.resolve(with: input, in: child.parent.context)

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

  func testUpdatedUserAddingNewBlockedApps() async throws {
    let child = try await self.child()
    var input = SaveUser.Input(from: child)
    input.blockedApps = [.init(identifier: "FaceSkype")]
    _ = try await SaveUser.resolve(with: input, in: child.parent.context)
    let blocked = try await child.model.blockedApps(in: self.db)
    expect(blocked.map(\.identifier)).toEqual(["FaceSkype"])
  }

  func testDeleteExistingBlockedApps() async throws {
    let child = try await self.child()
    try await self.db.create([UserBlockedApp(identifier: "FaceSkype", childId: child.id)])

    var input = SaveUser.Input(from: child)
    input.blockedApps = nil // <-- nil does not delete
    _ = try await SaveUser.resolve(with: input, in: child.parent.context)

    var retrieved = try await child.model.blockedApps(in: self.db)
    expect(retrieved.count).toEqual(1)

    input.blockedApps = []
    _ = try await SaveUser.resolve(with: input, in: child.parent.context)

    retrieved = try await child.model.blockedApps(in: self.db)
    expect(retrieved.count).toEqual(0)
  }

  func testUpdateExistingBlockedApps() async throws {
    let child = try await self.child()
    let id1 = UserBlockedApp.Id()
    let id2 = UserBlockedApp.Id()
    let id3 = UserBlockedApp.Id()
    try await self.db.create([UserBlockedApp(id: id1, identifier: "FaceSkype", childId: child.id)])

    var input = SaveUser.Input(from: child)
    input.blockedApps = [
      .init(id: id1, identifier: "FaceSkype"),
      .init(id: id2, identifier: "FaceApp"),
    ]
    _ = try await SaveUser.resolve(with: input, in: child.parent.context)

    var retrieved = try await child.model.blockedApps(in: self.db)
    expect(Set(retrieved.map(\.id))).toEqual([id1, id2])

    input = SaveUser.Input(from: child)
    input.blockedApps = [
      .init(id: id2, identifier: "FaceApp"),
      .init(id: id3, identifier: "WhatsZoom"),
    ]
    _ = try await SaveUser.resolve(with: input, in: child.parent.context)

    retrieved = try await child.model.blockedApps(in: self.db)
    expect(retrieved.map(\.id)).toEqual([id2, id3])
  }
}

extension SaveUser.Input {
  init(from child: ChildEntities, keychains: [ChildKeychain] = []) {
    self.init(
      id: child.id,
      isNew: false,
      name: child.name,
      keyloggingEnabled: child.keyloggingEnabled,
      screenshotsEnabled: child.screenshotsEnabled,
      screenshotsResolution: child.screenshotsResolution,
      screenshotsFrequency: child.screenshotsFrequency,
      showSuspensionActivity: child.showSuspensionActivity,
      filteringDisabled: child.filteringDisabled,
      keychains: keychains,
    )
  }

  static var mock: Self {
    SaveUser.Input(
      id: .init(),
      isNew: true,
      name: "Franny",
      keyloggingEnabled: true,
      screenshotsEnabled: true,
      screenshotsResolution: 100,
      screenshotsFrequency: 180,
      showSuspensionActivity: true,
      filteringDisabled: false,
      downtime: nil,
      keychains: [],
    )
  }

  static func mock(with config: (inout Self) -> Void) -> Self {
    var input = Self.mock
    config(&input)
    return input
  }
}
