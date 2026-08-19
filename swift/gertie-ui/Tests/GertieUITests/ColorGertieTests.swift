import SwiftUI
import Testing

@testable import GertieUI

@MainActor
@Test
func comparesResolvedColorLuminance() {
  let environment = EnvironmentValues()

  #expect(Color.black.isDarker(than: .white, in: environment))
  #expect(!Color.white.isDarker(than: .black, in: environment))
}
