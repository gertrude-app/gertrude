import GertieUI
import SwiftUI

struct FoldedContentLayout<Primary: View, Secondary: View>: View {
  private let geometry: FoldedContentGeometry
  private let primary: Primary
  private let secondary: Secondary

  init(
    geometry: FoldedContentGeometry,
    @ViewBuilder primary: (CGSize) -> Primary,
    @ViewBuilder secondary: (CGSize) -> Secondary,
  ) {
    self.geometry = geometry
    self.primary = primary(geometry.primarySize)
    self.secondary = secondary(geometry.secondarySize)
  }

  var body: some View {
    let layout = self.geometry.axis == .horizontal
      ? AnyLayout(HStackLayout(spacing: self.geometry.spacing))
      : AnyLayout(VStackLayout(spacing: self.geometry.spacing))

    layout {
      self.primary
        .frame(width: self.geometry.primarySize.width, height: self.geometry.primarySize.height)

      self.secondary
        .frame(width: self.geometry.secondarySize.width, height: self.geometry.secondarySize.height)
    }
  }
}
