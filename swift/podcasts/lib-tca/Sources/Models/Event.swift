import Foundation
import SharingGRDB

@Table
struct Event {
  let id: Int
  let name: String
  let detail: String?
  let createdAt: Date
}
