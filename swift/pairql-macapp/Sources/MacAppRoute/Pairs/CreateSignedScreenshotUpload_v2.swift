import Foundation
import PairQL

/// in use: v2.9.0 - present
public struct CreateSignedScreenshotUpload_v2: Pair {
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

    public init(uploadUrl: URL) {
      self.uploadUrl = uploadUrl
    }
  }
}
