import ComposableArchitecture
import GertieApp
import GertieTcaFeatures
import GertieUI
import LibViews
import SwiftUI

struct AppView: View {
  @Bindable var store: StoreOf<AppFeature>
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.scenePhase) private var scenePhase
  @Dependency(\.musicIdentity) private var identity
  @Namespace private var nowPlayingNamespace

  var body: some View {
    Group {
      #if os(iOS)
        self.iOSContent
          .animation(.snappy(duration: 0.22), value: self.store.playback.failure)
          .animation(
            .snappy(duration: 0.24),
            value: self.store.library.playlistMutationFailure,
          )
          .animation(
            .snappy(duration: 0.24),
            value: self.store.library.isLibraryRefreshFailurePresented,
          )
          .task(id: self.store.setup.isReady) {
            guard self.store.setup.isReady else { return }
            await self.store.send(.playback(.restorePlaybackPreferences)).finish()
            _ = self.store.send(.playback(.observePlayback))
            await self.store.send(.playback(.restoreCachedSession)).finish()
          }
      #else
        self.libraryView
          .safeAreaInset(edge: .bottom, spacing: 0) {
            if let failure = self.standalonePlaylistMutationFailure {
              self.playlistMutationFailureBanner(failure)
            } else if self.shouldPresentLibraryRefreshFailure {
              self.libraryRefreshFailureBanner
            }
          }
          .animation(
            .snappy(duration: 0.24),
            value: self.store.library.playlistMutationFailure,
          )
          .animation(
            .snappy(duration: 0.24),
            value: self.store.library.isLibraryRefreshFailurePresented,
          )
      #endif
    }
    .onChange(of: self.scenePhase, initial: true) { _, scenePhase in
      switch scenePhase {
      case .background, .inactive:
        self.store.send(.appBecameInactive)
        self.store.send(.playback(.saveCachedSession))
      case .active:
        let resolution = self.identity.resolve()
        self.store.send(.identityResolved(resolution))
        self.store.send(.appEnteredForeground)
        if resolution.needsReport { self.store.send(.identityReportRequested) }
      @unknown default:
        break
      }
    }
    .libraryPresentations(
      store: self.store.scope(\.library, action: \.library),
      isEnabled: !self.store.isNowPlayingPresented,
    )
    #if os(iOS)
    .task {
      await self.store.send(.appDidLaunch).finish()
    }
    .sheet(
      item: self.$store.scope(
        state: \.reviewPrompt,
        action: \.reviewPrompt,
      ),
    ) { store in
      GertieActionScreen(
        message: "Enjoying Gertrude Music? A quick App Store rating helps more families discover safer music listening. We won’t ask again.",
        actions: [
          .button("Give a rating") { store.send(.giveRatingButtonTapped) },
          .button("Leave a review") { store.send(.leaveReviewButtonTapped) },
          .button("No thanks") { store.send(.noThanksButtonTapped) },
        ],
      )
    }
    .crossPromoPresentations(
      store: self.$store.scope(state: \.crossPromo, action: \.crossPromo),
      onImageLoadFailure: Self.crossPromoImageLoadFailed,
    )
    #endif
  }

  private var libraryView: some View {
    LibraryViewContainer(
      store: self.store.scope(\.library, action: \.library),
      searchStore: self.store.scope(\.search, action: \.search),
      currentTrackID: self.store.playback.session?.currentTrackID,
      activePlaybackContext: self.store.playback.activePlaybackContext,
      isPlaybackLoading: self.store.playback.session?.isLoading ?? false,
      isPlaybackPlaying: self.store.playback.session?.isPlaying ?? false,
    )
  }

  #if os(iOS)
    @ViewBuilder
    private var iOSContent: some View {
      if !self.store.identity.available {
        MusicEmptyState(
          "Connecting Gertrude Music",
          message: self.store.identity.migrationPending
            ? "We’re connecting this phone to your account. Connect to the internet and try again."
            : "We couldn’t prepare this device. Please try again.",
          buttonTitle: "Try Again",
        ) { self.store.send(.identityRetryTapped) }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        Group {
          if self.store.setup.isReady, !self.store.library.isRestoringLaunchState {
            self.iOSLibraryContent
          } else {
            MusicSetupViewContainer(store: self.store.scope(\.setup, action: \.setup))
          }
        }
        .killSwitch(
          store: self.store.scope(\.killSwitch, action: \.killSwitch),
          suggestedUpdatesEnabled: self.store.setup.isReady,
        )
      }
    }

    private var iOSLibraryContent: some View {
      self.iOSTabView
        .coversTabLayoutUntilSettled()
        .nowPlayingPresentation(
          isPresented: self.nowPlayingPresented,
          zoomNamespace: self.nowPlayingNamespace,
          background: {
            NowPlayingBackgroundView(
              artworkURL: self.store.playback.session?.currentItem.artworkURL,
            )
          },
        ) {
          self.nowPlayingSheet
        }
    }

    @ViewBuilder
    private var iOSTabView: some View {
      if #available(iOS 26.0, *) {
        self.modernIOSTabView
          .tabViewBottomAccessory {
            TabBarAccessoryPlacementReader { placement in
              self.nowPlayingBarInset(
                displayMode: placement == .inline ? .inline : .expanded,
                showsBackground: false,
              )
            }
            .nowPlayingZoomSource(in: self.nowPlayingNamespace)
          }
          .tabBarMinimizeBehavior(.onScrollDown)
      } else if #available(iOS 18.0, *) {
        self.modernIOSTabView
      } else {
        TabView(selection: self.selectedTab) {
          self.iOSTabContent(self.libraryView)
            .tabItem {
              Label("Library", systemImage: "square.grid.2x2")
            }
            .tag(AppFeature.Tab.library)

          self.iOSTabContent(self.queueView)
            .tabItem {
              Label("Queue", systemImage: "list.bullet")
            }
            .tag(AppFeature.Tab.queue)
        }
      }
    }

    @available(iOS 18.0, *)
    private var modernIOSTabView: some View {
      TabView(selection: self.selectedTab) {
        Tab("Library", systemImage: "square.grid.2x2", value: AppFeature.Tab.library) {
          self.iOSTabContent(self.libraryView)
        }

        Tab("Queue", systemImage: "list.bullet", value: AppFeature.Tab.queue) {
          self.iOSTabContent(self.queueView)
        }
      }
    }

    @ViewBuilder
    private func iOSTabContent(_ content: some View) -> some View {
      if #available(iOS 26.0, *) {
        content
          .safeAreaInset(edge: .bottom, spacing: 0) {
            self.appNotice
          }
      } else {
        content
          .safeAreaInset(edge: .bottom, spacing: 0) {
            self.appNotice
          }
          .safeAreaInset(edge: .bottom, spacing: 0) {
            self.nowPlayingSafeAreaInset
          }
      }
    }

    @ViewBuilder
    private var appNotice: some View {
      if !self.isPlaybackFailurePresentedInDetail,
         let failure = self.store.playback.failure {
        self.playbackFailureBanner(failure)
      } else if self.store.playback.failure == nil,
                let failure = self.standalonePlaylistMutationFailure {
        self.playlistMutationFailureBanner(failure)
      } else if self.shouldPresentLibraryRefreshFailure {
        self.libraryRefreshFailureBanner
      }
    }

    private var queueView: some View {
      NavigationStack {
        if let session = self.store.playback.session {
          PlaybackQueueView(
            currentEntry: session.queue.currentEntry.viewData,
            queuedEntries: session.queue.queuedEntries.map(\.viewData),
            contextTitle: self.store.playback.queueContextTitle,
            contextEntries: session.queue.contextEntries.map(\.viewData),
            isPlaying: session.isPlaying,
            onClearQueue: {
              self.store.send(.playback(.clearQueueButtonTapped))
            },
            onRemove: {
              self.store.send(.playback(.queueEntryRemoveRequested($0)))
            },
            onReorder: { order in
              self.store.send(.playback(.reorderUpcoming(
                entryViewIDs: order.entryIDs,
                queuedEntryCount: order.queuedEntryCount,
              )))
            },
          )
        } else {
          MusicEmptyState(
            "Your queue is empty",
            message: "Choose an approved album, artist, or song to start listening.",
            buttonTitle: "Browse Library",
          ) { self.store.send(.queueBrowseLibraryButtonTapped) }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Queue")
        }
      }
    }

    private func nowPlayingBarInset(
      displayMode: NowPlayingBarDisplayMode,
      showsBackground: Bool,
    ) -> some View {
      self.nowPlayingBar(
        displayMode: displayMode,
        showsBackground: showsBackground,
      )
    }

    private var nowPlayingSafeAreaInset: some View {
      self.nowPlayingBar(
        displayMode: .expanded,
        showsBackground: true,
      )
      .padding(.horizontal, 12)
      .padding(.top, 6)
      .padding(.bottom, 8)
    }

    private var nowPlayingForegroundColor: Color {
      self.colorScheme == .dark ? .white : .black
    }

    private func nowPlayingBar(
      displayMode: NowPlayingBarDisplayMode,
      showsBackground: Bool,
    ) -> some View {
      let session = self.store.playback.session
      let item = session.map {
        self.nowPlayingBarItem($0.queue.currentEntry)
      } ?? NowPlayingBarItem(
        id: "not-playing",
        title: "Not Playing",
        artist: "Choose an approved track",
        artworkURL: nil,
      )
      let nextItem = session?.queue.upcomingEntries.first.map {
        self.nowPlayingBarItem($0)
      } ?? self.store.playback.repeatCollectionWrapEntry.map {
        self.nowPlayingBarItem($0)
      }
      return NowPlayingBar(
        item: item,
        nextItem: nextItem,
        isPlaying: session?.isPlaying ?? false,
        isLoading: session?.isLoading ?? false,
        isEnabled: session != nil,
        foregroundColor: self.nowPlayingForegroundColor,
        displayMode: displayMode,
        showsBackground: showsBackground,
        onTap: {
          guard self.store.playback.session != nil else { return }
          self.store.send(.nowPlayingPresentationChanged(true))
        },
        onPlayTap: {
          self.store.send(.playback(.togglePlayPause))
        },
        onNextTap: {
          self.store.send(.playback(.skipToNext))
        },
      )
    }

    private func nowPlayingBarItem(_ entry: PlaybackQueueEntry) -> NowPlayingBarItem {
      NowPlayingBarItem(
        id: entry.viewID,
        playbackID: entry.sourceEntryID.map { self.sourcePlaybackID($0) },
        title: entry.item.title,
        artist: entry.item.artistName,
        artworkURL: entry.item.artworkURL,
      )
    }

    private func nowPlayingBarItem(_ entry: PlaybackSource.Entry) -> NowPlayingBarItem {
      NowPlayingBarItem(
        id: "repeat-source:\(entry.id)",
        playbackID: self.sourcePlaybackID(entry.id),
        title: entry.item.title,
        artist: entry.item.artistName,
        artworkURL: entry.item.artworkURL,
      )
    }

    private func sourcePlaybackID(_ entryID: PlaybackSource.Entry.ID) -> String {
      "source:\(entryID)"
    }
  #endif

  #if os(iOS)
    @ViewBuilder
    private var nowPlayingSheet: some View {
      Group {
        if let session = self.store.playback.session {
          NowPlayingScreenView(
            title: session.currentItem.title,
            artist: session.currentItem.artistName,
            artworkURL: session.currentItem.artworkURL,
            showsBackground: false,
            isPlaying: session.isPlaying,
            isLoading: session.isLoading,
            progress: self.store.playback.progress.fraction,
            duration: self.store.playback.progress.duration,
            isShuffleEnabled: self.store.playback.preferences.isShuffleEnabled,
            isInfiniteEnabled: self.store.playback.preferences.endBehavior == .infinite,
            repeatMode: self.store.playback.preferences.endBehavior.nowPlayingRepeatMode,
            onPlayPauseTap: {
              self.store.send(.playback(.togglePlayPause))
            },
            onPreviousTap: {
              self.store.send(.playback(.skipToPrevious))
            },
            onNextTap: {
              self.store.send(.playback(.skipToNext))
            },
            onScrub: { time in
              self.store.send(.playback(.seek(time)))
            },
            onShuffleTap: {
              self.store.send(.playback(.shuffleButtonTapped))
            },
            onRepeatTap: {
              self.store.send(.playback(.repeatButtonTapped))
            },
            onInfiniteTap: {
              self.store.send(.playback(.infiniteButtonTapped))
            },
            isAddToPlaylistEnabled: session.currentItem.albumID != nil
              && !self.store.library.isPlaylistMutationInFlight,
            onCloseTap: {
              self.store.send(.nowPlayingPresentationChanged(false))
            },
            onAddToPlaylistTap: {
              self.store.send(.nowPlayingAddToPlaylistTapped)
            },
            onViewArtistTap: self.store.nowPlayingArtistID == nil ? nil : { @MainActor @Sendable in
              self.store.send(.nowPlayingViewArtistTapped)
            },
            onViewAlbumTap: self.store.nowPlayingAlbumID == nil ? nil : { @MainActor @Sendable in
              self.store.send(.nowPlayingViewAlbumTapped)
            },
          )
        } else {
          NowPlayingScreenView(
            title: "Not Playing",
            artist: "Choose an approved track",
            artworkURL: nil,
            showsBackground: false,
            isPlaying: false,
            isLoading: false,
            progress: 0,
            duration: 0,
            isShuffleEnabled: self.store.playback.preferences.isShuffleEnabled,
            isInfiniteEnabled: self.store.playback.preferences.endBehavior == .infinite,
            repeatMode: self.store.playback.preferences.endBehavior.nowPlayingRepeatMode,
            onPlayPauseTap: {},
            onPreviousTap: {},
            onNextTap: {},
            onScrub: { _ in },
            onShuffleTap: {
              self.store.send(.playback(.shuffleButtonTapped))
            },
            onRepeatTap: {
              self.store.send(.playback(.repeatButtonTapped))
            },
            onInfiniteTap: {
              self.store.send(.playback(.infiniteButtonTapped))
            },
            isAddToPlaylistEnabled: false,
            onCloseTap: {
              self.store.send(.nowPlayingPresentationChanged(false))
            },
          )
        }
      }
      .safeAreaInset(edge: .bottom, spacing: 0) {
        if let failure = self.store.playback.failure {
          self.playbackFailureBanner(failure)
        } else if let failure = self.standalonePlaylistMutationFailure {
          self.playlistMutationFailureBanner(failure)
        }
      }
      .animation(.snappy(duration: 0.22), value: self.store.playback.failure)
      .animation(
        .snappy(duration: 0.24),
        value: self.store.library.playlistMutationFailure,
      )
      .libraryPresentations(
        store: self.store.scope(\.library, action: \.library),
      )
    }

    private func playbackFailureBanner(_ failure: PlaybackFailure) -> some View {
      NoticeBanner(
        tone: .error,
        title: failure.title,
        message: failure.message,
        systemImage: failure.systemImage,
        actionTitle: failure.actionTitle,
        onActionTap: { self.store.send(.playback(.playbackFailureActionTapped)) },
        onDismissTap: { self.store.send(.playback(.playbackFailureDismissed)) },
      )
      .frame(maxWidth: 640)
      .padding(.horizontal, 18)
      .padding(.bottom, 12)
      .transition(.move(edge: .bottom).combined(with: .opacity))
    }
  #endif

  private func playlistMutationFailureBanner(
    _ failure: LibraryFeature.PlaylistMutationFailure,
  ) -> some View {
    NoticeBanner(
      tone: failure.tone,
      title: failure.title,
      message: failure.message,
      onDismissTap: {
        self.store.send(.library(.playlistMutationFailureDismissed))
      },
    )
    .frame(maxWidth: 640)
    .padding(.horizontal, 18)
    .padding(.bottom, 12)
    .transition(.move(edge: .bottom).combined(with: .opacity))
  }

  private var libraryRefreshFailureBanner: some View {
    NoticeBanner(
      tone: .warning,
      title: "Can’t refresh library",
      message: "Gertrude Music is showing cached music. It may be out of date.",
      systemImage: "wifi.exclamationmark",
      actionTitle: "Try Again",
      onActionTap: { self.store.send(.library(.retryButtonTapped)) },
      onDismissTap: { self.store.send(.library(.libraryRefreshFailureDismissed)) },
    )
    .frame(maxWidth: 640)
    .padding(.horizontal, 18)
    .padding(.bottom, 12)
    .transition(.move(edge: .bottom).combined(with: .opacity))
  }

  private var standalonePlaylistMutationFailure: LibraryFeature.PlaylistMutationFailure? {
    guard self.store.library.addToPlaylist == nil,
          self.store.library.playlistMusicPicker == nil else { return nil }
    return self.store.library.playlistMutationFailure
  }

  private var shouldPresentLibraryRefreshFailure: Bool {
    self.store.library.isLibraryRefreshFailurePresented
      && self.store.library.playlistMutationFailure == nil
      && self.store.playback.failure == nil
  }

  private var isPlaybackFailurePresentedInDetail: Bool {
    switch self.store.selectedTab {
    case .library:
      self.store.library.albumDetail != nil
        || self.store.library.playlistDetail != nil
    case .queue:
      false
    }
  }

  @MainActor
  private static func crossPromoImageLoadFailed(
    _ campaign: CrossPromoCampaign,
    _ image: CrossPromoImage,
    _ error: any Error,
  ) {
    log(
      .warn,
      .setup,
      "9b5e208d",
      detail: "campaign=\(campaign.campaignId) placement=\(campaign.placement) "
        + "url=\(image.url) error=\(error)",
    )
  }

  private var nowPlayingPresented: Binding<Bool> {
    self.$store.isNowPlayingPresented.sending(\.nowPlayingPresentationChanged)
  }

  private var selectedTab: Binding<AppFeature.Tab> {
    self.$store.selectedTab.sending(\.tabSelected)
  }
}

private extension PlaybackEndBehavior {
  var nowPlayingRepeatMode: NowPlayingRepeatMode {
    switch self {
    case .finite, .infinite:
      .off
    case .loopCollection:
      .collection
    case .loopTrack:
      .track
    }
  }
}

private extension PlaybackQueueEntry {
  var viewData: PlaybackQueueEntryData {
    PlaybackQueueEntryData(
      id: self.viewID,
      title: self.item.title,
      artist: self.item.artistName,
      artworkURL: self.item.artworkURL,
    )
  }
}

#if os(iOS)
  @available(iOS 26.0, *)
  private struct TabBarAccessoryPlacementReader<Content: View>: View {
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
    private let content: (TabViewBottomAccessoryPlacement?) -> Content

    init(
      @ViewBuilder content: @escaping (TabViewBottomAccessoryPlacement?) -> Content,
    ) {
      self.content = content
    }

    var body: some View {
      self.content(self.placement)
    }
  }
#endif
