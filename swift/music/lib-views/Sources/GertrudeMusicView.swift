import SwiftUI

public struct GertrudeMusicView: View {
  public init() {}

  public var body: some View {
    NavigationStack {
      LibraryView(state: .empty)
    }
  }
}

#if DEBUG
  #Preview {
    NavigationStack {
      LibraryView(state: .loaded(albums: .previewAlbums))
    }
  }
#endif
