import SwiftUI

struct EmptyTrackShelfCard: View {
  var body: some View {
    EmptyShelfCard(
      title: "No tracks yet",
      message: "Approved tracks will show up here.",
      icon: "play.fill",
    )
  }
}
