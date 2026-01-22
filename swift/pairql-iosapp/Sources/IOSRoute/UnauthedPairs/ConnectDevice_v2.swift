import Foundation
import GertieIOS
import PairQL

public struct ChildIOSDeviceData_v2: PairOutput {
  /// NB: this should be forward-compatible adding more possible states
  public enum Supervised: Codable, Equatable, Sendable {
    case byGertrude(claimCode: Int)
    case byOtherMethodUnconfirmed
    case byConfigurator
  }

  public var childId: UUID
  public var token: UUID
  public var deviceId: UUID
  public var childName: String
  public var supervised: Supervised?

  public var supervisedByGertrude: Bool {
    if case .byGertrude = self.supervised { true } else { false }
  }

  public init(
    childId: UUID,
    token: UUID,
    deviceId: UUID,
    childName: String,
    supervised: Supervised? = nil,
  ) {
    self.childId = childId
    self.token = token
    self.deviceId = deviceId
    self.childName = childName
    self.supervised = supervised
  }
}

/// in use: v1.7.x - present
public struct ConnectDevice_v2: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var verificationCode: Int
    public var vendorId: UUID
    public var modelIdentifier: String
    public var appVersion: String
    public var iosVersion: String

    public init(
      verificationCode: Int,
      vendorId: UUID,
      modelIdentifier: String,
      appVersion: String,
      iosVersion: String,
    ) {
      self.verificationCode = verificationCode
      self.vendorId = vendorId
      self.modelIdentifier = modelIdentifier
      self.appVersion = appVersion
      self.iosVersion = iosVersion
    }
  }

  public typealias Output = ChildIOSDeviceData_v2
}
