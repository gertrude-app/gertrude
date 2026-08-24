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
    var isLibraryRefreshFailurePresented = false
    var isRefreshingRemoteLibrary = false
    var hasStartedInitialLibraryLoad = false
    var isPlaylistMutationInFlight = false
    var playlistMutationFailure: PlaylistMutationFailure?
    var playlistIDsBeforeCreate: Set<MusicPlaylist.ID>?
    @Presents var playlistMusicPicker: PlaylistMusicPickerFeature.State?
    var path = StackState<LibraryPath.State>()
    var shouldPresentCreatedPlaylist = false

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
    case musicAccessUnavailable
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

  enum PlaylistMusicPickerMutationOutcome: Equatable {
    case batchConfirmationRequired(
      ApprovedMusicLibrary,
      MusicPlaylistBatchDuplicateConfirmation,
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
    case approvedTrackIDsUpdated(Set<ApprovedTrack.ID>)
    case artistPlaybackButtonTapped(
      items: [PlaybackItem],
      context: PlaybackContext,
    )
    case connectionInvalid
    case dismissPlaybackFailure
    case playbackFailureActionTapped
    case playNext(items: [PlaybackItem])
    case playNow(
      items: [PlaybackItem],
      start: PlaybackStartIntent,
      context: PlaybackContext,
    )
    case togglePlayPause
  }

  enum Action: Equatable {
    case addAlbumToPlaylistTapped(ApprovedAlbum.ID)
    case addArtistToPlaylistTapped(ApprovedArtist.ID)
    case addPlaylistToPlaylistTapped(MusicPlaylist.ID)
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
    case approvedLibraryMusicAccessUnavailable
    case artistAddToQueueTapped(ApprovedArtist.ID)
    case artistPlayNextTapped(ApprovedArtist.ID)
    case artistPlayTapped(ApprovedArtist.ID)
    case artistTapped(ApprovedArtist.ID)
    case artistTopSongTapped(artistID: ApprovedArtist.ID, trackID: ApprovedTrack.ID)
    case cachedApprovedLibraryLoaded(ApprovedMusicLibrary)
    case collectionPlayNowSucceeded(LibraryCollectionIdentity)
    case collectionRecencyLoaded(LibraryCollectionRecency)
    case debugResetOnboardingButtonTapped
    case delegate(DelegateAction)
    case createPlaylistSubmitted(String)
    case libraryRefreshFailureDismissed
    case onAppear
    case path(StackActionOf<LibraryPath>)
    case playlistAddToQueueTapped(MusicPlaylist.ID)
    case playlistDeleteConfirmed(
      playlistID: MusicPlaylist.ID,
      expectedRevision: Int64,
    )
    case playlistEntryRemoveTapped(
      playlistID: MusicPlaylist.ID,
      expectedRevision: Int64,
      entryID: MusicPlaylistEntry.ID,
    )
    case playlistMusicPicker(PresentationAction<PlaylistMusicPickerFeature.Action>)
    case playlistMusicPickerMutationResponse(PlaylistMusicPickerMutationOutcome)
    case playlistMusicPickerRequested(MusicPlaylist.ID)
    case playlistMutationFailureDismissed
    case playlistMutationResponse(
      PlaylistMutationOutcome,
      rollback: ApprovedMusicLibrary?,
    )
    case playlistPlayNextTapped(MusicPlaylist.ID)
    case playlistRenameSubmitted(
      playlistID: MusicPlaylist.ID,
      expectedRevision: Int64,
      name: String,
    )
    case playlistReorderSubmitted(
      playlistID: MusicPlaylist.ID,
      expectedRevision: Int64,
      entryIDs: [MusicPlaylistEntry.ID],
    )
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

      case .addArtistToPlaylistTapped(let artistID):
        guard !state.isPlaylistMutationInFlight,
              case .loaded(let library) = state.status,
              library.artist(id: artistID) != nil,
              !library.artistDiscographyPlaybackItems(for: artistID).isEmpty else { return .none }
        state.addToPlaylist = .init(source: .artist(artistId: artistID.rawValue))
        state.playlistMutationFailure = nil
        return .none

      case .addPlaylistToPlaylistTapped(let playlistID):
        guard !state.isPlaylistMutationInFlight,
              case .loaded(let library) = state.status,
              let playlist = library.playlist(id: playlistID),
              !playlist.entries.isEmpty else { return .none }
        state.addToPlaylist = .init(source: .playlist(playlistId: playlistID.rawValue))
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
        state.shouldPresentCreatedPlaylist = false
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
        if case .playlist(let sourcePlaylistID) = source,
           sourcePlaylistID == playlistID.rawValue { return .none }
        state.addToPlaylist?.destinationPlaylistID = playlistID
        state.isPlaylistMutationInFlight = true
        state.playlistMutationFailure = nil
        return self.performAddToPlaylistMutation {
          try await self.approvedMusic.addSourceToPlaylist(.init(
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
          try await self.approvedMusic.addSourceToPlaylist(.init(
            playlistId: playlistID.rawValue,
            source: presentation.source,
            duplicateResolution: resolution,
          ))
        }

      case .addToPlaylistMutationResponse(let outcome):
        state.isPlaylistMutationInFlight = false
        state.isRefreshingRemoteLibrary = false
        var effects: [EffectOf<Self>] = []
        var recencyToSave: LibraryCollectionRecency?
        switch outcome {
        case .updated(let library):
          effects.append(self.applyAuthoritativeLibrary(library, to: &state))
          state.addToPlaylist = nil
          if state.playlistIDsBeforeCreate != nil,
             let playlist = state.createdPlaylist(in: library, at: self.now) {
            recencyToSave = state.collectionRecency
            if state.shouldPresentCreatedPlaylist {
              state.presentPlaylistDetail(playlistID: playlist.id)
              state.playlistMusicPicker = .init(playlist: playlist, library: library)
            }
          }
          state.shouldPresentCreatedPlaylist = false
        case .confirmationRequired(let library, let confirmation):
          effects.append(self.applyAuthoritativeLibrary(library, to: &state))
          state.addToPlaylist?.confirmation = confirmation
          state.playlistIDsBeforeCreate = nil
          state.shouldPresentCreatedPlaylist = false
        case .conflict(let library):
          effects.append(self.applyAuthoritativeLibrary(library, to: &state))
          state.playlistMutationFailure = .conflict
          state.playlistIDsBeforeCreate = nil
          state.shouldPresentCreatedPlaylist = false
        case .failed:
          state.playlistMutationFailure = .failed
          state.playlistIDsBeforeCreate = nil
          state.shouldPresentCreatedPlaylist = false
        }
        if let recencyToSave {
          effects.append(self.saveCollectionRecency(recencyToSave))
        }
        return .merge(effects)

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
        state.shouldPresentCreatedPlaylist = true
        return self.performPlaylistMutation {
          try await self.approvedMusic.createPlaylist(.init(name: name))
        }

      case .playlistAddToQueueTapped(let playlistID):
        return self.queuePlaylist(
          playlistID: playlistID,
          position: .tail,
          status: state.status,
        )

      case .playlistDeleteConfirmed(let playlistID, let expectedRevision):
        return self.deletePlaylist(
          playlistID: playlistID,
          expectedRevision: expectedRevision,
          state: &state,
        )

      case .playlistEntryRemoveTapped(let playlistID, let expectedRevision, let entryID):
        return self.removePlaylistEntry(
          playlistID: playlistID,
          expectedRevision: expectedRevision,
          entryID: entryID,
          state: &state,
        )

      case .playlistRenameSubmitted(let playlistID, let expectedRevision, let name):
        return self.renamePlaylist(
          playlistID: playlistID,
          expectedRevision: expectedRevision,
          rawName: name,
          state: &state,
        )

      case .playlistReorderSubmitted(let playlistID, let expectedRevision, let entryIDs):
        return self.reorderPlaylist(
          playlistID: playlistID,
          expectedRevision: expectedRevision,
          entryIDs: entryIDs,
          state: &state,
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

      case .artistAddToQueueTapped(let artistID):
        guard let items = self.artistDiscographyPlaybackItems(
          for: artistID,
          in: state.status,
        ) else { return .none }
        return .send(.delegate(.addToQueue(items: items)))

      case .artistPlayNextTapped(let artistID):
        guard let items = self.artistDiscographyPlaybackItems(
          for: artistID,
          in: state.status,
        ) else { return .none }
        return .send(.delegate(.playNext(items: items)))

      case .artistTapped(let artistID):
        guard case .loaded(let library) = state.status,
              library.artist(id: artistID) != nil
        else { return .none }
        state.path.append(.artist(.init(artistID: artistID)))
        return .none

      case .artistPlayTapped(let artistID):
        guard let items = self.artistDiscographyPlaybackItems(
          for: artistID,
          in: state.status,
        ), let context = self.artistPlaybackContext(
          for: artistID,
          source: .discography,
          in: state.status,
        ) else { return .none }
        return .send(.delegate(.artistPlaybackButtonTapped(
          items: items,
          context: context,
        )))

      case .artistTopSongTapped(let artistID, let trackID):
        guard let items = self.artistTopSongsPlaybackItems(
          for: artistID,
          in: state.status,
        ), let startIndex = items.firstIndex(where: { $0.id == trackID }),
        let context = self.artistPlaybackContext(
          for: artistID,
          source: .topSongs,
          in: state.status,
        )
        else { return .none }
        return .send(.delegate(.playNow(
          items: items,
          start: .selectedEntry(index: startIndex),
          context: context,
        )))

      case .path(.element(id: let id, action: .artist(.addToPlaylistTapped))):
        guard let artistID = state.path[id: id, case: \.artist]?.artistID
        else { return .none }
        return .send(.addArtistToPlaylistTapped(artistID))

      case .path(.element(id: let id, action: .artist(.addToQueueTapped))):
        guard let artistID = state.path[id: id, case: \.artist]?.artistID,
              let items = self.artistDiscographyPlaybackItems(for: artistID, in: state.status)
        else { return .none }
        return .send(.delegate(.addToQueue(items: items)))

      case .path(.element(id: let id, action: .artist(.playButtonTapped))):
        guard let artistID = state.path[id: id, case: \.artist]?.artistID
        else { return .none }
        return .send(.artistPlayTapped(artistID))

      case .path(.element(id: let id, action: .artist(.playNextTapped))):
        guard let artistID = state.path[id: id, case: \.artist]?.artistID,
              let items = self.artistDiscographyPlaybackItems(for: artistID, in: state.status)
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
              let items = self.artistTopSongsPlaybackItems(for: artistID, in: state.status),
              let item = items.first(where: { $0.id == trackID })
        else { return .none }
        return .send(.delegate(.addToQueue(items: [item])))

      case .path(.element(id: let id, action: .artist(.topSongPlayNextTapped(let trackID)))):
        guard let artistID = state.path[id: id, case: \.artist]?.artistID,
              let items = self.artistTopSongsPlaybackItems(for: artistID, in: state.status),
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
        case .addToPlaylist:
          return .send(.addPlaylistToPlaylistTapped(detail.playlist.id))

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
          guard !state.isPlaylistMutationInFlight,
                case .loaded(let library) = state.status else { return .none }
          state.playlistMusicPicker = .init(playlist: detail.playlist, library: library)
          state.playlistMutationFailure = nil
          return .none

        case .addToQueue(let items):
          return .send(.delegate(.addToQueue(items: items)))

        case .delete:
          return self.deletePlaylist(
            playlistID: detail.playlist.id,
            expectedRevision: detail.playlist.revision,
            state: &state,
          )

        case .dismissPlaybackFailure:
          return .send(.delegate(.dismissPlaybackFailure))

        case .playbackFailureActionTapped:
          return .send(.delegate(.playbackFailureActionTapped))

        case .playNext(let items):
          return .send(.delegate(.playNext(items: items)))

        case .playNow(let items, let start):
          return .send(.delegate(.playNow(
            items: items,
            start: start,
            context: PlaybackContext(
              identity: .playlist(detail.playlist.id),
              title: detail.playlist.name,
            ),
          )))

        case .removeEntry(let entryID):
          return self.removePlaylistEntry(
            playlistID: detail.playlist.id,
            expectedRevision: detail.playlist.revision,
            entryID: entryID,
            state: &state,
          )

        case .rename(let rawName):
          return self.renamePlaylist(
            playlistID: detail.playlist.id,
            expectedRevision: detail.playlist.revision,
            rawName: rawName,
            state: &state,
          )

        case .reorder(let entryIDs):
          return self.reorderPlaylist(
            playlistID: detail.playlist.id,
            expectedRevision: detail.playlist.revision,
            entryIDs: entryIDs,
            state: &state,
          )

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
        state.isLibraryRefreshFailurePresented = false
        if library.isEmpty {
          log(.debug, .library, "e24738fc")
        }
        return self.applyAuthoritativeLibrary(library, to: &state)

      case .approvedLibraryLoadFailed:
        log(.err, .library, "cd55459e")
        if state.status.isDisplayingLibrary {
          state.isLibraryRefreshFailurePresented = true
        } else {
          state.status = .failed
        }
        return .none

      case .approvedLibraryMusicAccessUnavailable:
        state.isLibraryRefreshFailurePresented = false
        state.status = .musicAccessUnavailable
        state.addToPlaylist = nil
        state.isPlaylistMutationInFlight = false
        state.playlistIDsBeforeCreate = nil
        state.playlistMusicPicker = nil
        state.playlistMutationFailure = nil
        state.path.removeAll()
        state.shouldPresentCreatedPlaylist = false
        log(.warn, .subs, "ded74480")
        return .send(.delegate(.approvedTrackIDsUpdated([])))

      case .cachedApprovedLibraryLoaded(let library):
        state.applyLibrary(library)
        return .send(.delegate(.approvedTrackIDsUpdated(library.approvedTrackIDs)))

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

      case .libraryRefreshFailureDismissed:
        state.isLibraryRefreshFailurePresented = false
        return .none

      case .playlistMusicPickerRequested(let playlistID):
        guard !state.isPlaylistMutationInFlight,
              case .loaded(let library) = state.status,
              let playlist = library.playlist(id: playlistID) else { return .none }
        state.playlistMusicPicker = .init(playlist: playlist, library: library)
        state.playlistMutationFailure = nil
        return .none

      case .playlistMusicPicker(.presented(.delegate(.addRequested(
        let sources,
        let duplicateResolution,
      )))):
        guard !state.isPlaylistMutationInFlight,
              case .loaded(let library) = state.status,
              let picker = state.playlistMusicPicker,
              library.playlist(id: picker.playlistID) != nil else { return .none }
        state.isPlaylistMutationInFlight = true
        state.playlistMutationFailure = nil
        return self.performPlaylistMusicPickerMutation {
          try await self.approvedMusic.addMusicBatchToPlaylist(.init(
            playlistId: picker.playlistID.rawValue,
            sources: sources,
            duplicateResolution: duplicateResolution,
          ))
        }

      case .playlistMusicPicker(.dismiss):
        state.playlistMutationFailure = nil
        return .none

      case .playlistMusicPicker(.presented):
        return .none

      case .playlistMusicPickerMutationResponse(let outcome):
        state.isPlaylistMutationInFlight = false
        state.isRefreshingRemoteLibrary = false
        switch outcome {
        case .updated(let library):
          state.playlistMusicPicker = nil
          return self.applyAuthoritativeLibrary(library, to: &state)
        case .batchConfirmationRequired(let library, let confirmation):
          let effect = self.applyAuthoritativeLibrary(library, to: &state)
          return .merge(
            effect,
            .send(.playlistMusicPicker(.presented(.duplicateConfirmationReceived(confirmation)))),
          )
        case .conflict(let library):
          state.playlistMutationFailure = .conflict
          return self.applyAuthoritativeLibrary(library, to: &state)
        case .failed:
          state.playlistMutationFailure = .failed
          return .none
        }

      case .playlistMutationFailureDismissed:
        state.playlistMutationFailure = nil
        return .none

      case .playlistMutationResponse(let outcome, let rollback):
        state.isPlaylistMutationInFlight = false
        state.isRefreshingRemoteLibrary = false
        var effects: [EffectOf<Self>] = []
        var recencyToSave: LibraryCollectionRecency?
        switch outcome {
        case .updated(let library):
          effects.append(self.applyAuthoritativeLibrary(library, to: &state))
          if state.playlistIDsBeforeCreate != nil,
             let playlist = state.createdPlaylist(in: library, at: self.now) {
            recencyToSave = state.collectionRecency
            if state.shouldPresentCreatedPlaylist {
              state.presentPlaylistDetail(playlistID: playlist.id)
              state.playlistMusicPicker = .init(playlist: playlist, library: library)
            }
          }
          state.shouldPresentCreatedPlaylist = false
        case .conflict(let library):
          effects.append(self.applyAuthoritativeLibrary(library, to: &state))
          state.playlistMutationFailure = .conflict
          state.playlistIDsBeforeCreate = nil
          state.shouldPresentCreatedPlaylist = false
        case .failed:
          if let rollback {
            state.applyLibrary(rollback)
          }
          state.playlistMutationFailure = .failed
          state.playlistIDsBeforeCreate = nil
          state.shouldPresentCreatedPlaylist = false
        }
        if let recencyToSave {
          effects.append(self.saveCollectionRecency(recencyToSave))
        }
        return .merge(effects)

      case .refreshPresentationFinished:
        state.isRefreshingRemoteLibrary = false
        return .none

      case .refreshPulled:
        guard !state.isPlaylistMutationInFlight else { return .none }
        state.isLibraryRefreshFailurePresented = false
        state.isRefreshingRemoteLibrary = true
        if !state.status.isDisplayingLibrary {
          state.status = .loading
        }
        return self.refreshRemoteApprovedLibrary(loadCache: false)

      case .retryButtonTapped:
        state.isLibraryRefreshFailurePresented = false
        state.isRefreshingRemoteLibrary = true
        if !state.status.isDisplayingLibrary {
          state.status = .loading
        }
        return self.refreshRemoteApprovedLibrary(loadCache: true)

      case .path(.element(id: let id, action: .album(.delegate(let delegateAction)))):
        guard let album = state.path[id: id, case: \.album]?.album else { return .none }
        switch delegateAction {
        case .addAlbumToPlaylist(let albumID):
          return .send(.addAlbumToPlaylistTapped(albumID))
        case .addToQueue(let items):
          return .send(.delegate(.addToQueue(items: items)))
        case .dismissPlaybackFailure:
          return .send(.delegate(.dismissPlaybackFailure))
        case .playbackFailureActionTapped:
          return .send(.delegate(.playbackFailureActionTapped))
        case .playNow(let items, let start):
          return .send(.delegate(.playNow(
            items: items,
            start: start,
            context: PlaybackContext(
              identity: .album(album.id),
              title: album.title,
            ),
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
    .ifLet(\.$playlistMusicPicker, action: \.playlistMusicPicker) {
      PlaylistMusicPickerFeature()
    }
  }

  private func deletePlaylist(
    playlistID: MusicPlaylist.ID,
    expectedRevision: Int64,
    state: inout State,
  ) -> EffectOf<Self> {
    guard !state.isPlaylistMutationInFlight,
          case .loaded(let library) = state.status,
          library.playlist(id: playlistID)?.revision == expectedRevision else { return .none }
    state.isPlaylistMutationInFlight = true
    state.playlistMutationFailure = nil
    return self.performPlaylistMutation {
      try await self.approvedMusic.deletePlaylist(.init(
        playlistId: playlistID.rawValue,
        expectedRevision: expectedRevision,
      ))
    }
  }

  private func removePlaylistEntry(
    playlistID: MusicPlaylist.ID,
    expectedRevision: Int64,
    entryID: MusicPlaylistEntry.ID,
    state: inout State,
  ) -> EffectOf<Self> {
    guard !state.isPlaylistMutationInFlight,
          case .loaded(let library) = state.status,
          let playlistIndex = library.playlists.firstIndex(where: {
            $0.id == playlistID && $0.revision == expectedRevision
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
        playlistId: playlistID.rawValue,
        expectedRevision: expectedRevision,
        entryId: entryID.rawValue,
      ))
    }
  }

  private func renamePlaylist(
    playlistID: MusicPlaylist.ID,
    expectedRevision: Int64,
    rawName: String,
    state: inout State,
  ) -> EffectOf<Self> {
    guard !state.isPlaylistMutationInFlight,
          let name = rawName.validPlaylistName,
          case .loaded(let library) = state.status,
          let playlistIndex = library.playlists.firstIndex(where: {
            $0.id == playlistID && $0.revision == expectedRevision
          }),
          library.playlists[playlistIndex].name != name else { return .none }
    var optimisticLibrary = library
    optimisticLibrary.playlists[playlistIndex].name = name
    state.isPlaylistMutationInFlight = true
    state.playlistMutationFailure = nil
    state.applyLibrary(optimisticLibrary)
    return self.performPlaylistMutation(rollback: library) {
      try await self.approvedMusic.renamePlaylist(.init(
        playlistId: playlistID.rawValue,
        expectedRevision: expectedRevision,
        name: name,
      ))
    }
  }

  private func reorderPlaylist(
    playlistID: MusicPlaylist.ID,
    expectedRevision: Int64,
    entryIDs: [MusicPlaylistEntry.ID],
    state: inout State,
  ) -> EffectOf<Self> {
    guard !state.isPlaylistMutationInFlight,
          case .loaded(let library) = state.status,
          let playlistIndex = library.playlists.firstIndex(where: {
            $0.id == playlistID && $0.revision == expectedRevision
          }) else { return .none }
    let entriesByID = Dictionary(
      uniqueKeysWithValues: library.playlists[playlistIndex].entries.map {
        ($0.id, $0)
      },
    )
    guard Set(entryIDs) == Set(entriesByID.keys) else { return .none }
    var optimisticLibrary = library
    optimisticLibrary.playlists[playlistIndex].entries = entryIDs.compactMap {
      entriesByID[$0]
    }
    state.isPlaylistMutationInFlight = true
    state.playlistMutationFailure = nil
    state.applyLibrary(optimisticLibrary)
    return self.performPlaylistMutation(rollback: library) {
      try await self.approvedMusic.reorderPlaylistEntries(.init(
        playlistId: playlistID.rawValue,
        expectedRevision: expectedRevision,
        entryIds: entryIDs.map(\.rawValue),
      ))
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

  private func artistDiscographyPlaybackItems(
    for artistID: ApprovedArtist.ID,
    in status: Status,
  ) -> [PlaybackItem]? {
    guard case .loaded(let library) = status else { return nil }
    let items = library.artistDiscographyPlaybackItems(for: artistID)
    return items.isEmpty ? nil : items
  }

  private func artistTopSongsPlaybackItems(
    for artistID: ApprovedArtist.ID,
    in status: Status,
  ) -> [PlaybackItem]? {
    guard case .loaded(let library) = status else { return nil }
    let items = library.artistTopSongsPlaybackItems(for: artistID)
    return items.isEmpty ? nil : items
  }

  private func artistPlaybackContext(
    for artistID: ApprovedArtist.ID,
    source: PlaybackContext.ArtistSource,
    in status: Status,
  ) -> PlaybackContext? {
    guard case .loaded(let library) = status,
          let artist = library.artist(id: artistID) else { return nil }
    return PlaybackContext(
      identity: .artist(artist.id),
      title: artist.name,
      artistSource: source,
    )
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
          case .batchDuplicateConfirmationRequired(let library, _),
               .conflict(let library):
            await send(.addToPlaylistMutationResponse(.conflict(library)))
          }
        } catch ApprovedMusicClientError.invalidConnection {
          await send(.delegate(.connectionInvalid))
        } catch ApprovedMusicClientError.musicAccessUnavailable {
          await send(.approvedLibraryMusicAccessUnavailable)
        } catch {
          await send(.addToPlaylistMutationResponse(.failed))
        }
      },
    )
  }

  private func performPlaylistMusicPickerMutation(
    operation: @escaping @Sendable () async throws -> MusicPlaylistMutationResult,
  ) -> EffectOf<Self> {
    .merge(
      .cancel(id: CancelID.approvedLibraryRefresh),
      .run { send in
        do {
          switch try await operation() {
          case .updated(let library):
            await send(.playlistMusicPickerMutationResponse(.updated(library)))
          case .batchDuplicateConfirmationRequired(let library, let confirmation):
            await send(.playlistMusicPickerMutationResponse(.batchConfirmationRequired(
              library,
              confirmation,
            )))
          case .duplicateConfirmationRequired(let library, _),
               .conflict(let library):
            await send(.playlistMusicPickerMutationResponse(.conflict(library)))
          }
        } catch ApprovedMusicClientError.invalidConnection {
          await send(.delegate(.connectionInvalid))
        } catch ApprovedMusicClientError.musicAccessUnavailable {
          await send(.approvedLibraryMusicAccessUnavailable)
        } catch {
          await send(.playlistMusicPickerMutationResponse(.failed))
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
               .duplicateConfirmationRequired(let library, _),
               .batchDuplicateConfirmationRequired(let library, _):
            await send(.playlistMutationResponse(.conflict(library), rollback: rollback))
          }
        } catch ApprovedMusicClientError.invalidConnection {
          await send(.delegate(.connectionInvalid))
        } catch ApprovedMusicClientError.musicAccessUnavailable {
          await send(.approvedLibraryMusicAccessUnavailable)
        } catch {
          await send(.playlistMutationResponse(.failed, rollback: rollback))
        }
      },
    )
  }

  private func applyAuthoritativeLibrary(
    _ library: ApprovedMusicLibrary,
    to state: inout State,
  ) -> EffectOf<Self> {
    state.applyLibrary(library)
    return .send(.delegate(.approvedTrackIDsUpdated(library.approvedTrackIDs)))
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
      } catch ApprovedMusicClientError.invalidConnection {
        await send(.delegate(.connectionInvalid))
        return
      } catch ApprovedMusicClientError.musicAccessUnavailable {
        await send(.approvedLibraryMusicAccessUnavailable)
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
    case .loading, .failed, .musicAccessUnavailable:
      false
    }
  }
}

extension LibraryFeature.State {
  mutating func applyLibrary(_ library: ApprovedMusicLibrary) {
    self.status = library.isEmpty ? .empty : .loaded(library)
    self.path.reconcile(with: library)
    if var picker = self.playlistMusicPicker,
       library.playlist(id: picker.playlistID) != nil {
      picker.applyLibrary(library)
      self.playlistMusicPicker = picker
    } else {
      self.playlistMusicPicker = nil
    }
  }

  mutating func createdPlaylist(
    in library: ApprovedMusicLibrary,
    at date: Date,
  ) -> MusicPlaylist? {
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
    return playlist
  }

  @discardableResult
  mutating func pushAlbumDetail(albumID: ApprovedAlbum.ID) -> Bool {
    guard case .loaded(let library) = self.status,
          let album = library.album(id: albumID)
    else { return false }

    self.path.append(.album(.init(album: album)))
    return true
  }

  @discardableResult
  mutating func pushArtistDetail(artistID: ApprovedArtist.ID) -> Bool {
    guard case .loaded(let library) = self.status,
          library.artist(id: artistID) != nil
    else { return false }

    self.path.append(.artist(.init(artistID: artistID)))
    return true
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

  mutating func setAlbumDetailPlaybackSession(
    _ session: PlaybackFeature.Session?,
    activeContext: PlaybackContext?,
  ) {
    guard var albumDetail = self.albumDetail else { return }
    albumDetail.setPlaybackSession(session, activeContext: activeContext)
    self.albumDetail = albumDetail
  }

  mutating func setPlaylistDetailPlaybackFailure(_ failure: PlaybackFailure?) {
    guard var playlistDetail = self.playlistDetail else { return }
    playlistDetail.setPlaybackFailure(failure)
    self.playlistDetail = playlistDetail
  }

  mutating func setPlaylistDetailPlaybackSession(
    _ session: PlaybackFeature.Session?,
    activeContext: PlaybackContext?,
  ) {
    guard var playlistDetail = self.playlistDetail else { return }
    playlistDetail.setPlaybackSession(session, activeContext: activeContext)
    self.playlistDetail = playlistDetail
  }
}

private extension MusicPlaylistDuplicateConfirmation {
  func allows(_ resolution: MusicPlaylistDuplicateResolution) -> Bool {
    switch (self, resolution) {
    case (.track, .addAgain),
         (.album, .addAll),
         (.album, .addOnlyNew),
         (.artist, .addAll),
         (.artist, .addOnlyNew),
         (.playlist, .addAll),
         (.playlist, .addOnlyNew):
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
