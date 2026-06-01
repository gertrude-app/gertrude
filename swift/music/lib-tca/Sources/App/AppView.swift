import ComposableArchitecture
import LibViews
import SwiftUI

struct AppView: View {
  @Environment(\.colorScheme) private var colorScheme

  @Bindable var store: StoreOf<AppFeature>

  private let nowPlayingPanelTransitionID = "now-playing-panel"
  private let nowPlayingArtworkTransitionID = "now-playing-artwork"

  var body: some View {
    #if os(iOS)
      if #available(iOS 26.0, *) {
        self.libraryView
          .safeAreaInset(edge: .bottom, spacing: 0) {
            self.nowPlayingAccessoryInset
          }
          .nowPlayingZoomPresentation(
            isPresented: self.nowPlayingPresented,
            panelSourceID: self.nowPlayingPanelTransitionID,
            artworkID: self.nowPlayingArtworkTransitionID,
          ) {
            self.nowPlayingSheet
          }
          .task {
            await self.store.send(.playback(.observePlayback)).finish()
          }
      } else {
        self.libraryView
          .task {
            await self.store.send(.playback(.observePlayback)).finish()
          }
      }
    #else
      self.libraryView
        .task {
          await self.store.send(.playback(.observePlayback)).finish()
        }
    #endif
  }

  private var libraryView: some View {
    LibraryViewContainer(
      store: self.store.scope(state: \.library, action: \.library),
    )
  }

  #if os(iOS)
    @available(iOS 26.0, *)
    private var nowPlayingAccessory: some View {
      let session = self.store.playback.session
      return NowPlayingAccessoryView(
        title: session?.currentItem.title ?? "Not Playing",
        artist: session?.currentItem.artistName ?? "Choose an approved track",
        artworkURL: session?.currentItem.allowsArtwork == true ? session?.currentItem
          .artworkURL : nil,
        isPlaying: session?.isPlaying ?? false,
        isEnabled: session != nil,
        foregroundColor: self.nowPlayingForegroundColor,
        panelTransitionID: self.nowPlayingPanelTransitionID,
        artworkTransitionID: self.nowPlayingArtworkTransitionID,
        displayMode: .expanded,
        showsGlassBackground: true,
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

    @available(iOS 26.0, *)
    private var nowPlayingAccessoryInset: some View {
      self.nowPlayingAccessory
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }
  #endif

  private var nowPlayingForegroundColor: Color {
    self.colorScheme == .dark ? .white : .black
  }

  #if os(iOS)
    @available(iOS 26.0, *)
    @ViewBuilder
    private var nowPlayingSheet: some View {
      if let session = self.store.playback.session {
        NowPlayingScreenView(
          title: session.currentItem.title,
          artist: session.currentItem.artistName,
          artworkURL: session.currentItem.artworkURL,
          showsArtwork: session.currentItem.allowsArtwork,
          artworkTransitionID: self.nowPlayingArtworkTransitionID,
          isPlaying: session.isPlaying,
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
          progress: 0,
          duration: 0,
        )
      }
    }
  #endif

  private var nowPlayingPresented: Binding<Bool> {
    Binding(
      get: { self.store.isNowPlayingPresented },
      set: { self.store.send(.nowPlayingPresentationChanged($0)) },
    )
  }
}
