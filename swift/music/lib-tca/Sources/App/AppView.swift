import ComposableArchitecture
import GertieTcaFeatures
import LibViews
import SwiftUI

struct AppView: View {
  @Bindable var store: StoreOf<AppFeature>
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.scenePhase) private var scenePhase

  private let nowPlayingPanelTransitionID = "now-playing-panel"
  private let nowPlayingArtworkTransitionID = "now-playing-artwork"

  var body: some View {
    Group {
      #if os(iOS)
        self.iOSContent
          .overlay(alignment: .top) {
            if self.store.library.albumDetail == nil,
               let failure = self.store.playback.failure {
              self.playbackFailureBanner(failure)
            }
          }
          .animation(.snappy(duration: 0.22), value: self.store.playback.failure)
          .task(id: self.store.setup.isReady) {
            guard self.store.setup.isReady else { return }
            await self.store.send(.playback(.restoreCachedSession)).finish()
            _ = self.store.send(.playback(.observePlayback))
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
    .killSwitch(
      store: self.store.scope(state: \.killSwitch, action: \.killSwitch),
      suggestedUpdatesEnabled: self.store.setup.isReady,
    )
  }

  private var libraryView: some View {
    LibraryViewContainer(
      store: self.store.scope(state: \.library, action: \.library),
      currentTrackID: self.store.playback.session?.currentTrackID,
      playbackQueueTrackIDs: self.store.playback.session?.queue.items.map(\.id) ?? [],
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
        .nowPlayingZoomPresentation(
          isPresented: self.nowPlayingPresented,
          panelSourceID: self.nowPlayingPanelTransitionID,
          artworkID: self.nowPlayingArtworkTransitionID,
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
        TabView {
          self.libraryView
            .tabItem {
              Label("Library", systemImage: "square.grid.2x2")
            }

          self.queueView
            .tabItem {
              Label("Queue", systemImage: "list.bullet")
            }

          self.searchView
            .tabItem {
              Label("Search", systemImage: "magnifyingglass")
            }
        }
      }
    }

    @available(iOS 18.0, *)
    private var modernIOSTabView: some View {
      TabView {
        Tab("Library", systemImage: "square.grid.2x2") {
          self.libraryView
        }

        Tab("Queue", systemImage: "list.bullet") {
          self.queueView
        }

        Tab("Search", systemImage: "magnifyingglass", role: .search) {
          self.searchView
        }
      }
    }

    private var queueView: some View {
      NavigationStack {
        if let session = self.store.playback.session {
          List(session.queue.items) { item in
            Text(item.title)
              .fontWeight(item.id == session.currentTrackID ? .semibold : .regular)
          }
          .navigationTitle("Queue")
        } else {
          ContentUnavailableView("Queue", systemImage: "list.bullet")
            .navigationTitle("Queue")
        }
      }
    }

    private var searchView: some View {
      NavigationStack {
        ContentUnavailableView("Search", systemImage: "magnifyingglass")
          .navigationTitle("Search")
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
      .padding(.vertical, 7)
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
        panelTransitionID: self.nowPlayingPanelTransitionID,
        artworkTransitionID: self.nowPlayingArtworkTransitionID,
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
            artworkTransitionID: self.nowPlayingArtworkTransitionID,
            isPlaying: session.isPlaying,
            isLoading: session.isLoading,
            progress: session.progress.fraction,
            duration: session.progress.duration,
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
            artworkTransitionID: self.nowPlayingArtworkTransitionID,
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
      .padding(.horizontal, 18)
      .padding(.top, 12)
      .transition(.move(edge: .top).combined(with: .opacity))
    }
  #endif

  private var nowPlayingPresented: Binding<Bool> {
    self.$store.isNowPlayingPresented.sending(\.nowPlayingPresentationChanged)
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
