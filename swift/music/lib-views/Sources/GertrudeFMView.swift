import SwiftUI

public struct GertrudeFMView: View {
  public init() {}

  public var body: some View {
    NavigationStack {
      LibraryView(state: .loaded(albums: .previewAlbums))
    }
  }
}

#Preview {
  GertrudeFMView()
}
