import ComposableArchitecture
import LibCore
import LibViews
import PodcastRoute
import SwiftUI

struct ClaimFlowView: View {
  @Bindable var store: StoreOf<ClaimFlow>

  var body: some View {
    Group {
      switch self.store.step {
      case .showingCode:
        ClaimCodeView(
          code: self.store.claimCode,
          failed: self.store.claimCodeFailed,
          dismissLabel: self.dismissLabel,
          deviceType: self.deviceFormFactor,
          onEvent: { event in
            switch event {
            case .retryTapped: self.store.send(.retryTapped)
            case .dismissTapped: self.store.send(.cancelTapped)
            }
          },
        )

      case .success:
        ClaimSuccessView(
          entitlement: self.store.entitlement?.claimSuccessEntitlement,
          deviceName: self.deviceName,
          buttonLabel: self.store.context == .onboarding ? lstr(.claimContinue) : nil,
          onEvent: { _ in
            self.store.send(self.store.successIsTerminal ? .doneTapped : .nextTapped)
          },
        )

      case .payment:
        ClaimPaymentView(
          shareUrl: self.remediationUrl,
          need: self.paymentNeed,
          dismissLabel: lstr(.claimNotNow),
          deviceType: self.deviceFormFactor,
          onEvent: { _ in self.store.send(.notNowTapped) },
        )
      }
    }
    .onAppear { self.store.send(.onAppear) }
  }

  private var dismissLabel: String {
    self.store.context == .modal ? lstr(.pinCancel) : lstr(.claimDismissSkip)
  }

  private var deviceName: String? {
    self.store.childName.map { String(format: lstr(.claimDeviceName), $0, self.deviceFormFactor) }
  }

  private var deviceFormFactor: String {
    UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
  }

  private var paymentNeed: ClaimPaymentView.Need {
    switch self.store.entitlement {
    case .legacyExpired: .renew
    default: .subscribe
    }
  }

  private var remediationUrl: String {
    switch self.store.entitlement {
    case .unpaid(let url), .legacyExpired(_, let url):
      url?.absoluteString ?? Self.fallbackUrl
    default:
      Self.fallbackUrl
    }
  }

  private static let fallbackUrl = "https://parents.gertrude.app/settings"
}
