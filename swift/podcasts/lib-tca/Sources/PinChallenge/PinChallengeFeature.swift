import ComposableArchitecture
import Foundation
import SQLiteData

@Reducer
struct PinChallengeFeature {
  let logBaseId: String

  @ObservableState
  struct State: Equatable {
    var lockout: Date? = .pinLockout()
  }

  enum Action: Equatable {
    case pincodeVerified
    case pincodeFailed
    case pincodeCancelled
    case delegate(Delegate)

    enum Delegate: Equatable {
      case cancelled
      case verified
    }
  }

  @Dependency(\.db) var db
  @Dependency(\.date.now) var now
  @Dependency(\.haptics) var haptics

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .pincodeVerified:
        self.insertAttempt(success: true)
        let wasLockedOut = state.lockout != nil
        state.lockout = .pinLockout()
        return .run { send in
          await self.haptics.notification(.success)
          if wasLockedOut { log(.info("\(self.logBaseId)-1"), "pin lockout cleared") }
          await send(.delegate(.verified))
        }

      case .pincodeFailed:
        self.insertAttempt(success: false)
        let lockout = Date.pinLockout()
        let newlyLockedOut = lockout != nil && state.lockout == nil
        state.lockout = lockout
        return .run { _ in
          await self.haptics.notification(.error)
          if newlyLockedOut { log(.info("\(self.logBaseId)-2"), "pin lockout set") }
        }

      case .pincodeCancelled:
        return .send(.delegate(.cancelled))

      case .delegate:
        return .none
      }
    }
  }

  func insertAttempt(success: Bool) {
    self.db.tryWrite { db in
      try PinAttempt.insert {
        PinAttempt.Draft(success: success, createdAt: self.now)
      }.execute(db)
    }
  }
}

extension Date {
  static func pinLockout() -> Date? {
    @Dependency(\.db) var db
    @Dependency(\.date.now) var now

    let attempts: [Date] = withErrorReporting {
      try db.read { db in
        try PinAttempt
          .select(\.createdAt)
          .where { $0.success.eq(false) }
          .where { $0.createdAt > now.addingTimeInterval(-24 * 60 * 60 * 10) }
          .order { $0.createdAt.asc() }
          .fetchAll(db)
      }
    } ?? []

    guard let last = attempts.last, attempts.count >= 5 else {
      return nil
    }

    // 5 minute lockout for 5-10 failed attempts, 20 minute lockout for more than 10
    let lockout = last.addingTimeInterval(60 * 5 * (attempts.count > 10 ? 4 : 1))
    return lockout > now ? lockout : nil
  }
}
