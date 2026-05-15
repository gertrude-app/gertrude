import SwiftUI

struct ShelfHeaderView: View {
  let title: String
  let accessibilityLabel: String
  let onTap: @MainActor @Sendable () -> Void

  init(
    title: String,
    accessibilityLabel: String,
    onTap: @MainActor @escaping @Sendable () -> Void,
  ) {
    self.title = title
    self.accessibilityLabel = accessibilityLabel
    self.onTap = onTap
  }

  var body: some View {
    Button(action: self.onTap) {
      HStack(alignment: .center, spacing: 8) {
        Text(self.title)
          .font(.system(size: 24, weight: .bold))
          .foregroundStyle(.primary)

        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(.secondary)
          .offset(y: 1)

        Spacer()
      }
      .contentShape(Rectangle())
      .padding(.horizontal, 20)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(self.accessibilityLabel)
  }
}

#Preview("Shelf header") {
  ShelfHeaderView(
    title: "My albums",
    accessibilityLabel: "Show all albums",
    onTap: {},
  )
  .padding(.vertical, 12)
  .background(.background)
}
