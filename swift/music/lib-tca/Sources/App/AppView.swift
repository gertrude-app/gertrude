import ComposableArchitecture
import GertieTcaFeatures
import LibViews
import SwiftUI

struct AppView: View {
  @Bindable var store: StoreOf<AppFeature>
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.scenePhase) private var scenePhase

  var body: some View {
    Group {
      #if os(iOS)
        self.iOSContent
          .overlay(alignment: .top) {
            if !self.isPlaybackFailurePresentedInDetail,
               let failure = self.store.playback.failure {
              self.playbackFailureBanner(failure)
            }
          }
          .animation(.snappy(duration: 0.22), value: self.store.playback.failure)
          .task(id: self.store.setup.isReady) {
            guard self.store.setup.isReady else { return }
            _ = self.store.send(.playback(.observePlayback))
            await self.store.send(.playback(.restoreCachedSession)).finish()
          }
      #else
        self.libraryView
      #endif
    }
    .onChange(of: self.scenePhase) { _, scenePhase in
      switch scenePhase {
      case .background, .inactive:
        self.store.send(.playback(.saveCachedSession))
      case .active:
        break
      @unknown default:
        break
      }
    }
    .libraryPresentations(
      store: self.store.scope(state: \.library, action: \.library),
    )
    .killSwitch(
      store: self.store.scope(state: \.killSwitch, action: \.killSwitch),
      suggestedUpdatesEnabled: self.store.setup.isReady,
    )
  }

  private var libraryView: some View {
    LibraryViewContainer(
      store: self.store.scope(state: \.library, action: \.library),
      currentTrackID: self.store.playback.session?.currentTrackID,
      isPlaybackLoading: self.store.playback.session?.isLoading ?? false,
      isPlaybackPlaying: self.store.playback.session?.isPlaying ?? false,
    )
  }

  #if os(iOS)
    @ViewBuilder
    private var iOSContent: some View {
      if self.store.setup.isReady {
        self.iOSLibraryContent
      } else {
        MusicSetupViewContainer(
          store: self.store.scope(state: \.setup, action: \.setup),
        )
      }
    }

    private var iOSLibraryContent: some View {
      self.iOSTabView
        .nowPlayingPresentation(
          isPresented: self.nowPlayingPresented,
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

          self.iOSTabContent(self.searchView)
            .tabItem {
              Label("Search", systemImage: "magnifyingglass")
            }
            .tag(AppFeature.Tab.search)
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

        Tab(
          "Search",
          systemImage: "magnifyingglass",
          value: AppFeature.Tab.search,
          role: .search,
        ) {
          self.iOSTabContent(self.searchView)
        }
      }
    }

    @ViewBuilder
    private func iOSTabContent(_ content: some View) -> some View {
      if #available(iOS 26.0, *) {
        content
      } else {
        content
          .safeAreaInset(edge: .bottom, spacing: 0) {
            self.nowPlayingSafeAreaInset
          }
      }
    }

    private var queueView: some View {
      NavigationStack {
        if let session = self.store.playback.session {
          PlaybackQueueView(
            currentEntry: session.queue.currentEntry.viewData,
            upcomingEntries: session.queue.upcomingEntries.map(\.viewData),
            onClearUpcoming: {
              self.store.send(.playback(.clearUpcomingButtonTapped))
            },
            onRemove: {
              self.store.send(.playback(.queueEntryRemoveRequested($0)))
            },
            onReorder: {
              self.store.send(.playback(.reorderUpcoming($0)))
            },
          )
        } else {
          ContentUnavailableView {
            Label("Your queue is empty", systemImage: "music.note.list")
          } description: {
            Text("Choose an approved album, artist, or song to start listening.")
          } actions: {
            Button("Browse Library") {
              self.store.send(.queueBrowseLibraryButtonTapped)
            }
            .buttonStyle(.borderedProminent)
          }
          .navigationTitle("Queue")
        }
      }
    }

    private var searchView: some View {
      SearchViewContainer(
        store: self.store.scope(state: \.search, action: \.search),
        library: self.approvedLibrary,
        currentTrackID: self.store.playback.session?.currentTrackID,
        isPlaybackLoading: self.store.playback.session?.isLoading ?? false,
        isPlaybackPlaying: self.store.playback.session?.isPlaying ?? false,
        isPlaylistMutationInFlight: self.store.library.isPlaylistMutationInFlight,
      )
    }

    private var approvedLibrary: ApprovedMusicLibrary? {
      guard case .loaded(let library) = self.store.library.status else { return nil }
      return library
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
      return NowPlayingBar(
        title: session?.currentItem.title ?? "Not Playing",
        artist: session?.currentItem.artistName ?? "Choose an approved track",
        artworkURL: session?.currentItem.artworkURL,
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
  #endif

  #if os(iOS)
    @ViewBuilder
    private var nowPlayingSheet: some View {
      ZStack(alignment: .top) {
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
            onAlbumInfoTap: session.currentItem.albumID == nil ? nil : {
              self.store.send(.nowPlayingAlbumInfoTapped)
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
            onPlayPauseTap: {},
            onPreviousTap: {},
            onNextTap: {},
            onScrub: { _ in },
          )
        }

        if let failure = self.store.playback.failure {
          self.playbackFailureBanner(failure)
        }
      }
      .animation(.snappy(duration: 0.22), value: self.store.playback.failure)
    }

    private func playbackFailureBanner(_ failure: PlaybackFailure) -> some View {
      PlaybackErrorBanner(
        title: failure.title,
        message: failure.message,
        systemImage: failure.systemImage,
        actionTitle: failure.actionTitle,
        onActionTap: { self.store.send(.playback(.playbackFailureActionTapped)) },
        onDismissTap: { self.store.send(.playback(.playbackFailureDismissed)) },
      )
      .frame(maxWidth: 640)
      .padding(.horizontal, 18)
      .padding(.top, 12)
      .transition(.move(edge: .top).combined(with: .opacity))
    }
  #endif

  private var isPlaybackFailurePresentedInDetail: Bool {
    switch self.store.selectedTab {
    case .library:
      self.store.library.albumDetail != nil
        || self.store.library.playlistDetail != nil
    case .queue:
      false
    case .search:
      self.store.search.albumDetail != nil
        || self.store.search.playlistDetail != nil
    }
  }

  private var nowPlayingPresented: Binding<Bool> {
    self.$store.isNowPlayingPresented.sending(\.nowPlayingPresentationChanged)
  }

  private var selectedTab: Binding<AppFeature.Tab> {
    self.$store.selectedTab.sending(\.tabSelected)
  }
}

private extension PlaybackQueueEntry {
  var viewData: PlaybackQueueEntryData {
    PlaybackQueueEntryData(
      id: self.id,
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
