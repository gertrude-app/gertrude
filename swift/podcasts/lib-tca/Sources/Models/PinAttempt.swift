import Foundation
import SharingGRDB
import Tagged

@Table
struct PinAttempt {
  typealias ID = Tagged<Self, Int>
  let id: ID
  let success: Bool
  let createdAt: Date
}
