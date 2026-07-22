import Gertie
import XCTest

@testable import Api

final class BackfillUnrestrictedMacAppsTests: XCTestCase {
  typealias Backfill = BackfillUnrestrictedMacApps

  func testSingleUnscheduledSourceBecomesOneAlwaysOnRow() throws {
    let child = UUID()
    let plan = try Backfill.plan(sources: [
      self.source(child: child, slug: "slack", schedule: nil),
    ])
    XCTAssertEqual(plan.rows.count, 1)
    XCTAssertEqual(plan.rows[0].childId, child)
    XCTAssertEqual(plan.rows[0].scope, .identifiedAppSlug("slack"))
    XCTAssertNil(plan.rows[0].schedule)
    XCTAssertNil(plan.rows[0].scheduleJson)
  }

  func testSingleScheduledSourcePreservesSchedule() throws {
    let child = UUID()
    let plan = try Backfill.plan(sources: [
      self.source(
        child: child,
        slug: "slack",
        schedule: self.weekdaySchedule,
        scheduleJson: "{verbatim}",
      ),
    ])
    XCTAssertEqual(plan.rows.count, 1)
    XCTAssertEqual(plan.rows[0].schedule, self.weekdaySchedule)
    XCTAssertEqual(plan.rows[0].scheduleJson, "{verbatim}")
  }

  func testSharedKeychainFansOutOneRowPerChild() throws {
    let childA = UUID()
    let childB = UUID()
    let plan = try Backfill.plan(sources: [
      self.source(child: childA, slug: "slack", schedule: nil),
      self.source(child: childB, slug: "slack", schedule: nil),
    ])
    XCTAssertEqual(plan.rows.count, 2)
    XCTAssertEqual(Set(plan.rows.map(\.childId)), [childA, childB])
  }

  func testAnyUnscheduledSourceWinsForSameChildAndScope() throws {
    let child = UUID()
    let plan = try Backfill.plan(sources: [
      self.source(child: child, slug: "slack", schedule: self.weekdaySchedule),
      self.source(child: child, slug: "slack", schedule: nil),
    ])
    XCTAssertEqual(plan.rows.count, 1)
    XCTAssertNil(plan.rows[0].schedule)
  }

  func testAllIdenticalSchedulesCollapseToOneRow() throws {
    let child = UUID()
    let plan = try Backfill.plan(sources: [
      self.source(
        child: child,
        slug: "slack",
        schedule: self.weekdaySchedule,
        scheduleJson: "{first}",
      ),
      self.source(
        child: child,
        slug: "slack",
        schedule: self.weekdaySchedule,
        scheduleJson: "{second}",
      ),
    ])
    XCTAssertEqual(plan.rows.count, 1)
    XCTAssertEqual(plan.rows[0].schedule, self.weekdaySchedule)
  }

  func testDifferingSchedulesWithoutExceptionAborts() {
    let child = UUID()
    XCTAssertThrowsError(try Backfill.plan(sources: [
      self.source(child: child, slug: "slack", schedule: self.weekdaySchedule),
      self.source(child: child, slug: "slack", schedule: self.weekendSchedule),
    ])) { error in
      guard case Backfill.BackfillError.unresolvedScheduleConflict = error else {
        return XCTFail("expected unresolvedScheduleConflict, got \(error)")
      }
    }
  }

  func testPreResolvedConflictResolvesAndPassesAssertion() throws {
    let conflictChild = UUID(
      uuidString: Backfill.preResolvedScheduleConflicts[0].childIdPrefix + "0000",
    )!
    let plan = try Backfill.plan(sources: [
      Backfill.Source(
        childId: conflictChild,
        scope: .identifiedAppSlug("chrome"),
        schedule: self.weekdaySchedule,
        scheduleJson: "{weekday}",
      ),
      Backfill.Source(
        childId: conflictChild,
        scope: .identifiedAppSlug("chrome"),
        schedule: self.weekendSchedule,
        scheduleJson: "{weekend}",
      ),
    ])
    XCTAssertEqual(plan.rows.count, 1)
    XCTAssertEqual(plan.rows[0].scope, .identifiedAppSlug("chrome"))
    XCTAssertEqual(plan.rows[0].schedule, Backfill.preResolvedScheduleConflicts[0].resolved)
  }

  func testAssertionCatchesBehavioralDivergence() {
    let key = Backfill.GroupKey(childId: UUID(), scope: .identifiedAppSlug("slack"))
    let groups: [Backfill.GroupKey: [Backfill.Source]] = [
      key: [self.source(child: key.childId, slug: "slack", schedule: self.weekdaySchedule)],
    ]
    let divergentRow = Backfill.NewRow(
      id: UUID(),
      childId: key.childId,
      scope: key.scope,
      scopeJson: "{}",
      schedule: self.weekendSchedule,
      scheduleJson: "{weekend}",
    )
    XCTAssertThrowsError(
      try Backfill.assertBehaviorPreserved(groups: groups, rows: [divergentRow]),
    ) { error in
      guard case Backfill.BackfillError.behavioralDivergence = error else {
        return XCTFail("expected behavioralDivergence, got \(error)")
      }
    }
  }

  func testAssertionAllowsEquivalentButDifferentlyShapedSchedule() throws {
    let key = Backfill.GroupKey(childId: UUID(), scope: .identifiedAppSlug("slack"))
    let groups: [Backfill.GroupKey: [Backfill.Source]] = [
      key: [
        self.source(child: key.childId, slug: "slack", schedule: self.weekdaySchedule),
        self.source(child: key.childId, slug: "slack", schedule: nil),
      ],
    ]
    let alwaysOnRow = Backfill.NewRow(
      id: UUID(),
      childId: key.childId,
      scope: key.scope,
      scopeJson: "{}",
      schedule: nil,
      scheduleJson: nil,
    )
    XCTAssertNoThrow(
      try Backfill.assertBehaviorPreserved(groups: groups, rows: [alwaysOnRow]),
    )
  }

  func testLeadingDotBundleIdIsNormalizedInRowAndJson() throws {
    let child = UUID()
    let plan = try Backfill.plan(sources: [
      self.bundleSource(child: child, bundleId: ".com.apple.sharingd", schedule: nil),
    ])
    XCTAssertEqual(plan.rows.count, 1)
    XCTAssertEqual(plan.rows[0].scope, .bundleId("com.apple.sharingd"))
    XCTAssertFalse(plan.rows[0].scopeJson.contains(".com.apple.sharingd"))
  }

  func testDottedAndCleanBundleIdsMergeForSameChild() throws {
    let child = UUID()
    let plan = try Backfill.plan(sources: [
      self.bundleSource(child: child, bundleId: ".com.testsys.SecureBrowser.ITS", schedule: nil),
      self.bundleSource(child: child, bundleId: "com.testsys.SecureBrowser.ITS", schedule: nil),
    ])
    XCTAssertEqual(plan.rows.count, 1)
    XCTAssertEqual(plan.rows[0].scope, .bundleId("com.testsys.SecureBrowser.ITS"))
    XCTAssertNil(plan.rows[0].schedule)
  }

  func testDotVariantsAcrossDifferentChildrenStaySeparate() throws {
    let childA = UUID()
    let childB = UUID()
    let plan = try Backfill.plan(sources: [
      self.bundleSource(child: childA, bundleId: ".com.foo", schedule: nil),
      self.bundleSource(child: childB, bundleId: "com.foo", schedule: nil),
    ])
    XCTAssertEqual(plan.rows.count, 2)
    XCTAssertEqual(Set(plan.rows.map(\.childId)), [childA, childB])
    XCTAssertEqual(Set(plan.rows.map(\.scope)), [.bundleId("com.foo")])
  }

  // helpers

  private func source(
    child: UUID,
    slug: String,
    schedule: RuleSchedule?,
    scheduleJson: String? = nil,
  ) -> Backfill.Source {
    Backfill.Source(
      childId: child,
      scope: .identifiedAppSlug(slug),
      schedule: schedule,
      scheduleJson: schedule == nil ? nil : (scheduleJson ?? "{}"),
    )
  }

  private func bundleSource(
    child: UUID,
    bundleId: String,
    schedule: RuleSchedule?,
  ) -> Backfill.Source {
    Backfill.Source(
      childId: child,
      scope: .bundleId(bundleId),
      schedule: schedule,
      scheduleJson: schedule == nil ? nil : "{}",
    )
  }

  private let weekdaySchedule = RuleSchedule(
    mode: .active,
    days: RuleSchedule.Days(
      sunday: false,
      monday: true,
      tuesday: true,
      wednesday: true,
      thursday: true,
      friday: true,
      saturday: false,
    ),
    window: PlainTimeWindow(
      start: PlainTime(hour: 7, minute: 0),
      end: PlainTime(hour: 17, minute: 0),
    ),
  )

  private let weekendSchedule = RuleSchedule(
    mode: .active,
    days: RuleSchedule.Days(
      sunday: true,
      monday: false,
      tuesday: false,
      wednesday: false,
      thursday: false,
      friday: false,
      saturday: true,
    ),
    window: PlainTimeWindow(
      start: PlainTime(hour: 8, minute: 0),
      end: PlainTime(hour: 22, minute: 30),
    ),
  )
}
