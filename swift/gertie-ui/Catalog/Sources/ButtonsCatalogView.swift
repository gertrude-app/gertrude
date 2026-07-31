import GertieUI
import SwiftUI

struct ButtonsCatalogView: View {
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 32) {
        VStack(alignment: .leading, spacing: 16) {
          Text("Primary")
            .font(.headline)
            .foregroundStyle(.secondary)

          Button("Continue") {}
            .buttonStyle(.gertiePrimary)

          Button {} label: {
            HStack(spacing: 8) {
              Text("Continue")
              Image(systemName: "arrow.right")
            }
          }
          .buttonStyle(.gertiePrimary)

          Button("Disabled") {}
            .buttonStyle(.gertiePrimary)
            .disabled(true)
        }

        VStack(alignment: .leading, spacing: 16) {
          Text("Secondary")
            .font(.headline)
            .foregroundStyle(.secondary)

          Button("Continue") {}
            .buttonStyle(.gertieSecondary)

          Button {} label: {
            HStack(spacing: 8) {
              Text("Continue")
              Image(systemName: "arrow.right")
            }
          }
          .buttonStyle(.gertieSecondary)

          Button("Disabled") {}
            .buttonStyle(.gertieSecondary)
            .disabled(true)
        }
      }
      .padding()
    }
    .navigationTitle("Buttons")
    .navigationBarTitleDisplayMode(.inline)
  }
}
