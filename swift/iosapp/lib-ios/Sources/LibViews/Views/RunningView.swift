import ComposableArchitecture
import GertieUI
import LibApp
import SwiftUI

struct RunningView: View {
  @Environment(\.colorScheme) var cs

  @State private var showBg = false

  @Bindable var store: StoreOf<IOSReducer>

  var body: some View {
    ZStack {
      FairiesView()
        .opacity(self.showBg ? 1 : 0)
        .onAppear {
          withAnimation {
            self.showBg = true
          }
        }

      VStack(spacing: 0) {
        Spacer()

        Image(systemName: "checkmark")
          .font(.system(size: 40, weight: .regular))
          .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
          .accessibilityHidden(true)
          .swooshIn(
            fromYOffset: 20,
            after: .milliseconds(200),
            animation: .bouncy(duration: 0.5, extraBounce: 0.3),
          )

        Text("Gertude is blocking unwanted content")
          .font(.system(size: 24, weight: .medium))
          .padding(.bottom, 12)
          .padding(.top, 28)
          .swooshIn(
            fromYOffset: 20,
            after: .milliseconds(300),
            animation: .bouncy(duration: 0.5, extraBounce: 0.3),
          )

        Text("You can quit the app now, it will keep blocking even when not running.")
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .black.opacity(0.6), dark: .white.opacity(0.6)))
          .swooshIn(
            fromYOffset: 20,
            after: .milliseconds(400),
            animation: .bouncy(duration: 0.5, extraBounce: 0.3),
          )

        Link(destination: URL(string: "https://gertrude.app/iosapp-main")!) {
          HStack {
            Text("www.gertrude.app")
            Image(systemName: "arrow.up.right")
              .font(.system(size: 14, weight: .semibold))
              .offset(y: 1.5)
          }
        }
        .padding(.top, 25)
        .swooshIn(
          fromYOffset: 20,
          after: .milliseconds(500),
          animation: .bouncy(duration: 0.5, extraBounce: 0.3),
        )

        Spacer()

        Button(action: { self.store.send(.interactive(.infoBtnTapped)) }) {
          HStack(spacing: 6) {
            Image(systemName: "gearshape")
              .font(.system(size: 14, weight: .regular))
            Text("Info")
              .font(.system(size: 15, weight: .regular))
          }
        }
        .padding(.bottom, 12)
        .swooshIn(
          fromYOffset: 20,
          after: .milliseconds(600),
          animation: .bouncy(duration: 0.5, extraBounce: 0.3),
        )
      }
      .frame(maxWidth: .infinity)
      .multilineTextAlignment(.center)
      .padding(.horizontal, 30)
    }
  }
}

#Preview {
  RunningView(store: .init(initialState: .init()) { IOSReducer() })
}

#Preview("Dark Mode") {
  RunningView(store: .init(initialState: .init()) { IOSReducer() })
    .preferredColorScheme(.dark)
}
