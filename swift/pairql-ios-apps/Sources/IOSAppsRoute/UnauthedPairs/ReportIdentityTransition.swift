import Foundation
import GertieApp
import PairQL

public struct ReportIdentityTransition: Pair {
  public static let auth: ClientAuth = .none

  public enum Kind: String, Codable, Sendable {
    case migrated
    case sameDevice = "same_device"
  }

  public enum Reason: String, Codable, Sendable {
    case normal
    case supervisionCanonical
    case childConflictPin
    case resolvedAsMigration
  }

  public struct Input: PairInput {
    public var app: GertrudeIOSApp
    public var oldDeviceId: UUID
    public var newDeviceId: UUID
    public var kind: Kind
    public var proofToken: UUID?
    public var modelIdentifier: String
    public var iosVersion: String
    public var appVersion: String
    public var liveVendorId: UUID?

    public init(
      app: GertrudeIOSApp,
      oldDeviceId: UUID,
      newDeviceId: UUID,
      kind: Kind,
      proofToken: UUID? = nil,
      modelIdentifier: String,
      iosVersion: String,
      appVersion: String,
      liveVendorId: UUID? = nil,
    ) {
      self.app = app
      self.oldDeviceId = oldDeviceId
      self.newDeviceId = newDeviceId
      self.kind = kind
      self.proofToken = proofToken
      self.modelIdentifier = modelIdentifier
      self.iosVersion = iosVersion
      self.appVersion = appVersion
      self.liveVendorId = liveVendorId
    }
  }

  public struct Output: PairOutput {
    public var deviceId: UUID
    public var reason: Reason
    public var childId: UUID?
    public var token: UUID?

    public init(deviceId: UUID, reason: Reason, childId: UUID? = nil, token: UUID? = nil) {
      self.deviceId = deviceId
      self.reason = reason
      self.childId = childId
      self.token = token
    }
  }
}
