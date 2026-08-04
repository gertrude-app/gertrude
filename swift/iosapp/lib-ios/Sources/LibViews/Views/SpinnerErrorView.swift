import GertieUI
import SwiftUI

struct SpinnerErrorView: View {
  let loadingText: String
  let errorText: String
  let isError: Bool
  let onRetry: () -> Void

  var body: some View {
    if self.isError {
      GertieActionScreen(
        message: self.errorText,
        icon: .error,
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
    errorText: "Something went wrong.",
    isError: false,
    onRetry: {},
  )
}

#Preview("Error") {
  SpinnerErrorView(
    loadingText: "Doing something...",
    errorText: "Something went wrong.",
    isError: true,
    onRetry: {},
  )
}
