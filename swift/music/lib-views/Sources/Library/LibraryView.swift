import Foundation
import SwiftUI

public struct LibraryItemActions: Sendable {
  let onTap: @MainActor @Sendable (String) -> Void
  let onPlayNext: @MainActor @Sendable (String) -> Void
  let onAddToQueue: @MainActor @Sendable (String) -> Void
  let onAddToPlaylist: @MainActor @Sendable (String) -> Void

  public init(
    onTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onPlayNext: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onAddToQueue: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onAddToPlaylist: @MainActor @escaping @Sendable (String) -> Void = { _ in },
  ) {
    self.onTap = onTap
    self.onPlayNext = onPlayNext
    self.onAddToQueue = onAddToQueue
    self.onAddToPlaylist = onAddToPlaylist
  }
}

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
  private let onCreatePlaylist: @MainActor @Sendable (String) -> Void
  private let albumActions: LibraryItemActions
  private let artistActions: LibraryItemActions
  private let playlistActions: LibraryItemActions
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
    onCreatePlaylist: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    albumActions: LibraryItemActions = .init(),
    artistActions: LibraryItemActions = .init(),
    playlistActions: LibraryItemActions = .init(),
    onDebugResetTap: (@MainActor @Sendable () -> Void)? = nil,
  ) {
    self.state = state
    self.playingItemID = playingItemID
    self.isRefreshing = isRefreshing
    self.isPlaylistMutationInFlight = isPlaylistMutationInFlight
    self.transitionNamespace = transitionNamespace
    self.onRetryTap = onRetryTap
    self.onRefresh = onRefresh
    self.onCreatePlaylist = onCreatePlaylist
    self.albumActions = albumActions
    self.artistActions = artistActions
    self.playlistActions = playlistActions
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
      .sheet(isPresented: self.$isCreatePlaylistPromptPresented) {
        PlaylistNamePrompt(
          title: "New Playlist",
          message: "Enter a name for your playlist.",
          actionTitle: "Create",
          name: self.$createPlaylistName,
          onCancel: self.createPlaylistPromptCancelled,
          onSubmit: self.createPlaylistPromptSubmitted,
        )
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
        albumActions: self.albumActions,
        artistActions: self.artistActions,
        playlistActions: self.playlistActions,
        onDebugResetTap: self.onDebugResetTap,
      )

    case .empty:
      self.messageContent(
        title: "No music yet",
        message: "Approved artists, albums, and your playlists will appear here.",
        buttonTitle: "Check again",
      )

    case .failed:
      self.messageContent(
        title: "Couldn’t load library",
        message: "Check your connection and try again.",
        buttonTitle: "Try again",
      )

    case .musicAccessUnavailable:
      self.messageContent(
        title: "Subscription needs attention",
        message: "Gertrude Music requires at least an active $5/month Medium subscription. Ask the parent or accountability partner who manages the connected account to check its subscription or payment method.",
        buttonTitle: "Check again",
      )
    }
  }

  private func messageContent(
    title: String,
    message: String,
    buttonTitle: String,
  ) -> some View {
    ScrollView {
      VStack(spacing: 14) {
        MusicEmptyState(
          title,
          message: message,
          buttonTitle: buttonTitle,
          onButtonTap: self.onRetryTap,
        )

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
