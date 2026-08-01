import GertieUI
import SwiftUI

struct ScreenIconBadgeCatalogView: View {
  private let examples = [
    Example(name: "Info", systemName: "info.circle"),
    Example(name: "Question", systemName: "questionmark.circle"),
    Example(name: "Error", systemName: "exclamationmark.circle"),
    Example(name: "Connection", systemName: "link.circle"),
    Example(name: "Payment", systemName: "creditcard"),
    Example(name: "Success", systemName: "checkmark.circle.fill"),
  ]

  var body: some View {
    ScrollView {
      LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 120), spacing: 24)],
        spacing: 32,
      ) {
        ForEach(self.examples) { example in
          VStack(spacing: 12) {
            GertieScreenIconBadge(systemName: example.systemName)

            Text(example.name)
              .font(.subheadline)
          }
        }
      }
      .padding(30)
    }
    .navigationTitle("Screen Icons")
    .navigationBarTitleDisplayMode(.inline)
  }

  private struct Example: Identifiable {
    let name: String
    let systemName: String

    var id: String { self.systemName }
  }
}
