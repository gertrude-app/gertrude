import SwiftUI

struct EmptyShelfCard: View {
  let title: String
  let message: String
  let icon: String

  var body: some View {
    HStack {
      Spacer()
      VStack(alignment: .center, spacing: 4) {
        HStack(spacing: 0) {
          Image(systemName: self.icon)
            .font(.system(size: 22, weight: .semibold))
            .rotationEffect(.degrees(-10))
          Image(systemName: self.icon)
            .font(.system(size: 28))
            .offset(y: -6)
          Image(systemName: self.icon)
            .font(.system(size: 22, weight: .semibold))
            .rotationEffect(.degrees(10))
        }
        .foregroundStyle(.primary.opacity(0.2))
        .padding(.bottom, 10)

        Text(self.title)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.primary)

        Text(self.message)
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(.secondary)
      }
      Spacer()
    }
    .padding(26)
    .background(.primary.opacity(0.05))
    .clipShape(.rect(cornerRadius: 20, style: .continuous))
    .frame(maxWidth: 600)
    .frame(maxWidth: .infinity)
  }
}
