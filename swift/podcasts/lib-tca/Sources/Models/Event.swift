import Foundation
import SharingGRDB
import Tagged

@Table
struct Event {
  typealias ID = Tagged<Self, Int>
  let id: ID
  let name: String
  let detail: String?
  let createdAt: Date
}
