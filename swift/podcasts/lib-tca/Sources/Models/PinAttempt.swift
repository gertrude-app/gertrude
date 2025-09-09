import Foundation
import SharingGRDB

@Table
struct PinAttempt {
  let id: Int
  let success: Bool
  let createdAt: Date
}
