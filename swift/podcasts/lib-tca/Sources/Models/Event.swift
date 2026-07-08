import Foundation
import SQLiteData
import Tagged

@Table
struct Event {
  typealias ID = Tagged<Self, Int>
  let id: ID
  var kind: String
  var detail: String?
  var apiId: String?
  var createdAt: Date = .init()
}
