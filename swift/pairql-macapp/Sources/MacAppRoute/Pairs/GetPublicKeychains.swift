import Foundation
import PairQL

public struct GetPublicKeychains: Pair {
  public static let auth: ClientAuth = .none

  public struct PublicKeychain: PairOutput {
    public var id: UUID
    public var name: String
    public var description: String?
    public var warning: String?
    public var brandColor: String?

    public init(
      id: UUID,
      name: String,
      description: String?,
      warning: String?,
      brandColor: String?,
    ) {
      self.id = id
      self.name = name
      self.description = description
      self.warning = warning
      self.brandColor = brandColor
    }
  }

  public typealias Output = [PublicKeychain]
}
