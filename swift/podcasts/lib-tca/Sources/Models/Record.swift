import Foundation
import SQLiteData
import Tagged

@Table
struct Record {
  typealias ID = Tagged<Self, String>
  let id: ID
  var value: String
  var detail: String?
  var updatedAt: Date = .init()
  var createdAt: Date = .init()
}

extension Record {
  static func find(id: ID) -> Where<Record> {
    Record.where { $0.id == id }
  }
}

extension Record.ID {
  static let installDate = Record.ID(rawValue: "installDate")
  static let installId = Record.ID(rawValue: "installId")
  static let onboardingFinished = Record.ID(rawValue: "onboardingFinished")
  static let trialEndingAlertShown = Record.ID(rawValue: "trialEndingAlertShown")
  static let feedUpdatesLock = Record.ID(rawValue: "feedUpdatesLock")
}
