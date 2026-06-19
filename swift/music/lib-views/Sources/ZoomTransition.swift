import SwiftUI

extension View {
  @ViewBuilder
  func matchedTransitionSourceIfAvailable<ID: Hashable>(
    id: ID,
    in namespace: Namespace.ID?,
    cornerRadius: CGFloat? = nil,
  ) -> some View {
    #if os(iOS)
      if #available(iOS 18.0, *), let namespace {
        if let cornerRadius {
          self.matchedTransitionSource(id: id, in: namespace) { source in
            source.clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
          }
        } else {
          self.matchedTransitionSource(id: id, in: namespace)
        }
      } else {
        self
      }
    #else
      if let namespace {
        if let cornerRadius {
          self.matchedTransitionSource(id: id, in: namespace) { source in
            source.clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
          }
        } else {
          self.matchedTransitionSource(id: id, in: namespace)
        }
      } else {
        self
      }
    #endif
  }

  @ViewBuilder
  func navigationZoomTransitionIfAvailable<ID: Hashable>(
    sourceID: ID?,
    in namespace: Namespace.ID?,
  ) -> some View {
    #if os(iOS)
      if #available(iOS 18.0, *), let sourceID, let namespace {
        self.navigationTransition(.zoom(sourceID: sourceID, in: namespace))
      } else {
        self
      }
    #else
      self
    #endif
  }
}
