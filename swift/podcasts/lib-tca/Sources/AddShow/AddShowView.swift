import ComposableArchitecture
import LibViews
import SwiftUI

struct AddShowView: View {
  @Bindable var store: StoreOf<AddShowFeature>
  @Dependency(\.haptics) var haptics
  @Dependency(\.keychain) var keychain

  var body: some View {
    Group {
      switch self.store.screen {
      case .enteringPin:
        PinCodeView(
          mode: .verify(
            self.pincode,
            lockout: self.store.lockout,
            onVerify: { self.store.send(.pincodeVerified) },
            onFail: { self.store.send(.pincodeFailed) },
          ),
          onCancel: { self.store.send(.pincodeCancelled) },
          onPrepHaptics: self.haptics.prepare,
        )

      case .changePinInstructions:
        ButtonScreenView(
          text: lstr(.pinChangeInstructions),
          primary: .init(lstr(.pinChangeProceed)) {
            self.store.send(.changePinInstructionsOkTapped)
          },
          ignoreKeyboard: true,
        )

      case .settingNewPin:
        PinCodeView(
          mode: .set(
            onComplete: { self.store.send(.newPinSubmitted($0)) },
            onConfirmFail: { self.store.send(.pincodeCancelled) },
          ),
          onCancel: { self.store.send(.pincodeCancelled) },
          onPrepHaptics: self.haptics.prepare,
        )

      case .choosingMethod:
        ButtonScreenView(
          text: lstr(.addShowHowToAdd),
          primary: .init(lstr(.addShowSearch)) {
            self.store.send(.selectSearchTapped)
          },
          secondary: .init(lstr(.addShowAddByUrl)) {
            self.store.send(.selectAddByUrlTapped)
          },
        )

      case .searching:
        SearchShowView(
          searchText: self.$store.searchText.sending(\.setSearchText),
          results: self.store.searchResults,
          onResultTap: { self.store.send(.selectShow($0)) },
        )
        .task(id: self.store.searchText) {
          do {
            try await Task.sleep(for: .milliseconds(500))
            self.store.send(.searchSetDebounced)
          } catch {}
        }

      case .chooseArtworkPolicy:
        ButtonScreenView(
          text: lstr(.addShowShowArtworkQuestion),
          primary: .init(lstr(.addShowAllowImages)) {
            self.store.send(.selectAllowArtworkTapped)
          },
          secondary: .init(lstr(.addShowNoImages)) {
            self.store.send(.selectDontAllowArtworkTapped)
          },
          ignoreKeyboard: true,
        )

      case .subscribing:
        LoadingScreenView(text: lstr(.addShowSubscribing))

      case .addingByUrl:
        ButtonScreenView(
          text: lstr(.addShowEnterUrl),
          urlInput: .init(
            placeholder: "https://site.com/feed.xml",
            buttonText: lstr(.addShowSubscribe),
          ) { url in
            self.store.send(.addByUrlSubmitted(url))
          },
          animateBtnEntry: false,
        )
      }
    }
  }

  var pincode: Int {
    if let pin = self.keychain.loadPincode() {
      return pin
    } else {
      log(.error("17cb36cc"), "missing pincode")
      return Int.random(in: 100_000 ... 999_999)
    }
  }
}
