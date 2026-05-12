import SwiftUI

public struct GertrudeFMView: View {
  public init() {}

  public var body: some View {
    Text("Gertrude FM")
      .font(.largeTitle.bold())
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

#Preview {
  GertrudeFMView()
}
