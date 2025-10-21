import ComposableArchitecture
import LibViews
import SQLiteData
import SwiftUI

@Reducer
struct ShowFeature {
  @ObservableState
  struct State: Equatable {
    var showId: Show.ID
    @Shared var showArchivedEpisodes: Bool
    @FetchOne var show: Show
    @FetchAll var episodes: [Episode]
    @Fetch(EpisodePlaying()) var nowPlaying: EpisodePlaying.Value = nil
    @Presents var destination: Destination.State?
  }

  @Reducer(state: .equatable, action: .equatable)
  enum Destination {
    case episode(EpisodeFeature)
  }

  enum Action: Equatable {
    enum DelegateAction: Equatable {
      case episodePlayPauseTapped(Episode, Show)
      case alert(String)
    }

    case episodeView(Episode.ID, EpisodeView.Event)
    case showView(ShowView.Event)
    case delegate(DelegateAction)
    case destination(PresentationAction<Destination.Action>)
  }

  @Dependency(\.db) var database
  @Dependency(\.date) var date

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .episodeView(let episodeId, let episodeAction):
        guard let episode = state.episodes.first(where: { $0.id == episodeId }) else {
          unexpected(id: "60324a0d", assert: true)
          return .none
        }
        switch episodeAction {
        case .downloadTapped:
          return .run { send in
            if let error = await ensureDownloaded(episode: episode).error {
              await send(.delegate(.alert(error.message)))
            }
          }
        case .playPauseTapped:
          return .send(.delegate(.episodePlayPauseTapped(episode, state.show)))
        case .episodeTapped:
          state.destination = .episode(.init(episode: episode, show: state.show))
          return .none
        case .removeDownloadTapped:
          return .run { _ in
            episode.removeLocalAudioFile()
            self.database.tryWrite { db in
              try Episode
                .update { $0.downloadedAt = nil }
                .where { $0.id == episode.id }
                .execute(db)
            }
          }
        case .toggleCompletedTapped:
          return .run { _ in
            self.database.tryWrite { db in
              try Episode
                .update { $0.completedAt = episode.completedAt == nil ? self.date.now : nil }
                .where { $0.id == episode.id }
                .execute(db)
            }
          }
        case .toggleArchivedTapped:
          return .run { [state] _ in
            if !episode.isArchived {
              episode.removeLocalAudioFile()
            }
            self.database.tryWrite { db in
              try Episode
                .update {
                  $0.isArchived.toggle()
                  $0.downloadedAt = nil
                  $0.progress = 0
                  $0.completedAt = nil
                }
                .where { $0.id == episode.id }
                .execute(db)
            }
            try await state.$episodes.load(state.selectEpisodes)
          }
        }
      case .showView(let event):
        switch event {
        case .sortOldestToNewest, .sortNewestToOldest:
          return .run { [state] _ in
            let sortOrder: Show.SortOrder = event == .sortNewestToOldest
              ? .newestToOldest : .oldestToNewest
            self.database.tryWrite { db in
              try Show
                .update { $0.sort = sortOrder }
                .where { $0.id == state.showId }
                .execute(db)
            }
            try await state.$episodes.load(
              episodeQuery(showId: state.showId, sortOrder: sortOrder),
            )
          }
        case .toggleShowArchivedTapped:
          withAnimation(.default) {
            state.$showArchivedEpisodes.withLock { $0.toggle() }
          }
          return .none
        case .unarchiveAllTapped:
          return .run { [state] _ in
            self.database.tryWrite { db in
              try Episode
                .update { $0.isArchived = false }
                .where { $0.showId == state.showId }
                .execute(db)
            }
            try await state.$episodes.load(state.selectEpisodes)
          }
        case .headerPlayButtonTapped:
          switch state.headerPlayButtonState {
          case .resume(let episode, _):
            return .send(.delegate(.episodePlayPauseTapped(episode, state.show)))
          case .playLatest(let episode, _):
            return .send(.delegate(.episodePlayPauseTapped(episode, state.show)))
          case .none:
            return .none
          }
        }
      case .destination:
        return .none
      case .delegate:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
}

func episodeQuery(
  showId: Show.ID,
  sortOrder: Show.SortOrder,
) -> some SelectStatementOf<Episode> {
  Episode
    .where { $0.showId == showId }
    .order {
      switch sortOrder {
      case .newestToOldest:
        ($0.pubDate.desc(), $0.episodeNumber.desc())
      case .oldestToNewest:
        ($0.pubDate.asc(), $0.episodeNumber.asc())
      }
    }
}

extension ShowFeature.State {
  enum HeaderPlayButtonState: Equatable {
    case resume(Episode, isPlaying: Bool)
    case playLatest(Episode, isPlaying: Bool)
    case none
  }

  var headerPlayButtonState: HeaderPlayButtonState {
    let lastPlayed = self.episodes
      .filter { $0.lastPlayedAt != nil && $0.completedAt == nil && !$0.isArchived }
      .sorted { ($0.lastPlayedAt ?? .distantPast) > ($1.lastPlayedAt ?? .distantPast) }
      .first

    if let lastPlayed {
      return .resume(
        lastPlayed,
        isPlaying: self.nowPlaying.isPlaying(episodeId: lastPlayed.id)
      )
    }

    let latestUncompleted = self.episodes
      .filter { $0.completedAt == nil && !$0.isArchived }
      .sorted { $0.pubDate > $1.pubDate }
      .first

    if let latestUncompleted {
      return .playLatest(
        latestUncompleted,
        isPlaying: self.nowPlaying.isPlaying(episodeId: latestUncompleted.id)
      )
    }

    return .none
  }

  var selectEpisodes: some SelectStatementOf<Episode> {
    episodeQuery(showId: self.showId, sortOrder: self.show.sort)
  }

  init(show: Show) {
    self.showId = show.id
    self._showArchivedEpisodes = Shared(
      wrappedValue: false,
      .inMemory("show-archived-\(show.id)")
    )
    self._show = FetchOne(
      wrappedValue: show,
      Show.where { $0.id == show.id }
    )
    self._episodes = FetchAll(
      episodeQuery(showId: show.id, sortOrder: show.sort)
    )
  }
}
