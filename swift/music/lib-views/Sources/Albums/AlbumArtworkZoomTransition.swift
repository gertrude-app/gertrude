import SwiftUI

public enum AlbumArtworkZoomRole: Sendable {
  case source
  case destination
}

public func albumArtworkZoomTransitionID(for albumID: String) -> String {
  "album-artwork-\(albumID)"
}

public struct ZoomableAlbumArtworkView: View {
  @Environment(\.colorScheme) private var colorScheme

  private let album: AlbumData
  private let size: CGFloat
  private let cornerRadius: CGFloat
  private let transitionID: String?
  private let role: AlbumArtworkZoomRole

  public init(
    album: AlbumData,
    size: CGFloat = 148,
    cornerRadius: CGFloat = 20,
    transitionID: String? = nil,
    role: AlbumArtworkZoomRole = .source,
  ) {
    self.album = album
    self.size = size
    self.cornerRadius = cornerRadius
    self.transitionID = transitionID
    self.role = role
  }

  public var body: some View {
    #if os(iOS)
      if let transitionID {
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
    let role: AlbumArtworkZoomRole
    let colorScheme: ColorScheme

    func makeUIView(context: Context) -> HostedAlbumArtworkUIView {
      let view = HostedAlbumArtworkUIView()
      view.update(
        album: self.album,
        size: self.size,
        cornerRadius: self.cornerRadius,
        colorScheme: self.colorScheme,
      )
      AlbumArtworkZoomRegistry.shared.register(view, id: self.transitionID, role: self.role)
      return view
    }

    func updateUIView(_ uiView: HostedAlbumArtworkUIView, context: Context) {
      uiView.update(
        album: self.album,
        size: self.size,
        cornerRadius: self.cornerRadius,
        colorScheme: self.colorScheme,
      )
      AlbumArtworkZoomRegistry.shared.register(uiView, id: self.transitionID, role: self.role)
    }

    static func dismantleUIView(_ uiView: HostedAlbumArtworkUIView, coordinator: ()) {
      AlbumArtworkZoomRegistry.shared.unregister(uiView)
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
          .environment(\.colorScheme, colorScheme)
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

  public struct NavigationControllerReader: UIViewControllerRepresentable {
    private let onResolve: (UINavigationController?) -> Void

    public init(onResolve: @escaping (UINavigationController?) -> Void) {
      self.onResolve = onResolve
    }

    public func makeUIViewController(context: Context) -> NavigationControllerReaderViewController {
      let viewController = NavigationControllerReaderViewController()
      viewController.onResolve = self.onResolve
      return viewController
    }

    public func updateUIViewController(
      _ uiViewController: NavigationControllerReaderViewController,
      context: Context,
    ) {
      uiViewController.onResolve = self.onResolve
      uiViewController.resolve()
    }
  }

  public final class NavigationControllerReaderViewController: UIViewController {
    var onResolve: ((UINavigationController?) -> Void)?
    private weak var resolvedNavigationController: UINavigationController?

    public override func viewDidLoad() {
      super.viewDidLoad()
      self.view.backgroundColor = .clear
    }

    public override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      self.resolve()
    }

    public override func didMove(toParent parent: UIViewController?) {
      super.didMove(toParent: parent)
      self.resolve()
    }

    func resolve() {
      guard self.resolvedNavigationController !== self.navigationController else { return }
      self.resolvedNavigationController = self.navigationController
      self.onResolve?(self.navigationController)
    }
  }

  @MainActor
  private final class AlbumDetailHostingController: UIHostingController<AnyView> {
    let pushID: String
    private let onPop: @MainActor () -> Void
    private var didPop = false

    init(
      pushID: String,
      rootView: AnyView,
      onPop: @MainActor @escaping () -> Void,
    ) {
      self.pushID = pushID
      self.onPop = onPop
      super.init(rootView: rootView)
    }

    override func viewDidDisappear(_ animated: Bool) {
      super.viewDidDisappear(animated)
      guard !self.didPop else { return }
      guard self.isMovingFromParent || self.navigationController?.viewControllers.contains(self) != true else {
        return
      }
      self.didPop = true
      self.onPop()
    }

    @available(*, unavailable)
    @MainActor
    required dynamic init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
  }

  public enum AlbumDetailZoomPusher {
    @discardableResult
    @MainActor
    public static func push<Content: View>(
      pushID: String,
      transitionSourceID: String?,
      rootView: Content,
      in navigationController: UINavigationController?,
      onPop: @MainActor @escaping () -> Void,
    ) -> Bool {
      guard let navigationController else { return false }
      if let topDetail = navigationController.topViewController as? AlbumDetailHostingController,
         topDetail.pushID == pushID
      {
        return true
      }

      let transitionID = transitionSourceID.map(albumArtworkZoomTransitionID)
      let detailViewController = AlbumDetailHostingController(
        pushID: pushID,
        rootView: AnyView(rootView),
        onPop: onPop,
      )
      detailViewController.view.backgroundColor = .systemBackground

      if let transitionID {
        let options = UIViewController.Transition.ZoomOptions()
        options.alignmentRectProvider = { context in
          MainActor.assumeIsolated {
            context.zoomedViewController.view.layoutIfNeeded()
            guard let destinationView = AlbumArtworkZoomRegistry.shared.destinationView(for: transitionID) else {
              return .null
            }
            return destinationView.convert(destinationView.bounds, to: context.zoomedViewController.view)
          }
        }

        detailViewController.preferredTransition = .zoom(options: options) { _ in
          MainActor.assumeIsolated {
            AlbumArtworkZoomRegistry.shared.sourceView(for: transitionID)
          }
        }
      }

      navigationController.pushViewController(detailViewController, animated: true)
      return true
    }
  }

  @MainActor
  private final class AlbumArtworkZoomRegistry {
    static let shared = AlbumArtworkZoomRegistry()

    private var sourceViews: [String: WeakUIView] = [:]
    private var destinationViews: [String: WeakUIView] = [:]

    func register(_ view: UIView, id: String, role: AlbumArtworkZoomRole) {
      self.unregister(view)
      switch role {
      case .source:
        self.sourceViews[id] = WeakUIView(view)
      case .destination:
        self.destinationViews[id] = WeakUIView(view)
      }
    }

    func unregister(_ view: UIView) {
      self.sourceViews = self.sourceViews.filter { $0.value.view !== view && $0.value.view != nil }
      self.destinationViews = self.destinationViews.filter { $0.value.view !== view && $0.value.view != nil }
    }

    func sourceView(for id: String) -> UIView? {
      self.sourceViews[id]?.view
    }

    func destinationView(for id: String) -> UIView? {
      self.destinationViews[id]?.view
    }
  }

  private final class WeakUIView {
    weak var view: UIView?

    init(_ view: UIView) {
      self.view = view
    }
  }
#endif
