import ComposableArchitecture
import LibViews
import SwiftUI

struct AppView: View {
  @Bindable var store: StoreOf<AppFeature>

  private let nowPlayingPanelTransitionID = "now-playing-panel"
  private let nowPlayingArtworkTransitionID = "now-playing-artwork"

  var body: some View {
    #if os(iOS)
      self.iOSContent
        .overlay(alignment: .top) {
          if self.store.library.albumDetail == nil,
             let failure = self.store.playback.failure {
            self.playbackFailureBanner(failure)
          }
        }
        .animation(.snappy(duration: 0.22), value: self.store.playback.failure)
        .task {
          _ = self.store.send(.playback(.observePlayback))
          await self.store.send(.onAppear).finish()
        }
    #else
      self.libraryView
    #endif
  }

  private var libraryView: some View {
    LibraryViewContainer(
      store: self.store.scope(state: \.library, action: \.library),
    )
  }

  #if os(iOS)
    @ViewBuilder
    private var iOSContent: some View {
      switch self.store.connection {
      case .claimed:
        self.iOSLibraryContent
      case .checking:
        MusicAppConnectionView(
          state: .checking,
          onRetryTap: { self.store.send(.refreshConnectionTapped) },
        )
      case .unclaimed(let code, _):
        MusicAppConnectionView(
          state: .unclaimed(code: code),
          onRetryTap: { self.store.send(.refreshConnectionTapped) },
        )
      case .failed:
        MusicAppConnectionView(
          state: .failed,
          onRetryTap: { self.store.send(.refreshConnectionTapped) },
        )
      }
    }

    private var iOSLibraryContent: some View {
      self.libraryView
        .safeAreaInset(edge: .bottom, spacing: 0) {
          self.nowPlayingBarInset(showsBackground: true)
        }
        .nowPlayingZoomPresentation(
          isPresented: self.nowPlayingPresented,
          panelSourceID: self.nowPlayingPanelTransitionID,
          artworkID: self.nowPlayingArtworkTransitionID,
        ) {
          self.nowPlayingSheet
        }
    }

    private func nowPlayingBarInset(showsBackground: Bool) -> some View {
      self.nowPlayingBar(showsBackground: showsBackground)
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    private func nowPlayingBar(showsBackground: Bool) -> some View {
      let session = self.store.playback.session
      let artworkURL = session?.currentItem.allowsArtwork == true
        ? session?.currentItem.artworkURL
        : nil
      return NowPlayingBar(
        title: session?.currentItem.title ?? "Not Playing",
        artist: session?.currentItem.artistName ?? "Choose an approved track",
        artworkURL: artworkURL,
        isPlaying: session?.isPlaying ?? false,
        isLoading: session?.isLoading ?? false,
        isEnabled: session != nil,
        foregroundColor: .black,
        panelTransitionID: self.nowPlayingPanelTransitionID,
        artworkTransitionID: self.nowPlayingArtworkTransitionID,
        displayMode: .expanded,
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
            showsArtwork: session.currentItem.allowsArtwork,
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
          )
        } else {
          NowPlayingScreenView(
            title: "Not Playing",
            artist: "Choose an approved track",
            artworkURL: nil,
            showsArtwork: false,
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
