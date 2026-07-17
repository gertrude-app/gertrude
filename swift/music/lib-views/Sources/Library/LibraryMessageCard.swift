import SwiftUI

struct LibraryMessageCard: View {
  let title: String
  let message: String
  let systemImage: String
  var buttonTitle: String?
  var onButtonTap: @MainActor @Sendable () -> Void = {}

  var body: some View {
    VStack(spacing: 16) {
      Circle()
        .fill(.primary.opacity(0.06))
        .frame(width: 76, height: 76)
        .overlay {
          Image(systemName: self.systemImage)
            .font(.system(size: 30, weight: .semibold))
            .foregroundStyle(.secondary)
        }

      VStack(spacing: 6) {
        Text(self.title)
          .font(.system(size: 22, weight: .bold, design: .rounded))
          .foregroundStyle(.primary)

        Text(self.message)
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }

      if let buttonTitle {
        Button(buttonTitle, action: self.onButtonTap)
          .buttonStyle(.borderedProminent)
          .padding(.top, 4)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(28)
    .background(
      .primary.opacity(0.05),
      in: .rect(cornerRadius: 28, style: .continuous),
    )
  }
}
