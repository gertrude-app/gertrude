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
        // TODO: move to lib views, dark mode, previews
        VStack(spacing: 16) {
          ProgressView()
            .progressViewStyle(.circular)
            .scaleEffect(1.5)
          Text("Subscribing...")
            .font(.system(size: 18, weight: .medium))
        }

      case .subscribeError:
        Text("Adding show failed. Please try again.")
          .font(.system(size: 18, weight: .medium))
          .multilineTextAlignment(.center)
          .padding()

      case .addingByUrl:
        Text("adding by URL")
      }
    }
  }
}
