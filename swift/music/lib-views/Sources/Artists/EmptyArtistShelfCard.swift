import SwiftUI

struct EmptyArtistShelfCard: View {
  var body: some View {
    EmptyShelfCard(
      title: "No artists yet",
      message: "Approved artists will show up here.",
      icon: "circle.fill",
    )
  }
}
