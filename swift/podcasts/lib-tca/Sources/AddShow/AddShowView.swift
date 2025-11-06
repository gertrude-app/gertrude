import ComposableArchitecture
import LibViews
import SwiftUI

struct AddShowView: View {
  @Bindable var store: StoreOf<AddShowFeature>
  @Dependency(\.haptics) var haptics

  var body: some View {
    Group {
      switch self.store.screen {
      case .enteringPin:
        PinCodeView(
          mode: .verify(
            self.store.passcode,
            lockout: self.store.lockout,
            onVerify: { self.store.send(.passcodeVerified) },
            onFail: { self.store.send(.passcodeFailed) },
          ),
          onCancel: { self.store.send(.passcodeCancelled) },
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
          onResultTap: { self.store.send(.selectShow($0)) }
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
          ignoreKeyboard: true
        )

      case .subscribing:
        LoadingScreenView(text: lstr(.addShowSubscribing))

      case .addingByUrl:
        ButtonScreenView(
          text: lstr(.addShowEnterUrl),
          urlInput: .init(
            placeholder: "https://site.com/feed.xml",
            buttonText: lstr(.addShowSubscribe)
          ) { url in
            self.store.send(.addByUrlSubmitted(url))
          },
          animateBtnEntry: false
        )
      }
    }
  }
}
