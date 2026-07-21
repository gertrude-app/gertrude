import DuetSQL
import Foundation
import PairQL
import XCTest
import XExpect

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@testable import Api

final class MusicAdminResolverTests: ApiTestCase, @unchecked Sendable {
  func testRouteParses() throws {
    let token = UUID(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef")!
    var request = URLRequest(url: URL(string: "admin/MusicOverview")!)
    request.httpMethod = "POST"
    request.addValue(token.uuidString, forHTTPHeaderField: "X-SuperAdminToken")

    let matched = try PairQLRoute.router.match(request: request)

    expect(matched).toEqual(.admin(.authed(token, .musicOverview)))
  }

  func testListAndDetailUseInstallsAndTolerateMissingEvents() async throws {
    try await self.resetMusicAdminTables()
    let parent = try await self.parent()
    try await self.addPaidSubscription(for: parent.id, tier: .medium)
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let connectedDevice = try await self.db.create(IOSDevice.mock { $0.childId = child.id })
    let connectedInstall = try await self.db.create(MusicApp.Install(
      deviceId: connectedDevice.id,
      appVersion: "1.0.0",
    ))
    try await self.db.create(MusicApp.Token(installId: connectedInstall.id))
    try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "album_1",
      title: "Kind of Blue",
      artistName: "Miles Davis",
      trackCount: 5,
    ))

    let unclaimedDevice = try await self.db.create(IOSDevice.mock)
    try await self.db.create(MusicApp.Install(
      deviceId: unclaimedDevice.id,
      appVersion: "1.0.0",
    ))

    let list = try await MusicInstallsList.resolve(
      with: .init(page: 1, pageSize: 30),
      in: .mock,
    )

    expect(list.totalCount).toEqual(2)
    expect(list.installs.map(\.status).contains("paid")).toBeTrue()
    expect(list.installs.map(\.status).contains("unclaimed")).toBeTrue()

    let connectedDetail = try await MusicInstallDetail.resolve(
      with: .init(deviceId: connectedDevice.id.rawValue),
      in: .mock,
    )
    expect(connectedDetail.status).toEqual("paid")
    expect(connectedDetail.connectedAccount?.parentId).toEqual(parent.id)
    expect(connectedDetail.approvedAlbums.map(\.title)).toEqual(["Kind of Blue"])
    expect(connectedDetail.events).toHaveCount(0)

    let unclaimedDetail = try await MusicInstallDetail.resolve(
      with: .init(deviceId: unclaimedDevice.id.rawValue),
      in: .mock,
    )
    expect(unclaimedDetail.status).toEqual("unclaimed")
    expect(unclaimedDetail.connectedAccount).toBeNil()
    expect(unclaimedDetail.approvedAlbums).toHaveCount(0)
    expect(unclaimedDetail.events).toHaveCount(0)
  }

  func testOverviewCountsStatusesAndApprovedAlbums() async throws {
    try await self.resetMusicAdminTables()
    let parent = try await self.parent()
    try await self.addPaidSubscription(for: parent.id, tier: .medium)
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let paidDevice = try await self.db.create(IOSDevice.mock { $0.childId = child.id })
    let paidInstall = try await self.db.create(MusicApp.Install(
      deviceId: paidDevice.id,
      appVersion: "1.0.0",
    ))
    try await self.db.create(MusicApp.Token(installId: paidInstall.id))
    try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "album_1",
      title: "Blue Train",
      artistName: "John Coltrane",
    ))

    let unclaimedDevice = try await self.db.create(IOSDevice.mock)
    try await self.db.create(MusicApp.Install(
      deviceId: unclaimedDevice.id,
      appVersion: "1.0.0",
    ))

    let output = try await MusicOverview.resolve(in: .mock)

    expect(output.totalInstalls).toEqual(2)
    expect(output.connectedMusicUsers).toEqual(1)
    expect(output.paidMusicFamilies).toEqual(1)
    expect(output.approvedAlbums).toEqual(1)
    expect(output.statusBreakdown.paid).toEqual(1)
    expect(output.statusBreakdown.unclaimed).toEqual(1)
  }

  private func resetMusicAdminTables() async throws {
    try await self.db.delete(all: Music.ApprovedAlbum.self)
    try await self.db.delete(all: MusicApp.Event.self)
    try await self.db.delete(all: MusicApp.Token.self)
    try await self.db.delete(all: MusicApp.Install.self)
  }
}
