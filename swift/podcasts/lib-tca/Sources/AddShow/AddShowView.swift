import ComposableArchitecture
import LibViews
import SwiftUI

struct AddShowView: View {
  @Bindable var store: StoreOf<AddShowFeature>

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
        )

      case .choosingMethod:
        ButtonScreenView(
          text: "How would you like to add a podcast?",
          primary: .init("Search") { self.store.send(.selectSearchTapped) },
          secondary: .init("Add by URL") { self.store.send(.selectAddByUrlTapped) },
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
          text: "Show podcast and episode images?",
          primary: .init("Yes, allow images") { self.store.send(.selectAllowArtworkTapped) },
          secondary: .init("No images") { self.store.send(.selectDontAllowArtworkTapped) },
        )

      case .subscribing:
        LoadingScreenView(text: "Subscribing...")

      case .subscribeError:
        ErrorView(text: "Adding show failed. Please try again.")

      case .addingByUrl:
        ButtonScreenView(
          text: "Enter a podcast RSS feed URL:",
          urlInput: .init(
            placeholder: "https://show.com/feed.rss",
            buttonText: "Subscribe"
          ) { url in
            self.store.send(.addByUrlSubmitted(url))
          }
        )
      }
    }
  }
}
