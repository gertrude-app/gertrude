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
  private let currentTrackID: String?
  private let playbackQueueTrackIDs: [String]
  private let isPlaybackLoading: Bool
  private let isPlaybackPlaying: Bool
  private let onRetryTap: @MainActor @Sendable () -> Void
  private let onRefresh: @MainActor @Sendable () async -> Void
  private let onAlbumTap: @MainActor @Sendable (String) -> Void
  private let onArtistPlayTap: @MainActor @Sendable (String) -> Void
  private let onArtistSongTap: @MainActor @Sendable (String, String) -> Void
  private let onDebugResetTap: (@MainActor @Sendable () -> Void)?

  public init(
    state: LibraryViewState,
    isRefreshing: Bool = false,
    transitionNamespace: Namespace.ID? = nil,
    currentTrackID: String? = nil,
    playbackQueueTrackIDs: [String] = [],
    isPlaybackLoading: Bool = false,
    isPlaybackPlaying: Bool = false,
    onRetryTap: @MainActor @escaping @Sendable () -> Void = {},
    onRefresh: @MainActor @escaping @Sendable () async -> Void = {},
    onAlbumTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onArtistPlayTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onArtistSongTap: @MainActor @escaping @Sendable (String, String) -> Void = { _, _ in },
    onDebugResetTap: (@MainActor @Sendable () -> Void)? = nil,
  ) {
    self.state = state
    self.isRefreshing = isRefreshing
    self.transitionNamespace = transitionNamespace
    self.currentTrackID = currentTrackID
    self.playbackQueueTrackIDs = playbackQueueTrackIDs
    self.isPlaybackLoading = isPlaybackLoading
    self.isPlaybackPlaying = isPlaybackPlaying
    self.onRetryTap = onRetryTap
    self.onRefresh = onRefresh
    self.onAlbumTap = onAlbumTap
    self.onArtistPlayTap = onArtistPlayTap
    self.onArtistSongTap = onArtistSongTap
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

  @ViewBuilder private var content: some View {
    switch self.state {
    case .loading:
      LibraryGridView(albums: [], isLoading: true)

    case .loaded(let albums, let artists):
      self.loadedContent(albums: albums, artists: artists)

    case .empty:
      self.messageContent(
        title: "No music yet",
        message:
        "Approved artists and albums will appear here after they’re added in Gertrude.",
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

  private func loadedContent(albums: [AlbumData], artists: [ArtistData]) -> some View {
    LibraryGridView(
      albums: albums,
      artists: artists,
      transitionNamespace: self.transitionNamespace,
      currentTrackID: self.currentTrackID,
      playbackQueueTrackIDs: self.playbackQueueTrackIDs,
      isPlaybackLoading: self.isPlaybackLoading,
      isPlaybackPlaying: self.isPlaybackPlaying,
      onAlbumTap: self.onAlbumTap,
      onArtistPlayTap: self.onArtistPlayTap,
      onArtistSongTap: self.onArtistSongTap,
      onDebugResetTap: self.onDebugResetTap,
    )
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

        #if DEBUG
          if let onDebugResetTap = self.onDebugResetTap {
            LibraryDebugResetOnboardingButton(
              onTap: onDebugResetTap,
            )
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

private struct LibraryRefreshAtmosphere: View {
  @Environment(\.colorScheme) private var colorScheme

  let isActive: Bool

  @State private var isPresented = false
  @State private var isRendered = false

  var body: some View {
    Group {
      if self.isRendered {
        self.glow
          .frame(height: 430)
          .scaleEffect(x: 1.12, y: 0.98, anchor: .top)
          .offset(y: self.isPresented ? -24 : -520)
          .opacity(0.86)
          .blur(radius: 28)
          .mask(self.fade)
          .ignoresSafeArea(edges: .top)
          .allowsHitTesting(false)
          .accessibilityHidden(true)
      }
    }
    .task(id: self.isActive) {
      if self.isActive {
        self.isRendered = true
        self.isPresented = false
        await Task.yield()
        withAnimation(.snappy(duration: 0.68)) {
          self.isPresented = true
        }
      } else if self.isRendered {
        withAnimation(.snappy(duration: 0.52)) {
          self.isPresented = false
        }
        try? await Task.sleep(for: .milliseconds(640))
        if !Task.isCancelled {
          self.isRendered = false
        }
      }
    }
  }

  @ViewBuilder private var glow: some View {
    if #available(iOS 18.0, macOS 15.0, *) {
      MeshGradient(
        width: 5,
        height: 4,
        points: self.meshPoints,
        colors: self.meshColors,
        smoothsColors: true,
      )
    } else {
      LinearGradient(
        colors: [
          Color(
            self.colorScheme,
            light: .violet500.opacity(0.64),
            dark: .violet900.opacity(0.76),
          ),
          Color(
            self.colorScheme,
            light: .fuchsia500.opacity(0.34),
            dark: .fuchsia900.opacity(0.46),
          ),
          .clear,
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing,
      )
    }
  }

  private var meshPoints: [SIMD2<Float>] {
    [
      .init(0, 0), .init(0.26, 0), .init(0.50, 0.02), .init(0.74, 0), .init(1, 0),
      .init(0, 0.24), .init(0.24, 0.18), .init(0.50, 0.12), .init(0.76, 0.18), .init(1, 0.24),
      .init(0, 0.52), .init(0.24, 0.43), .init(0.50, 0.37), .init(0.76, 0.43), .init(1, 0.52),
      .init(0, 0.88), .init(0.28, 0.82), .init(0.50, 0.78), .init(0.72, 0.82), .init(1, 0.88),
    ]
  }

  private var meshColors: [Color] {
    [
      Color(self.colorScheme, light: .violet500.opacity(0.80), dark: .violet800.opacity(0.68)),
      Color(self.colorScheme, light: .fuchsia400.opacity(0.58), dark: .fuchsia900.opacity(0.52)),
      Color(self.colorScheme, light: .fuchsia300.opacity(0.66), dark: .fuchsia950.opacity(0.44)),
      Color(self.colorScheme, light: .fuchsia400.opacity(0.58), dark: .fuchsia900.opacity(0.52)),
      Color(self.colorScheme, light: .violet500.opacity(0.80), dark: .violet800.opacity(0.68)),
      Color(self.colorScheme, light: .violet600.opacity(0.54), dark: .violet900.opacity(0.52)),
      Color(self.colorScheme, light: .fuchsia500.opacity(0.42), dark: .fuchsia900.opacity(0.40)),
      Color(self.colorScheme, light: .violet500.opacity(0.42), dark: .violet900.opacity(0.38)),
      Color(self.colorScheme, light: .fuchsia500.opacity(0.42), dark: .fuchsia900.opacity(0.40)),
      Color(self.colorScheme, light: .violet600.opacity(0.54), dark: .violet900.opacity(0.52)),
      Color(self.colorScheme, light: .violet500.opacity(0.16), dark: .violet950.opacity(0.16)),
      Color(self.colorScheme, light: .fuchsia400.opacity(0.14), dark: .fuchsia950.opacity(0.14)),
      Color(self.colorScheme, light: .violet500.opacity(0.18), dark: .violet950.opacity(0.16)),
      Color(self.colorScheme, light: .fuchsia400.opacity(0.14), dark: .fuchsia950.opacity(0.14)),
      Color(self.colorScheme, light: .violet500.opacity(0.16), dark: .violet950.opacity(0.16)),
      .clear,
      .clear,
      .clear,
      .clear,
      .clear,
    ]
  }

  private var fade: some View {
    LinearGradient(
      stops: [
        .init(color: .black, location: 0),
        .init(color: .black.opacity(0.88), location: 0.34),
        .init(color: .black.opacity(0.18), location: 0.72),
        .init(color: .clear, location: 0.94),
      ],
      startPoint: .top,
      endPoint: .bottom,
    )
  }
}

#if DEBUG
  private struct LibraryDebugResetOnboardingButton: View {
    let onTap: @MainActor @Sendable () -> Void

    var body: some View {
      Button("Reset onboarding", action: self.onTap)
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .buttonStyle(.bordered)
        .tint(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
    }
  }
#endif

private struct LibraryMessageCard: View {
  let title: String
  let message: String
  let systemImage: String
  var buttonTitle: String?
  var onButtonTap: @MainActor @Sendable () -> Void = {}

  var body: some View {
    VStack(spacing: 16) {
      ZStack {
        Circle()
          .fill(.primary.opacity(0.06))
          .frame(width: 76, height: 76)

        Image(systemName: self.systemImage)
          .font(.system(size: 30, weight: .semibold))
          .foregroundStyle(.secondary)
      }

      VStack(spacing: 6) {
        Text(self.title)
          .font(.system(size: 22, weight: .bold, design: .rounded))
          .foregroundStyle(.primary)

        Text(self.message)
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }

      if let buttonTitle {
        Button(buttonTitle, action: self.onButtonTap)
          .buttonStyle(.borderedProminent)
          .padding(.top, 4)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(28)
    .background(
      .primary.opacity(0.05),
      in: .rect(cornerRadius: 28, style: .continuous),
    )
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
