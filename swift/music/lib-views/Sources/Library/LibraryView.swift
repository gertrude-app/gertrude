import Foundation
import SwiftUI

public enum LibraryViewState: Equatable, Sendable {
  case loading
  case loaded(albums: [AlbumData], artists: [ArtistData])
  case empty
  case failed
  case subscriptionRequired
}

public struct LibraryView: View {
  private let state: LibraryViewState
  private let isRefreshing: Bool
  private let transitionNamespace: Namespace.ID?
  private let onRetryTap: @MainActor @Sendable () -> Void
  private let onRefresh: @MainActor @Sendable () async -> Void
  private let onAlbumAddToQueue: @MainActor @Sendable (String) -> Void
  private let onAlbumPlayNext: @MainActor @Sendable (String) -> Void
  private let onAlbumTap: @MainActor @Sendable (String) -> Void
  private let onArtistTap: @MainActor @Sendable (String) -> Void
  private let onDebugResetTap: (@MainActor @Sendable () -> Void)?

  public init(
    state: LibraryViewState,
    isRefreshing: Bool = false,
    transitionNamespace: Namespace.ID? = nil,
    onRetryTap: @MainActor @escaping @Sendable () -> Void = {},
    onRefresh: @MainActor @escaping @Sendable () async -> Void = {},
    onAlbumAddToQueue: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onAlbumPlayNext: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onAlbumTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onArtistTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onDebugResetTap: (@MainActor @Sendable () -> Void)? = nil,
  ) {
    self.state = state
    self.isRefreshing = isRefreshing
    self.transitionNamespace = transitionNamespace
    self.onRetryTap = onRetryTap
    self.onRefresh = onRefresh
    self.onAlbumAddToQueue = onAlbumAddToQueue
    self.onAlbumPlayNext = onAlbumPlayNext
    self.onAlbumTap = onAlbumTap
    self.onArtistTap = onArtistTap
    self.onDebugResetTap = onDebugResetTap
  }

  public var body: some View {
    #if os(iOS)
      self.decoratedContent
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
          if self.showsRefreshIndicator {
            ToolbarItem(placement: .topBarTrailing) {
              self.refreshToolbarContent
            }
          }
        }
    #else
      self.decoratedContent
        .navigationTitle("Library")
        .toolbar {
          if self.showsRefreshIndicator {
            ToolbarItem(placement: .automatic) {
              self.refreshToolbarContent
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
  }

  private var refreshToolbarContent: some View {
    ProgressView()
      .controlSize(.small)
      .accessibilityLabel("Refreshing library")
      .allowsHitTesting(false)
  }

  private var showsRefreshIndicator: Bool {
    guard self.isRefreshing else { return false }
    switch self.state {
    case .loaded, .empty:
      return true
    case .loading, .failed, .subscriptionRequired:
      return false
    }
  }

  @ViewBuilder
  private var content: some View {
    switch self.state {
    case .loading:
      LibraryGridView(albums: [], isLoading: true)

    case .loaded(let albums, let artists):
      LibraryGridView(
        albums: albums,
        artists: artists,
        transitionNamespace: self.transitionNamespace,
        onAlbumAddToQueue: self.onAlbumAddToQueue,
        onAlbumPlayNext: self.onAlbumPlayNext,
        onAlbumTap: self.onAlbumTap,
        onArtistTap: self.onArtistTap,
        onDebugResetTap: self.onDebugResetTap,
      )

    case .empty:
      self.messageContent(
        title: "No music yet",
        message: "Approved artists and albums will appear here after they’re added in Gertrude.",
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

    case .subscriptionRequired:
      self.messageContent(
        title: "Subscription required",
        message:
        "The Gertrude account needs an active subscription before approved music can play on this device.",
        systemImage: "creditcard",
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
  #Preview("Loaded") {
    NavigationStack {
      LibraryView(
        state: .loaded(albums: .previewAlbums, artists: .previewArtists),
        onDebugResetTap: {},
      )
    }
  }

  #Preview("Loaded, Refreshing") {
    NavigationStack {
      LibraryView(
        state: .loaded(albums: .previewAlbums, artists: .previewArtists),
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
      LibraryView(state: .subscriptionRequired)
    }
  }

  #Preview("Failed") {
    NavigationStack {
      LibraryView(state: .failed, onDebugResetTap: {})
    }
  }
#endif
