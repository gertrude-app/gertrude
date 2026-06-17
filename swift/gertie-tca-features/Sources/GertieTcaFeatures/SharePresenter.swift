#if os(iOS)
  import SwiftUI
  import UIKit

  public struct SharePresenter: UIViewControllerRepresentable {
    let text: String?
    let onComplete: (Bool) -> Void

    public init(text: String?, onComplete: @escaping (Bool) -> Void) {
      self.text = text
      self.onComplete = onComplete
    }

    public func makeUIViewController(context _: Context) -> UIViewController {
      UIViewController()
    }

    public func updateUIViewController(_ host: UIViewController, context _: Context) {
      if let text {
        guard host.presentedViewController == nil else { return }
        let activity = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        activity.completionWithItemsHandler = { _, completed, _, _ in self.onComplete(completed) }
        activity.popoverPresentationController?.sourceView = host.view
        activity.popoverPresentationController?.sourceRect = CGRect(
          x: host.view.bounds.midX,
          y: host.view.bounds.midY,
          width: 0,
          height: 0,
        )
        host.present(activity, animated: true)
      } else if host.presentedViewController is UIActivityViewController {
        host.dismiss(animated: true)
      }
    }
  }
#endif
