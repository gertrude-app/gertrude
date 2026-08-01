import ComposableArchitecture
import GertieUI
import LibViews
import SwiftUI

struct AddShowView: View {
  @Bindable var store: StoreOf<AddShowFeature>
  @Dependency(\.haptics) var haptics

  var body: some View {
    Group {
      switch self.store.screen {
      case .enteringPin:
        PinChallengeView(
          store: self.store.scope(state: \.pinChallenge, action: \.pinChallenge),
          context: .addShow,
        )

      case .changePinInstructions:
        GertieActionScreen(
          message: lstr(.pinChangeInstructions),
          action: .button(
            lstr(.pinChangeProceed),
            behavior: .afterExitAnimation,
          ) {
            self.store.send(.changePinInstructionsOkTapped)
          },
        )
        .ignoresSafeArea(.keyboard, edges: .bottom)

      case .settingNewPin:
        PinCodeView(
          mode: .set(
            onComplete: { self.store.send(.newPinSubmitted($0)) },
            onConfirmFail: { self.store.send(.newPinCancelled) },
          ),
          onCancel: { self.store.send(.newPinCancelled) },
          onPrepHaptics: self.haptics.prepare,
        )

      case .choosingMethod:
        GertieActionScreen(
          message: lstr(.addShowHowToAdd),
          actions: [
            .button(lstr(.addShowSearch), behavior: .afterExitAnimation) {
              self.store.send(.selectSearchTapped)
            },
            .button(lstr(.addShowAddByUrl), behavior: .afterExitAnimation) {
              self.store.send(.selectAddByUrlTapped)
            },
          ],
        )

      case .searching:
        SearchShowView(
          searchText: self.$store.searchText.sending(\.setSearchText),
          isSearching: self.store.searchInFlight,
          results: self.store.searchResults,
          onResultTap: { self.store.send(.selectShow($0)) },
          onSubmit: { self.store.send(.searchSubmitted) },
        )
        .task(id: self.store.searchText) {
          do {
            try await Task.sleep(for: .milliseconds(500))
            self.store.send(.searchSetDebounced)
          } catch {}
        }

      case .chooseArtworkPolicy:
        GertieActionScreen(
          message: lstr(.addShowShowArtworkQuestion),
          actions: [
            .button(lstr(.addShowAllowImages), behavior: .afterExitAnimation) {
              self.store.send(.selectAllowArtworkTapped)
            },
            .button(lstr(.addShowNoImages), behavior: .afterExitAnimation) {
              self.store.send(.selectDontAllowArtworkTapped)
            },
          ],
        )
        .ignoresSafeArea(.keyboard, edges: .bottom)

      case .subscribing:
        GertieLoadingScreen(message: lstr(.addShowSubscribing))

      case .addingByUrl:
        AddShowURLScreen { url in
          self.store.send(.addByUrlSubmitted(url))
        }
      }
    }
  }
}

private struct AddShowURLScreen: View {
  @Environment(\.colorScheme) private var colorScheme
  @FocusState private var isURLFieldFocused: Bool
  @State private var url = ""

  let onSubmit: @MainActor @Sendable (String) -> Void

  var body: some View {
    GertieActionScreen(
      message: lstr(.addShowEnterUrl),
      motion: .none,
      supplementPlacement: .afterMessage,
    ) {
      VStack(spacing: 40) {
        TextField("https://site.com/feed.xml", text: self.$url)
          .textInputAutocapitalization(.never)
          .font(.system(size: 22, weight: .medium))
          .textContentType(.URL)
          .autocorrectionDisabled()
          .focused(self.$isURLFieldFocused)
          .padding(.horizontal, 16)
          .padding(.vertical, 14)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(self.colorScheme == .dark ? Color.black : Color.white),
          )
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(
                Color.gray.opacity(self.colorScheme == .dark ? 0.5 : 0.3),
                lineWidth: 1,
              ),
          )
          .onAppear {
            self.isURLFieldFocused = true
          }

        Button(lstr(.addShowSubscribe)) {
          self.onSubmit(self.url)
        }
        .buttonStyle(.gertiePrimary)
        .disabled(self.url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      .padding(.bottom, 20)
    }
  }
}
