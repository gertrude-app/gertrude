import GertieUI
import SwiftUI

struct FinishedView: View {
  var body: some View {
    GertieResultScreen(
      icon: "party.popper",
      title: "Quit the app, you’re done!",
      message: "Gertrude will keep blocking even when the app is not running.",
    )
  }
}

#Preview {
  FinishedView()
}
