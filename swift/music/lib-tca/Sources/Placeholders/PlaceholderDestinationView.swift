import LibViews
import SwiftUI

struct PlaceholderDestinationView: View {
  let title: String
  let transitionSourceID: String?
  let transitionNamespace: Namespace.ID?

  var body: some View {
    #if os(iOS)
      if let transitionSourceID, let transitionNamespace {
        self.content
          .navigationTransition(.zoom(sourceID: transitionSourceID, in: transitionNamespace))
      } else {
        self.content
      }
    #else
      self.content
    #endif
  }

  private var content: some View {
    PlaceholderScreenView(title: self.title)
  }
}
