import Foundation
import SwiftUI

public extension Color {
  static let violet100 = Color(hex: "#ede9fe")!
  static let violet200 = Color(hex: "#ddd6fe")!
  static let violet300 = Color(hex: "#c4b5fd")!
  static let violet400 = Color(hex: "#a78bfa")!
  static let violet500 = Color(hex: "#8b5cf6")!
  static let violet600 = Color(hex: "#7c3aed")!
  static let violet700 = Color(hex: "#6d28d9")!
  static let violet800 = Color(hex: "#5b21b6")!
  static let violet900 = Color(hex: "#4c1d95")!
  static let violet950 = Color(hex: "#2e1065")!

  static let fuchsia100 = Color(hex: "#fae8ff")!
  static let fuchsia200 = Color(hex: "#f5d0fe")!
  static let fuchsia300 = Color(hex: "#f0abfc")!
  static let fuchsia400 = Color(hex: "#e879f9")!
  static let fuchsia500 = Color(hex: "#d946ef")!
  static let fuchsia600 = Color(hex: "#c026d3")!
  static let fuchsia700 = Color(hex: "#a21caf")!
  static let fuchsia800 = Color(hex: "#86198f")!
  static let fuchsia900 = Color(hex: "#701a75")!
  static let fuchsia950 = Color(hex: "#4a044e")!

  static let gertrudeBrandAccent = Color(
    .displayP3,
    red: 0.5234135825731157,
    green: 0.329732894016774,
    blue: 0.9906499401483219,
    opacity: 1,
  )

  init?(hex: String) {
    let red, green, blue: Double
    var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hex = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex

    var rgb: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&rgb)

    switch hex.count {
    case 3:
      (red, green, blue) = (
        Double((rgb >> 8) & 0xF) / 15.0,
        Double((rgb >> 4) & 0xF) / 15.0,
        Double(rgb & 0xF) / 15.0,
      )
    case 6:
      (red, green, blue) = (
        Double((rgb >> 16) & 0xFF) / 255.0,
        Double((rgb >> 8) & 0xFF) / 255.0,
        Double(rgb & 0xFF) / 255.0,
      )
    default:
      return nil
    }

    self.init(red: red, green: green, blue: blue)
  }

  init(_ colorScheme: ColorScheme, light: Color, dark: Color) {
    self = colorScheme == .dark ? dark : light
  }
}
