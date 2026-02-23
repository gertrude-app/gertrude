import Foundation

public struct BlockedApp {
  public var identifier: String
  public var schedule: RuleSchedule?

  public init(identifier: String, schedule: RuleSchedule? = nil) {
    self.identifier = identifier
    self.schedule = schedule
  }
}

public extension BlockedApp {
  func blocks(app: RunningApp, at date: Date, in calendar: Calendar = .current) -> Bool {
    let id = self.identifier.trimmingCharacters(in: .whitespaces)
    if self.schedule.map({ $0.active(at: date, in: calendar) }) == .some(false) {
      // if it has a schedule, and it's not active, we know it isn't blocked
      return false
    } else if app.localizedName == id {
      return true
    } else if app.bundleName == id {
      return true
    } else if app.bundleId == id {
      return true
    } else if id.contains("."), app.bundleId.contains(id) {
      return true
    } else {
      return false
    }
  }
}

public extension Collection<BlockedApp> {
  func blocks(app: RunningApp, at date: Date, in calendar: Calendar = .current) -> Bool {
    self.contains { $0.blocks(app: app, at: date, in: calendar) }
  }
}

// conformances

extension BlockedApp: Equatable, Codable, Sendable, Hashable {}
