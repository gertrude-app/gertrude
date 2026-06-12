import Foundation
import SQLiteData
import Tagged

@Table
struct CrossPromoDismissal {
  typealias ID = Tagged<Self, String>
  let id: ID
  var dismissedAt: Date = .init()
}

extension CrossPromoDismissal {
  static func find(id: ID) -> Where<CrossPromoDismissal> {
    CrossPromoDismissal.where { $0.id.eq(id) }
  }
}
