import GertieUI
import SwiftUI

struct WelcomeCatalogView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    GertieWelcomeScreen(
      greeting: "Hi there!",
      message: "Gertrude blocks unwanted stuff, like GIFs, from your device.",
      actionTitle: "Get started",
    ) {
      self.dismiss()
    }
    .navigationTitle("Welcome")
    .navigationBarTitleDisplayMode(.inline)
  }
}
