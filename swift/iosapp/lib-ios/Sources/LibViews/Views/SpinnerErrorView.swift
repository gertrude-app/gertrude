import GertieUI
import SwiftUI

struct SpinnerErrorView: View {
  let loadingText: String
  let errorTitle: String
  let errorMessage: String?
  let isError: Bool
  let onRetry: () -> Void

  var body: some View {
    if self.isError {
      GertieResultScreen(
        icon: "xmark.circle.fill",
        tone: .error,
        title: self.errorTitle,
        message: self.errorMessage,
        action: .button("Try again") {
          self.onRetry()
        },
      )
    } else {
      GertieLoadingScreen(message: self.loadingText)
    }
  }
}

#Preview("Loading") {
  SpinnerErrorView(
    loadingText: "Doing something...",
    errorTitle: "Something went wrong",
    errorMessage: nil,
    isError: false,
    onRetry: {},
  )
}

#Preview("Setup code error") {
  SpinnerErrorView(
    loadingText: "Generating your setup code...",
    errorTitle: "Couldn’t generate a setup code",
    errorMessage: "Please try again.",
    isError: true,
    onRetry: {},
  )
}
