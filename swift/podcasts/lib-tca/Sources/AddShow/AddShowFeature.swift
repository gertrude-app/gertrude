import ComposableArchitecture
import SharingGRDB
import SwiftUI

@Reducer
struct AddShowFeature {
  @ObservableState
  struct State: Equatable {
    var passcode: Int
    var authorized = false
    var lockout: Date? = .pinLockout()
  }

  enum Action: Equatable {
    case passcodeVerified
    case passcodeFailed
    case passcodeCancelled
  }

  @Dependency(\.dismiss) var dismiss
  @Dependency(\.defaultDatabase) var db
  @Dependency(\.date.now) var now

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .passcodeVerified:
        state.authorized = true
        self.insertAttempt(success: true)
        state.lockout = .pinLockout()
        return .none

      case .passcodeFailed:
        self.insertAttempt(success: false)
        state.lockout = .pinLockout()
        return .none

      case .passcodeCancelled:
        return .run { _ in
          await self.dismiss()
        }
      }
    }
  }

  func insertAttempt(success: Bool) {
    withErrorReporting {
      try self.db.write { db in
        try PinAttempt.insert {
          PinAttempt.Draft(success: success, createdAt: self.now)
        }.execute(db)
      }
    }
  }
}

extension Date {
  static func pinLockout() -> Date? {
    @Dependency(\.defaultDatabase) var db
    @Dependency(\.date.now) var now

    let attempts: [Date] = withErrorReporting {
      try db.read { db in
        try PinAttempt
          .select(\.createdAt)
          .where { $0.success == false }
          .where { $0.createdAt > now.addingTimeInterval(-24 * 60 * 60 * 10) }
          .order { $0.createdAt.asc() }
          .fetchAll(db)
      }
    } ?? []

    guard let last = attempts.last, attempts.count >= 5 else {
      return nil
    }

    print(attempts, last, now, attempts.count)
    // 5 minute lockout for 5-10 failed attempts, 20 minute lockout for more than 10
    let lockout = last.addingTimeInterval(60 * 5 * (attempts.count > 10 ? 4 : 1))
    return lockout > now ? lockout : nil
  }
}
