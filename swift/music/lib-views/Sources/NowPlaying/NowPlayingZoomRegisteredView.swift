import SwiftUI

#if os(iOS)
  import UIKit

  enum NowPlayingZoomRole {
    case source
    case destination
  }

  struct NowPlayingZoomRegisteredView<Content: View>: UIViewRepresentable {
    let id: String
    let role: NowPlayingZoomRole
    let cornerRadius: CGFloat
    let allowsInteraction: Bool
    let content: Content

    init(
      id: String,
      role: NowPlayingZoomRole,
      cornerRadius: CGFloat,
      allowsInteraction: Bool = false,
      @ViewBuilder content: () -> Content,
    ) {
      self.id = id
      self.role = role
      self.cornerRadius = cornerRadius
      self.allowsInteraction = allowsInteraction
      self.content = content()
    }

    func makeUIView(context: Context) -> NowPlayingZoomUIView {
      let view = NowPlayingZoomUIView()
      view.update(
        rootView: AnyView(self.content),
        cornerRadius: self.cornerRadius,
        allowsInteraction: self.allowsInteraction,
      )
      NowPlayingZoomRegistry.shared.register(view, id: self.id, role: self.role)
      return view
    }

    func updateUIView(_ uiView: NowPlayingZoomUIView, context: Context) {
      uiView.update(
        rootView: AnyView(self.content),
        cornerRadius: self.cornerRadius,
        allowsInteraction: self.allowsInteraction,
      )
      NowPlayingZoomRegistry.shared.register(uiView, id: self.id, role: self.role)
    }

    static func dismantleUIView(_ uiView: NowPlayingZoomUIView, coordinator: ()) {
      NowPlayingZoomRegistry.shared.unregister(uiView)
    }

    func sizeThatFits(
      _ proposal: ProposedViewSize,
      uiView: NowPlayingZoomUIView,
      context: Context,
    ) -> CGSize? {
      uiView.fittingSize(for: proposal)
    }
  }

  @MainActor
  final class NowPlayingZoomUIView: UIView {
    private var hostingController: UIHostingController<AnyView>?

    override init(frame: CGRect) {
      super.init(frame: frame)
      self.backgroundColor = .clear
      self.isOpaque = false
      self.clipsToBounds = false
      self.isUserInteractionEnabled = false
      self.layer.cornerCurve = .continuous
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    func update(
      rootView: AnyView,
      cornerRadius: CGFloat,
      allowsInteraction: Bool,
    ) {
      self.layer.cornerRadius = cornerRadius
      self.isUserInteractionEnabled = allowsInteraction
      if let hostingController {
        hostingController.rootView = rootView
        hostingController.view.isUserInteractionEnabled = allowsInteraction
      } else {
        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.isOpaque = false
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.isUserInteractionEnabled = allowsInteraction
        self.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
          hostingController.view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
          hostingController.view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
          hostingController.view.topAnchor.constraint(equalTo: self.topAnchor),
          hostingController.view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
        self.hostingController = hostingController
      }
      self.invalidateIntrinsicContentSize()
    }

    func fittingSize(for proposal: ProposedViewSize) -> CGSize {
      let proposedWidth = proposal.width ?? UIScreen.main.bounds.width
      let proposedHeight = proposal.height ?? UIView.layoutFittingCompressedSize.height
      let targetSize = CGSize(width: proposedWidth, height: proposedHeight)
      let fittingSize = self.hostingController?.sizeThatFits(in: targetSize) ?? targetSize
      return CGSize(
        width: proposal.width ?? fittingSize.width,
        height: fittingSize.height,
      )
    }
  }

  @MainActor
  final class NowPlayingZoomRegistry {
    static let shared = NowPlayingZoomRegistry()

    private var sourceViews: [String: WeakUIView] = [:]
    private var destinationViews: [String: WeakUIView] = [:]

    func register(_ view: UIView, id: String, role: NowPlayingZoomRole) {
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
