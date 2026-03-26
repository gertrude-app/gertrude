import Foundation
import PairQL

/// deprecated: v2.0.0 - v2.8.1
/// remove when MSV is 2.9.0
public struct CreateSignedScreenshotUpload: Pair {
  public static let auth: ClientAuth = .child

  public struct Input: PairInput {
    public let width: Int
    public let height: Int
    public var filterSuspended: Bool?
    public let createdAt: Date?

    public init(
      width: Int,
      height: Int,
      filterSuspended: Bool? = false,
      createdAt: Date? = nil,
    ) {
      self.width = width
      self.height = height
      self.filterSuspended = filterSuspended
      self.createdAt = createdAt
    }
  }

  public struct Output: PairOutput {
    public let uploadUrl: URL
    public let webUrl: URL

    public init(uploadUrl: URL, webUrl: URL) {
      self.uploadUrl = uploadUrl
      self.webUrl = webUrl
    }
  }
}
