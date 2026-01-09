import DuetSQL

extension DuetSQL.Client {
  func logDeprecated(_ event: String) async {
    guard get(dependency: \.env.mode) == .prod else {
      return
    }

    if var existing = try? await InterestingEvent.query()
      .where(.eventId == event)
      .where(.kind == "deprecation")
      .where(.context == "active")
      .first(in: self) {
      existing.createdAt = Date()
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

  func notifyDeprecationComplete(
    if event: String,
    notLoggedWithinLast interval: TimeInterval,
  ) async {
    guard get(dependency: \.env.mode) == .prod else {
      return
    }

    guard var record = try? await InterestingEvent.query()
      .where(.eventId == event)
      .where(.kind == "deprecation")
      .where(.context == "active")
      .first(in: self) else {
      return
    }

    guard record.createdAt < Date().addingTimeInterval(-interval) else {
      return
    }

    record.context = "complete"
    _ = try? await self.update(record)

    with(dependency: \.postmark)
      .toSuperAdmin("deprecation complete!", event)
  }
}
