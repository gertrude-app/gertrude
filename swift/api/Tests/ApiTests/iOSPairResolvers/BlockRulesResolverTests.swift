import GertieIOS
import IOSRoute
import XCTest
import XExpect

@testable import Api

final class BlockRulesResolverTests: ApiTestCase, @unchecked Sendable {

  // MARK: v3 tests

  func testBlockRulesV3_AllGroupsEnabled() async throws {
    let gifs = CreateBlockGroups.GroupIds().gifs
    let ads = CreateBlockGroups.GroupIds().ads
    try await self.db.delete(all: BlockerApp.BlockRule.self)
    try await self.db.create([
      BlockerApp.BlockRule(rule: .urlContains(value: "gif"), groupId: .init(gifs)),
      BlockerApp.BlockRule(rule: .urlContains(value: "ad"), groupId: .init(ads)),
    ])

    let rules = try await BlockRules_v3.resolve(
      with: .init(deviceId: UUID(), appVersion: "2.0.0", disabledGroups: []),
      in: .mock,
    )
    expect(Set(rules)).toEqual([.urlContains(value: "gif"), .urlContains(value: "ad")])
  }

  func testBlockRulesV3_OneGroupDisabled() async throws {
    let gifs = CreateBlockGroups.GroupIds().gifs
    let ads = CreateBlockGroups.GroupIds().ads
    try await self.db.delete(all: BlockerApp.BlockRule.self)
    try await self.db.create([
      BlockerApp.BlockRule(rule: .urlContains(value: "gif"), groupId: .init(gifs)),
      BlockerApp.BlockRule(rule: .urlContains(value: "ad"), groupId: .init(ads)),
    ])

    let rules = try await BlockRules_v3.resolve(
      with: .init(deviceId: UUID(), appVersion: "2.0.0", disabledGroups: [ads]),
      in: .mock,
    )
    expect(rules).toEqual([.urlContains(value: "gif")])
  }

  func testBlockRulesV3_MultipleGroupsDisabled() async throws {
    let gifs = CreateBlockGroups.GroupIds().gifs
    let ads = CreateBlockGroups.GroupIds().ads
    let spotify = CreateBlockGroups.GroupIds().spotifyImages
    try await self.db.delete(all: BlockerApp.BlockRule.self)
    try await self.db.create([
      BlockerApp.BlockRule(rule: .urlContains(value: "gif"), groupId: .init(gifs)),
      BlockerApp.BlockRule(rule: .urlContains(value: "ad"), groupId: .init(ads)),
      BlockerApp.BlockRule(rule: .urlContains(value: "spotify"), groupId: .init(spotify)),
    ])

    let rules = try await BlockRules_v3.resolve(
      with: .init(deviceId: UUID(), appVersion: "2.0.0", disabledGroups: [ads, gifs]),
      in: .mock,
    )
    expect(rules).toEqual([.urlContains(value: "spotify")])
  }

  func testBlockRulesV3_DeviceSpecificRulesAlwaysIncluded() async throws {
    let vendorId = UUID()
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice(
      id: .init(vendorId),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.0",
    ))
    let gifs = CreateBlockGroups.GroupIds().gifs
    try await self.db.delete(all: BlockerApp.BlockRule.self)
    try await self.db.create([
      BlockerApp.BlockRule(rule: .urlContains(value: "gif"), groupId: .init(gifs)),
      BlockerApp.BlockRule(deviceId: device.id, rule: .urlContains(value: "custom")),
    ])

    let rules = try await BlockRules_v3.resolve(
      with: .init(deviceId: vendorId, appVersion: "2.0.0", disabledGroups: [gifs]),
      in: .mock,
    )
    expect(rules).toEqual([.urlContains(value: "custom")])
  }

  // MARK: v2 tests

  func testBlockRules() async throws {
    let vendorId = UUID()
    let otherVendorId = UUID()
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice(
      id: .init(vendorId),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.0",
    ))
    let device2 = try await self.db.create(IOSDevice(
      id: .init(otherVendorId),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.0",
    ))
    let gifs = CreateBlockGroups.GroupIds().gifs
    let ads = CreateBlockGroups.GroupIds().ads
    try await self.db.delete(all: BlockerApp.BlockRule.self)
    try await self.db.create([
      BlockerApp.BlockRule(rule: .urlContains(value: "bad"), groupId: .init(gifs)),
      BlockerApp.BlockRule(rule: .urlContains(value: "cat"), groupId: .init(ads)),
      // <-- skip, disabled
      BlockerApp.BlockRule(deviceId: device.id, rule: .urlContains(value: "x1")), // <-- include
      BlockerApp.BlockRule(deviceId: device2.id, rule: .urlContains(value: "x2")),
      // <-- skip, other
      BlockerApp.BlockRule(rule: .urlContains(value: "nope"), groupId: nil),
    ])

    let rules = try await BlockRules_v2.resolve(
      with: .init(disabledGroups: [.ads], vendorId: vendorId, version: "1.0"),
      in: .mock,
    )
    expect(Set(rules)).toEqual([.urlContains("bad"), .urlContains("x1")])
  }

  func testBlockRuleIgnoresZeroAskNotToTrackVendorId() async throws {
    // not sure if users can do this with gertrude, but when you "ask not to track" on iOS
    // my understanding is that it just means the vendorId is set to zero, so we don't want
    // to ever consider these vendor ids for customizations
    let zeroVid = UUID("00000000-0000-0000-0000-000000000000")!
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice(
      id: .init(zeroVid),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.0",
    ))
    let gifs = CreateBlockGroups.GroupIds().gifs
    try await self.db.delete(all: BlockerApp.BlockRule.self)
    try await self.db.create([
      BlockerApp.BlockRule(rule: .urlContains(value: "bad"), groupId: .init(gifs)),
      BlockerApp.BlockRule(deviceId: device.id, rule: .urlContains(value: "x1")), // <-- skip, b/c 0
    ])

    let rules = try await BlockRules_v2.resolve(
      with: .init(disabledGroups: [.ads], vendorId: zeroVid, version: "1.0"),
      in: .mock,
    )
    expect(rules).toEqual([.urlContains("bad")])
  }

  func testDefaultBlockRulesRetrievesAllWithGroup() async throws {
    let gifs = CreateBlockGroups.GroupIds().gifs
    let ads = CreateBlockGroups.GroupIds().ads
    try await self.db.delete(all: BlockerApp.BlockRule.self)
    try await self.db.create([
      BlockerApp.BlockRule(rule: .urlContains(value: "bad"), groupId: .init(gifs)),
      BlockerApp.BlockRule(rule: .urlContains(value: "thing"), groupId: nil), // <-- skip, no group
      BlockerApp.BlockRule(rule: .urlContains(value: "cat"), groupId: .init(ads)),
    ])

    let defaultRules = try await DefaultBlockRules.resolve(
      with: .init(vendorId: nil, version: "1.0"),
      in: .mock,
    )
    expect(defaultRules).toEqual([.urlContains("bad"), .urlContains("cat")])
  }

  func testBlockRulesV2_RetroactiveOptOut_OldVersion() async throws {
    let spotify = CreateBlockGroups.GroupIds().spotifyImages
    let gifs = CreateBlockGroups.GroupIds().gifs
    try await self.db.delete(all: BlockerApp.BlockRule.self)
    try await self.db.create([
      BlockerApp.BlockRule(rule: .urlContains(value: "spotify1"), groupId: .init(spotify)),
      BlockerApp.BlockRule(rule: .urlContains(value: "spotify2"), groupId: .init(spotify)),
      BlockerApp.BlockRule(rule: .urlContains(value: "gif"), groupId: .init(gifs)),
    ])

    let rulesV130 = try await BlockRules_v2.resolve(
      with: .init(disabledGroups: [], vendorId: UUID(), version: "1.3.0"),
      in: .mock,
    )
    expect(Set(rulesV130)).toEqual([.urlContains("gif")])

    let rulesV149 = try await BlockRules_v2.resolve(
      with: .init(disabledGroups: [], vendorId: UUID(), version: "1.4.9"),
      in: .mock,
    )
    expect(Set(rulesV149)).toEqual([.urlContains("gif")])
  }

  func testBlockRulesV2_NewVersion_ReceivesSpotify() async throws {
    let spotify = CreateBlockGroups.GroupIds().spotifyImages
    let gifs = CreateBlockGroups.GroupIds().gifs
    try await self.db.delete(all: BlockerApp.BlockRule.self)
    try await self.db.create([
      BlockerApp.BlockRule(rule: .urlContains(value: "spotify1"), groupId: .init(spotify)),
      BlockerApp.BlockRule(rule: .urlContains(value: "spotify2"), groupId: .init(spotify)),
      BlockerApp.BlockRule(rule: .urlContains(value: "gif"), groupId: .init(gifs)),
    ])

    let rulesV150 = try await BlockRules_v2.resolve(
      with: .init(disabledGroups: [], vendorId: UUID(), version: "1.5.0"),
      in: .mock,
    )
    expect(Set(rulesV150)).toEqual([
      .urlContains("spotify1"),
      .urlContains("spotify2"),
      .urlContains("gif"),
    ])
  }

  func testBlockRulesV2_NewVersion_CanOptOutOfSpotify() async throws {
    let spotify = CreateBlockGroups.GroupIds().spotifyImages
    let gifs = CreateBlockGroups.GroupIds().gifs
    try await self.db.delete(all: BlockerApp.BlockRule.self)
    try await self.db.create([
      BlockerApp.BlockRule(rule: .urlContains(value: "spotify1"), groupId: .init(spotify)),
      BlockerApp.BlockRule(rule: .urlContains(value: "gif"), groupId: .init(gifs)),
    ])

    let rules = try await BlockRules_v2.resolve(
      with: .init(disabledGroups: [.spotifyImages], vendorId: UUID(), version: "1.5.0"),
      in: .mock,
    )
    expect(Set(rules)).toEqual([.urlContains("gif")])
  }

  // MARK: opt-in grandfathering tests

  func testBlockRulesV3_GrandfatheredDevice_ReceivesWhatsApp() async throws {
    let vendorId = UUID()
    try await self.seedGrandfatheringFixtures(
      deviceVendorId: vendorId,
      deviceCreatedAt: .reference,
    )

    let rules = try await BlockRules_v3.resolve(
      with: .init(deviceId: vendorId, appVersion: "2.0.0", disabledGroups: []),
      in: .mock,
    )
    expect(rules).toEqual([.urlContains(value: "whatsapp-rule")])
  }

  func testBlockRulesV3_GrandfatheredDevice_CanDisableWhatsApp() async throws {
    let ids = CreateBlockGroups.GroupIds()
    let vendorId = UUID()
    try await self.seedGrandfatheringFixtures(
      deviceVendorId: vendorId,
      deviceCreatedAt: .reference,
      extraRule: BlockerApp.BlockRule(
        rule: .urlContains(value: "non-opt-in"),
        groupId: .init(ids.gifs),
      ),
    )

    let rules = try await BlockRules_v3.resolve(
      with: .init(deviceId: vendorId, appVersion: "2.0.0", disabledGroups: [ids.whatsAppFeatures]),
      in: .mock,
    )
    expect(rules).toEqual([.urlContains(value: "non-opt-in")])
  }

  func testBlockRulesV3_NewDevice_ExcludesAllOptInGroups() async throws {
    let vendorId = UUID()
    try await self.seedGrandfatheringFixtures(
      deviceVendorId: vendorId,
      deviceCreatedAt: .distantFuture,
      extraRule: BlockerApp.BlockRule(
        rule: .urlContains(value: "non-opt-in"),
        groupId: .init(CreateBlockGroups.GroupIds().gifs),
      ),
    )

    let rules = try await BlockRules_v3.resolve(
      with: .init(deviceId: vendorId, appVersion: "2.0.0", disabledGroups: []),
      in: .mock,
    )
    expect(rules).toEqual([.urlContains(value: "non-opt-in")])
  }

  func testBlockRulesV3_MissingDeviceRow_TreatedAsNew() async throws {
    try await self.seedGrandfatheringFixtures(
      deviceVendorId: nil,
      extraRule: BlockerApp.BlockRule(
        rule: .urlContains(value: "non-opt-in"),
        groupId: .init(CreateBlockGroups.GroupIds().gifs),
      ),
    )

    let rules = try await BlockRules_v3.resolve(
      with: .init(deviceId: UUID(), appVersion: "2.0.0", disabledGroups: []),
      in: .mock,
    )
    expect(rules).toEqual([.urlContains(value: "non-opt-in")])
  }

  func testDefaultBlockRules_NewDevice_ExcludesOptInGroups() async throws {
    let vendorId = UUID()
    try await self.seedGrandfatheringFixtures(
      deviceVendorId: vendorId,
      deviceCreatedAt: .distantFuture,
      extraRule: BlockerApp.BlockRule(
        rule: .urlContains(value: "non-opt-in"),
        groupId: .init(CreateBlockGroups.GroupIds().gifs),
      ),
    )

    let rules = try await DefaultBlockRules.resolve(
      with: .init(vendorId: vendorId, version: "1.0"),
      in: .mock,
    )
    expect(rules).toEqual([.urlContains("non-opt-in")])
  }

  func testDefaultBlockRules_GrandfatheredDevice_ReceivesWhatsApp() async throws {
    let vendorId = UUID()
    try await self.seedGrandfatheringFixtures(
      deviceVendorId: vendorId,
      deviceCreatedAt: .reference,
      extraRule: BlockerApp.BlockRule(
        rule: .urlContains(value: "non-opt-in"),
        groupId: .init(CreateBlockGroups.GroupIds().gifs),
      ),
    )

    let rules = try await DefaultBlockRules.resolve(
      with: .init(vendorId: vendorId, version: "1.0"),
      in: .mock,
    )
    expect(Set(rules)).toEqual([.urlContains("whatsapp-rule"), .urlContains("non-opt-in")])
  }

  func testBlockRulesV2_GrandfatheredDevice_ReceivesWhatsApp() async throws {
    let vendorId = UUID()
    try await self.seedGrandfatheringFixtures(
      deviceVendorId: vendorId,
      deviceCreatedAt: .reference,
    )

    let rules = try await BlockRules_v2.resolve(
      with: .init(disabledGroups: [], vendorId: vendorId, version: "1.5.0"),
      in: .mock,
    )
    expect(rules.map(\.current)).toEqual([.urlContains(value: "whatsapp-rule")])
  }

  func testBlockRulesV2_GrandfatheredDevice_CanDisableWhatsApp() async throws {
    let vendorId = UUID()
    try await self.seedGrandfatheringFixtures(
      deviceVendorId: vendorId,
      deviceCreatedAt: .reference,
      extraRule: BlockerApp.BlockRule(
        rule: .urlContains(value: "non-opt-in"),
        groupId: .init(CreateBlockGroups.GroupIds().gifs),
      ),
    )

    let rules = try await BlockRules_v2.resolve(
      with: .init(disabledGroups: [.whatsAppFeatures], vendorId: vendorId, version: "1.5.0"),
      in: .mock,
    )
    expect(rules.map(\.current)).toEqual([.urlContains(value: "non-opt-in")])
  }

  // MARK: v1 legacy tests

  func testBlockRules_v1() async throws {
    let rules = try await BlockRules.resolve(with: .init(vendorId: UUID()), in: .mock)
    expect(rules).toEqual(BlockRule.Legacy.defaults)
  }

  func testCustomizedBlockRules_v1() async throws {
    let vendorId = UUID(uuidString: "2cada392-9d09-4425-bec2-b0c4e3aeafec")!
    let rules = try await BlockRules.resolve(with: .init(vendorId: vendorId), in: .mock)
    expect(rules.contains(
      .both(
        .bundleIdContains(".com.apple.MobileSMS"),
        .targetContains("amp-api-edge.apps.apple.com"),
      ),
    )).toEqual(true)
  }

  // MARK: helpers

  private func seedGrandfatheringFixtures(
    deviceVendorId: UUID?,
    deviceCreatedAt: Date? = nil,
    extraRule: BlockerApp.BlockRule? = nil,
  ) async throws {
    if let deviceVendorId, let deviceCreatedAt {
      let parent = try await self.parent()
      let child = try await self.db.create(Child.random { $0.parentId = parent.id })
      var device = try await self.db.create(IOSDevice(
        id: .init(deviceVendorId),
        childId: child.id,
        modelIdentifier: "iPhone15,2",
        iosVersion: "18.0",
      ))
      try await self.db.create(BlockerApp.Install.mock { $0.deviceId = device.id })
      try await device.modifyCreatedAt(.exact(deviceCreatedAt))
    }

    let ids = CreateBlockGroups.GroupIds()
    try await self.db.delete(all: BlockerApp.BlockRule.self)
    var rules = [
      BlockerApp.BlockRule(
        rule: .urlContains(value: "whatsapp-rule"),
        groupId: .init(ids.whatsAppFeatures),
      ),
    ]
    if let extraRule { rules.append(extraRule) }
    try await self.db.create(rules)
  }
}

extension IOSDevice: HasCreatedAt {}
