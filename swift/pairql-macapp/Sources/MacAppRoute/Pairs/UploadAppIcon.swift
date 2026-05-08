import Foundation
import PairQL

public struct UploadAppIcon: Pair {
  public static let auth: ClientAuth = .child

  public struct Input: PairInput {
    public var bundleId: String
    public var iconData: Data
    public var iconContentHash: String
    public var appVersion: String?

    public init(
      bundleId: String,
      iconData: Data,
      iconContentHash: String,
      appVersion: String? = nil,
    ) {
      self.bundleId = bundleId
      self.iconData = iconData
      self.iconContentHash = iconContentHash
      self.appVersion = appVersion
    }
  }

  public typealias Output = SuccessOutput
}
