import SwiftUI

public struct GertrudeFMView: View {
  public init() {}

  public var body: some View {
    MusicPocView(
      state: .needsAuthorization,
      onAuthorizeTap: {},
      onPlayPauseTap: {},
      onArtworkBlockingChanged: { _ in },
    )
  }
}

#Preview {
  GertrudeFMView()
}
