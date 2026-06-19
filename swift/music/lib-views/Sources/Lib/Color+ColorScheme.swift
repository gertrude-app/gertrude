import SwiftUI

extension Color {
  public static let gertrudeBrandAccent = Color(
    .displayP3,
    red: 0.5234135825731157,
    green: 0.329732894016774,
    blue: 0.9906499401483219,
    opacity: 1,
  )

  init(_ cs: ColorScheme, light: Color, dark: Color) {
    self = cs == .dark ? dark : light
  }
}
