import SwiftUI

struct SkeletonBlock: View {
  @State private var isThrobbing = false

  let width: CGFloat?
  let height: CGFloat
  let cornerRadius: CGFloat

  init(
    width: CGFloat? = nil,
    height: CGFloat,
    cornerRadius: CGFloat,
  ) {
    self.width = width
    self.height = height
    self.cornerRadius = cornerRadius
  }

  var body: some View {
    Rectangle()
      .fill(.primary.opacity(0.08))
      .frame(width: self.width, height: self.height)
      .clipShape(.rect(cornerRadius: self.cornerRadius, style: .continuous))
      .opacity(self.isThrobbing ? 0.45 : 1)
      .onAppear {
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
          self.isThrobbing = true
        }
      }
  }
}
