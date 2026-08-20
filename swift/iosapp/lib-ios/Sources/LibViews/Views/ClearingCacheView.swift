import ComposableArchitecture
import GertieUI
import LibApp
import SwiftUI

struct ClearingCacheView: View {
  @Environment(\.colorScheme) var cs

  @Bindable var store: StoreOf<ClearCacheFeature>

  var clearedMessage: String
  var clearedBtnLabel: String

  @State private var showBg = false

  var body: some View {
    switch self.store.screen {
    case .loading:
      Color.clear // can't use EmptyView, won't get .onAppear
    case .batteryWarning:
      self.batteryWarningView
    case .clearing:
      self.clearingView
    case .cleared:
      self.clearedView
    }
  }

  var batteryWarningView: some View {
    GertieActionScreen(
      message: "Clearing the cache uses a lot of battery; we recommend you plug in the device now.",
      action: .button("Next", behavior: .afterExitAnimation) {
        self.store.send(.batteryWarningContinueTapped)
      },
    )
  }

  var clearedView: some View {
    GertieResultScreen(
      icon: "checkmark.circle.fill",
      title: "Done!",
      message: self.clearedMessage,
      action: .button(self.clearedBtnLabel, behavior: .afterExitAnimation) {
        self.store.send(.completeBtnTapped)
      },
    )
  }

  var clearingView: some View {
    ZStack {
      FairiesView()
        .opacity(self.showBg ? 1 : 0)
        .onAppear {
          withAnimation {
            self.showBg = true
          }
        }

      VStack(spacing: 0) {
        ProgressView()
          .swooshIn(
            fromYOffset: 20,
            after: .milliseconds(200),
            animation: .bouncy(duration: 0.5, extraBounce: 0.3),
          )

        Text("Clearing cache...")
          .font(.system(size: 24, weight: .medium))
          .padding(.top, 16)
          .swooshIn(
            fromYOffset: 20,
            after: .milliseconds(300),
            animation: .bouncy(duration: 0.5, extraBounce: 0.3),
          )

        Text("This may take a little while.")
          .padding(.top, 6)
          .font(.system(size: 18, weight: .regular))
          .foregroundStyle(Color(self.cs, light: .black.opacity(0.7), dark: .white.opacity(0.7)))
          .swooshIn(
            fromYOffset: 20,
            after: .milliseconds(400),
            animation: .bouncy(duration: 0.5, extraBounce: 0.3),
          )

        if let availableSpace = self.store.availableDiskSpaceInBytes {
          ProgressView(
            value: Double(self.store.bytesCleared),
            // available is estimate, pad a little to prevent full bar
            total: Double(availableSpace) * 1.1,
          )
          .progressViewStyle(LinearProgressViewStyle())
          .frame(height: 20)
          .padding(.horizontal, 60)
          .padding(.top, 20)
          .swooshIn(
            fromYOffset: 20,
            after: .milliseconds(500),
            animation: .bouncy(duration: 0.5, extraBounce: 0.3),
          )
        }

        Text(
          "\(Bytes.humanReadable(self.store.bytesCleared, decimalPlaces: 3, prefix: .decimal)) checked",
        )
        .font(.system(size: 16, weight: .regular))
        .foregroundStyle(Color(self.cs, light: .black.opacity(0.4), dark: .white.opacity(0.4)))
        .padding(.top, 15)
        .swooshIn(
          fromYOffset: 20,
          after: .milliseconds(500),
          animation: .bouncy(duration: 0.5, extraBounce: 0.3),
        )
      }
    }
  }
}

#Preview("Battery warning") {
  ClearingCacheView(
    store: .init(initialState: .init(
      context: .onboarding,
      screen: .batteryWarning,
    )) {
      ClearCacheFeature()
    },
    clearedMessage: "Previously downloaded GIFs should be gone!",
    clearedBtnLabel: "Next",
  )
}

#Preview("Clearing") {
  ClearingCacheView(
    store: .init(initialState: .init(
      context: .onboarding,
      screen: .clearing,
      availableDiskSpaceInBytes: 3_000_000_000,
      bytesCleared: 1_040_031_000,
    )) {
      ClearCacheFeature()
    },
    clearedMessage: "Previously downloaded GIFs should be gone!",
    clearedBtnLabel: "Next",
  )
  .tint(.gertrudeBrandAccent)
}

#Preview("Cleared") {
  ClearingCacheView(
    store: .init(initialState: .init(
      context: .onboarding,
      screen: .cleared,
    )) {
      ClearCacheFeature()
    },
    clearedMessage: "Previously downloaded GIFs should be gone!",
    clearedBtnLabel: "Next",
  )
}
