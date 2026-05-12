import SwiftUI

public struct GertrudeFMView: View {
  public init() {}

  public var body: some View {
    MusicPocView(
      state: .needsAuthorization,
      onAuthorizeTap: {},
      onPlayTap: {},
    )
  }
}

#Preview {
  GertrudeFMView()
}
