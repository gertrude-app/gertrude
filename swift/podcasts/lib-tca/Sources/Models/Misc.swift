import Foundation
import SharingGRDB
import Tagged

@Table
struct Misc: Equatable, Hashable, Identifiable {
  typealias ID = Tagged<Self, String>
  let id: ID
  var value: String
  var rowId: Int?
  var updatedAt: Date = .init()
  var createdAt: Date = .init()
}

extension Misc {
  static func find(id: ID) -> Where<Misc> {
    Misc.where { $0.id == id }
  }

  func decodingValue<T: Decodable>(as type: T.Type) -> T? {
    guard let data = self.value.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode(T.self, from: data)
  }
}

extension Misc.ID {
  static let nowPlaying = Misc.ID(rawValue: "nowPlaying/v1")
}
