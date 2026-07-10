import SwiftUI

public func albumArtworkZoomTransitionID(for albumID: String) -> String {
  "album-artwork-\(albumID)"
}

public struct ZoomableAlbumArtworkView: View {
  @Environment(\.colorScheme) private var colorScheme

  private let album: AlbumData
  private let size: CGFloat
  private let cornerRadius: CGFloat
  private let transitionID: String?
  private let role: ArtworkZoomRole

  public init(
    album: AlbumData,
    size: CGFloat = 148,
    cornerRadius: CGFloat = 12,
    transitionID: String? = nil,
    role: ArtworkZoomRole = .source,
  ) {
    self.album = album
    self.size = size
    self.cornerRadius = cornerRadius
    self.transitionID = transitionID
    self.role = role
  }

  public var body: some View {
    #if os(iOS)
      if #available(iOS 18.0, *), let transitionID {
        HostedZoomableAlbumArtworkView(
          album: self.album,
          size: self.size,
          cornerRadius: self.cornerRadius,
          transitionID: transitionID,
          role: self.role,
          colorScheme: self.colorScheme,
        )
        .frame(width: self.size, height: self.size)
      } else {
        AlbumArtworkView(
          album: self.album,
          size: self.size,
          cornerRadius: self.cornerRadius,
        )
      }
    #else
      AlbumArtworkView(
        album: self.album,
        size: self.size,
        cornerRadius: self.cornerRadius,
      )
    #endif
  }
}

#if os(iOS)
  import UIKit

  private struct HostedZoomableAlbumArtworkView: UIViewRepresentable {
    let album: AlbumData
    let size: CGFloat
    let cornerRadius: CGFloat
    let transitionID: String
    let role: ArtworkZoomRole
    let colorScheme: ColorScheme

    func makeUIView(context: Context) -> HostedAlbumArtworkUIView {
      let view = HostedAlbumArtworkUIView()
      view.update(
        album: self.album,
        size: self.size,
        cornerRadius: self.cornerRadius,
        colorScheme: self.colorScheme,
      )
      ArtworkZoomRegistry.shared.register(view, id: self.transitionID, role: self.role)
      return view
    }

    func updateUIView(_ uiView: HostedAlbumArtworkUIView, context: Context) {
      uiView.update(
        album: self.album,
        size: self.size,
        cornerRadius: self.cornerRadius,
        colorScheme: self.colorScheme,
      )
      ArtworkZoomRegistry.shared.register(uiView, id: self.transitionID, role: self.role)
    }

    static func dismantleUIView(_ uiView: HostedAlbumArtworkUIView, coordinator: ()) {
      ArtworkZoomRegistry.shared.unregister(uiView)
    }
  }

  private final class HostedAlbumArtworkUIView: UIView {
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
      album: AlbumData,
      size: CGFloat,
      cornerRadius: CGFloat,
      colorScheme: ColorScheme,
    ) {
      let content = AnyView(
        AlbumArtworkView(album: album, size: size, cornerRadius: cornerRadius)
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
