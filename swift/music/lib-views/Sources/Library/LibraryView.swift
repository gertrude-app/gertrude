import Foundation
import SwiftUI

public enum LibraryViewState: Equatable, Sendable {
  case loading
  case loaded(items: [LibraryCollectionItemData])
  case empty
  case failed
  case musicAccessUnavailable
}

public struct LibraryView: View {
  private let state: LibraryViewState
  private let playingItemID: String?
  private let isRefreshing: Bool
  private let isPlaylistMutationInFlight: Bool
  private let transitionNamespace: Namespace.ID?
  private let onRetryTap: @MainActor @Sendable () -> Void
  private let onRefresh: @MainActor @Sendable () async -> Void
  private let onAlbumAddToPlaylist: @MainActor @Sendable (String) -> Void
  private let onAlbumAddToQueue: @MainActor @Sendable (String) -> Void
  private let onAlbumPlayNext: @MainActor @Sendable (String) -> Void
  private let onAlbumTap: @MainActor @Sendable (String) -> Void
  private let onArtistTap: @MainActor @Sendable (String) -> Void
  private let onCreatePlaylist: @MainActor @Sendable (String) -> Void
  private let onPlaylistAddToQueue: @MainActor @Sendable (String) -> Void
  private let onPlaylistPlayNext: @MainActor @Sendable (String) -> Void
  private let onPlaylistTap: @MainActor @Sendable (String) -> Void
  private let onDebugResetTap: (@MainActor @Sendable () -> Void)?

  @State private var createPlaylistName = ""
  @State private var isCreatePlaylistPromptPresented = false

  public init(
    state: LibraryViewState,
    playingItemID: String? = nil,
    isRefreshing: Bool = false,
    isPlaylistMutationInFlight: Bool = false,
    transitionNamespace: Namespace.ID? = nil,
    onRetryTap: @MainActor @escaping @Sendable () -> Void = {},
    onRefresh: @MainActor @escaping @Sendable () async -> Void = {},
    onAlbumAddToPlaylist: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onAlbumAddToQueue: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onAlbumPlayNext: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onAlbumTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onArtistTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onCreatePlaylist: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onPlaylistAddToQueue: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onPlaylistPlayNext: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onPlaylistTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onDebugResetTap: (@MainActor @Sendable () -> Void)? = nil,
  ) {
    self.state = state
    self.playingItemID = playingItemID
    self.isRefreshing = isRefreshing
    self.isPlaylistMutationInFlight = isPlaylistMutationInFlight
    self.transitionNamespace = transitionNamespace
    self.onRetryTap = onRetryTap
    self.onRefresh = onRefresh
    self.onAlbumAddToPlaylist = onAlbumAddToPlaylist
    self.onAlbumAddToQueue = onAlbumAddToQueue
    self.onAlbumPlayNext = onAlbumPlayNext
    self.onAlbumTap = onAlbumTap
    self.onArtistTap = onArtistTap
    self.onCreatePlaylist = onCreatePlaylist
    self.onPlaylistAddToQueue = onPlaylistAddToQueue
    self.onPlaylistPlayNext = onPlaylistPlayNext
    self.onPlaylistTap = onPlaylistTap
    self.onDebugResetTap = onDebugResetTap
  }

  public var body: some View {
    #if os(iOS)
      self.decoratedContent
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
          ToolbarItemGroup(placement: .topBarTrailing) {
            if self.showsRefreshIndicator {
              self.refreshToolbarContent
            }
            if self.showsCreateButton {
              self.createPlaylistButton
            }
          }
        }
    #else
      self.decoratedContent
        .navigationTitle("Library")
        .toolbar {
          ToolbarItemGroup(placement: .automatic) {
            if self.showsRefreshIndicator {
              self.refreshToolbarContent
            }
            if self.showsCreateButton {
              self.createPlaylistButton
            }
          }
        }
    #endif
  }

  private var decoratedContent: some View {
    self.content
      .refreshable {
        await self.onRefresh()
      }
      .overlay(alignment: .top) {
        LibraryRefreshAtmosphere(isActive: self.isRefreshing)
      }
      .alert("New Playlist", isPresented: self.$isCreatePlaylistPromptPresented) {
        TextField("Playlist Name", text: self.$createPlaylistName)
          .onSubmit(self.createPlaylistPromptSubmitted)
        Button("Cancel", role: .cancel, action: self.createPlaylistPromptCancelled)
          .tint(.primary)
        Button("Create", action: self.createPlaylistPromptSubmitted)
          .tint(.white)
          .keyboardShortcut(.defaultAction)
          .disabled(!self.createPlaylistName.isValidPlaylistName)
      } message: {
        Text("Enter a name for your playlist.")
      }
  }

  private var refreshToolbarContent: some View {
    ProgressView()
      .controlSize(.small)
      .tint(.primary)
      .accessibilityLabel("Refreshing library")
      .allowsHitTesting(false)
  }

  @ViewBuilder
  private var createPlaylistButton: some View {
    if self.isPlaylistMutationInFlight {
      ProgressView()
        .controlSize(.small)
        .tint(.primary)
        .accessibilityLabel("Saving playlist")
    } else {
      Button {
        self.createPlaylistName = ""
        self.isCreatePlaylistPromptPresented = true
      } label: {
        Label("New Playlist", systemImage: "plus")
      }
      .tint(.primary)
    }
  }

  private func createPlaylistPromptCancelled() {
    self.isCreatePlaylistPromptPresented = false
  }

  private func createPlaylistPromptSubmitted() {
    guard self.createPlaylistName.isValidPlaylistName else { return }
    self.isCreatePlaylistPromptPresented = false
    self.onCreatePlaylist(self.createPlaylistName)
  }

  private var showsCreateButton: Bool {
    switch self.state {
    case .loaded, .empty:
      true
    case .loading, .failed, .musicAccessUnavailable:
      false
    }
  }

  private var showsRefreshIndicator: Bool {
    guard self.isRefreshing else { return false }
    switch self.state {
    case .loaded, .empty:
      return true
    case .loading, .failed, .musicAccessUnavailable:
      return false
    }
  }

  @ViewBuilder
  private var content: some View {
    switch self.state {
    case .loading:
      LibraryGridView(items: [], isLoading: true)

    case .loaded(let items):
      LibraryGridView(
        items: items,
        playingItemID: self.playingItemID,
        transitionNamespace: self.transitionNamespace,
        onAlbumAddToPlaylist: self.onAlbumAddToPlaylist,
        onAlbumAddToQueue: self.onAlbumAddToQueue,
        onAlbumPlayNext: self.onAlbumPlayNext,
        onAlbumTap: self.onAlbumTap,
        onArtistTap: self.onArtistTap,
        onPlaylistAddToQueue: self.onPlaylistAddToQueue,
        onPlaylistPlayNext: self.onPlaylistPlayNext,
        onPlaylistTap: self.onPlaylistTap,
        onDebugResetTap: self.onDebugResetTap,
      )

    case .empty:
      self.messageContent(
        title: "No music yet",
        message: "Approved artists, albums, and your playlists will appear here.",
        systemImage: "rectangle.stack",
        buttonTitle: "Check again",
      )

    case .failed:
      self.messageContent(
        title: "Couldn’t load library",
        message: "Check your connection and try again.",
        systemImage: "wifi.exclamationmark",
        buttonTitle: "Try again",
      )

    case .musicAccessUnavailable:
      self.messageContent(
        title: "Music unavailable",
        message:
        "This device is connected, but Gertrude Music isn’t available for this account.",
        systemImage: "music.note",
        buttonTitle: "Check again",
      )
    }
  }

  private func messageContent(
    title: String,
    message: String,
    systemImage: String,
    buttonTitle: String,
  ) -> some View {
    ScrollView {
      VStack(spacing: 14) {
        LibraryMessageCard(
          title: title,
          message: message,
          systemImage: systemImage,
          buttonTitle: buttonTitle,
          onButtonTap: self.onRetryTap,
        )
        .frame(maxWidth: 600)

        #if DEBUG
          if let onDebugResetTap = self.onDebugResetTap {
            DebugResetOnboardingButton(onTap: onDebugResetTap)
          }
        #endif
      }
      .padding(.horizontal, 20)
      .padding(.top, 48)
      .padding(.bottom, 96)
    }
    .background(.background)
  }
}

#if DEBUG
  private let previewLibraryViewItems =
    [PlaylistData.previewRoadTrip].map(LibraryCollectionItemData.playlist)
      + [ArtistData].previewArtists.map(LibraryCollectionItemData.artist)
      + [AlbumData].previewAlbums.map(LibraryCollectionItemData.album)

  #Preview("Loaded") {
    NavigationStack {
      LibraryView(
        state: .loaded(items: previewLibraryViewItems),
        playingItemID: previewLibraryViewItems[0].id,
        onDebugResetTap: {},
      )
    }
  }

  #Preview("Loaded, Dark") {
    NavigationStack {
      LibraryView(state: .loaded(items: previewLibraryViewItems))
    }
    .preferredColorScheme(.dark)
  }

  #Preview("Loaded, Refreshing") {
    NavigationStack {
      LibraryView(
        state: .loaded(items: previewLibraryViewItems),
        isRefreshing: true,
      )
    }
  }

  #Preview("Loading") {
    NavigationStack {
      LibraryView(state: .loading)
    }
  }

  #Preview("Empty") {
    NavigationStack {
      LibraryView(state: .empty)
    }
  }

  #Preview("Subscription required") {
    NavigationStack {
      LibraryView(state: .musicAccessUnavailable)
    }
  }

  #Preview("Failed") {
    NavigationStack {
      LibraryView(state: .failed, onDebugResetTap: {})
    }
  }

#endif
