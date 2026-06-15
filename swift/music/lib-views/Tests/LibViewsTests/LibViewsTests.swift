import Testing

@testable import LibViews

@MainActor
@Test
func packageLoads() {
  _ = GertrudeMusicView()
}
