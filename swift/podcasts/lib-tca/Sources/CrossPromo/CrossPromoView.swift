import ComposableArchitecture
import LibViews
import SwiftUI

#if os(iOS)
  import UIKit
#endif

struct CrossPromoView: View {
  let store: StoreOf<CrossPromoFeature>

  var body: some View {
    ButtonScreenView(
      text: "\(self.store.campaign.headline)\n\n\(self.store.campaign.body)",
      primary: .init(
        self.store.campaign.primaryCta.label,
        animate: false,
      ) {
        self.store.send(.primaryBtnTapped)
      },
      secondary: self.store.campaign.secondaryCta.map { cta in
        .init(cta.label, animate: false) {
          self.store.send(.secondaryBtnTapped)
        }
      },
      tertiary: self.store.campaign.tertiaryCta.map { cta in
        .init(cta.label, animate: false) {
          self.store.send(.tertiaryBtnTapped)
        }
      },
      remoteImage: self.store.campaign.image.map { .init(url: $0.url, label: $0.description) },
      screenType: .announcement,
    )
    .interactiveDismissDisabled(!self.store.campaign.dismissable)
    .background {
      #if os(iOS)
        SharePresenter(text: self.store.share?.text) { self.store.send(.shareCompleted($0)) }
      #else
        EmptyView()
      #endif
    }
  }
}

#if os(iOS)
  private struct SharePresenter: UIViewControllerRepresentable {
    let text: String?
    let onComplete: (Bool) -> Void

    func makeUIViewController(context _: Context) -> UIViewController {
      UIViewController()
    }

    func updateUIViewController(_ host: UIViewController, context _: Context) {
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
