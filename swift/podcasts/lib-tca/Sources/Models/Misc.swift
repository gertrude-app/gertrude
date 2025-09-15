import Foundation
import SharingGRDB

@Table
struct Misc: Equatable, Hashable {
  var id: String
  var value: String
  var rowId: Int?
  var updatedAt: Date = .init()
  var createdAt: Date
}

extension Misc {
  struct Ids {
    let nowPlaying = "nowPlaying/v1"
  }

  static let ids = Ids()

  func decodingValue<T: Decodable>(as type: T.Type) -> T? {
    guard let data = self.value.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode(T.self, from: data)
  }
}
