import DuetSQL

extension DuetSQL.Client {
  func logDeprecated(_ event: String) async {
    guard get(dependency: \.env.mode) == .prod else {
      return
    }

    if let existing = try? await InterestingEvent.query()
      .where(.eventId == event)
      .where(.kind == "deprecation")
      .where(.context == "active")
      .first(in: self) {
      _ = try? await self.update(existing)
      return
    }

    _ = try? await self.create(InterestingEvent(
      eventId: event,
      kind: "deprecation",
      context: "active",
    ))
    with(dependency: \.postmark)
      .toSuperAdmin("deprecation starting", event)
  }

  func notifyCompletedDeprecations(noRequestsWithinLast interval: TimeInterval) async {
    guard get(dependency: \.env.mode) == .prod else {
      return
    }

    guard let stale = try? await InterestingEvent.query()
      .where(.kind == "deprecation")
      .where(.context == "active")
      .where(.updatedAt < Date().addingTimeInterval(-interval))
      .all(in: self) else {
      return
    }

    for var record in stale {
      record.context = "complete"
      _ = try? await self.update(record)
      with(dependency: \.postmark)
        .toSuperAdmin("deprecation complete!", record.eventId)
    }
  }
}
