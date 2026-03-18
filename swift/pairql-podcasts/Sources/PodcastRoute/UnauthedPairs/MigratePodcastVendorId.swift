import Foundation
import PairQL

/// in use: v1.4.x - present
public struct MigratePodcastVendorId: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var oldDeviceId: UUID
    public var newVendorId: UUID

    public init(oldDeviceId: UUID, newVendorId: UUID) {
      self.oldDeviceId = oldDeviceId
      self.newVendorId = newVendorId
    }
  }

  public typealias Output = Infallible
}
