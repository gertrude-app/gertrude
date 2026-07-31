import GertieUI
import SwiftUI

struct StatusCatalogView: View {
  var body: some View {
    List {
      NavigationLink("Loading screen") {
        GertieLoadingScreen(message: "Checking Gertrude account connection…")
          .navigationTitle("Loading")
          .navigationBarTitleDisplayMode(.inline)
      }

      NavigationLink("Long loading message") {
        GertieLoadingScreen(
          message: "Please wait while Gertrude fetches and validates the information needed to continue.",
        )
        .navigationTitle("Long Loading")
        .navigationBarTitleDisplayMode(.inline)
      }

      NavigationLink("Waiting status") {
        WaitingStatusCatalogView()
      }
    }
    .navigationTitle("Loading & Status")
    .navigationBarTitleDisplayMode(.inline)
  }
}

private struct WaitingStatusCatalogView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 40) {
      VStack(alignment: .leading, spacing: 16) {
        Text("Immediate")
          .font(.headline)
          .foregroundStyle(.secondary)

        GertieWaitingStatus(
          label: "Waiting for account connection…",
          delay: .zero,
        )
      }

      VStack(alignment: .leading, spacing: 16) {
        Text("After two seconds")
          .font(.headline)
          .foregroundStyle(.secondary)

        GertieWaitingStatus(
          label: "Waiting for the subscription…",
          delay: .seconds(2),
        )
      }

      Spacer()
    }
    .padding(30)
    .navigationTitle("Waiting Status")
    .navigationBarTitleDisplayMode(.inline)
  }
}
