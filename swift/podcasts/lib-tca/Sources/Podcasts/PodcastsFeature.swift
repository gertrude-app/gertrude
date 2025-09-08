import ComposableArchitecture
import SharingGRDB
import SwiftUI

@Reducer
struct PodcastsFeature {
  @ObservableState
  struct State: Equatable {
    var shows: [Show]
  }
}

extension PodcastsFeature.State {
  init() {
    @Dependency(\.defaultDatabase) var db
    var shows: [Show] = []

    withErrorReporting {
      try db.read { db in
        shows = try Show.all.fetchAll(db)
      }
      // shows = try db.read { db in
      //   // try Show..fet
      // }
    }
    self.shows = shows
  }
}
