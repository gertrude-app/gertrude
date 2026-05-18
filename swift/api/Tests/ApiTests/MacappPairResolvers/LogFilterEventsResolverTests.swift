import DuetSQL
import Gertie
import MacAppRoute
import XCTest
import XExpect

@testable import Api

final class LogFilterEventsResolverTests: ApiTestCase, @unchecked Sendable {
  func testLogFilterEvents() async throws {
    try await self.db.delete(all: IdentifiedApp.self)
    try await self.db.delete(all: UnidentifiedApp.self)
    try await self.db.create(UnidentifiedApp(bundleId: "com.widget", count: 3))
    let child = try await self.childWithComputer()
    let xcode = try await self.db
      .create(IdentifiedApp(name: "Xcode", slug: "", launchable: true))
    try await self.db.create(AppBundleId(identifiedAppId: xcode.id, bundleId: "com.xcode"))

    let eventId1 = UUID().lowercased
    let eventId2 = UUID().lowercased

    let input = FilterLogs(
      bundleIds: [
        "com.widget": 3,
        "com.gadget": 2,
        "com.xcode": 1, // <-- identified, ignored
      ],
      events: [
        .init(id: eventId1, detail: "ev 1"): 1,
        .init(id: eventId2, detail: "ev 2"): 4,
      ],
    )

    _ = try await LogFilterEvents.resolve(with: input, in: child.context)

    let event1 = try await InterestingEvent.query()
      .where(.eventId == eventId1)
      .first(in: self.db)

    let event2 = try await InterestingEvent.query()
      .where(.eventId == eventId2)
      .first(in: self.db)

    expect(event1.detail).toEqual("ev 1")
    expect(event2.detail).toEqual("ev 2 (4x)") // <-- appends non-1 count
    expect(event1.computerUserId).toEqual(child.computerUser.id)
    expect(event2.computerUserId).toEqual(child.computerUser.id)
    expect(event1.kind).toEqual("event")
    expect(event2.kind).toEqual("event")
    expect(event1.context).toEqual("macapp-filter")

    let unidentifiedApps = try await UnidentifiedApp.query()
      .orderBy(.bundleId, .asc)
      .all(in: self.db)

    expect(unidentifiedApps.count).toEqual(2)
    expect(unidentifiedApps[0].bundleId).toEqual("com.gadget")
    expect(unidentifiedApps[0].count).toEqual(2)
    expect(unidentifiedApps[1].bundleId).toEqual("com.widget")
    expect(unidentifiedApps[1].count).toEqual(6) // <-- added to existing count

    let xcodeBundleId = try await AppBundleId.query()
      .where(.bundleId == "com.xcode")
      .first(in: self.db)
    expect(xcodeBundleId.count).toEqual(1) // <-- identified app count incremented

    // ensure no crash if all bundle ids already identified
    let input2 = FilterLogs(bundleIds: ["com.xcode": 5], events: [:])
    let output = try await LogFilterEvents.resolve(with: input2, in: child.context)
    expect(output).toEqual(.success)

    let xcodeBundleIdAfter = try await AppBundleId.query()
      .where(.bundleId == "com.xcode")
      .first(in: self.db)
    expect(xcodeBundleIdAfter.count).toEqual(6) // <-- accumulated
  }

  func testScreenTimeWarningEmailSentOncePerComputer() async throws {
    let child = try await self.childWithComputer()
    let input = FilterLogs(
      bundleIds: [:],
      events: [.init(id: "933aa385", detail: "Screen Time web filter detected"): 1],
    )

    _ = try await LogFilterEvents.resolve(with: input, in: child.context)

    expect(self.sent.emails.count).toEqual(1)
    expect(self.sent.emails[0].template).toEqual("screen-time-warning")
    expect(self.sent.emails[0].to).toEqual(child.parent.model.email.rawValue)
    expect(self.sent.emails[0].templateModel["childName"]).toEqual(child.model.name)
    expect(self.sent.emails[0].templateModel["computerName"]).not.toBeNil()

    let announcements = try await DashAnnouncement.query()
      .where(.parentId == child.parent.model.id)
      .all(in: self.db)
    expect(announcements.count).toEqual(1)
    expect(announcements[0].kind).toEqual(DashAnnouncement.Kind.warning)
    expect(announcements[0].learnMoreUrl).toEqual(
      "https://gertrude.app/blog/screen-time-web-filter-conflict",
    )

    _ = try await LogFilterEvents.resolve(with: input, in: child.context)
    _ = try await LogFilterEvents.resolve(with: input, in: child.context)

    expect(self.sent.emails.count).toEqual(1)

    let announcementsAfter = try await DashAnnouncement.query()
      .where(.parentId == child.parent.model.id)
      .all(in: self.db)
    expect(announcementsAfter.count).toEqual(1)
  }

  func testNoScreenTimeWarningEmailWhenFilteringDisabled() async throws {
    let child = try await self.child(with: {
      $0.filteringDisabled = true
    }).withDevice()
    let input = FilterLogs(
      bundleIds: [:],
      events: [.init(id: "933aa385", detail: "Screen Time web filter detected"): 1],
    )

    _ = try await LogFilterEvents.resolve(with: input, in: child.context)

    expect(self.sent.emails.count).toEqual(0)

    let emailSentEvents = try await InterestingEvent.query()
      .where(.eventId == "screentime-email-sent")
      .where(.computerUserId == child.computerUser.id)
      .all(in: self.db)
    expect(emailSentEvents.isEmpty).toEqual(true)

    let announcements = try await DashAnnouncement.query()
      .where(.parentId == child.parent.model.id)
      .all(in: self.db)
    expect(announcements.isEmpty).toEqual(true)
  }
}
