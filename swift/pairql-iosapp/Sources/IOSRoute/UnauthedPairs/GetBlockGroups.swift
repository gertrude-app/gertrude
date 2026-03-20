import Foundation
import PairQL

/// in use: v1.8.0 - present
public struct GetBlockGroups: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var deviceId: UUID

    public init(deviceId: UUID) {
      self.deviceId = deviceId
    }
  }

  public struct BlockGroupInfo: PairOutput, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var shortDescription: String
    public var longDescription: String
    public var imageSlug: String?

    public init(
      id: UUID,
      name: String,
      shortDescription: String,
      longDescription: String,
      imageSlug: String? = nil,
    ) {
      self.id = id
      self.name = name
      self.shortDescription = shortDescription
      self.longDescription = longDescription
      self.imageSlug = imageSlug
    }
  }

  public typealias Output = [BlockGroupInfo]
}
