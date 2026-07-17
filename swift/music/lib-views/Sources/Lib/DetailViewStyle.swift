import SwiftUI

extension View {
  @ViewBuilder
  func detailNavigationBarBackground() -> some View {
    #if os(iOS)
      self.toolbarBackground(.hidden, for: .navigationBar)
    #else
      self
    #endif
  }
}
