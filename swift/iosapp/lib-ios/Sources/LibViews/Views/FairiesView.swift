import GertieUI
import SwiftUI

struct FairiesView: View {
  struct Sparkle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let velocity: CGVector

    mutating func update(in size: CGSize) {
      self.position.x += self.velocity.dx
      self.position.y += self.velocity.dy

      if self.position.y > size.height + 10 {
        self.position.y = -10
      } else if self.position.y < -10 {
        self.position.y = size.height + 10
      }

      if self.position.x > size.width + 10 {
        self.position.x = -10
      } else if self.position.x < -10 {
        self.position.x = size.width + 10
      }
    }
  }

  @Environment(\.colorScheme) var cs
  @State private var sparkles = [Sparkle]()

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        Rectangle()
          .fill(Gradient(colors: [.clear, Color(self.cs, light: .violet300, dark: .violet950)]))
          .ignoresSafeArea()

        ForEach(self.sparkles) { sparkle in
          Circle()
            .frame(width: 3, height: 3)
            .foregroundStyle(Color.violet500)
            .blur(radius: 3)
            .position(x: sparkle.position.x, y: sparkle.position.y)
        }
        .ignoresSafeArea()
      }
      .task(id: proxy.size) {
        await self.animate(in: proxy.size)
      }
    }
  }

  @MainActor
  private func animate(in size: CGSize) async {
    self.sparkles = (0 ..< 30).map { _ in
      Sparkle(
        position: CGPoint(
          x: .random(in: 0 ... max(0, size.width)),
          y: .random(in: 0 ... max(0, size.height)),
        ),
        velocity: CGVector(
          dx: .random(in: -1 ... 1),
          dy: .random(in: -1 ... 1),
        ),
      )
    }

    while !Task.isCancelled {
      do {
        try await Task.sleep(for: .milliseconds(16))
      } catch {
        return
      }

      for index in self.sparkles.indices {
        self.sparkles[index].update(in: size)
      }
    }
  }
}

#Preview {
  FairiesView()
}
