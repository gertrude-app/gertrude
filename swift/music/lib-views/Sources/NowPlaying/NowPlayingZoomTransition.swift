import SwiftUI

#if os(iOS)
  import UIKit

  public extension View {
    func nowPlayingZoomPresentation(
      isPresented: Binding<Bool>,
      panelSourceID: String,
      artworkID: String,
      @ViewBuilder content: @escaping () -> some View,
    ) -> some View {
      self.background {
        NowPlayingZoomPresentationBridge(
          isPresented: isPresented,
          panelSourceID: panelSourceID,
          artworkID: artworkID,
          content: content,
        )
        .frame(width: 0, height: 0)
      }
    }
  }

  private struct NowPlayingZoomPresentationBridge<Presented: View>: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let panelSourceID: String
    let artworkID: String
    let content: () -> Presented

    func makeCoordinator() -> Coordinator {
      Coordinator()
    }

    func makeUIViewController(context: Context) -> NowPlayingZoomPresentationViewController {
      NowPlayingZoomPresentationViewController()
    }

    func updateUIViewController(
      _ uiViewController: NowPlayingZoomPresentationViewController,
      context: Context,
    ) {
      context.coordinator.isPresented = self.$isPresented
      uiViewController.update(
        isPresented: self.isPresented,
        panelSourceID: self.panelSourceID,
        artworkID: self.artworkID,
        rootView: AnyView(self.content()),
        onDismiss: { context.coordinator.presentationDidDismiss() },
      )
    }

    @MainActor
    final class Coordinator {
      var isPresented: Binding<Bool>?

      func presentationDidDismiss() {
        guard self.isPresented?.wrappedValue == true else { return }
        self.isPresented?.wrappedValue = false
      }
    }
  }

  @MainActor
  private final class NowPlayingZoomPresentationViewController: UIViewController {
    private weak var nowPlayingController: NowPlayingZoomHostingController?
    private var desiredPresentation = false
    private var panelSourceID = ""
    private var artworkID = ""
    private var rootView: AnyView?
    private var onDismiss: (@MainActor () -> Void)?
    private var isAnimatingPresentation = false
    private var isAnimatingDismissal = false

    override func viewDidLoad() {
      super.viewDidLoad()
      self.view.backgroundColor = .clear
    }

    override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      self.reconcilePresentation()
    }

    func update(
      isPresented: Bool,
      panelSourceID: String,
      artworkID: String,
      rootView: AnyView,
      onDismiss: @MainActor @escaping () -> Void,
    ) {
      self.desiredPresentation = isPresented
      self.panelSourceID = panelSourceID
      self.artworkID = artworkID
      self.rootView = rootView
      self.onDismiss = onDismiss
      self.reconcilePresentation()
    }

    private func reconcilePresentation() {
      guard self.isViewLoaded, self.view.window != nil else { return }

      if self.desiredPresentation {
        guard let rootView, let onDismiss else { return }
        if let nowPlayingController {
          nowPlayingController.rootView = rootView
          nowPlayingController.onDismissRequest = { [weak self] in
            self?.dismissNowPlaying(updatesState: true)
          }
          nowPlayingController.onDismiss = onDismiss
        } else {
          self.presentNowPlaying(
            rootView: rootView,
            onDismiss: onDismiss,
          )
        }
      } else {
        self.dismissNowPlaying(updatesState: false)
      }
    }

    private func presentNowPlaying(
      rootView: AnyView,
      onDismiss: @MainActor @escaping () -> Void,
    ) {
      guard !self.isAnimatingPresentation else { return }
      let controller = NowPlayingZoomHostingController(
        rootView: rootView,
        onDismiss: onDismiss,
        onDismissRequest: { [weak self] in
          self?.dismissNowPlaying(updatesState: true)
        },
      )
      controller.view.backgroundColor = .clear
      controller.modalPresentationStyle = .overFullScreen
      controller.modalPresentationCapturesStatusBarAppearance = true
      controller.view.alpha = 0
      self.nowPlayingController = controller
      self.isAnimatingPresentation = true
      self.present(controller, animated: false) { [weak self, weak controller] in
        guard let self, let controller else { return }
        self.performPresentationAnimation(for: controller, attemptsRemaining: 3)
      }
    }

    private func performPresentationAnimation(
      for controller: NowPlayingZoomHostingController,
      attemptsRemaining: Int,
    ) {
      self.layout(controller)
      guard let window = controller.view.window else {
        self.finishPresentation(controller)
        return
      }
      guard
        let artworkSourceView = NowPlayingZoomRegistry.shared.sourceView(for: self.artworkID),
        let artworkDestinationView = NowPlayingZoomRegistry.shared
        .destinationView(for: self.artworkID)
      else {
        if attemptsRemaining > 0 {
          Task { @MainActor in
            await Task.yield()
            self.performPresentationAnimation(
              for: controller,
              attemptsRemaining: attemptsRemaining - 1,
            )
          }
        } else {
          self.fadeIn(controller)
        }
        return
      }

      let panelSourceView = NowPlayingZoomRegistry.shared.sourceView(for: self.panelSourceID)
      let artworkSourceFrame = artworkSourceView.convert(artworkSourceView.bounds, to: window)
      let artworkDestinationFrame = artworkDestinationView.convert(
        artworkDestinationView.bounds,
        to: window,
      )
      let panelSourceFrame = panelSourceView?.convert(panelSourceView?.bounds ?? .zero, to: window)
        ?? artworkSourceFrame.insetBy(dx: -16, dy: -8)
      guard
        !artworkSourceFrame.isNull,
        !artworkDestinationFrame.isNull,
        artworkSourceFrame.width > 0,
        artworkDestinationFrame.width > 0
      else {
        self.fadeIn(controller)
        return
      }

      let originalControllerAlpha = controller.view.alpha
      let originalDestinationAlpha = artworkDestinationView.alpha
      controller.view.alpha = 1
      artworkDestinationView.alpha = 1
      controller.view.setNeedsLayout()
      controller.view.layoutIfNeeded()
      let artworkSnapshot = artworkDestinationView.snapshotView(afterScreenUpdates: false)
        ?? artworkSourceView.snapshotView(afterScreenUpdates: false)
      let panelSnapshot = panelSourceView?.snapshotView(afterScreenUpdates: false)
      controller.view.alpha = originalControllerAlpha
      artworkDestinationView.alpha = 0

      guard let artworkSnapshot else {
        artworkDestinationView.alpha = originalDestinationAlpha
        self.fadeIn(controller)
        return
      }

      let panelCard = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
      panelCard.frame = panelSourceFrame
      panelCard.layer.cornerCurve = .continuous
      panelCard.layer.cornerRadius = panelSourceView?.layer.cornerRadius ?? 24
      panelCard.clipsToBounds = true
      panelCard.alpha = 0.92
      window.addSubview(panelCard)

      if let panelSnapshot {
        panelSnapshot.frame = panelSourceFrame
        panelSnapshot.layer.cornerCurve = .continuous
        panelSnapshot.layer.cornerRadius = panelSourceView?.layer.cornerRadius ?? 24
        panelSnapshot.clipsToBounds = true
        window.addSubview(panelSnapshot)
      }

      artworkSnapshot.frame = artworkSourceFrame
      artworkSnapshot.layer.cornerCurve = .continuous
      artworkSnapshot.layer.cornerRadius = artworkSourceView.layer.cornerRadius
      artworkSnapshot.clipsToBounds = true
      window.addSubview(artworkSnapshot)
      controller.view.alpha = 0

      UIView.animate(
        withDuration: 0.52,
        delay: 0,
        usingSpringWithDamping: 0.9,
        initialSpringVelocity: 0.08,
        options: [.allowUserInteraction, .beginFromCurrentState],
      ) {
        controller.view.alpha = 1
        panelCard.frame = window.bounds
        panelCard.layer.cornerRadius = 0
        panelCard.alpha = 0
        panelSnapshot?.frame = window.bounds
        panelSnapshot?.layer.cornerRadius = 0
        panelSnapshot?.alpha = 0
        artworkSnapshot.frame = artworkDestinationFrame
        artworkSnapshot.layer.cornerRadius = artworkDestinationView.layer.cornerRadius
      } completion: { _ in
        artworkDestinationView.alpha = originalDestinationAlpha
        panelCard.removeFromSuperview()
        panelSnapshot?.removeFromSuperview()
        artworkSnapshot.removeFromSuperview()
        self.finishPresentation(controller)
      }
    }

    private func dismissNowPlaying(updatesState: Bool) {
      guard !self.isAnimatingDismissal else { return }
      guard let controller = self.nowPlayingController else {
        if updatesState {
          self.onDismiss?()
        }
        return
      }
      self.isAnimatingDismissal = true
      self.layout(controller)
      guard let window = controller.view.window else {
        self.finishDismissal(controller, updatesState: updatesState)
        return
      }
      guard
        let artworkSourceView = NowPlayingZoomRegistry.shared.sourceView(for: self.artworkID),
        let artworkDestinationView = NowPlayingZoomRegistry.shared
        .destinationView(for: self.artworkID),
        let artworkSnapshot = artworkDestinationView.snapshotView(afterScreenUpdates: false)
      else {
        self.fadeOut(controller, updatesState: updatesState)
        return
      }

      let panelSourceView = NowPlayingZoomRegistry.shared.sourceView(for: self.panelSourceID)
      let artworkSourceFrame = artworkSourceView.convert(artworkSourceView.bounds, to: window)
      let artworkDestinationFrame = artworkDestinationView.convert(
        artworkDestinationView.bounds,
        to: window,
      )
      let panelSourceFrame = panelSourceView?.convert(panelSourceView?.bounds ?? .zero, to: window)
        ?? artworkSourceFrame.insetBy(dx: -16, dy: -8)
      guard
        !artworkSourceFrame.isNull,
        !artworkDestinationFrame.isNull,
        artworkSourceFrame.width > 0,
        artworkDestinationFrame.width > 0
      else {
        self.fadeOut(controller, updatesState: updatesState)
        return
      }

      let panelCard = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
      panelCard.frame = window.bounds
      panelCard.layer.cornerCurve = .continuous
      panelCard.layer.cornerRadius = 0
      panelCard.clipsToBounds = true
      panelCard.alpha = 0
      window.addSubview(panelCard)

      artworkSnapshot.frame = artworkDestinationFrame
      artworkSnapshot.layer.cornerCurve = .continuous
      artworkSnapshot.layer.cornerRadius = artworkDestinationView.layer.cornerRadius
      artworkSnapshot.clipsToBounds = true
      window.addSubview(artworkSnapshot)
      let originalDestinationAlpha = artworkDestinationView.alpha
      artworkDestinationView.alpha = 0

      UIView.animate(
        withDuration: 0.44,
        delay: 0,
        usingSpringWithDamping: 0.92,
        initialSpringVelocity: 0.1,
        options: [.allowUserInteraction, .beginFromCurrentState],
      ) {
        controller.view.alpha = 0
        panelCard.frame = panelSourceFrame
        panelCard.layer.cornerRadius = panelSourceView?.layer.cornerRadius ?? 24
        panelCard.alpha = 0.15
        artworkSnapshot.frame = artworkSourceFrame
        artworkSnapshot.layer.cornerRadius = artworkSourceView.layer.cornerRadius
      } completion: { _ in
        artworkDestinationView.alpha = originalDestinationAlpha
        panelCard.removeFromSuperview()
        artworkSnapshot.removeFromSuperview()
        self.finishDismissal(controller, updatesState: updatesState)
      }
    }

    private func layout(_ controller: NowPlayingZoomHostingController) {
      controller.view.frame = controller.view.window?.bounds ?? self.view.window?.bounds ?? UIScreen
        .main.bounds
      controller.view.setNeedsLayout()
      controller.view.layoutIfNeeded()
    }

    private func fadeIn(_ controller: NowPlayingZoomHostingController) {
      UIView.animate(
        withDuration: 0.24,
        delay: 0,
        options: [.allowUserInteraction, .beginFromCurrentState],
      ) {
        controller.view.alpha = 1
      } completion: { _ in
        self.finishPresentation(controller)
      }
    }

    private func fadeOut(_ controller: NowPlayingZoomHostingController, updatesState: Bool) {
      UIView.animate(
        withDuration: 0.22,
        delay: 0,
        options: [.allowUserInteraction, .beginFromCurrentState],
      ) {
        controller.view.alpha = 0
      } completion: { _ in
        self.finishDismissal(controller, updatesState: updatesState)
      }
    }

    private func finishPresentation(_ controller: NowPlayingZoomHostingController) {
      self.isAnimatingPresentation = false
      controller.view.alpha = 1
    }

    private func finishDismissal(
      _ controller: NowPlayingZoomHostingController,
      updatesState: Bool,
    ) {
      controller.dismiss(animated: false) {
        self.isAnimatingDismissal = false
        self.nowPlayingController = nil
        if updatesState {
          self.onDismiss?()
        }
      }
    }
  }

  @MainActor
  private final class NowPlayingZoomHostingController: UIHostingController<AnyView> {
    var onDismiss: @MainActor () -> Void
    var onDismissRequest: @MainActor () -> Void
    private var didDismiss = false

    init(
      rootView: AnyView,
      onDismiss: @MainActor @escaping () -> Void,
      onDismissRequest: @MainActor @escaping () -> Void,
    ) {
      self.onDismiss = onDismiss
      self.onDismissRequest = onDismissRequest
      super.init(rootView: rootView)
    }

    override func viewDidLoad() {
      super.viewDidLoad()
      self.view.addGestureRecognizer(UIPanGestureRecognizer(
        target: self,
        action: #selector(self.handlePan(_:)),
      ))
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
      .lightContent
    }

    override func viewDidDisappear(_ animated: Bool) {
      super.viewDidDisappear(animated)
      if self.isBeingDismissed || self.presentingViewController == nil {
        self.notifyDismissed()
      }
    }

    @objc
    private func handlePan(_ recognizer: UIPanGestureRecognizer) {
      let translation = recognizer.translation(in: self.view)
      let progress = max(0, translation.y / 260)
      switch recognizer.state {
      case .changed:
        guard translation.y > 0 else { return }
        self.view.transform = CGAffineTransform(translationX: 0, y: translation.y * 0.28)
        self.view.alpha = max(0.72, 1 - progress * 0.22)
      case .ended:
        let velocity = recognizer.velocity(in: self.view)
        if translation.y > 90 || velocity.y > 650 {
          self.view.transform = .identity
          self.view.alpha = 1
          self.onDismissRequest()
        } else {
          UIView.animate(
            withDuration: 0.22,
            delay: 0,
            usingSpringWithDamping: 0.86,
            initialSpringVelocity: 0.1,
            options: [.allowUserInteraction, .beginFromCurrentState],
          ) {
            self.view.transform = .identity
            self.view.alpha = 1
          }
        }
      case .cancelled, .failed:
        UIView.animate(withDuration: 0.18) {
          self.view.transform = .identity
          self.view.alpha = 1
        }
      default:
        break
      }
    }

    private func notifyDismissed() {
      guard !self.didDismiss else { return }
      self.didDismiss = true
      self.onDismiss()
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
  }

#endif
