import DuetSQL
import Foundation
import XCTest
import XExpect

@testable import Api

final class CohortAnalysisResolverTests: ApiTestCase, @unchecked Sendable {
  func testCohortRowSegmentsSignupsAndRevenue() async throws {
    let cohortDate = Date(timeIntervalSince1970: 805_000_000)
    let monthKey = "1995-07"

    // Parent A: paid-intent (Mac), mac-protected, ever-paid + currently paying
    let customerId = "cus_cohorttest_\(UUID().uuidString.prefix(8))"
    let a = try await self.childWithComputer()
    var screenshot = Screenshot.random
    screenshot.computerUserId = a.computerUser.id
    try await self.db.create(screenshot)
    var keychain = Keychain.random
    keychain.parentId = a.parent.model.id
    keychain.isPublic = false
    try await self.db.create(keychain)
    var key = Key.random
    key.keychainId = keychain.id
    key.deletedAt = nil
    try await self.db.create(key)
    try await self.db.create(ChildKeychain(childId: a.model.id, keychainId: keychain.id))
    try await self.db.create(BillingIdentity(
      parentId: a.parent.model.id,
      stripeCustomerId: .init(rawValue: customerId),
    ))
    try await self.db.create(StripeSubscription(
      parentId: a.parent.model.id,
      tier: .full,
      stripeId: "sub_cohorttest",
      stripeStatus: .active,
      currentPeriodEnd: .reference + .days(30),
    ))
    try await self.db.create(StripeEvent(
      json: """
      {"type":"invoice.paid","data":{"object":{"id":"in_cohorttest",\
      "customer":"\(customerId)","amount_paid":1000}}}
      """,
    ))

    // Parent B: free-iOS account only (iOS device, no Mac, no supervision)
    let b = try await self.childWithIOSDevice()

    let d = try await self.child()
    let musicDevice = try await self.db.create(IOSDevice.mock { $0.childId = d.id })
    try await self.db.create(MusicApp.Install(
      deviceId: musicDevice.id,
      appVersion: "1.0.0",
    ))

    // Parent C: verified signup, no surface
    let c = try await self.parent { $0.emailVerifiedAt = .reference }

    for parentId in [a.parent.model.id, b.parent.model.id, c.model.id, d.parent.model.id] {
      try await self.placeParentInCohort(parentId, at: cohortDate)
    }

    let output = try await CohortAnalysis.resolve(in: .mock)
    let row = try XCTUnwrap(output.cohorts.first { $0.month == monthKey })

    expect(row.verifiedSignups).toEqual(4)
    expect(row.paidIntentCount).toEqual(2)
    expect(row.paidIntentEverPaidCount).toEqual(1)
    expect(row.paidIntentPayingCount).toEqual(1)
    expect(row.freeIosCount).toEqual(1)
    expect(row.freeIosProtectedCount).toEqual(0)
    expect(row.protectedCount).toEqual(1)
    expect(row.macProtectedCount).toEqual(1)
    expect(row.iosProtectedCount).toEqual(0)
    expect(row.everPaidCount).toEqual(1)
    expect(row.currentlyPayingCount).toEqual(1)
  }

  func testFilteringDisabledMacChildCountsAsMacProtectedWithoutKeys() async throws {
    let cohortDate = Date(timeIntervalSince1970: 947_894_400)
    let monthKey = "2000-01"

    let child = try await self.childWithComputer()
    var childModel = child.model
    childModel.filteringDisabled = true
    try await self.db.update(childModel)
    var screenshot = Screenshot.random
    screenshot.computerUserId = child.computerUser.id
    try await self.db.create(screenshot)
    try await self.placeParentInCohort(child.parent.model.id, at: cohortDate)

    let output = try await CohortAnalysis.resolve(in: .mock)
    let row = try XCTUnwrap(output.cohorts.first { $0.month == monthKey })

    expect(row.verifiedSignups).toEqual(1)
    expect(row.protectedCount).toEqual(1)
    expect(row.macProtectedCount).toEqual(1)
  }

  private func placeParentInCohort(_ id: Parent.Id, at date: Date) async throws {
    var stmt = SQL.Statement("""
    UPDATE \(table: Parent.self) SET \(Parent.columnName(.createdAt)) =
    """)
    stmt.components.append(.binding(.date(date)))
    stmt.components.append(.sql(", \(Parent.columnName(.emailVerifiedAt)) = "))
    stmt.components.append(.binding(.date(date)))
    stmt.components.append(.sql(" WHERE \(Parent.columnName(.id)) = "))
    stmt.components.append(.binding(.uuid(id)))
    try await self.db.execute(statement: stmt)
  }
}
