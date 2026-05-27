import SwiftUI

public struct PlaceholderScreenView: View {
  private let title: String

  public init(title: String) {
    self.title = title
  }

  public var body: some View {
    Text(self.title)
      .navigationTitle(self.title)
  }
}

#Preview("Placeholder") {
  NavigationStack {
    PlaceholderScreenView(title: "Queue")
  }
}
