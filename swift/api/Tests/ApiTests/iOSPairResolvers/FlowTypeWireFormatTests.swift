import GertieIOS
import IOSRoute
import XCTest
import XCTVapor
import XExpect

@testable import Api

final class FlowTypeWireFormatTests: ApiTestCase, @unchecked Sendable {
  func testBlockRules_v2_encodesFlowTypeIsAsLegacyObject() async throws {
    let gifs = CreateBlockGroups.GroupIds().gifs
    try await self.db.delete(all: BlockerApp.BlockRule.self)
    try await self.db.create(BlockerApp.BlockRule(
      rule: .flowTypeIs(value: .browser),
      groupId: .init(gifs),
    ))

    let body = """
    {"disabledGroups":[],"vendorId":"\(UUID())","version":"1.5.0"}
    """

    try await app.test(
      .POST,
      "pairql/ios-app/BlockRules_v2",
      body: .init(string: body),
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.ok)
        expect(res.body.string.contains(#""browser":{}"#)).toEqual(true)
      },
    )
  }

  func testDefaultBlockRules_encodesFlowTypeIsAsLegacyObject() async throws {
    let gifs = CreateBlockGroups.GroupIds().gifs
    try await self.db.delete(all: BlockerApp.BlockRule.self)
    try await self.db.create(BlockerApp.BlockRule(
      rule: .flowTypeIs(value: .browser),
      groupId: .init(gifs),
    ))

    let body = #"{"vendorId":null,"version":"1.0"}"#

    try await app.test(
      .POST,
      "pairql/ios-app/DefaultBlockRules",
      body: .init(string: body),
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.ok)
        expect(res.body.string.contains(#""browser":{}"#)).toEqual(true)
      },
    )
  }

  func testConnectedRules_v2_encodesFlowTypeIsAsLegacyObject() async throws {
    let child = try await self.childWithIOSDevice()
    let gifs = CreateBlockGroups.GroupIds().gifs
    try await self.db.create(BlockerApp.DeviceBlockGroup(
      deviceId: child.device.id,
      blockGroupId: .init(gifs),
    ))
    try await self.db.delete(all: BlockerApp.BlockRule.self)
    try await self.db.create(BlockerApp.BlockRule(
      rule: .flowTypeIs(value: .browser),
      groupId: .init(gifs),
    ))

    let body = """
    {"deviceId":"\(child.device.id
      .rawValue)","modelIdentifier":"iPhone15,2","appVersion":"1.7.0","iosVersion":"18.0"}
    """

    try await app.test(
      .POST,
      "pairql/ios-app/ConnectedRules_v2",
      headers: ["X-DeviceToken": child.token.value.rawValue.uuidString],
      body: .init(string: body),
      afterResponse: { (res: XCTHTTPResponse) async throws in
        expect(res.status).toEqual(.ok)
        expect(res.body.string.contains(#""browser":{}"#)).toEqual(true)
      },
    )
  }
}
