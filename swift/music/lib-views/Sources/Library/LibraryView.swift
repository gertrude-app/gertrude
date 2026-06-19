import SwiftUI

public enum LibraryViewState: Equatable, Sendable {
  case loading
  case loaded(albums: [AlbumData])
  case empty
  case failed
  case subscriptionRequired
}

public struct LibraryView: View {
  private let state: LibraryViewState
  private let transitionNamespace: Namespace.ID?
  private let onRetryTap: @MainActor @Sendable () -> Void
  private let onAlbumTap: @MainActor @Sendable (String) -> Void

  public init(
    state: LibraryViewState,
    transitionNamespace: Namespace.ID? = nil,
    onRetryTap: @MainActor @escaping @Sendable () -> Void = {},
    onAlbumTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
  ) {
    self.state = state
    self.transitionNamespace = transitionNamespace
    self.onRetryTap = onRetryTap
    self.onAlbumTap = onAlbumTap
  }

  public var body: some View {
    self.content
      .navigationTitle("Albums")
  }

  @ViewBuilder private var content: some View {
    switch self.state {
    case .loading:
      AlbumGridView(albums: [], isLoading: true)

    case .loaded(let albums):
      AlbumGridView(
        albums: albums,
        transitionNamespace: self.transitionNamespace,
        onAlbumTap: self.onAlbumTap,
      )

    case .empty:
      self.messageContent(
        title: "No albums yet",
        message: "Approved albums will appear here after a parent adds them in Gertrude.",
        systemImage: "rectangle.stack",
        buttonTitle: "Check again",
      )

    case .failed:
      self.messageContent(
        title: "Couldn’t load albums",
        message: "Check your connection and try again.",
        systemImage: "wifi.exclamationmark",
        buttonTitle: "Try again",
      )

    case .subscriptionRequired:
      self.messageContent(
        title: "Subscription required",
        message: "A parent needs Gertrude Light or Full before approved music can play on this device.",
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
      LibraryMessageCard(
        title: title,
        message: message,
        systemImage: systemImage,
        buttonTitle: buttonTitle,
        onButtonTap: self.onRetryTap,
      )
      .padding(.horizontal, 20)
      .padding(.top, 48)
      .padding(.bottom, 96)
    }
    .background(.background)
  }
}

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
    .background(.primary.opacity(0.05), in: .rect(cornerRadius: 28, style: .continuous))
  }
}

#if DEBUG
  #Preview("Loaded") {
    NavigationStack {
      LibraryView(state: .loaded(albums: .previewAlbums))
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
      LibraryView(state: .failed)
    }
  }
#endif
