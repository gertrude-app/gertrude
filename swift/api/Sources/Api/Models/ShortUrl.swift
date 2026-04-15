import Dependencies
import Duet
import Foundation

struct ShortUrl: Codable, Sendable {
  var id: Id
  var shortId: String
  var target: String
  var clickCount: Int
  var createdAt = Date()
  var deletedAt: Date

  init(
    id: Id? = nil,
    shortId: String? = nil,
    target: String,
    clickCount: Int = 0,
    deletedAt: Date? = nil,
  ) {
    @Dependency(\.uuid) var uuid
    self.id = id ?? .init(uuid())
    self.shortId = shortId ?? ShortUrl.generateShortId()
    self.target = target
    self.clickCount = clickCount
    self.deletedAt = deletedAt ?? Date(addingDays: 7)
  }
}

extension ShortUrl {
  static let alphabet = Array("23456789abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ")

  static func generateShortId(length: Int = 6) -> String {
    String((0 ..< length).map { _ in self.alphabet.randomElement()! })
  }

  var publicUrl: String {
    "https://gertrude.app/u/\(self.shortId)"
  }

  static let securityEvents = "https://gertrude.app/u/s"
}
