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
}

extension SaveUser.Input {
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
