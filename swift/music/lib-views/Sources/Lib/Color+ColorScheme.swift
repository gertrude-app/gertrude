import SwiftUI

extension Color {
    init(_ cs: ColorScheme, light: Color, dark: Color) {
        self = cs == .dark ? dark : light
    }
}
