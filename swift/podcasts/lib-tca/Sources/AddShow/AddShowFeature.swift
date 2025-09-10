import ComposableArchitecture
import LibCore
import SharingGRDB
import SwiftUI

@Reducer
struct AddShowFeature {
  @ObservableState
  struct State: Equatable {
    enum Screen: Equatable {
      case enteringPin
      case choosingMethod
      case searching
      case addingByUrl
      case chooseArtworkPolicy(SearchResult)
    }

    var passcode: Int
    var screen: Screen = .enteringPin
    var lockout: Date? = .pinLockout()
    var searchText: String = ""
    var searchResults: [SearchResult] = []
  }

  enum Action: Equatable {
    case passcodeVerified
    case passcodeFailed
    case passcodeCancelled
    case selectSearchTapped
    case selectAddByUrlTapped
    case selectAllowArtworkTapped
    case selectDontAllowArtworkTapped
    case setSearchText(String)
    case searchSetDebounced
    case setSearchResults([SearchResult])
  }

  @Dependency(\.dismiss) var dismiss
  @Dependency(\.defaultDatabase) var db
  @Dependency(\.date.now) var now
  @Dependency(\.search) var search

  private enum CancelID { case search }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .setSearchText(let text):
        state.searchText = text
        return .none

      case .searchSetDebounced:
        guard !state.searchText.isEmpty else {
          return .none
        }
        return .run { [text = state.searchText] send in
          // TODO: handle errors
          let results = try await self.search.search(text)
          await send(.setSearchResults(results))
        }
        .cancellable(id: CancelID.search)

      case .setSearchResults(let results):
        state.searchResults = results
        return .none

      case .passcodeVerified:
        self.insertAttempt(success: true)
        state.screen = .choosingMethod
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

      case .selectSearchTapped:
        state.screen = .searching
        return .none

      case .selectAddByUrlTapped:
        state.screen = .addingByUrl
        return .none

      case .selectAllowArtworkTapped:
        guard case .chooseArtworkPolicy(let show) = state.screen else {
          reportIssue("Unexpected action \(action) in state \(state)")
          return .none
        }
        return .none

      case .selectDontAllowArtworkTapped:
        guard case .chooseArtworkPolicy(let show) = state.screen else {
          reportIssue("Unexpected action \(action) in state \(state)")
          return .none
        }
        return .none
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
