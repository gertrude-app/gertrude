import Foundation
import TSCodable
import XCore

@TSCodable
enum Entitlement: Equatable, Sendable {
  case free
  case light
  case fullTrial(until: Date)
  case fullTrialGrace(until: Date)
  case full
  case complimentary
}

extension Entitlement {
  static let trialPeriod: TimeInterval = .days(21)
  static let gracePeriod: TimeInterval = .days(7)
}
