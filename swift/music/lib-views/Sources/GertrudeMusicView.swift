import SwiftUI

public struct GertrudeMusicView: View {
  public init() {}

  public var body: some View {
    NavigationStack {
      LibraryView(state: .loaded(albums: .previewAlbums))
    }
  }
}

#Preview {
  GertrudeMusicView()
}
