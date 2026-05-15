import SwiftUI

struct EmptyAlbumShelfCard: View {
  var body: some View {
    EmptyShelfCard(
      title: "No albums yet",
      message: "Approved albums will show up here.",
      icon: "square.fill",
    )
  }
}
