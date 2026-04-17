import Dependencies
import DuetSQL
import Gertie
import MacAppRoute
import XCTest
import XExpect

@testable import Api

final class SetDowntimeScheduleResolverTests: ApiTestCase, @unchecked Sendable {
  func testSuccessfullySetsDowntimeSchedule() async throws {
    let child = try await self.child(with: {
      $0.downtime = nil
    }).withDevice()

    let window = PlainTimeWindow(
      start: PlainTime(hour: 21, minute: 0),
      end: PlainTime(hour: 7, minute: 30),
    )
    let output = try await SetDowntimeSchedule.resolve(with: window, in: context(child))

    expect(output).toEqual(.success)

    let updated = try await self.db.find(child.model.id)
    expect(updated.downtime).toEqual(window)

    let events = try await InterestingEvent.query()
      .where(.eventId == "cf582b72")
      .where(.computerUserId == child.computerUser.id)
      .all(in: self.db)

    expect(events).toHaveCount(1)
    let detail = try XCTUnwrap(events.first?.detail)
    expect(detail).toContain("downtime set during onboarding")
    expect(detail).toContain("21:00-7:30")
  }

  func testRejectsInvalidWindows() async throws {
    let child = try await self.child(with: {
      $0.downtime = nil
    }).withDevice()

    let invalid: [PlainTimeWindow] = [
      .init(start: .init(hour: 24, minute: 0), end: .init(hour: 7, minute: 0)),
      .init(start: .init(hour: -1, minute: 0), end: .init(hour: 7, minute: 0)),
      .init(start: .init(hour: 21, minute: 0), end: .init(hour: 24, minute: 0)),
      .init(start: .init(hour: 21, minute: 60), end: .init(hour: 7, minute: 0)),
      .init(start: .init(hour: 21, minute: 0), end: .init(hour: 7, minute: -1)),
      .init(start: .init(hour: 21, minute: 0), end: .init(hour: 21, minute: 0)),
    ]

    for window in invalid {
      do {
        _ = try await SetDowntimeSchedule.resolve(with: window, in: self.context(child))
        XCTFail("expected error to be thrown for \(window)")
      } catch let error as PqlError {
        expect(error.type).toEqual(.badRequest)
      }
    }

    let updated = try await self.db.find(child.model.id)
    expect(updated.downtime).toBeNil()
  }

  func testRejectedWhenTokenTooOld() async throws {
    let child = try await self.child(with: {
      $0.downtime = nil
    }).withDevice()

    let window = PlainTimeWindow(
      start: PlainTime(hour: 21, minute: 0),
      end: PlainTime(hour: 7, minute: 30),
    )

    let tooOld = child.token.createdAt.addingTimeInterval(25 * 60 * 60)
    do {
      try await withDependencies {
        $0.date = .constant(tooOld)
      } operation: {
        _ = try await SetDowntimeSchedule.resolve(
          with: window,
          in: self.context(child),
        )
      }
      XCTFail("expected error to be thrown")
    } catch let error as PqlError {
      expect(error.type).toEqual(.unauthorized)
    }

    let updated = try await self.db.find(child.model.id)
    expect(updated.downtime).toBeNil()

    let events = try await InterestingEvent.query()
      .where(.eventId == "1eda41cd")
      .all(in: self.db)

    expect(events).toHaveCount(1)
    let detail = try XCTUnwrap(events.first?.detail)
    expect(detail).toContain("suspicious SetDowntimeSchedule")
  }
}
