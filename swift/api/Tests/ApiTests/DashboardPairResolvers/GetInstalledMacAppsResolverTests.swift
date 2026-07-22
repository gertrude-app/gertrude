import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class GetInstalledMacAppsResolverTests: ApiTestCase, @unchecked Sendable {
  func testReturnsCatalogedAppsAcrossDevices() async throws {
    let child = try await self.childWithComputer()
    let secondComputer = try await self.db.create(Computer.random {
      $0.parentId = child.parent.model.id
    })
    try await self.db.create(ComputerUser.random {
      $0.childId = child.model.id
      $0.computerId = secondComputer.id
    })

    let notes = try await self.db.create(CatalogedApp(
      bundleId: "com.apple.Notes",
      name: "Notes",
      category: "productivity",
      iconContentHash: "hash-notes",
    ))
    let safari = try await self.db.create(CatalogedApp(
      bundleId: "com.apple.Safari",
      name: "Safari",
      category: "browser",
    ))
    let unrelated = try await self.db.create(CatalogedApp(
      bundleId: "com.example.Unrelated",
      name: "Unrelated",
    ))

    try await self.db.create(InstalledMacApp(
      childId: child.model.id,
      computerId: child.computer.id,
      macAppId: notes.id,
    ))
    try await self.db.create(InstalledMacApp(
      childId: child.model.id,
      computerId: secondComputer.id,
      macAppId: safari.id,
    ))

    let otherChild = try await self.child()
    let otherComputer = try await self.db.create(Computer.random {
      $0.parentId = otherChild.parent.model.id
    })
    try await self.db.create(InstalledMacApp(
      childId: otherChild.model.id,
      computerId: otherComputer.id,
      macAppId: unrelated.id,
    ))

    let output = try await GetInstalledMacApps.resolve(
      with: child.model.id,
      in: self.context(child.parent),
    )

    expect(output.count).toEqual(2)
    expect(output.map(\.bundleId)).toEqual(["com.apple.Notes", "com.apple.Safari"])
    expect(output[0].name).toEqual("Notes")
    expect(output[0].category).toEqual("productivity")
    expect(output[0].iconHash).toEqual("hash-notes")
    expect(output[1].name).toEqual("Safari")
    expect(output[1].iconHash).toBeNil()
  }

  func testIncludesIdentifiedAppSlugWhenKnown() async throws {
    let child = try await self.childWithComputer()
    let bundleId = "com.example.identified-\(UUID().uuidString)"
    let cataloged = try await self.db.create(CatalogedApp(
      bundleId: bundleId,
      name: "Identified",
    ))
    try await self.db.create(InstalledMacApp(
      childId: child.model.id,
      computerId: child.computer.id,
      macAppId: cataloged.id,
    ))
    let identified = try await self.db.create(IdentifiedApp(
      name: "Identified",
      slug: "identified-\(UUID().uuidString.prefix(8))",
      launchable: true,
    ))
    try await self.db.create(AppBundleId(
      identifiedAppId: identified.id,
      bundleId: bundleId,
    ))

    let output = try await GetInstalledMacApps.resolve(
      with: child.model.id,
      in: self.context(child.parent),
    )

    expect(output.count).toEqual(1)
    expect(output[0].identifiedAppSlug).toEqual(identified.slug)
  }

  func testReturnsEmptyArrayWhenNoInstalledApps() async throws {
    let child = try await self.child()
    let output = try await GetInstalledMacApps.resolve(
      with: child.model.id,
      in: self.context(child.parent),
    )
    expect(output).toEqual([])
  }
}
