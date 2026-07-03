import Foundation

public struct RecordingSuspension: Equatable, Sendable {
  public var expiration: Date
  public var graceUntil: Date

  public init(expiration: Date, graceUntil: Date) {
    self.expiration = expiration
    self.graceUntil = graceUntil
  }
}

public extension RecordingSuspension {
  static let screenshotInterval: TimeInterval = 5
  static let livenessWiggle: TimeInterval = 1
  static let livenessWindow: TimeInterval = screenshotInterval + livenessWiggle

  static func entered(expiration: Date?, now: Date) -> RecordingSuspension? {
    guard let expiration, expiration > now else { return nil }
    return RecordingSuspension(expiration: expiration, graceUntil: now + self.livenessWindow)
  }

  static func rederived(expiration: Date?, lastScreenshot: Date?, now: Date)
    -> RecordingSuspension? {
    guard let expiration, expiration > now else { return nil }
    guard self.recordingIsLive(lastScreenshot: lastScreenshot, now: now) else { return nil }
    return RecordingSuspension(expiration: expiration, graceUntil: .distantPast)
  }

  static func recordingIsLive(lastScreenshot: Date?, now: Date) -> Bool {
    guard let lastScreenshot else { return false }
    let elapsed = now.timeIntervalSince(lastScreenshot)
    return elapsed >= 0 && elapsed < self.livenessWindow
  }

  func isValid(lastScreenshot: Date?, now: Date) -> Bool {
    guard self.expiration > now else { return false }
    return now < self.graceUntil
      || Self.recordingIsLive(lastScreenshot: lastScreenshot, now: now)
  }
}
