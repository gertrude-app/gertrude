import Foundation
import SwiftUI

#if os(iOS)
  import UIKit
#endif

public func artistArtworkZoomTransitionID(for artistID: String) -> String {
  "artist-artwork-\(artistID)"
}

public struct ZoomableArtistArtworkView: View {
  @Environment(\.colorScheme) private var colorScheme

  private let artworkUrl: URL?
  private let size: CGFloat
  private let transitionID: String?
  private let role: ArtworkZoomRole

  public init(
    artworkUrl: URL?,
    size: CGFloat = 148,
    transitionID: String? = nil,
    role: ArtworkZoomRole = .source,
  ) {
    self.artworkUrl = artworkUrl
    self.size = size
    self.transitionID = transitionID
    self.role = role
  }

  public var body: some View {
    #if os(iOS)
      if #available(iOS 18.0, *), let transitionID {
        HostedZoomableArtistArtworkView(
          artworkUrl: self.artworkUrl,
          size: self.size,
          transitionID: transitionID,
          role: self.role,
          colorScheme: self.colorScheme,
        )
        .frame(width: self.size, height: self.size)
      } else {
        ArtistArtworkView(
          artworkUrl: self.artworkUrl,
          size: self.size,
        )
      }
    #else
      ArtistArtworkView(
        artworkUrl: self.artworkUrl,
        size: self.size,
      )
    #endif
  }
}

extension View {
  func artistDetailZoomPush(
    artist: ArtistData?,
    releases: [ArtistReleaseData],
    currentTrackID: String?,
    isPlaying: Bool,
    isLoading: Bool,
    onPlayTap: @MainActor @escaping (String) -> Void,
    onSongTap: @MainActor @escaping (String, String) -> Void,
    onReleaseTap: @MainActor @escaping (String) -> Void,
    onDismiss: @MainActor @escaping (String) -> Void,
  ) -> some View {
    self.modifier(ArtistDetailZoomPushModifier(
      artist: artist,
      releases: releases,
      currentTrackID: currentTrackID,
      isPlaying: isPlaying,
      isLoading: isLoading,
      onPlayTap: onPlayTap,
      onSongTap: onSongTap,
      onReleaseTap: onReleaseTap,
      onDismiss: onDismiss,
    ))
  }
}

private struct ArtistDetailZoomPushModifier: ViewModifier {
  let artist: ArtistData?
  let releases: [ArtistReleaseData]
  let currentTrackID: String?
  let isPlaying: Bool
  let isLoading: Bool
  let onPlayTap: @MainActor (String) -> Void
  let onSongTap: @MainActor (String, String) -> Void
  let onReleaseTap: @MainActor (String) -> Void
  let onDismiss: @MainActor (String) -> Void

  #if os(iOS)
    @State private var navigationController: UINavigationController?
    @State private var pushedArtistID: String?
  #endif

  func body(content: Content) -> some View {
    #if os(iOS)
      content
        .background {
          NavigationControllerReader { navigationController in
            if self.navigationController !== navigationController {
              self.navigationController = navigationController
            }
            self.pushArtistDetailIfNeeded()
          }
        }
        .onChange(of: self.artist?.id, initial: true) { _, _ in
          self.pushArtistDetailIfNeeded()
        }
        .onChange(of: self.currentTrackID) { _, _ in
          self.pushArtistDetailIfNeeded()
        }
        .onChange(of: self.isPlaying) { _, _ in
          self.pushArtistDetailIfNeeded()
        }
        .onChange(of: self.isLoading) { _, _ in
          self.pushArtistDetailIfNeeded()
        }
    #else
      content
    #endif
  }

  #if os(iOS)
    private func pushArtistDetailIfNeeded() {
      guard let artist else {
        self.pushedArtistID = nil
        return
      }

      let rootView = ArtistDetailView(
        artist: ArtistDetailData(artist: artist),
        topSongs: artist.topSongs,
        releases: self.releases,
        transitionSourceID: artist.id,
        currentTrackID: self.currentTrackID,
        isPlaying: self.isPlaying,
        isLoading: self.isLoading,
        onPlayTap: { self.onPlayTap(artist.id) },
        onSongTap: { self.onSongTap(artist.id, $0) },
        onReleaseTap: self.onReleaseTap,
      )

      if self.pushedArtistID == artist.id {
        _ = ArtworkDetailZoomPusher.update(
          kind: .artist,
          pushID: artist.id,
          rootView: rootView,
          in: self.navigationController,
        )
        return
      }
      self.pushedArtistID = artist.id

      let didPush = ArtworkDetailZoomPusher.push(
        kind: .artist,
        pushID: artist.id,
        transitionID: artistArtworkZoomTransitionID(for: artist.id),
        rootView: rootView,
        in: self.navigationController,
        onPop: { self.onDismiss(artist.id) },
      )
      if !didPush {
        self.pushedArtistID = nil
      }
    }
  #endif
}

#if os(iOS)
  private struct HostedZoomableArtistArtworkView: UIViewRepresentable {
    let artworkUrl: URL?
    let size: CGFloat
    let transitionID: String
    let role: ArtworkZoomRole
    let colorScheme: ColorScheme

    func makeUIView(context: Context) -> HostedArtistArtworkUIView {
      let view = HostedArtistArtworkUIView()
      view.update(
        artworkUrl: self.artworkUrl,
        size: self.size,
        colorScheme: self.colorScheme,
      )
      ArtworkZoomRegistry.shared.register(view, id: self.transitionID, role: self.role)
      return view
    }

    func updateUIView(_ uiView: HostedArtistArtworkUIView, context: Context) {
      uiView.update(
        artworkUrl: self.artworkUrl,
        size: self.size,
        colorScheme: self.colorScheme,
      )
      ArtworkZoomRegistry.shared.register(uiView, id: self.transitionID, role: self.role)
    }

    static func dismantleUIView(_ uiView: HostedArtistArtworkUIView, coordinator: ()) {
      ArtworkZoomRegistry.shared.unregister(uiView)
    }
  }

  private final class HostedArtistArtworkUIView: UIView {
    private var hostingController: UIHostingController<AnyView>?

    override init(frame: CGRect) {
      super.init(frame: frame)
      self.backgroundColor = .clear
      self.clipsToBounds = false
      self.isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    func update(
      artworkUrl: URL?,
      size: CGFloat,
      colorScheme: ColorScheme,
    ) {
      let content = AnyView(
        ArtistArtworkView(artworkUrl: artworkUrl, size: size)
          .environment(\.colorScheme, colorScheme),
      )

      if let hostingController {
        hostingController.rootView = content
      } else {
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.isUserInteractionEnabled = false
        self.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
          hostingController.view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
          hostingController.view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
          hostingController.view.topAnchor.constraint(equalTo: self.topAnchor),
          hostingController.view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
        self.hostingController = hostingController
      }
    }
  }
#endif
