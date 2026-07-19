import ComposableArchitecture
import Foundation
import GertieApp
import MusicRoute

@Reducer
struct LibraryFeature: Sendable {
  @ObservableState
  struct State: Equatable {
    var status = Status.loading
    var addToPlaylist: AddToPlaylistState?
    var collectionRecency = LibraryCollectionRecency()
    var isRefreshingRemoteLibrary = false
    var hasStartedInitialLibraryLoad = false
    var isPlaylistMutationInFlight = false
    var playlistMutationFailure: PlaylistMutationFailure?
    var playlistIDsBeforeCreate: Set<MusicPlaylist.ID>?
    var path = StackState<LibraryPath.State>()

    var albumDetail: AlbumDetailFeature.State? {
      get {
        guard let id = self.path.ids.last else { return nil }
        return self.path[id: id, case: \.album]
      }
      set {
        if let id = self.path.ids.last,
           self.path[id: id, case: \.album] != nil {
          if let newValue {
            self.path[id: id] = .album(newValue)
          } else {
            self.path.pop(from: id)
          }
        } else if let newValue {
          self.path.append(.album(newValue))
        }
      }
    }

    var playlistDetail: PlaylistDetailFeature.State? {
      get {
        guard let id = self.path.ids.last else { return nil }
        return self.path[id: id, case: \.playlist]
      }
      set {
        if let id = self.path.ids.last,
           self.path[id: id, case: \.playlist] != nil {
          if let newValue {
            self.path[id: id] = .playlist(newValue)
          } else {
            self.path.pop(from: id)
          }
        } else if let newValue {
          self.path.append(.playlist(newValue))
        }
      }
    }
  }

  enum Status: Equatable {
    case loading
    case loaded(ApprovedMusicLibrary)
    case empty
    case failed
    case subscriptionRequired
  }

  struct AddToPlaylistState: Equatable {
    let source: MusicPlaylistSourceSelection
    var confirmation: MusicPlaylistDuplicateConfirmation?
    var destinationPlaylistID: MusicPlaylist.ID?
  }

  enum AddToPlaylistMutationOutcome: Equatable {
    case confirmationRequired(
      ApprovedMusicLibrary,
      MusicPlaylistDuplicateConfirmation,
    )
    case conflict(ApprovedMusicLibrary)
    case failed
    case updated(ApprovedMusicLibrary)
  }

  enum PlaylistMutationFailure: Equatable {
    case conflict
    case failed
  }

  enum PlaylistMutationOutcome: Equatable {
    case conflict(ApprovedMusicLibrary)
    case failed
    case updated(ApprovedMusicLibrary)
  }

  enum CancelID: Hashable, Sendable {
    case approvedLibraryRefresh
  }

  enum DelegateAction: Equatable {
    case addToQueue(items: [PlaybackItem])
    case artistPlaybackButtonTapped(
      items: [PlaybackItem],
      origin: LibraryCollectionIdentity,
    )
    case dismissPlaybackFailure
    case playbackFailureActionTapped
    case playNext(items: [PlaybackItem])
    case playNow(
      items: [PlaybackItem],
      startIndex: Int,
      origin: LibraryCollectionIdentity,
    )
    case togglePlayPause
  }

  enum Action: Equatable {
    case addAlbumToPlaylistTapped(ApprovedAlbum.ID)
    case addToPlaylistCancelled
    case addToPlaylistCreateSubmitted(String)
    case addToPlaylistDestinationSelected(MusicPlaylist.ID)
    case addToPlaylistDuplicateCancelled
    case addToPlaylistDuplicateResolutionSelected(MusicPlaylistDuplicateResolution)
    case addToPlaylistMutationResponse(AddToPlaylistMutationOutcome)
    case addTrackToPlaylistTapped(trackID: ApprovedTrack.ID, albumID: ApprovedAlbum.ID)
    case albumAddToQueueTapped(ApprovedAlbum.ID)
    case albumPlayNextTapped(ApprovedAlbum.ID)
    case albumTapped(ApprovedAlbum.ID)
    case approvedLibraryLoaded(ApprovedMusicLibrary)
    case approvedLibraryLoadFailed
    case approvedLibrarySubscriptionRequired
    case artistPlayTapped(ApprovedArtist.ID)
    case artistTapped(ApprovedArtist.ID)
    case artistTopSongTapped(artistID: ApprovedArtist.ID, trackID: ApprovedTrack.ID)
    case cachedApprovedLibraryLoaded(ApprovedMusicLibrary)
    case collectionPlayNowSucceeded(LibraryCollectionIdentity)
    case collectionRecencyLoaded(LibraryCollectionRecency)
    case debugResetOnboardingButtonTapped
    case delegate(DelegateAction)
    case createPlaylistSubmitted(String)
    case onAppear
    case path(StackActionOf<LibraryPath>)
    case playlistAddToQueueTapped(MusicPlaylist.ID)
    case playlistMutationFailureDismissed
    case playlistMutationResponse(
      PlaylistMutationOutcome,
      rollback: ApprovedMusicLibrary?,
    )
    case playlistPlayNextTapped(MusicPlaylist.ID)
    case playlistTapped(MusicPlaylist.ID)
    case refreshPresentationFinished
    case refreshPulled
    case retryButtonTapped
  }

  @Dependency(\.approvedMusic) var approvedMusic
  @Dependency(\.continuousClock) var clock
  @Dependency(\.date.now) var now
  @Dependency(\.libraryCollectionRecency) var libraryCollectionRecency

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .addAlbumToPlaylistTapped(let albumID):
        guard !state.isPlaylistMutationInFlight,
              case .loaded(let library) = state.status,
              let album = library.album(id: albumID),
              !album.tracks.isEmpty else { return .none }
        state.addToPlaylist = .init(source: .album(albumId: albumID.rawValue))
        state.playlistMutationFailure = nil
        return .none

      case .addTrackToPlaylistTapped(let trackID, let albumID):
        guard !state.isPlaylistMutationInFlight,
              case .loaded(let library) = state.status,
              library.album(id: albumID)?.tracks.contains(where: {
                $0.id == trackID
              }) == true else { return .none }
        state.addToPlaylist = .init(source: .track(
          trackId: trackID.rawValue,
          albumId: albumID.rawValue,
        ))
        state.playlistMutationFailure = nil
        return .none

      case .addToPlaylistCancelled:
        guard !state.isPlaylistMutationInFlight else { return .none }
        state.addToPlaylist = nil
        state.playlistMutationFailure = nil
        return .none

      case .addToPlaylistCreateSubmitted(let rawName):
        guard !state.isPlaylistMutationInFlight,
              let name = rawName.validPlaylistName,
              let source = state.addToPlaylist?.source else { return .none }
        state.isPlaylistMutationInFlight = true
        state.playlistMutationFailure = nil
        state.playlistIDsBeforeCreate = state.status.playlistIDs
        return self.performAddToPlaylistMutation {
          try await self.approvedMusic.createPlaylist(.init(
            name: name,
            source: source,
          ))
        }

      case .addToPlaylistDestinationSelected(let playlistID):
        guard !state.isPlaylistMutationInFlight,
              case .loaded(let library) = state.status,
              library.playlist(id: playlistID) != nil,
              let source = state.addToPlaylist?.source else { return .none }
        state.addToPlaylist?.destinationPlaylistID = playlistID
        state.isPlaylistMutationInFlight = true
        state.playlistMutationFailure = nil
        return self.performAddToPlaylistMutation {
          try await self.approvedMusic.addToPlaylist(.init(
            playlistId: playlistID.rawValue,
            source: source,
          ))
        }

      case .addToPlaylistDuplicateCancelled:
        state.addToPlaylist?.confirmation = nil
        return .none

      case .addToPlaylistDuplicateResolutionSelected(let resolution):
        guard !state.isPlaylistMutationInFlight,
              let presentation = state.addToPlaylist,
              let playlistID = presentation.destinationPlaylistID,
              presentation.confirmation?.allows(resolution) == true else { return .none }
        state.addToPlaylist?.confirmation = nil
        state.isPlaylistMutationInFlight = true
        return self.performAddToPlaylistMutation {
          try await self.approvedMusic.addToPlaylist(.init(
            playlistId: playlistID.rawValue,
            source: presentation.source,
            duplicateResolution: resolution,
          ))
        }

      case .addToPlaylistMutationResponse(let outcome):
        state.isPlaylistMutationInFlight = false
        state.isRefreshingRemoteLibrary = false
        var recencyToSave: LibraryCollectionRecency?
        switch outcome {
        case .updated(let library):
          state.applyLibrary(library)
          state.addToPlaylist = nil
          if state.playlistIDsBeforeCreate != nil {
            recencyToSave = state.prioritizeCreatedPlaylist(in: library, at: self.now)
          }
        case .confirmationRequired(let library, let confirmation):
          state.applyLibrary(library)
          state.addToPlaylist?.confirmation = confirmation
          state.playlistIDsBeforeCreate = nil
        case .conflict(let library):
          state.applyLibrary(library)
          state.playlistMutationFailure = .conflict
          state.playlistIDsBeforeCreate = nil
        case .failed:
          state.playlistMutationFailure = .failed
          state.playlistIDsBeforeCreate = nil
        }
        if let recencyToSave {
          return self.saveCollectionRecency(recencyToSave)
        }
        return .none

      case .albumAddToQueueTapped(let albumID):
        return self.queueAlbum(
          albumID: albumID,
          position: .tail,
          status: state.status,
        )

      case .albumPlayNextTapped(let albumID):
        return self.queueAlbum(
          albumID: albumID,
          position: .next,
          status: state.status,
        )

      case .albumTapped(let albumID):
        state.presentAlbumDetail(
          albumID: albumID,
          transitionSourceID: albumID.rawValue,
        )
        return .none

      case .createPlaylistSubmitted(let rawName):
        guard !state.isPlaylistMutationInFlight,
              let name = rawName.validPlaylistName else { return .none }
        state.isPlaylistMutationInFlight = true
        state.playlistMutationFailure = nil
        state.playlistIDsBeforeCreate = state.status.playlistIDs
        return self.performPlaylistMutation {
          try await self.approvedMusic.createPlaylist(.init(name: name))
        }

      case .playlistAddToQueueTapped(let playlistID):
        return self.queuePlaylist(
          playlistID: playlistID,
          position: .tail,
          status: state.status,
        )

      case .playlistPlayNextTapped(let playlistID):
        return self.queuePlaylist(
          playlistID: playlistID,
          position: .next,
          status: state.status,
        )

      case .playlistTapped(let playlistID):
        state.presentPlaylistDetail(playlistID: playlistID)
        return .none

      case .artistTapped(let artistID):
        guard case .loaded(let library) = state.status,
              library.artist(id: artistID) != nil
        else { return .none }
        state.path.append(.artist(.init(artistID: artistID)))
        return .none

      case .artistPlayTapped(let artistID):
        guard let items = self.artistPlaybackItems(
          for: artistID,
          in: state.status,
        ) else { return .none }
        return .send(.delegate(.artistPlaybackButtonTapped(
          items: items,
          origin: .artist(artistID),
        )))

      case .artistTopSongTapped(let artistID, let trackID):
        guard let items = self.artistPlaybackItems(
          for: artistID,
          in: state.status,
        ), let startIndex = items.firstIndex(where: { $0.id == trackID })
        else { return .none }
        return .send(.delegate(.playNow(
          items: items,
          startIndex: startIndex,
          origin: .artist(artistID),
        )))

      case .path(.element(id: let id, action: .artist(.addToQueueTapped))):
        guard let artistID = state.path[id: id, case: \.artist]?.artistID,
              let items = self.artistPlaybackItems(for: artistID, in: state.status)
        else { return .none }
        return .send(.delegate(.addToQueue(items: items)))

      case .path(.element(id: let id, action: .artist(.playButtonTapped))):
        guard let artistID = state.path[id: id, case: \.artist]?.artistID
        else { return .none }
        return .send(.artistPlayTapped(artistID))

      case .path(.element(id: let id, action: .artist(.playNextTapped))):
        guard let artistID = state.path[id: id, case: \.artist]?.artistID,
              let items = self.artistPlaybackItems(for: artistID, in: state.status)
        else { return .none }
        return .send(.delegate(.playNext(items: items)))

      case .path(.element(id: let id, action: .artist(.releaseAddToPlaylistTapped(let albumID)))):
        guard state.path[id: id, case: \.artist] != nil else { return .none }
        return .send(.addAlbumToPlaylistTapped(albumID))

      case .path(.element(id: let id, action: .artist(.releaseAddToQueueTapped(let albumID)))):
        guard state.path[id: id, case: \.artist] != nil else { return .none }
        return .send(.albumAddToQueueTapped(albumID))

      case .path(.element(id: let id, action: .artist(.releasePlayNextTapped(let albumID)))):
        guard state.path[id: id, case: \.artist] != nil else { return .none }
        return .send(.albumPlayNextTapped(albumID))

      case .path(.element(id: let id, action: .artist(.releaseTapped(let albumID)))):
        guard state.path[id: id, case: \.artist] != nil else { return .none }
        state.presentAlbumDetail(
          albumID: albumID,
          transitionSourceID: albumID.rawValue,
        )
        return .none

      case .path(.element(id: let id, action: .artist(.topSongAddToPlaylistTapped(let trackID)))):
        guard let artistID = state.path[id: id, case: \.artist]?.artistID,
              case .loaded(let library) = state.status,
              let track = library.artist(id: artistID)?.topSongs?.first(where: {
                $0.id == trackID
              }),
              let albumID = track.albumID else { return .none }
        return .send(.addTrackToPlaylistTapped(
          trackID: trackID,
          albumID: albumID,
        ))

      case .path(.element(id: let id, action: .artist(.topSongAddToQueueTapped(let trackID)))):
        guard let artistID = state.path[id: id, case: \.artist]?.artistID,
              let items = self.artistPlaybackItems(for: artistID, in: state.status),
              let item = items.first(where: { $0.id == trackID })
        else { return .none }
        return .send(.delegate(.addToQueue(items: [item])))

      case .path(.element(id: let id, action: .artist(.topSongPlayNextTapped(let trackID)))):
        guard let artistID = state.path[id: id, case: \.artist]?.artistID,
              let items = self.artistPlaybackItems(for: artistID, in: state.status),
              let item = items.first(where: { $0.id == trackID })
        else { return .none }
        return .send(.delegate(.playNext(items: [item])))

      case .path(.element(id: let id, action: .artist(.topSongTapped(let trackID)))):
        guard let artistID = state.path[id: id, case: \.artist]?.artistID
        else { return .none }
        return .send(.artistTopSongTapped(artistID: artistID, trackID: trackID))

      case .path(.element(id: let id, action: .playlist(.delegate(let delegateAction)))):
        guard let detail = state.path[id: id, case: \.playlist] else { return .none }
        switch delegateAction {
        case .addEntryToPlaylist(let entryID):
          guard let track = detail.playlist.entries.first(where: {
            $0.id == entryID
          })?.track,
            let albumID = track.albumID else { return .none }
          return .send(.addTrackToPlaylistTapped(
            trackID: track.id,
            albumID: albumID,
          ))

        case .addMusic:
          state.path.pop(from: id)
          return .none

        case .addToQueue(let items):
          return .send(.delegate(.addToQueue(items: items)))

        case .delete:
          guard !state.isPlaylistMutationInFlight else { return .none }
          state.isPlaylistMutationInFlight = true
          state.playlistMutationFailure = nil
          return self.performPlaylistMutation {
            try await self.approvedMusic.deletePlaylist(.init(
              playlistId: detail.playlist.id.rawValue,
              expectedRevision: detail.playlist.revision,
            ))
          }

        case .dismissPlaybackFailure:
          return .send(.delegate(.dismissPlaybackFailure))

        case .playbackFailureActionTapped:
          return .send(.delegate(.playbackFailureActionTapped))

        case .playNext(let items):
          return .send(.delegate(.playNext(items: items)))

        case .playNow(let items, let startIndex):
          return .send(.delegate(.playNow(
            items: items,
            startIndex: startIndex,
            origin: .playlist(detail.playlist.id),
          )))

        case .removeEntry(let entryID):
          guard !state.isPlaylistMutationInFlight,
                case .loaded(let library) = state.status,
                let playlistIndex = library.playlists.firstIndex(where: {
                  $0.id == detail.playlist.id
                }),
                library.playlists[playlistIndex].entries.contains(where: {
                  $0.id == entryID
                }) else { return .none }
          var optimisticLibrary = library
          optimisticLibrary.playlists[playlistIndex].entries.removeAll {
            $0.id == entryID
          }
          state.isPlaylistMutationInFlight = true
          state.playlistMutationFailure = nil
          state.applyLibrary(optimisticLibrary)
          return self.performPlaylistMutation(rollback: library) {
            try await self.approvedMusic.removePlaylistEntry(.init(
              playlistId: detail.playlist.id.rawValue,
              expectedRevision: detail.playlist.revision,
              entryId: entryID.rawValue,
            ))
          }

        case .rename(let rawName):
          guard !state.isPlaylistMutationInFlight,
                let name = rawName.validPlaylistName,
                name != detail.playlist.name,
                case .loaded(let library) = state.status,
                let playlistIndex = library.playlists.firstIndex(where: {
                  $0.id == detail.playlist.id
                }) else { return .none }
          var optimisticLibrary = library
          optimisticLibrary.playlists[playlistIndex].name = name
          state.isPlaylistMutationInFlight = true
          state.playlistMutationFailure = nil
          state.applyLibrary(optimisticLibrary)
          return self.performPlaylistMutation(rollback: library) {
            try await self.approvedMusic.renamePlaylist(.init(
              playlistId: detail.playlist.id.rawValue,
              expectedRevision: detail.playlist.revision,
              name: name,
            ))
          }

        case .reorder(let entryIDs):
          guard !state.isPlaylistMutationInFlight,
                case .loaded(let library) = state.status,
                let playlistIndex = library.playlists.firstIndex(where: {
                  $0.id == detail.playlist.id
                }) else { return .none }
          let entriesByID = Dictionary(
            uniqueKeysWithValues: library.playlists[playlistIndex].entries.map {
              ($0.id, $0)
            },
          )
          guard entryIDs.count == entriesByID.count,
                entryIDs.allSatisfy({ entriesByID[$0] != nil }) else { return .none }
          var optimisticLibrary = library
          optimisticLibrary.playlists[playlistIndex].entries = entryIDs.compactMap {
            entriesByID[$0]
          }
          state.isPlaylistMutationInFlight = true
          state.playlistMutationFailure = nil
          state.applyLibrary(optimisticLibrary)
          return self.performPlaylistMutation(rollback: library) {
            try await self.approvedMusic.reorderPlaylistEntries(.init(
              playlistId: detail.playlist.id.rawValue,
              expectedRevision: detail.playlist.revision,
              entryIds: entryIDs.map(\.rawValue),
            ))
          }

        case .togglePlayPause:
          return .send(.delegate(.togglePlayPause))
        }

      case .onAppear:
        guard !state.hasStartedInitialLibraryLoad else { return .none }
        state.hasStartedInitialLibraryLoad = true
        state.isRefreshingRemoteLibrary = true
        if !state.status.isDisplayingLibrary {
          state.status = .loading
        }
        return .merge(
          self.refreshRemoteApprovedLibrary(loadCache: true),
          self.loadCollectionRecency(),
        )

      case .approvedLibraryLoaded(let library):
        state.applyLibrary(library)
        if library.isEmpty {
          log(.debug, .library, "e24738fc")
        }
        return .none

      case .approvedLibraryLoadFailed:
        log(.err, .library, "cd55459e")
        guard !state.status.isDisplayingLibrary else { return .none }
        state.status = .failed
        return .none

      case .approvedLibrarySubscriptionRequired:
        state.status = .subscriptionRequired
        log(.warn, .subs, "ded74480")
        return .none

      case .cachedApprovedLibraryLoaded(let library):
        state.applyLibrary(library)
        return .none

      case .collectionPlayNowSucceeded(let identity):
        guard case .loaded(let library) = state.status,
              let observedAddedAt = library.observedAddedAt(for: identity) else { return .none }
        state.collectionRecency.recordPlay(
          of: identity,
          observedAddedAt: observedAddedAt,
          at: self.now,
        )
        let recency = state.collectionRecency
        return self.saveCollectionRecency(recency)

      case .collectionRecencyLoaded(let recency):
        state.collectionRecency = recency
        return .none

      case .playlistMutationFailureDismissed:
        state.playlistMutationFailure = nil
        return .none

      case .playlistMutationResponse(let outcome, let rollback):
        state.isPlaylistMutationInFlight = false
        state.isRefreshingRemoteLibrary = false
        var recencyToSave: LibraryCollectionRecency?
        switch outcome {
        case .updated(let library):
          state.applyLibrary(library)
          if state.playlistIDsBeforeCreate != nil {
            recencyToSave = state.prioritizeCreatedPlaylist(in: library, at: self.now)
          }
        case .conflict(let library):
          state.applyLibrary(library)
          state.playlistMutationFailure = .conflict
          state.playlistIDsBeforeCreate = nil
        case .failed:
          if let rollback {
            state.applyLibrary(rollback)
          }
          state.playlistMutationFailure = .failed
          state.playlistIDsBeforeCreate = nil
        }
        if let recencyToSave {
          return self.saveCollectionRecency(recencyToSave)
        }
        return .none

      case .refreshPresentationFinished:
        state.isRefreshingRemoteLibrary = false
        return .none

      case .refreshPulled:
        guard !state.isPlaylistMutationInFlight else { return .none }
        state.isRefreshingRemoteLibrary = true
        if !state.status.isDisplayingLibrary {
          state.status = .loading
        }
        return self.refreshRemoteApprovedLibrary(loadCache: false)

      case .retryButtonTapped:
        state.isRefreshingRemoteLibrary = true
        if !state.status.isDisplayingLibrary {
          state.status = .loading
        }
        return self.refreshRemoteApprovedLibrary(loadCache: true)

      case .path(.element(id: let id, action: .album(.delegate(let delegateAction)))):
        guard let albumID = state.path[id: id, case: \.album]?.album.id else { return .none }
        switch delegateAction {
        case .addAlbumToPlaylist(let albumID):
          return .send(.addAlbumToPlaylistTapped(albumID))
        case .addToQueue(let items):
          return .send(.delegate(.addToQueue(items: items)))
        case .dismissPlaybackFailure:
          return .send(.delegate(.dismissPlaybackFailure))
        case .playbackFailureActionTapped:
          return .send(.delegate(.playbackFailureActionTapped))
        case .playNow(let items, let startIndex):
          return .send(.delegate(.playNow(
            items: items,
            startIndex: startIndex,
            origin: .album(albumID),
          )))
        case .playNext(let items):
          return .send(.delegate(.playNext(items: items)))
        case .togglePlayPause:
          return .send(.delegate(.togglePlayPause))
        case .addTrackToPlaylist(let trackID, let albumID):
          return .send(.addTrackToPlaylistTapped(
            trackID: trackID,
            albumID: albumID,
          ))
        }

      case .debugResetOnboardingButtonTapped, .delegate, .path:
        return .none
      }
    }
    .forEach(\.path, action: \.path) {
      LibraryPath.body
    }
  }

  private func queueAlbum(
    albumID: ApprovedAlbum.ID,
    position: PlaybackQueueInsertionPosition,
    status: Status,
  ) -> EffectOf<Self> {
    guard case .loaded(let library) = status,
          let album = library.album(id: albumID) else { return .none }
    guard !album.tracks.isEmpty else { return .none }
    let items = album.tracks.map { PlaybackItem(
      track: $0,
      artworkURL: album.artworkURL,
      albumID: album.id,
    ) }
    switch position {
    case .next:
      return .send(.delegate(.playNext(items: items)))
    case .tail:
      return .send(.delegate(.addToQueue(items: items)))
    }
  }

  private func queuePlaylist(
    playlistID: MusicPlaylist.ID,
    position: PlaybackQueueInsertionPosition,
    status: Status,
  ) -> EffectOf<Self> {
    guard case .loaded(let library) = status,
          let playlist = library.playlist(id: playlistID) else { return .none }
    let items = PlaylistDetailFeature.State(playlist: playlist).playbackItems
    guard !items.isEmpty else { return .none }
    switch position {
    case .next:
      return .send(.delegate(.playNext(items: items)))
    case .tail:
      return .send(.delegate(.addToQueue(items: items)))
    }
  }

  private func artistPlaybackItems(
    for artistID: ApprovedArtist.ID,
    in status: Status,
  ) -> [PlaybackItem]? {
    guard case .loaded(let library) = status,
          let topSongs = library.artist(id: artistID)?.topSongs,
          !topSongs.isEmpty else { return nil }
    return topSongs.map {
      PlaybackItem(track: $0, artworkURL: $0.artworkURL)
    }
  }

  private func performAddToPlaylistMutation(
    operation: @escaping @Sendable () async throws -> MusicPlaylistMutationResult,
  ) -> EffectOf<Self> {
    .merge(
      .cancel(id: CancelID.approvedLibraryRefresh),
      .run { send in
        do {
          switch try await operation() {
          case .updated(let library):
            await send(.addToPlaylistMutationResponse(.updated(library)))
          case .duplicateConfirmationRequired(let library, let confirmation):
            await send(.addToPlaylistMutationResponse(.confirmationRequired(
              library,
              confirmation,
            )))
          case .conflict(let library):
            await send(.addToPlaylistMutationResponse(.conflict(library)))
          }
        } catch {
          await send(.addToPlaylistMutationResponse(.failed))
        }
      },
    )
  }

  private func performPlaylistMutation(
    rollback: ApprovedMusicLibrary? = nil,
    operation: @escaping @Sendable () async throws -> MusicPlaylistMutationResult,
  ) -> EffectOf<Self> {
    .merge(
      .cancel(id: CancelID.approvedLibraryRefresh),
      .run { send in
        do {
          switch try await operation() {
          case .updated(let library):
            await send(.playlistMutationResponse(.updated(library), rollback: rollback))
          case .conflict(let library),
               .duplicateConfirmationRequired(let library, _):
            await send(.playlistMutationResponse(.conflict(library), rollback: rollback))
          }
        } catch {
          await send(.playlistMutationResponse(.failed, rollback: rollback))
        }
      },
    )
  }

  private func saveCollectionRecency(
    _ recency: LibraryCollectionRecency,
  ) -> EffectOf<Self> {
    .run { _ in
      await self.libraryCollectionRecency.save(recency)
    }
  }

  private func loadCollectionRecency() -> EffectOf<Self> {
    .run { send in
      guard let recency = await self.libraryCollectionRecency.load(),
            !recency.records.isEmpty else { return }
      await send(.collectionRecencyLoaded(recency))
    }
  }

  private func refreshRemoteApprovedLibrary(loadCache: Bool) -> EffectOf<Self> {
    .run { send in
      async let minimumDisplayDuration: Void = self.clock.sleep(for: .milliseconds(1500))
      if loadCache,
         let cachedLibrary = await self.approvedMusic.loadCachedApprovedLibrary() {
        await send(.cachedApprovedLibraryLoaded(cachedLibrary))
      }
      do {
        try await send(.approvedLibraryLoaded(self.approvedMusic.loadRemoteApprovedLibrary()))
      } catch ApprovedMusicClientError.subscriptionRequired {
        await send(.approvedLibrarySubscriptionRequired)
      } catch {
        await send(.approvedLibraryLoadFailed)
      }
      try await minimumDisplayDuration
      await send(.refreshPresentationFinished)
    }
    .cancellable(id: CancelID.approvedLibraryRefresh, cancelInFlight: true)
  }
}

private extension LibraryFeature.Status {
  var playlistIDs: Set<MusicPlaylist.ID> {
    guard case .loaded(let library) = self else { return [] }
    return Set(library.playlists.map(\.id))
  }

  var isDisplayingLibrary: Bool {
    switch self {
    case .loaded, .empty:
      true
    case .loading, .failed, .subscriptionRequired:
      false
    }
  }
}

extension LibraryFeature.State {
  mutating func applyLibrary(_ library: ApprovedMusicLibrary) {
    self.status = library.isEmpty ? .empty : .loaded(library)
    for id in Array(self.path.ids) {
      guard var detail = self.path[id: id, case: \.playlist] else { continue }
      guard let playlist = library.playlist(id: detail.playlist.id) else {
        self.path.pop(from: id)
        return
      }
      detail.playlist = playlist
      self.path[id: id] = .playlist(detail)
    }
  }

  mutating func prioritizeCreatedPlaylist(
    in library: ApprovedMusicLibrary,
    at date: Date,
  ) -> LibraryCollectionRecency? {
    guard let playlistIDsBeforeCreate = self.playlistIDsBeforeCreate else { return nil }
    self.playlistIDsBeforeCreate = nil
    guard let playlist = library.playlists
      .filter({ !playlistIDsBeforeCreate.contains($0.id) })
      .max(by: {
        if $0.createdAt != $1.createdAt {
          return $0.createdAt < $1.createdAt
        }
        return $0.id.rawValue.uuidString < $1.id.rawValue.uuidString
      })
    else { return nil }
    self.collectionRecency.recordPlay(
      of: .playlist(playlist.id),
      observedAddedAt: playlist.createdAt,
      at: date,
    )
    return self.collectionRecency
  }

  @discardableResult
  mutating func presentAlbumDetail(
    albumID: ApprovedAlbum.ID,
    transitionSourceID: String?,
  ) -> Bool {
    guard case .loaded(let library) = self.status,
          let album = library.album(id: albumID)
    else { return false }

    if self.albumDetail?.album.id == albumID {
      return true
    }

    self.albumDetail = AlbumDetailFeature.State(
      album: album,
      transitionSourceID: transitionSourceID,
    )
    return true
  }

  @discardableResult
  mutating func presentPlaylistDetail(playlistID: MusicPlaylist.ID) -> Bool {
    guard case .loaded(let library) = self.status,
          let playlist = library.playlist(id: playlistID) else { return false }
    if self.playlistDetail?.playlist.id == playlistID {
      return true
    }
    self.playlistDetail = PlaylistDetailFeature.State(playlist: playlist)
    return true
  }

  mutating func setAlbumDetailPlaybackFailure(_ failure: PlaybackFailure?) {
    guard var albumDetail = self.albumDetail else { return }
    albumDetail.setPlaybackFailure(failure)
    self.albumDetail = albumDetail
  }

  mutating func setAlbumDetailPlaybackSession(_ session: PlaybackFeature.Session?) {
    guard var albumDetail = self.albumDetail else { return }
    albumDetail.setPlaybackSession(session)
    self.albumDetail = albumDetail
  }

  mutating func setPlaylistDetailPlaybackFailure(_ failure: PlaybackFailure?) {
    guard var playlistDetail = self.playlistDetail else { return }
    playlistDetail.setPlaybackFailure(failure)
    self.playlistDetail = playlistDetail
  }

  mutating func setPlaylistDetailPlaybackSession(_ session: PlaybackFeature.Session?) {
    guard var playlistDetail = self.playlistDetail else { return }
    playlistDetail.setPlaybackSession(session)
    self.playlistDetail = playlistDetail
  }
}

private extension MusicPlaylistDuplicateConfirmation {
  func allows(_ resolution: MusicPlaylistDuplicateResolution) -> Bool {
    switch (self, resolution) {
    case (.track, .addAgain),
         (.album, .addAll),
         (.album, .addOnlyNew):
      true
    default:
      false
    }
  }
}

private extension String {
  var validPlaylistName: String? {
    let name = self.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty,
          name.count <= 100,
          name.rangeOfCharacter(from: .newlines) == nil else { return nil }
    return name
  }
}
