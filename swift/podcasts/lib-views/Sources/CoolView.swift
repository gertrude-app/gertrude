import SwiftUI

public struct CoolView: View {
  @State private var isAnimating = false

  public init() {}

  public var body: some View {
    VStack {
      Text("Cool View")
        .font(.largeTitle)
        .padding()

      Button(action: {
        withAnimation(.easeInOut(duration: 1.0)) {
          self.isAnimating.toggle()
        }
      }) {
        Text("Animate")
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(10)
      }

      if self.isAnimating {
        Circle()
          .fill(Color.red)
          .frame(width: 100, height: 100)
          .transition(.scale)
      }
    }
    .padding()
  }

  public func hello() -> String {
    "Hello from CoolView"
  }
}
