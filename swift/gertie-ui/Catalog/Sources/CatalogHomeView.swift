import SwiftUI

struct CatalogHomeView: View {
  var body: some View {
    NavigationStack {
      List {
        Section("Foundations") {
          NavigationLink {
            ColorsCatalogView()
          } label: {
            Label("Colors", systemImage: "paintpalette")
          }
        }

        Section("Components") {
          NavigationLink {
            ButtonsCatalogView()
          } label: {
            Label("Buttons", systemImage: "rectangle.and.hand.point.up.left")
          }

          NavigationLink {
            WelcomeCatalogView()
          } label: {
            Label("Welcome", systemImage: "hand.wave")
          }

          NavigationLink {
            ScreenIconBadgeCatalogView()
          } label: {
            Label("Screen Icons", systemImage: "app.dashed")
          }

          NavigationLink {
            ActionScreenCatalogView()
          } label: {
            Label("Action Screen", systemImage: "rectangle.and.hand.point.up.left.fill")
          }

          NavigationLink {
            StatusCatalogView()
          } label: {
            Label("Loading & Status", systemImage: "progress.indicator")
          }
        }
      }
      .navigationTitle("Gertie UI")
    }
  }
}
