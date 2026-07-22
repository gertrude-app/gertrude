import DuetSQL
import Gertie
import PairQL
import XCTest
import XExpect

@testable import Api

final class SaveMacappAppsResolverTests: ApiTestCase, @unchecked Sendable {
  func testAddingNewBlockedApps() async throws {
    let child = try await self.child()
    _ = try await SaveMacappApps.resolve(
      with: .init(
        id: child.id,
        blockedApps: [.init(identifier: "FaceSkype")],
        unrestrictedApps: [],
      ),
      in: child.parent.context,
    )
    let blocked = try await child.model.blockedMacApps(in: self.db)
    expect(blocked.map(\.identifier)).toEqual(["FaceSkype"])
  }

  func testEmptyArrayDeletesExistingBlockedApps() async throws {
    let child = try await self.child()
    try await self.db.create([BlockedMacApp(identifier: "FaceSkype", childId: child.id)])

    _ = try await SaveMacappApps.resolve(
      with: .init(id: child.id, blockedApps: [], unrestrictedApps: []),
      in: child.parent.context,
    )

    let retrieved = try await child.model.blockedMacApps(in: self.db)
    expect(retrieved.count).toEqual(0)
  }

  func testUpdateExistingBlockedApps() async throws {
    let child = try await self.child()
    let id1 = BlockedMacApp.Id()
    let id2 = BlockedMacApp.Id()
    let id3 = BlockedMacApp.Id()
    try await self.db.create([BlockedMacApp(id: id1, identifier: "FaceSkype", childId: child.id)])

    _ = try await SaveMacappApps.resolve(
      with: .init(
        id: child.id,
        blockedApps: [
          .init(id: id1, identifier: "FaceSkype"),
          .init(id: id2, identifier: "FaceApp"),
        ],
        unrestrictedApps: [],
      ),
      in: child.parent.context,
    )

    var retrieved = try await child.model.blockedMacApps(in: self.db)
    expect(Set(retrieved.map(\.id))).toEqual([id1, id2])

    _ = try await SaveMacappApps.resolve(
      with: .init(
        id: child.id,
        blockedApps: [
          .init(id: id2, identifier: "FaceApp"),
          .init(id: id3, identifier: "WhatsZoom"),
        ],
        unrestrictedApps: [],
      ),
      in: child.parent.context,
    )

    retrieved = try await child.model.blockedMacApps(in: self.db)
    expect(retrieved.map(\.id)).toEqual([id2, id3])
  }

  func testAddingNewUnrestrictedApps() async throws {
    let child = try await self.child()
    _ = try await SaveMacappApps.resolve(
      with: .init(
        id: child.id,
        blockedApps: [],
        unrestrictedApps: [.init(scope: .bundleId("com.apple.Safari"))],
      ),
      in: child.parent.context,
    )
    let unrestricted = try await child.model.unrestrictedMacApps(in: self.db)
    expect(unrestricted.map(\.scope)).toEqual([.bundleId("com.apple.Safari")])
  }

  func testEmptyArrayDeletesExistingUnrestrictedApps() async throws {
    let child = try await self.child()
    try await self.db.create([
      UnrestrictedMacApp(scope: .bundleId("com.apple.Safari"), childId: child.id),
    ])

    _ = try await SaveMacappApps.resolve(
      with: .init(id: child.id, blockedApps: [], unrestrictedApps: []),
      in: child.parent.context,
    )

    let retrieved = try await child.model.unrestrictedMacApps(in: self.db)
    expect(retrieved.count).toEqual(0)
  }

  func testReplaceUnrestrictedApps() async throws {
    let child = try await self.child()
    let id1 = UnrestrictedMacApp.Id()
    let id2 = UnrestrictedMacApp.Id()
    let id3 = UnrestrictedMacApp.Id()
    try await self.db.create([
      UnrestrictedMacApp(id: id1, scope: .bundleId("com.apple.Safari"), childId: child.id),
    ])

    _ = try await SaveMacappApps.resolve(
      with: .init(
        id: child.id,
        blockedApps: [],
        unrestrictedApps: [
          .init(id: id1, scope: .bundleId("com.apple.Safari")),
          .init(id: id2, scope: .identifiedAppSlug("chess")),
        ],
      ),
      in: child.parent.context,
    )

    var retrieved = try await child.model.unrestrictedMacApps(in: self.db)
    expect(Set(retrieved.map(\.id))).toEqual([id1, id2])

    _ = try await SaveMacappApps.resolve(
      with: .init(
        id: child.id,
        blockedApps: [],
        unrestrictedApps: [
          .init(id: id2, scope: .identifiedAppSlug("chess")),
          .init(id: id3, scope: .bundleId("com.tinyspeck.slackmacgap")),
        ],
      ),
      in: child.parent.context,
    )

    retrieved = try await child.model.unrestrictedMacApps(in: self.db)
    expect(Set(retrieved.map(\.id))).toEqual([id2, id3])
  }

  func testIndependentBlockedAndUnrestrictedSaves() async throws {
    let child = try await self.child()
    try await self.db.create([
      BlockedMacApp(identifier: "FaceSkype", childId: child.id),
    ])
    try await self.db.create([
      UnrestrictedMacApp(scope: .bundleId("com.apple.Safari"), childId: child.id),
    ])

    _ = try await SaveMacappApps.resolve(
      with: .init(
        id: child.id,
        blockedApps: [.init(identifier: "FaceSkype")],
        unrestrictedApps: [],
      ),
      in: child.parent.context,
    )

    let blocked = try await child.model.blockedMacApps(in: self.db)
    let unrestricted = try await child.model.unrestrictedMacApps(in: self.db)
    expect(blocked.map(\.identifier)).toEqual(["FaceSkype"])
    expect(unrestricted.count).toEqual(0)
  }
}
