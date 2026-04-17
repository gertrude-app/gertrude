import Foundation
import PairQL

public struct GetOnboardingConfig: Pair {
  public static let auth: ClientAuth = .child

  public struct PublicKeychain: PairNestable {
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

  public struct AlwaysBlockedGroup: PairNestable {
    public var id: UUID
    public var name: String
    public var description: String
    public var longDescription: String

    public init(id: UUID, name: String, description: String, longDescription: String) {
      self.id = id
      self.name = name
      self.description = description
      self.longDescription = longDescription
    }
  }

  public struct AlwaysBlocked: PairNestable {
    public var groups: [AlwaysBlockedGroup]
    public var preselected: [UUID]

    public init(groups: [AlwaysBlockedGroup], preselected: [UUID]) {
      self.groups = groups
      self.preselected = preselected
    }
  }

  public struct Output: PairOutput {
    public var publicKeychains: [PublicKeychain]
    public var alwaysBlocked: AlwaysBlocked

    public init(publicKeychains: [PublicKeychain], alwaysBlocked: AlwaysBlocked) {
      self.publicKeychains = publicKeychains
      self.alwaysBlocked = alwaysBlocked
    }
  }
}
