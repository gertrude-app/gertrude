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
          results: [],
          onResultTap: { _ in }
        )
        .task(id: self.store.searchText) {
          do {
            try await Task.sleep(for: .milliseconds(500))
            self.store.send(.searchSetDebounced)
          } catch {}
        }
      case .addingByUrl:
        Text("adding by URL")
      }
    }
  }
}
