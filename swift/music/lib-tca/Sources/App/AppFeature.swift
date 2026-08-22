import ComposableArchitecture
import Foundation
import GertieApp
import GertieTcaFeatures
import MusicRoute

@Reducer
struct AppFeature: Sendable {
  enum Tab: Equatable, Hashable, Sendable {
    case library
    case queue
    case search
  }

  @ObservableState
  struct State: Equatable {
    @Presents var crossPromo: CrossPromoFeature.State?
    var crossPromos = CrossPromos.Output(promos: [])
    var killSwitch = KillSwitchFeature.State()
    var library = LibraryFeature.State()
    var playback = PlaybackFeature.State()
    var pendingLibraryPlayNowOrigin: LibraryCollectionIdentity?
    var search = SearchFeature.State()
    var setup = MusicSetupFeature.State()
    var isNowPlayingPresented = false
    var selectedTab = Tab.library

    var nowPlayingAlbumID: ApprovedAlbum.ID? {
      guard let albumID = self.playback.session?.currentItem.albumID,
            case .loaded(let library) = self.library.status,
            library.album(id: albumID) != nil
      else { return nil }
      return albumID
    }

    var nowPlayingArtistID: ApprovedArtist.ID? {
      guard let item = self.playback.session?.currentItem,
            case .loaded(let library) = self.library.status
      else { return nil }
      return library.artist(matching: item)?.id
    }
  }

  enum Action: Equatable {
    case appDidLaunch
    case appEnteredForeground
    case crossPromo(PresentationAction<CrossPromoFeature.Action>)
    case crossPromosReceived(CrossPromos.Output)
    case killSwitch(KillSwitchFeature.Action)
    case library(LibraryFeature.Action)
    case nowPlayingAddToPlaylistTapped
    case nowPlayingPresentationChanged(Bool)
    case nowPlayingViewAlbumTapped
    case nowPlayingViewArtistTapped
    case playback(PlaybackFeature.Action)
    case playbackAlbumIDsResolved(ApprovedTrack.ID, [ApprovedAlbum.ID])
    case queueBrowseLibraryButtonTapped
    case search(SearchFeature.Action)
    case setup(MusicSetupFeature.Action)
    case tabSelected(Tab)
  }

  enum CancelID: Hashable {
    case albumResolution
  }

  enum CrossPromoTrigger: Equatable {
    case home
    case postOnboarding

    var placement: String {
      switch self {
      case .home: "musicHome"
      case .postOnboarding: "musicOnboarding"
      }
    }
  }

  enum CrossPromoEvent: String {
    case cta
    case dismiss
    case impression

    var id: String {
      switch self {
      case .cta: "4a82fd13"
      case .dismiss: "0d39be76"
      case .impression: "71e4c6a9"
      }
    }
  }

  static let crossPromoThrottle: TimeInterval = 60 * 60 * 72

  @Dependency(\.api) var api
  @Dependency(\.approvedMusicLibraryCache) var approvedMusicLibraryCache
  @Dependency(\.crossPromoStorage) var crossPromoStorage
  @Dependency(\.date.now) var now
  @Dependency(\.device) var device
  @Dependency(\.keychain) var keychain
  @Dependency(\.playback) var playback
  @Dependency(\.playbackSessionCache) var playbackSessionCache
  @Dependency(\.uuid) var uuid

  var body: some ReducerOf<Self> {
    Scope(state: \.killSwitch, action: \.killSwitch) {
      KillSwitchFeature(app: .music) {
        guard let deviceId = await self.device.vendorId() else {
          throw KillSwitchDeviceIdError.missingDeviceId
        }
        return deviceId
      }
    }

    Scope(state: \.library, action: \.library) {
      LibraryFeature()
    }

    Scope(state: \.playback, action: \.playback) {
      PlaybackFeature()
    }

    Scope(state: \.search, action: \.search) {
      SearchFeature()
    }

    Scope(state: \.setup, action: \.setup) {
      MusicSetupFeature()
    }

    Reduce { state, action in
      switch action {
      case .appDidLaunch:
        return .run { send in
          guard let crossPromos = try? await self.api.crossPromos(),
                !crossPromos.promos.isEmpty else { return }
          await send(.crossPromosReceived(crossPromos))
        }

      case .appEnteredForeground:
        return self.presentCrossPromo(&state, for: .home)

      case .crossPromo(.presented(.delegate(.ctaTapped(let slot)))):
        return self.closeCrossPromo(&state, event: .cta, ctaSlot: slot)

      case .crossPromo(.dismiss), .crossPromo(.presented(.delegate(.dismissed))):
        return self.closeCrossPromo(&state, event: .dismiss, ctaSlot: nil)

      case .crossPromo:
        return .none

      case .crossPromosReceived(let crossPromos):
        let dropped = crossPromos.promos.filter { !$0.hasGuaranteedExit }
        state.crossPromos = .init(promos: crossPromos.promos.filter(\.hasGuaranteedExit))
        let trigger: CrossPromoTrigger = state.setup.resumedStoredConnection
          ? .home
          : .postOnboarding
        return .merge(
          self.logUnpresentableCrossPromos(dropped),
          self.presentCrossPromo(&state, for: trigger),
        )

      case .nowPlayingAddToPlaylistTapped:
        guard let currentItem = state.playback.session?.currentItem,
              let albumID = currentItem.albumID else { return .none }
        return .send(.library(.addTrackToPlaylistTapped(
          trackID: currentItem.id,
          albumID: albumID,
        )))

      case .nowPlayingViewAlbumTapped:
        guard let albumID = state.nowPlayingAlbumID,
              state.library.pushAlbumDetail(albumID: albumID)
        else { return .none }
        state.isNowPlayingPresented = false
        state.selectedTab = .library
        self.synchronizeDetailPlayback(state: &state)
        return .none

      case .nowPlayingViewArtistTapped:
        guard let artistID = state.nowPlayingArtistID,
              state.library.pushArtistDetail(artistID: artistID)
        else { return .none }
        state.isNowPlayingPresented = false
        state.selectedTab = .library
        return .none

      case .killSwitch:
        return .none

      case .nowPlayingPresentationChanged(let isPresented):
        state.isNowPlayingPresented = isPresented
        return .none

      case .queueBrowseLibraryButtonTapped:
        state.selectedTab = .library
        return .none

      case .tabSelected(let tab):
        state.selectedTab = tab
        if tab == .search {
          state.search.applyLibraryStatus(state.library.status)
        }
        return .none

      #if DEBUG
        case .library(.debugResetOnboardingButtonTapped):
          self.keychain.save(deviceId: self.uuid())
          return self.resetConnectionBoundState(&state)
      #endif

      case .library(.delegate(.connectionInvalid)):
        guard self.keychain.loadConnection() != nil else { return .none }
        log(.warn, .setup, "bc86178a")
        return self.resetConnectionBoundState(&state)

      case .library(.delegate(.addToQueue(let items))):
        state.pendingLibraryPlayNowOrigin = nil
        return .send(.playback(.addToQueue(items)))

      case .library(.delegate(.approvedTrackIDsUpdated)):
        let approvedLibrary = if case .loaded(let library) = state.library.status {
          library
        } else {
          ApprovedMusicLibrary.empty
        }
        return .send(.playback(.approvedLibraryUpdated(approvedLibrary)))

      case .library(.delegate(.artistPlaybackButtonTapped(let items, let context))):
        guard !items.isEmpty else { return .none }
        if state.playback.activePlaybackContext?.identity == context.identity,
           state.playback.activePlaybackContext?.artistSource == context.artistSource {
          state.pendingLibraryPlayNowOrigin = nil
          return .send(.playback(.togglePlayPause))
        }
        state.pendingLibraryPlayNowOrigin = context.identity
        return .send(.playback(.playNow(
          items: items,
          start: .collection,
          context: context,
        )))

      case .library(.delegate(.dismissPlaybackFailure)):
        return .send(.playback(.playbackFailureDismissed))

      case .library(.delegate(.playbackFailureActionTapped)):
        return .send(.playback(.playbackFailureActionTapped))

      case .library(.delegate(.playNext(let items))):
        state.pendingLibraryPlayNowOrigin = nil
        return .send(.playback(.playNext(items)))

      case .library(.delegate(.playNow(let items, let start, let context))):
        state.pendingLibraryPlayNowOrigin = context.identity
        return .send(.playback(.playNow(
          items: items,
          start: start,
          context: context,
        )))

      case .library(.delegate(.togglePlayPause)):
        return .send(.playback(.togglePlayPause))

      case .library:
        state.search.applyLibraryStatus(state.library.status)
        self.synchronizeDetailPlayback(state: &state)
        return self.resolveCurrentPlaybackAlbum(state: &state)

      case .playback(.playNowFinished):
        let origin = state.pendingLibraryPlayNowOrigin
        state.pendingLibraryPlayNowOrigin = nil
        self.synchronizeDetailPlayback(state: &state)
        let resolveAlbum = self.resolveCurrentPlaybackAlbum(state: &state)
        guard state.playback.hasAuthoritativeSnapshot, let origin else {
          return resolveAlbum
        }
        return .merge(
          resolveAlbum,
          .send(.library(.collectionPlayNowSucceeded(origin))),
        )

      case .playback(.playbackFailed):
        state.pendingLibraryPlayNowOrigin = nil
        self.synchronizeDetailPlayback(state: &state)
        return self.resolveCurrentPlaybackAlbum(state: &state)

      case .playback(.playbackEvent(.queueEnded)):
        state.pendingLibraryPlayNowOrigin = nil
        if state.playback.session == nil {
          state.isNowPlayingPresented = false
        }
        self.synchronizeDetailPlayback(state: &state)
        return .cancel(id: CancelID.albumResolution)

      case .playback(.playbackEvent(.progressChanged)):
        return .none

      case .playback(let playbackAction):
        switch playbackAction {
        case .addToQueue,
             .clearQueueButtonTapped,
             .playNext,
             .queueEntryRemoveRequested,
             .reorderUpcoming,
             .stop:
          state.pendingLibraryPlayNowOrigin = nil
        default:
          break
        }
        self.synchronizeDetailPlayback(state: &state)
        return self.resolveCurrentPlaybackAlbum(state: &state)

      case .playbackAlbumIDsResolved(let songID, let albumIDs):
        guard state.playback.session?.currentTrackID == songID,
              case .loaded(let library) = state.library.status else { return .none }
        let approvedAlbumIDs = Set(library.albums.map(\.id))
        guard let albumID = albumIDs
          .filter({ approvedAlbumIDs.contains($0) })
          .sorted(by: { $0.rawValue < $1.rawValue })
          .first else { return .none }
        state.playback.setSourceAlbumID(albumID, for: songID)
        self.synchronizeDetailPlayback(state: &state)
        return .send(.playback(.saveCachedSession))

      case .search(.delegate(.browseLibrary)):
        state.selectedTab = .library
        return .none

      case .search(.delegate(.library(let action))):
        return .send(.library(action))

      case .search(.delegate(.playback(let action))):
        return .send(.library(.delegate(action)))

      case .search(.delegate(.songTapped(let items, let start, let context))):
        let selectedIndex = switch start {
        case .collection:
          items.startIndex
        case .selectedEntry(let index):
          index
        }
        guard items.indices.contains(selectedIndex) else { return .none }
        if state.playback.session?.currentTrackID == items[selectedIndex].id {
          state.pendingLibraryPlayNowOrigin = nil
          return .send(.playback(.togglePlayPause))
        }
        state.pendingLibraryPlayNowOrigin = context?.identity
        return .send(.playback(.playNow(
          items: items,
          start: start,
          context: context,
        )))

      case .search:
        self.synchronizeDetailPlayback(state: &state)
        return .none

      case .setup(.delegate(.completed)):
        let trigger: CrossPromoTrigger = state.setup.resumedStoredConnection
          ? .home
          : .postOnboarding
        return self.presentCrossPromo(&state, for: trigger)

      case .setup:
        return .none
      }
    }
    .ifLet(\.$crossPromo, action: \.crossPromo) {
      CrossPromoFeature()
    }
  }

  private func presentCrossPromo(
    _ state: inout State,
    for trigger: CrossPromoTrigger,
  ) -> EffectOf<Self> {
    guard state.crossPromo == nil,
          state.setup.isReady,
          !state.isNowPlayingPresented,
          state.library.addToPlaylist == nil,
          state.library.playlistMusicPicker == nil
    else { return .none }
    let dismissedCampaignIDs = self.crossPromoStorage.dismissedCampaignIDs()
    guard let campaign = state.crossPromos.promos.firstEligible(
      at: trigger.placement,
      excluding: dismissedCampaignIDs,
    ) else { return .none }
    if trigger == .home,
       let lastShownAt = self.crossPromoStorage.lastShownAt(),
       self.now.timeIntervalSince(lastShownAt) < Self.crossPromoThrottle {
      return .none
    }
    let now = self.now
    state.crossPromo = .init(campaign: campaign)
    return .merge(
      .run { _ in self.crossPromoStorage.saveLastShownAt(now) },
      self.logCrossPromoEvent(.impression, campaign),
    )
  }

  private func closeCrossPromo(
    _ state: inout State,
    event: CrossPromoEvent,
    ctaSlot: CrossPromoFeature.CtaSlot?,
  ) -> EffectOf<Self> {
    guard let campaign = state.crossPromo?.campaign else {
      state.crossPromo = nil
      return .none
    }
    state.crossPromo = nil
    let extra = ctaSlot.map { slot in
      "slot=\(slot.rawValue) action=\(campaign.action(for: slot)?.analyticsLabel ?? "-")"
    }
    return .merge(
      self.logCrossPromoEvent(event, campaign, extra: extra),
      .run { _ in self.crossPromoStorage.insertDismissedCampaignID(campaign.campaignId) },
    )
  }

  private func logUnpresentableCrossPromos(
    _ campaigns: [CrossPromoCampaign],
  ) -> EffectOf<Self> {
    .merge(campaigns.map { campaign in
      .run { _ in
        await log(
          .warn,
          .setup,
          "c6f17a24",
          detail: "campaign=\(campaign.campaignId) placement=\(campaign.placement)",
        ).value
      }
    })
  }

  private func logCrossPromoEvent(
    _ event: CrossPromoEvent,
    _ campaign: CrossPromoCampaign,
    extra: String? = nil,
  ) -> EffectOf<Self> {
    let base = "campaign=\(campaign.campaignId)"
      + " variant=\(campaign.variant ?? "-")"
      + " placement=\(campaign.placement)"
    let detail = extra.map { "\(base) \($0)" } ?? base
    return .run { _ in
      await log(.info, .setup, event.id, detail: detail).value
    }
  }

  private func resetConnectionBoundState(
    _ state: inout State,
  ) -> EffectOf<Self> {
    let childID = self.keychain.loadConnection()?.childId
    let playbackPreferences = state.playback.preferences
    self.keychain.deleteConnection()
    state.crossPromo = nil
    state.isNowPlayingPresented = false
    state.library = .init()
    state.playback = .init(preferences: playbackPreferences)
    state.pendingLibraryPlayNowOrigin = nil
    state.search = .init()
    state.setup = .init()
    state.selectedTab = .library
    return .merge(
      .cancel(id: CancelID.albumResolution),
      .cancel(id: LibraryFeature.CancelID.approvedLibraryRefresh),
      .cancel(id: MusicSetupFeature.CancelID.musicAppStatusPolling),
      .cancel(id: PlaybackFeature.CancelID.checkpointSave),
      .cancel(id: PlaybackFeature.CancelID.playbackEvents),
      .cancel(id: PlaybackFeature.CancelID.playbackStart),
      .cancel(id: PlaybackFeature.CancelID.seek),
      .run { _ in
        await self.playback.stop()
        guard let childID else { return }
        await self.approvedMusicLibraryCache.delete(childId: childID)
        await self.playbackSessionCache.delete(childId: childID)
      },
    )
  }

  private func synchronizeDetailPlayback(state: inout State) {
    state.library.setAlbumDetailPlaybackSession(
      state.playback.session,
      activeContext: state.playback.activePlaybackContext,
    )
    state.library.setPlaylistDetailPlaybackSession(
      state.playback.session,
      activeContext: state.playback.activePlaybackContext,
    )
    state.library.setAlbumDetailPlaybackFailure(state.playback.failure)
    state.library.setPlaylistDetailPlaybackFailure(state.playback.failure)
    state.search.setAlbumDetailPlaybackSession(
      state.playback.session,
      activeContext: state.playback.activePlaybackContext,
    )
    state.search.setPlaylistDetailPlaybackSession(
      state.playback.session,
      activeContext: state.playback.activePlaybackContext,
    )
    state.search.setAlbumDetailPlaybackFailure(state.playback.failure)
    state.search.setPlaylistDetailPlaybackFailure(state.playback.failure)
  }

  private func resolveCurrentPlaybackAlbum(
    state: inout State,
  ) -> EffectOf<Self> {
    guard state.playback.hasAuthoritativeSnapshot,
          case .loaded(let library) = state.library.status,
          let currentItem = state.playback.session?.currentItem else { return .none }
    let previousAlbumID = currentItem.albumID
    _ = state.playback.resolveCurrentAlbum(in: library)
    if state.playback.session?.currentItem.albumID != previousAlbumID {
      self.synchronizeDetailPlayback(state: &state)
      return .send(.playback(.saveCachedSession))
    }
    guard state.playback.session?.currentItem.albumID == nil,
          state.playback.pendingAlbumResolutionSongID != currentItem.id else { return .none }
    state.playback.pendingAlbumResolutionSongID = currentItem.id
    return .run { send in
      let albumIDs = await (try? self.playback.loadAlbumIDs(currentItem.id)) ?? []
      try Task.checkCancellation()
      await send(.playbackAlbumIDsResolved(currentItem.id, albumIDs))
    }
    .cancellable(id: CancelID.albumResolution, cancelInFlight: true)
  }
}
