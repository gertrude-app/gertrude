import SwiftUI

#if os(iOS)
  import UIKit
#endif

public enum ArtworkZoomRole: Sendable {
  case source
  case destination
}

public enum ArtworkDetailZoomKind: Hashable, Sendable {
  case album
  case artist
}

extension View {
  @ViewBuilder
  func matchedTransitionSourceIfAvailable<ID: Hashable>(
    id: ID,
    in namespace: Namespace.ID?,
    cornerRadius: CGFloat? = nil,
  ) -> some View {
    #if os(iOS)
      if #available(iOS 18.0, *), let namespace {
        if let cornerRadius {
          self.matchedTransitionSource(id: id, in: namespace) { source in
            source.clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
          }
        } else {
          self.matchedTransitionSource(id: id, in: namespace)
        }
      } else {
        self
      }
    #else
      if let namespace {
        if let cornerRadius {
          self.matchedTransitionSource(id: id, in: namespace) { source in
            source.clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
          }
        } else {
          self.matchedTransitionSource(id: id, in: namespace)
        }
      } else {
        self
      }
    #endif
  }

  @ViewBuilder
  func navigationZoomTransitionIfAvailable<ID: Hashable>(
    sourceID: ID?,
    in namespace: Namespace.ID?,
  ) -> some View {
    #if os(iOS)
      if #available(iOS 18.0, *), let sourceID, let namespace {
        self.navigationTransition(.zoom(sourceID: sourceID, in: namespace))
      } else {
        self
      }
    #else
      self
    #endif
  }
}

#if os(iOS)
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
      uiViewController.resolve(force: true)
    }
  }

  public final class NavigationControllerReaderViewController: UIViewController {
    var onResolve: ((UINavigationController?) -> Void)?
    private weak var resolvedNavigationController: UINavigationController?

    override public func viewDidLoad() {
      super.viewDidLoad()
      self.view.backgroundColor = .clear
    }

    override public func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      self.resolve()
    }

    override public func didMove(toParent parent: UIViewController?) {
      super.didMove(toParent: parent)
      self.resolve()
    }

    func resolve(force: Bool = false) {
      guard force || self.resolvedNavigationController !== self.navigationController else { return }
      self.resolvedNavigationController = self.navigationController
      self.onResolve?(self.navigationController)
    }
  }

  @MainActor
  private final class ArtworkDetailHostingController: UIHostingController<AnyView> {
    let kind: ArtworkDetailZoomKind
    let pushID: String
    private let onPop: @MainActor () -> Void
    private var didPop = false

    init(
      kind: ArtworkDetailZoomKind,
      pushID: String,
      rootView: AnyView,
      onPop: @MainActor @escaping () -> Void,
    ) {
      self.kind = kind
      self.pushID = pushID
      self.onPop = onPop
      super.init(rootView: rootView)
    }

    override func viewDidDisappear(_ animated: Bool) {
      super.viewDidDisappear(animated)
      guard !self.didPop else { return }
      guard self.isMovingFromParent || self.navigationController?.viewControllers
        .contains(self) != true else {
        return
      }
      self.didPop = true
      self.onPop()
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
  }

  public enum ArtworkDetailZoomPusher {
    @discardableResult
    @MainActor
    public static func push(
      kind: ArtworkDetailZoomKind,
      pushID: String,
      transitionID: String?,
      rootView: some View,
      in navigationController: UINavigationController?,
      onPop: @MainActor @escaping () -> Void,
    ) -> Bool {
      guard let navigationController else { return false }
      if let topDetail = navigationController.topViewController
        as? ArtworkDetailHostingController,
        topDetail.kind == kind {
        return topDetail.pushID == pushID
      }

      let detailViewController = ArtworkDetailHostingController(
        kind: kind,
        pushID: pushID,
        rootView: AnyView(rootView),
        onPop: onPop,
      )
      detailViewController.view.backgroundColor = .systemBackground
      self.configureTransition(for: detailViewController, transitionID: transitionID)

      navigationController.pushViewController(detailViewController, animated: true)
      return true
    }

    @discardableResult
    @MainActor
    public static func update(
      kind: ArtworkDetailZoomKind,
      pushID: String,
      rootView: some View,
      in navigationController: UINavigationController?,
    ) -> Bool {
      guard let detail = navigationController?.viewControllers
        .reversed()
        .compactMap({ $0 as? ArtworkDetailHostingController })
        .first(where: { $0.kind == kind && $0.pushID == pushID })
      else { return false }
      detail.rootView = AnyView(rootView)
      return true
    }

    @MainActor
    public static func topDetailPushID(
      kind: ArtworkDetailZoomKind,
      in navigationController: UINavigationController?,
    ) -> String? {
      guard let detail = navigationController?.topViewController
        as? ArtworkDetailHostingController,
        detail.kind == kind
      else { return nil }
      return detail.pushID
    }

    @discardableResult
    @MainActor
    public static func popTopDetail(
      kind: ArtworkDetailZoomKind,
      in navigationController: UINavigationController?,
    ) -> Bool {
      guard let navigationController,
            let detail = navigationController.topViewController as? ArtworkDetailHostingController,
            detail.kind == kind
      else { return false }
      navigationController.popViewController(animated: true)
      return true
    }

    @MainActor
    private static func configureTransition(
      for detailViewController: ArtworkDetailHostingController,
      transitionID: String?,
    ) {
      guard #available(iOS 18.0, *) else { return }
      guard let transitionID else {
        detailViewController.preferredTransition = nil
        return
      }

      let options = UIViewController.Transition.ZoomOptions()
      options.alignmentRectProvider = { context in
        MainActor.assumeIsolated {
          context.zoomedViewController.view.layoutIfNeeded()
          guard let destinationView = ArtworkZoomRegistry.shared
            .destinationView(for: transitionID) else {
            return .null
          }
          return destinationView.convert(
            destinationView.bounds,
            to: context.zoomedViewController.view,
          )
        }
      }

      detailViewController.preferredTransition = .zoom(options: options) { _ in
        MainActor.assumeIsolated {
          ArtworkZoomRegistry.shared.sourceView(for: transitionID)
        }
      }
    }
  }

  @MainActor
  final class ArtworkZoomRegistry {
    static let shared = ArtworkZoomRegistry()

    private var sourceViews: [String: WeakUIView] = [:]
    private var destinationViews: [String: WeakUIView] = [:]

    func register(_ view: UIView, id: String, role: ArtworkZoomRole) {
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
      self.destinationViews = self.destinationViews
        .filter { $0.value.view !== view && $0.value.view != nil }
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
