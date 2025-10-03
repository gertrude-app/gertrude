import Foundation
import SQLiteData
import Tagged

@Table
struct Event {
  typealias ID = Tagged<Self, Int>
  let id: ID
  var name: String
  var detail: String?
  var createdAt: Date = .init()
}
