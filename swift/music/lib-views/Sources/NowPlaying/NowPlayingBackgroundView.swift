import Foundation
import SwiftUI

public struct NowPlayingBackgroundView: View {
  private let artworkURL: URL?

  public init(artworkURL: URL?) {
    self.artworkURL = artworkURL
  }

  public var body: some View {
    ZStack {
      Color.black

      BlurredArtworkBackground(artworkURL: self.artworkURL)
        .opacity(0.7)
    }
    .ignoresSafeArea()
  }
}
